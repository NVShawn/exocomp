# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.CommandOutboxTest do
  use ExUnit.Case, async: true

  alias Ecto.Multi

  alias Exocomp.MissionControl.{
    ClusterGateway,
    ClusterSessions,
    Command,
    CommandOutbox
  }

  defmodule ReadOnlyRepo do
    def all(_query), do: Process.get(:pending_commands, [])
    def update_all(_query, []), do: {0, nil}
  end

  defmodule TransitionRepo do
    def update_all(_query, []) do
      case Process.get(:update_count, 0) do
        0 ->
          Process.put(:update_count, 1)
          {1, nil}

        _ ->
          {0, nil}
      end
    end

    def one(_query), do: Process.get(:command_status, "acknowledged")
    def insert(changeset), do: {:error, %{changeset | valid?: false}}
  end

  defmodule GatewayOutbox do
    def deliver_pending(_organization_id, _cluster_id, _session, sender, opts) do
      sender.(Keyword.fetch!(opts, :command))
      {:ok, %{sent: 1, failed: []}}
    end

    def acknowledge(organization_id, cluster_id, command_id, opts) do
      send(
        Keyword.fetch!(opts, :test_pid),
        {:acknowledged, organization_id, cluster_id, command_id}
      )

      {:ok, :acknowledged}
    end
  end

  defp command(id) do
    %Command{
      command_id: id,
      kind: "conversation.message",
      issued_at: ~U[2026-08-01 00:00:00.000000Z],
      expires_at: ~U[2026-08-01 00:05:00.000000Z],
      organization_id: "org-1",
      cluster_id: "cluster-1",
      payload: %{"message" => "hello"},
      status: "pending"
    }
  end

  test "rejects kinds outside the shared protocol allow-list before touching the repo" do
    assert {:error, {:invalid_command_kind, "shell.exec"}} =
             CommandOutbox.enqueue("org-1", "cluster-1", %{kind: "shell.exec", payload: %{}},
               repo: ReadOnlyRepo
             )
  end

  test "command changesets preserve the complete durable protocol envelope" do
    assert {:ok, changeset} =
             CommandOutbox.insert_changeset("org-1", "cluster-1", %{
               command_id: "cmd-valid",
               kind: "approval.decide",
               issued_at: ~U[2026-08-01 00:00:00.000000Z],
               expires_at: ~U[2026-08-01 00:05:00.000000Z],
               payload: %{"approval_id" => "approval-1", "decision" => "approve"}
             })

    assert changeset.valid?
    assert %Command{} = stored = Ecto.Changeset.apply_changes(changeset)

    assert %{
             "command_id" => "cmd-valid",
             "kind" => "approval.decide",
             "payload" => %{"approval_id" => "approval-1", "decision" => "approve"}
           } = Command.envelope(stored)
  end

  test "offline delivery does not invoke a sender" do
    sender = fn _command -> flunk("offline command was sent") end

    assert {:error, :offline} =
             CommandOutbox.deliver_pending("org-1", "cluster-1", nil, sender,
               repo: ReadOnlyRepo,
               now: ~U[2026-08-01 00:01:00.000000Z]
             )
  end

  test "a committed command notification reaches the owning cluster topic" do
    pubsub = :"command_outbox_pubsub_#{System.unique_integer([:positive])}"
    start_supervised!({Phoenix.PubSub, name: pubsub})

    assert :ok = Phoenix.PubSub.subscribe(pubsub, CommandOutbox.topic("org-1", "cluster-1"))
    assert :ok = CommandOutbox.notify("org-1", "cluster-1", pubsub: pubsub)
    assert_received {:command_outbox, :deliver}
  end

  test "reconnect delivery replays pending commands without acknowledging them" do
    Process.put(:pending_commands, [command("cmd-1")])
    test_pid = self()

    assert {:ok, %{sent: 1, failed: []}} =
             CommandOutbox.deliver_pending(
               "org-1",
               "cluster-1",
               %{session_id: "session-1"},
               fn delivered ->
                 send(test_pid, {:sent, delivered.command_id})
                 :ok
               end,
               repo: ReadOnlyRepo,
               now: ~U[2026-08-01 00:01:00.000000Z]
             )

    assert_received {:sent, "cmd-1"}
    assert hd(Process.get(:pending_commands)).status == "pending"
  end

  test "duplicate acknowledgements make exactly one durable transition" do
    assert {:ok, :acknowledged} =
             CommandOutbox.acknowledge("org-1", "cluster-1", "cmd-ack", repo: TransitionRepo)

    assert {:ok, :already_acknowledged} =
             CommandOutbox.acknowledge("org-1", "cluster-1", "cmd-ack", repo: TransitionRepo)
  end

  test "expiration marks an undelivered command terminal without acknowledging it" do
    assert {:ok, 1} =
             CommandOutbox.expire(
               repo: TransitionRepo,
               now: ~U[2026-08-01 00:10:00.000000Z],
               organization_id: "org-1",
               cluster_id: "cluster-1"
             )

    Process.put(:command_status, "expired")

    assert {:error, :expired} =
             CommandOutbox.acknowledge("org-1", "cluster-1", "cmd-expired",
               repo: TransitionRepo,
               now: ~U[2026-08-01 00:10:00.000000Z]
             )
  end

  test "a transaction rolls back the command insert" do
    multi =
      Multi.new()
      |> CommandOutbox.put_in_multi(:command, "org-1", "cluster-1", %{
        command_id: "cmd-rollback",
        kind: "conversation.message",
        payload: %{}
      })
      |> Multi.run(:forced_failure, fn _repo, _changes -> {:error, :forced} end)

    assert [{:command, {:insert, _changeset, []}}, {:forced_failure, {:run, _}}] =
             Multi.to_list(multi)
  end

  test "an active replacement session alone receives the next delivery wakeup" do
    registry = start_registry()
    identity = identity()

    assert {:ok, first_session} = ClusterSessions.register(registry, identity, self())
    assert {:ok, replacement_session} = ClusterSessions.register(registry, identity, self())
    assert first_session != replacement_session
    assert_receive {:mission_control_session_replaced, ^replacement_session}

    old_state = gateway_state(registry, identity, first_session)

    assert {:ok, ^old_state} =
             ClusterGateway.Socket.handle_info(
               {:mission_control_command_outbox_delivery, "org-1", "cluster-1"},
               old_state
             )

    refute_received {:mission_control_command, _command}

    current_state = gateway_state(registry, identity, replacement_session)

    assert {:ok, ^current_state} =
             ClusterGateway.Socket.handle_info(
               {:mission_control_command_outbox_delivery, "org-1", "cluster-1"},
               current_state
             )

    assert_received {:mission_control_command, %Command{command_id: "cmd-gateway"}}
  end

  test "a session-ownership broadcast closes a superseded replica socket" do
    identity = identity()
    state = gateway_state(self(), identity, "session-old")

    assert {:stop, :session_replaced, 4001, ^state} =
             ClusterGateway.Socket.handle_info(
               {:mission_control_session_owner, identity.spiffe_id, "session-new"},
               state
             )
  end

  test "the gateway scopes a command acknowledgement to its certificate identity" do
    state = gateway_state(self(), identity(), "session-1")

    assert {:push, {:text, payload}, ^state} =
             ClusterGateway.Socket.handle_in(
               {Jason.encode!(%{"type" => "command_ack", "command_id" => "cmd-gateway"}),
                opcode: :text},
               state
             )

    assert_received {:acknowledged, "org-1", "cluster-1", "cmd-gateway"}

    assert %{
             "type" => "command_ack",
             "command_id" => "cmd-gateway",
             "status" => "acknowledged"
           } = Jason.decode!(payload)
  end

  defp start_registry do
    name = :"command_outbox_sessions_#{System.unique_integer([:positive])}"
    start_supervised!({ClusterSessions, name: name})
    name
  end

  defp identity do
    %{
      spiffe_id: "spiffe://exocomp/organizations/org-1/clusters/cluster-1",
      organization_id: "org-1",
      cluster_id: "cluster-1"
    }
  end

  defp gateway_state(registry, identity, session_id) do
    %{
      session_registry: registry,
      session_id: session_id,
      identity: identity,
      command_outbox: GatewayOutbox,
      command_outbox_opts: [command: command("cmd-gateway"), test_pid: self()]
    }
  end
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.CommandOutboxTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{Command, CommandOutbox, SessionRegistry}

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

    def one(_query), do: %Command{status: Process.get(:command_status, "acknowledged")}

    def insert(changeset) do
      Process.put(:insert_called, true)
      {:error, %{changeset | valid?: false}}
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

  test "rejects kinds outside the protocol allow-list before touching the repo" do
    assert {:error, {:invalid_command_kind, "shell.exec"}} =
             CommandOutbox.enqueue(
               %{
                 command_id: "cmd-invalid",
                 kind: "shell.exec",
                 organization_id: "org-1",
                 cluster_id: "cluster-1",
                 payload: %{}
               },
               repo: ReadOnlyRepo
             )
  end

  test "accepts an explicit protocol kind and string organization aliases" do
    changeset =
      Command.changeset(%Command{}, %{
        command_id: "cmd-valid",
        kind: "conversation.message",
        issued_at: ~U[2026-08-01 00:00:00.000000Z],
        expires_at: ~U[2026-08-01 00:05:00.000000Z],
        organization_id: "org-1",
        cluster_id: "cluster-1",
        payload: %{"message" => "hello"}
      })

    assert changeset.valid?

    assert %Command{command_id: "cmd-valid"} = Ecto.Changeset.apply_changes(changeset)
  end

  test "offline delivery does not invoke a sender" do
    sender = fn _command -> flunk("offline command was sent") end

    assert {:error, :offline} =
             CommandOutbox.deliver_pending("org-1", "cluster-1", nil, sender,
               repo: ReadOnlyRepo,
               now: ~U[2026-08-01 00:01:00.000000Z]
             )
  end

  test "reconnect delivery sends pending commands without acknowledging them" do
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

  test "duplicate acknowledgements are idempotent and do not execute a command twice" do
    assert {:ok, :acknowledged} = CommandOutbox.acknowledge("cmd-ack", repo: TransitionRepo)

    assert {:ok, :already_acknowledged} =
             CommandOutbox.acknowledge("cmd-ack", repo: TransitionRepo)
  end

  test "expiration marks undelivered commands terminal without acknowledging them" do
    assert {:ok, 1} =
             CommandOutbox.expire(
               repo: TransitionRepo,
               now: ~U[2026-08-01 00:10:00.000000Z],
               organization_id: "org-1",
               cluster_id: "cluster-1"
             )

    Process.put(:command_status, "expired")

    assert {:error, :expired} =
             CommandOutbox.acknowledge("cmd-expired",
               repo: TransitionRepo,
               now: ~U[2026-08-01 00:10:00.000000Z]
             )
  end

  test "a repository failure rolls enqueue back before any command is persisted" do
    assert {:error, changeset} =
             CommandOutbox.enqueue(
               %{
                 command_id: "cmd-rollback",
                 kind: "conversation.message",
                 organization_id: "org-1",
                 cluster_id: "cluster-1",
                 payload: %{}
               },
               repo: TransitionRepo
             )

    refute changeset.valid?
    assert Process.get(:insert_called)
  end

  test "a newer replica session replaces ownership and the previous one cannot unregister it" do
    name = Module.concat(__MODULE__, Registry)
    start_supervised!({SessionRegistry, name: name})

    assert {:ok, nil} = SessionRegistry.register("org-1", "cluster-1", "session-a", self(), name)

    assert {:ok, %{session_id: "session-a"}} =
             SessionRegistry.register("org-1", "cluster-1", "session-b", self(), name)

    assert {:error, :not_owner} =
             SessionRegistry.unregister("org-1", "cluster-1", "session-a", name)

    assert {:ok, %{session_id: "session-b"}} = SessionRegistry.owner("org-1", "cluster-1", name)
  end

  test "registered delivery uses the current session owner after reconnect" do
    Process.put(:pending_commands, [command("cmd-2")])
    name = Module.concat(__MODULE__, ReconnectRegistry)
    start_supervised!({SessionRegistry, name: name})
    test_pid = self()

    assert {:ok, nil} =
             SessionRegistry.register(
               "org-1",
               "cluster-1",
               "session-new",
               fn delivered ->
                 send(test_pid, {:replayed, delivered.command_id})
                 :ok
               end,
               name
             )

    assert {:ok, %{sent: 1}} =
             CommandOutbox.deliver_registered("org-1", "cluster-1",
               registry: name,
               repo: ReadOnlyRepo,
               now: ~U[2026-08-01 00:01:00.000000Z]
             )

    assert_received {:replayed, "cmd-2"}
  end
end

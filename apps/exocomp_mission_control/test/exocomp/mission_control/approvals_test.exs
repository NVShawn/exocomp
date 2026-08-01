# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ApprovalsTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{Approvals, Proposal}
  alias Exocomp.MissionControl.Identity.Operator

  @now ~U[2026-08-01 12:00:00.000000Z]

  defmodule FakeRepo do
    def transaction(fun) do
      previous = Process.get(:proposal)

      case fun.() do
        {:error, _reason} = error ->
          Process.put(:proposal, previous)
          error

        result ->
          {:ok, result}
      end
    end

    def one(_query), do: Process.get(:proposal)

    def update(changeset) do
      if Process.get(:update_error) do
        {:error, :database_unavailable}
      else
        proposal = Ecto.Changeset.apply_changes(changeset)
        Process.put(:proposal, proposal)
        {:ok, proposal}
      end
    end
  end

  defmodule FakeOutbox do
    def enqueue(attrs, _opts) do
      case Process.get(:enqueue_error) do
        nil ->
          Process.put(:command, attrs)
          {:ok, attrs}

        reason ->
          {:error, reason}
      end
    end
  end

  setup do
    Process.put(:proposal, proposal())
    Process.delete(:command)
    Process.delete(:enqueue_error)
    Process.delete(:update_error)

    :ok
  end

  test "approval records the operator decision and queues one typed command" do
    assert {:ok, %Proposal{} = approved} = approve()

    assert approved.status == "approved"
    assert approved.decision == "approved"
    assert approved.decided_by_sub == "operator-1"
    assert approved.decided_by_display_name == "Ada"
    assert approved.decided_by_organization_id == "org-1"
    assert approved.decision_actor["sub"] == "operator-1"
    assert approved.decision_actor["organization_id"] == "org-1"
    refute approved.status == "executed"

    assert %{kind: "proposal.approve", payload: payload} = Process.get(:command)
    assert payload["proposal_id"] == "proposal-1"
    assert payload["decision"] == "approved"
  end

  test "an administrator may approve in the same organization" do
    assert {:ok, %Proposal{status: "approved", decided_by_sub: "operator-1"}} =
             approve(operator: operator(:admin))
  end

  test "denial records a reason and queues a typed denial command" do
    assert {:ok, %Proposal{status: "denied", denial_reason: "not safe"}} =
             Approvals.deny("org-1", "proposal-1", operator(:operator), "not safe", options())

    assert %{kind: "proposal.deny", payload: payload} = Process.get(:command)
    assert payload["denial_reason"] == "not safe"
  end

  test "denial requires a non-empty reason" do
    assert {:error, :invalid_denial_reason} =
             Approvals.deny("org-1", "proposal-1", operator(:operator), "  ", options())

    refute Process.get(:command)
  end

  test "approval is rejected without an active cluster session and queues nothing" do
    assert {:error, :cluster_disconnected} =
             approve(connected?: fn _org, _cluster -> false end)

    refute Process.get(:command)
    assert Process.get(:proposal).status == "pending"
  end

  test "expired, stale, and terminal proposals are rejected" do
    for {field, value, reason} <- [
          {:expires_at, ~U[2026-08-01 11:59:59.000000Z], :proposal_expired},
          {:evidence_fresh_until, ~U[2026-08-01 11:59:59.000000Z], :evidence_stale},
          {:status, "denied", :proposal_terminal}
        ] do
      Process.put(:proposal, Map.put(proposal(), field, value))
      assert {:error, ^reason} = approve()
      refute Process.get(:command)
    end
  end

  test "viewer cannot approve and a cross-organization operator cannot approve" do
    assert {:error, :insufficient_role} = approve(operator: operator(:viewer))

    assert {:error, :cross_organization} =
             approve(operator: operator(:admin, "org-2"))
  end

  test "proposal organization is checked independently of operator authorization" do
    Process.put(:proposal, %{proposal() | organization_id: "org-2"})

    assert {:error, :organization_mismatch} = approve()
    refute Process.get(:command)
  end

  test "outbox failure rolls the decision back" do
    Process.put(:enqueue_error, :database_unavailable)

    assert {:error, {:queue_failed, :database_unavailable}} = approve()
    assert Process.get(:proposal).status == "pending"
    refute Process.get(:command)
  end

  test "a proposal can be decided only once" do
    assert {:ok, %Proposal{status: "approved"}} = approve()
    assert {:error, :proposal_terminal} = approve()
  end

  defp approve(overrides \\ []) do
    opts = Keyword.merge(options(), Keyword.take(overrides, [:connected?]))
    actor = Keyword.get(overrides, :operator, operator(:operator))
    Approvals.approve("org-1", "proposal-1", actor, opts)
  end

  defp options do
    [
      repo: FakeRepo,
      outbox: FakeOutbox,
      now: @now,
      connected?: fn _org, _cluster -> true end,
      command_id: "command-1",
      correlation_id: "corr-1"
    ]
  end

  defp operator(role, organization_id \\ "org-1") do
    %Operator{
      sub: "operator-1",
      organization_id: organization_id,
      display_name: "Ada",
      role: role
    }
  end

  defp proposal do
    %Proposal{
      proposal_id: "proposal-1",
      organization_id: "org-1",
      cluster_id: "cluster-1",
      task_id: "task-1",
      correlation_id: "corr-task-1",
      node_id: "node-1",
      target_id: "nginx.service",
      action_id: "systemd.service.restart",
      parameters: %{"unit" => "nginx.service"},
      evidence_refs: %{"evidence-1" => "sha256:abc"},
      evidence_hash: "sha256:evidence",
      evidence_fresh_until: ~U[2026-08-01 12:05:00.000000Z],
      expires_at: ~U[2026-08-01 12:10:00.000000Z],
      status: "pending"
    }
  end
end

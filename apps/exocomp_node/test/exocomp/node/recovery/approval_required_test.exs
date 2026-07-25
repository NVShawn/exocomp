# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Recovery.ApprovalRequiredTest do
  use ExUnit.Case, async: false

  alias Exocomp.Node.Recovery.ApprovalRequired
  alias Exocomp.Node.Safety.ReplayLedger
  alias Exocomp.Recovery.Evidence

  @moduletag :tmp_dir
  @node "node-7"
  @service "fixture.service"
  @task "task-32"
  @now ~U[2026-07-24 19:00:00Z]

  defmodule Verifier do
    def verify(%{failure: reason}, _context), do: {:error, reason}
    def verify(token, _context), do: {:ok, token}
  end

  defmodule Checker do
    def verify(%{check_failure: reason}, _action, _target), do: {:error, reason}
    def verify(%{"check_failure" => reason}, _action, _target), do: {:error, reason}
    def verify(_payload, _action, _target), do: :ok
  end

  setup %{tmp_dir: tmp_dir} do
    unique = System.unique_integer([:positive])
    ledger_name = :"approval_required_ledger_#{unique}"
    table = :"approval_required_table_#{unique}"
    Application.put_env(:exocomp_node, :replay_ledger_path, Path.join(tmp_dir, "unused.dets"))

    ledger =
      start_supervised!(
        {ReplayLedger,
         name: ledger_name, table: table, path: Path.join(tmp_dir, "replay-#{unique}.dets")}
      )

    {:ok, audit} = Agent.start_link(fn -> [] end)
    {:ok, executions} = Agent.start_link(fn -> [] end)

    audit_fun = fn event ->
      Agent.update(audit, &(&1 ++ [event]))
      :ok
    end

    executor = fn action, target, allow_list ->
      Agent.update(executions, &(&1 ++ [{action, target, allow_list}]))

      {:ok,
       %{
         action_id: action,
         target: target,
         exit_code: 0,
         verified: true
       }}
    end

    base_opts = [
      task_id: @task,
      allow_list: [@service],
      now_fun: fn -> @now end,
      audit_fun: audit_fun,
      refresh_fun: fn _, _ -> {:ok, active_evidence()} end,
      verify_fun: fn _, _ -> {:ok, active_evidence()} end,
      executor: executor,
      gate_opts: [verifier: Verifier, checker: Checker, ledger: ledger]
    ]

    {:ok, base_opts: base_opts, audit: audit, executions: executions, ledger: ledger}
  end

  test "active service becomes input-required with exact impact and evidence", %{
    base_opts: opts,
    audit: audit,
    executions: executions
  } do
    assert {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)
    assert flow.machine.state == :awaiting_approval
    assert flow.task.status.state == :input_required
    assert Agent.get(executions, & &1) == []

    [%{data: payload}] = flow.task.status.message.parts
    assert payload["event"] == "approval_required"

    data = payload["data"]
    assert data["impact"]["service"] == @service
    assert data["impact"]["classification"] == "active"
    assert data["impact"]["disruption"] =~ "interrupt"
    assert data["evidence"]["evidence_id"] == "evidence-active"
    assert data["evidence"]["data"]["active_state"] == "active"
    assert data["approval"]["task_id"] == @task
    assert data["approval"]["correlation_id"] == flow.machine.correlation_id
    assert length(Agent.get(audit, & &1)) == 4
  end

  test "valid bound approval refreshes evidence before one restart", %{
    base_opts: opts,
    executions: executions,
    audit: audit
  } do
    refresh_counter = start_supervised!({Agent, fn -> 0 end})

    opts =
      Keyword.put(opts, :refresh_fun, fn _, _ ->
        Agent.update(refresh_counter, &(&1 + 1))
        {:ok, active_evidence()}
      end)

    assert {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)
    assert {:ok, completed} = ApprovalRequired.approve(flow, token(), "operator@example")

    assert completed.machine.state == :completed
    assert completed.task.status.state == :completed
    assert Agent.get(refresh_counter, & &1) == 1

    assert Agent.get(executions, & &1) == [
             {:restart_service, @service, [@service]}
           ]

    assert Enum.map(Agent.get(audit, & &1), & &1.event_tag) ==
             [
               :unhealthy_observation,
               :evidence_complete,
               :validate,
               :active_or_degraded,
               :valid_approval,
               :execution_complete,
               :stable_health
             ]
  end

  test "denial is terminal and performs no action", %{
    base_opts: opts,
    executions: executions,
    audit: audit
  } do
    {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)
    assert {:ok, denied} = ApprovalRequired.deny(flow, "maintenance window closed")

    assert denied.machine.state == :escalated
    assert denied.task.status.state == :failed
    assert Agent.get(executions, & &1) == []
    assert List.last(Agent.get(audit, & &1)).event_tag == :deny_or_expire_or_changed

    assert hd(denied.task.artifacts).parts |> hd() |> Map.fetch!(:data) |> Map.get("outcome") ==
             "approval_escalated"
  end

  test "timeout is terminal and performs no action", %{
    base_opts: opts,
    executions: executions
  } do
    {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)
    assert {:ok, timed_out} = ApprovalRequired.timeout(flow)

    assert timed_out.machine.state == :escalated
    assert timed_out.task.status.state == :failed
    assert Agent.get(executions, & &1) == []
  end

  test "expired approval is terminal and performs no action", %{
    base_opts: opts,
    executions: executions
  } do
    {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)
    expired = token(failure: :expired)

    assert {:ok, result} = ApprovalRequired.approve(flow, expired, "operator@example")
    assert result.machine.state == :escalated
    assert result.task.status.state == :failed
    assert Agent.get(executions, & &1) == []
  end

  test "wrong approver and invalid token stay input-required without action", %{
    base_opts: opts,
    executions: executions
  } do
    {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)

    assert {:error, :wrong_approver, wrong_actor} =
             ApprovalRequired.approve(flow, token(), "intruder@example")

    assert wrong_actor.machine.state == :awaiting_approval
    assert wrong_actor.task.status.state == :input_required

    assert {:error, {:invalid_approval, :invalid_signature}, bad_token} =
             ApprovalRequired.approve(
               wrong_actor,
               token(failure: :invalid_signature),
               "operator@example"
             )

    assert bad_token.machine.state == :awaiting_approval
    assert bad_token.task.status.state == :input_required
    assert Agent.get(executions, & &1) == []
  end

  test "malformed token stays input-required without action", %{
    base_opts: opts,
    executions: executions
  } do
    {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)

    assert {:error, {:invalid_approval, :malformed_token}, pending} =
             ApprovalRequired.approve(flow, "not-a-token", "operator@example")

    assert pending.machine.state == :awaiting_approval
    assert pending.task.status.state == :input_required
    assert Agent.get(executions, & &1) == []
  end

  test "changed evidence invalidates approval and re-diagnoses without action", %{
    base_opts: opts,
    executions: executions
  } do
    changed = active_evidence(%{"sub_state" => "reload"})
    opts = Keyword.put(opts, :refresh_fun, fn _, _ -> {:ok, changed} end)
    {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)

    assert {:ok, result} = ApprovalRequired.approve(flow, token(), "operator@example")
    assert result.machine.state == :escalated
    assert result.task.status.state == :failed
    assert Agent.get(executions, & &1) == []
  end

  test "degraded service becoming healthy invalidates approval without action", %{
    base_opts: opts,
    executions: executions
  } do
    opts = Keyword.put(opts, :refresh_fun, fn _, _ -> {:ok, active_evidence()} end)
    {:ok, flow} = ApprovalRequired.request(degraded_evidence(), opts)

    assert {:ok, result} = ApprovalRequired.approve(flow, token(), "operator@example")
    assert result.machine.state == :escalated
    assert result.task.status.state == :failed
    assert Agent.get(executions, & &1) == []
  end

  test "service becoming failed invalidates approval for automatic re-diagnosis", %{
    base_opts: opts,
    executions: executions
  } do
    opts = Keyword.put(opts, :refresh_fun, fn _, _ -> {:ok, failed_evidence()} end)
    {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)

    assert {:ok, result} = ApprovalRequired.approve(flow, token(), "operator@example")
    assert result.machine.state == :escalated
    assert result.task.status.state == :failed
    assert Agent.get(executions, & &1) == []
  end

  test "gate-time precondition drift invalidates approval without action", %{
    base_opts: opts,
    executions: executions
  } do
    {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)
    changed_at_gate = token(check_failure: :precondition_changed)

    assert {:ok, result} =
             ApprovalRequired.approve(flow, changed_at_gate, "operator@example")

    assert result.machine.state == :escalated
    assert Agent.get(executions, & &1) == []
  end

  test "cancellation is terminal and performs no action", %{
    base_opts: opts,
    executions: executions
  } do
    {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)
    assert {:ok, canceled} = ApprovalRequired.cancel(flow, "operator canceled")

    assert canceled.machine.state == :cancelled
    assert canceled.task.status.state == :canceled
    assert Agent.get(executions, & &1) == []
  end

  test "duplicate approval is rejected and never repeats the restart", %{
    base_opts: opts,
    executions: executions
  } do
    {:ok, original} = ApprovalRequired.request(active_evidence(), opts)
    assert {:ok, completed} = ApprovalRequired.approve(original, token(), "operator@example")

    assert {:error, :approval_not_pending, ^completed} =
             ApprovalRequired.approve(completed, token(), "operator@example")

    assert {:error, :duplicate_approval, replayed} =
             ApprovalRequired.approve(original, token(), "operator@example")

    assert replayed.machine.state == :awaiting_approval
    assert Agent.get(executions, &length/1) == 1
  end

  test "audit failure before executing blocks restart", %{
    base_opts: opts,
    audit: audit,
    executions: executions
  } do
    audit_fun = fn event ->
      Agent.update(audit, &(&1 ++ [event]))

      if event.event_tag == :valid_approval,
        do: {:error, :sink_unavailable},
        else: :ok
    end

    opts = Keyword.put(opts, :audit_fun, audit_fun)
    {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)

    assert {:error, {:execution_failed, {:audit_unavailable, :sink_unavailable}}, pending} =
             ApprovalRequired.approve(flow, token(), "operator@example")

    assert pending.machine.state == :awaiting_approval
    assert Agent.get(executions, & &1) == []
  end

  defp token(opts \\ []) do
    payload = %{
      nonce: "nonce-exocomp-32",
      operator: "operator@example",
      expires_at: DateTime.to_iso8601(DateTime.add(@now, 300, :second))
    }

    payload =
      case Keyword.fetch(opts, :check_failure) do
        {:ok, reason} -> Map.put(payload, :check_failure, reason)
        :error -> payload
      end

    token = %{payload: payload, signature: "stub"}

    case Keyword.fetch(opts, :failure) do
      {:ok, reason} -> Map.put(token, :failure, reason)
      :error -> token
    end
  end

  defp active_evidence(extra \\ %{}) do
    evidence(
      "evidence-active",
      Map.merge(
        %{
          "active_state" => "active",
          "health" => "healthy",
          "sub_state" => "running",
          "unit_name" => @service
        },
        extra
      )
    )
  end

  defp degraded_evidence do
    evidence("evidence-degraded", %{
      "active_state" => "active",
      "health" => "degraded",
      "sub_state" => "running",
      "unit_name" => @service
    })
  end

  defp failed_evidence do
    evidence("evidence-failed", %{
      "active_state" => "failed",
      "health" => "unhealthy",
      "sub_state" => "failed",
      "unit_name" => @service
    })
  end

  defp evidence(id, data) do
    Evidence.new(@node, @service, data,
      evidence_id: id,
      collected_at: @now,
      collector_version: "test"
    )
  end
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Recovery.FailedServiceTest do
  @moduledoc """
  Unit tests for `Exocomp.Node.Recovery.FailedService` (EXOCOMP-31).

  Covers:
  - M4-CRIT-2: A failed fixture service is detected, diagnosed, restarted once,
    and verified healthy through a complete A2A workflow.
  - M4-CRIT-3: An active or degraded service cannot be restarted without approval.
  - M4-CRIT-4: Duplicate, replayed, or concurrent recovery tasks cannot cause
    more than one execution.
  - M4-CRIT-5: Restart or verification failure enters cooldown and escalates
    without an autonomous retry loop.
  - M4-CRIT-7: End-to-end audit reconstructs observation, proposal, validation,
    execution, verification, and outcome.
  - M4-CRIT-8: Tests prove no user data is modified or deleted.

  Additional tests cover:
  - Happy path: full A2A task lifecycle (working → completed with artifact).
  - Audit trail shape and event-tag sequence.
  - Active/degraded evidence rejection.
  - Not-allowed service rejection.
  - Executor failure → cooling_down → escalated.
  - Health verification failure → cooling_down → escalated.
  - Pre-start audit failure blocks recovery.
  - Cancellation from executing state.
  - Terminal task carries the correct outcome artifact.
  """

  use ExUnit.Case, async: false

  alias Exocomp.Node.Recovery.FailedService
  alias Exocomp.Node.Safety.ReplayLedger
  alias Exocomp.Recovery.{Evidence, StateMachine}

  @moduletag :tmp_dir
  @node "node-m4"
  @service "fixture.service"
  @task "task-m4-001"
  @now ~U[2026-07-25 10:00:00Z]

  # ── Evidence helpers ──────────────────────────────────────────────────────────

  defp failed_evidence(extra \\ %{}) do
    base = %{
      "active_state" => "failed",
      "sub_state" => "failed",
      "unit_name" => @service
    }

    Evidence.new(@node, @service, Map.merge(base, extra),
      evidence_id: "ev-failed-001",
      collected_at: @now,
      collector_version: "m4-test"
    )
  end

  defp inactive_evidence do
    Evidence.new(@node, @service, %{"active_state" => "inactive"},
      evidence_id: "ev-inactive-001",
      collected_at: @now,
      collector_version: "m4-test"
    )
  end

  defp active_evidence do
    Evidence.new(
      @node,
      @service,
      %{
        "active_state" => "active",
        "sub_state" => "running",
        "health" => "healthy",
        "unit_name" => @service
      },
      evidence_id: "ev-active-001",
      collected_at: @now,
      collector_version: "m4-test"
    )
  end

  defp degraded_evidence do
    Evidence.new(
      @node,
      @service,
      %{
        "active_state" => "active",
        "health" => "degraded",
        "unit_name" => @service
      },
      evidence_id: "ev-degraded-001",
      collected_at: @now,
      collector_version: "m4-test"
    )
  end

  # ── Shared fixture builders ───────────────────────────────────────────────────

  defp make_agents do
    {:ok, audit} = Agent.start_link(fn -> [] end)
    {:ok, executions} = Agent.start_link(fn -> [] end)
    {audit, executions}
  end

  defp audit_fun(audit) do
    fn event ->
      Agent.update(audit, &(&1 ++ [event]))
      :ok
    end
  end

  defp executor_fun(executions) do
    fn action, target, allow_list ->
      Agent.update(executions, &(&1 ++ [{action, target, allow_list}]))
      {:ok, %{action_id: action, target: target, exit_code: 0}}
    end
  end

  defp base_opts(audit, executions) do
    [
      task_id: @task,
      allow_list: [@service],
      now_fun: fn -> @now end,
      audit_fun: audit_fun(audit),
      verify_fun: fn _, _ -> {:ok, active_evidence()} end,
      executor: executor_fun(executions)
    ]
  end

  defp start_ledger(tmp_dir) do
    id = System.unique_integer([:positive])

    start_supervised!(
      {ReplayLedger,
       name: :"failed_service_ledger_#{id}",
       table: :"failed_service_table_#{id}",
       path: Path.join(tmp_dir, "failed-service-#{id}.dets")}
    )
  end

  # ── M4-CRIT-2: Full happy path (detected → restarted → verified healthy) ──────

  describe "M4-CRIT-2: automatic failed-service recovery" do
    test "start/2 advances machine to :executing and returns :working task" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      assert {:ok, flow} = FailedService.start(failed_evidence(), opts)

      assert flow.machine.state == :executing
      assert flow.machine.execution_attempted == true
      assert flow.task.status.state == :working
      assert Agent.get(executions, & &1) == [], "no execution before execute/1 is called"
    end

    test "execute/1 performs exactly one restart and transitions to :completed" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      assert {:ok, flow} = FailedService.start(failed_evidence(), opts)
      assert {:ok, completed} = FailedService.execute(flow)

      assert completed.machine.state == :completed
      assert completed.task.status.state == :completed

      # Exactly one restart occurred.
      assert Agent.get(executions, & &1) == [{:restart_service, @service, [@service]}]
    end

    test "full happy path produces 6 audit events with the correct tag sequence" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, _} = FailedService.execute(flow)

      tags = Agent.get(audit, & &1) |> Enum.map(& &1.event_tag)

      assert tags == [
               :unhealthy_observation,
               :evidence_complete,
               :validate,
               :failed_and_allowed,
               :execution_complete,
               :stable_health
             ]
    end

    test "completed flow contains a service-recovery-result artifact" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, completed} = FailedService.execute(flow)

      assert [artifact] = completed.task.artifacts
      assert artifact.name == "service-recovery-result"
      [%{data: data}] = artifact.parts
      assert data["outcome"] == "recovery_completed"
      assert data["recovery_state"] == "completed"
      assert is_binary(data["correlation_id"])
    end

    test "inactive service is also eligible for automatic restart" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      assert {:ok, flow} = FailedService.start(inactive_evidence(), opts)
      assert {:ok, completed} = FailedService.execute(flow)
      assert completed.machine.state == :completed
      assert Agent.get(executions, &length/1) == 1
    end
  end

  # ── M4-CRIT-3: Active/degraded services must not be restarted automatically ──

  describe "M4-CRIT-3: active/degraded services cannot be automatically restarted" do
    test "active service evidence is rejected by start/2" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      assert {:error, {:not_failed_service, "active"}} =
               FailedService.start(active_evidence(), opts)

      # No execution, no audit.
      assert Agent.get(executions, & &1) == []
      assert Agent.get(audit, & &1) == []
    end

    test "degraded service evidence is rejected by start/2" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      assert {:error, {:not_failed_service, "active"}} =
               FailedService.start(degraded_evidence(), opts)

      assert Agent.get(executions, & &1) == []
    end
  end

  # ── M4-CRIT-4: No more than one execution per episode ─────────────────────────

  describe "M4-CRIT-4: exactly-once execution" do
    test "execution_attempted is set to true in the executing state" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      assert flow.machine.execution_attempted == true
    end

    test "calling execute/1 twice on the same pre-execution flow performs one action" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, _completed} = FailedService.execute(flow)

      # Attempt to re-use the same pre-execution flow struct (simulating a
      # coordinator restart that replays the task).
      assert {:error, :already_terminal, _} = FailedService.execute(flow)

      # Only one restart occurred.
      assert Agent.get(executions, &length/1) == 1
    end

    test "durable replay claim survives the flow value and blocks re-execution", %{
      tmp_dir: tmp_dir
    } do
      {audit, executions} = make_agents()
      ledger = start_ledger(tmp_dir)
      opts = base_opts(audit, executions) |> Keyword.put(:ledger, ledger)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, _completed} = FailedService.execute(flow)

      assert {:ok, :complete} =
               ReplayLedger.status(flow.machine.correlation_id, ledger)

      assert {:error, :already_terminal, _} = FailedService.execute(flow)
      assert Agent.get(executions, &length/1) == 1
    end

    test "execute/1 on an already-completed flow is rejected" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, completed} = FailedService.execute(flow)

      assert {:error, :already_terminal, ^completed} = FailedService.execute(completed)
      assert Agent.get(executions, &length/1) == 1
    end

    test "StateMachine execution_attempted guard blocks re-entry even with spoofed state" do
      {audit, _} = make_agents()
      opts = base_opts(audit, make_agents() |> elem(1))

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      # Spoof state back to :validating; execution_attempted should still block.
      spoofed = %{flow | machine: %{flow.machine | state: :validating}}

      assert {:error, :execution_already_attempted} =
               StateMachine.apply_event(
                 spoofed.machine,
                 {:failed_and_allowed,
                  Evidence.new(@node, @service, %{"active_state" => "failed"}, collected_at: @now)},
                 now: @now
               )
    end

    test "not-allowed service is rejected before any audit event" do
      {audit, executions} = make_agents()

      opts = [
        task_id: @task,
        allow_list: ["other.service"],
        now_fun: fn -> @now end,
        audit_fun: audit_fun(audit),
        verify_fun: fn _, _ -> {:ok, active_evidence()} end,
        executor: executor_fun(executions)
      ]

      assert {:error, {:service_not_allowed, @service}} =
               FailedService.start(failed_evidence(), opts)

      assert Agent.get(executions, & &1) == []
      assert Agent.get(audit, & &1) == []
    end
  end

  # ── M4-CRIT-5: Restart failure → cooldown → escalated, no retry ───────────────

  describe "M4-CRIT-5: failure enters cooldown and escalates without retry" do
    test "executor failure transitions to :escalated via cooldown; no retry" do
      {audit, executions} = make_agents()

      failing_executor = fn action, target, allow_list ->
        Agent.update(executions, &(&1 ++ [{action, target, allow_list}]))
        {:error, :systemd_timeout}
      end

      opts = [
        task_id: @task,
        allow_list: [@service],
        now_fun: fn -> @now end,
        audit_fun: audit_fun(audit),
        verify_fun: fn _, _ -> {:ok, active_evidence()} end,
        executor: failing_executor
      ]

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, escalated} = FailedService.execute(flow)

      # M4-CRIT-5: terminal escalated state, no retry loop.
      assert escalated.machine.state == :escalated
      assert escalated.task.status.state == :failed
      assert StateMachine.terminal?(escalated.machine)

      # Only one execution attempt.
      assert Agent.get(executions, &length/1) == 1

      # Audit trail includes cooldown path.
      final_tags = Agent.get(audit, & &1) |> Enum.map(& &1.event_tag)
      assert :valid_approval not in final_tags
      assert :execution_complete in final_tags
      assert :failure_or_instability in final_tags
      assert :cooldown_expired in final_tags

      # execution_attempted remains true.
      assert escalated.machine.execution_attempted == true
    end

    test "health verification failure escalates without retry" do
      {audit, executions} = make_agents()

      unhealthy_verifier = fn _, _ ->
        {:ok,
         Evidence.new(@node, @service, %{"active_state" => "active", "health" => "degraded"},
           collected_at: @now
         )}
      end

      opts = [
        task_id: @task,
        allow_list: [@service],
        now_fun: fn -> @now end,
        audit_fun: audit_fun(audit),
        verify_fun: unhealthy_verifier,
        executor: executor_fun(executions)
      ]

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, escalated} = FailedService.execute(flow)

      assert escalated.machine.state == :escalated
      assert escalated.task.status.state == :failed
      assert Agent.get(executions, &length/1) == 1
      assert escalated.machine.execution_attempted == true
    end

    test "failed verification does not re-enter :executing after escalation" do
      {_, executions} = make_agents()
      {audit2, _} = make_agents()

      failing_verifier = fn _, _ ->
        {:ok, Evidence.new(@node, @service, %{"active_state" => "failed"}, collected_at: @now)}
      end

      opts = [
        task_id: @task,
        allow_list: [@service],
        now_fun: fn -> @now end,
        audit_fun: audit_fun(audit2),
        verify_fun: failing_verifier,
        executor: executor_fun(executions)
      ]

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, escalated} = FailedService.execute(flow)

      assert StateMachine.terminal?(escalated.machine)

      # Any further event is rejected.
      assert {:error, :already_terminal} =
               StateMachine.apply_event(
                 escalated.machine,
                 {:failed_and_allowed,
                  Evidence.new(@node, @service, %{"active_state" => "failed"}, collected_at: @now)},
                 now: @now
               )
    end

    test "verify_fun error triggers escalation without another execution" do
      {audit, executions} = make_agents()

      opts = [
        task_id: @task,
        allow_list: [@service],
        now_fun: fn -> @now end,
        audit_fun: audit_fun(audit),
        verify_fun: fn _, _ -> {:error, :collector_unavailable} end,
        executor: executor_fun(executions)
      ]

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, escalated} = FailedService.execute(flow)

      assert escalated.machine.state == :escalated
      assert Agent.get(executions, &length/1) == 1
    end
  end

  # ── M4-CRIT-7: Audit trail reconstructs full recovery ─────────────────────────

  describe "M4-CRIT-7: end-to-end audit trail" do
    test "every transition is audited with correlated IDs" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, _} = FailedService.execute(flow)

      events = Agent.get(audit, & &1)
      assert length(events) == 6

      corr = hd(events).correlation_id
      ep = hd(events).episode_id

      Enum.each(events, fn ev ->
        assert ev.correlation_id == corr, "correlation_id mismatch at #{ev.event_tag}"
        assert ev.episode_id == ep, "episode_id mismatch at #{ev.event_tag}"
        assert ev.node_id == @node, "node_id mismatch at #{ev.event_tag}"
        assert ev.service == @service, "service mismatch at #{ev.event_tag}"
      end)
    end

    test "audit event sequences are strictly 1..N" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, _} = FailedService.execute(flow)

      events = Agent.get(audit, & &1)

      Enum.each(Enum.zip(1..length(events), events), fn {seq, ev} ->
        assert ev.sequence == seq, "expected sequence #{seq}, got #{ev.sequence}"
      end)
    end

    test "audit trail for failure path includes cooling_down and escalated" do
      {audit, executions} = make_agents()

      failing_executor = fn action, target, allow_list ->
        Agent.update(executions, &(&1 ++ [{action, target, allow_list}]))
        {:error, :exec_failed}
      end

      opts = [
        task_id: @task,
        allow_list: [@service],
        now_fun: fn -> @now end,
        audit_fun: audit_fun(audit),
        verify_fun: fn _, _ -> {:ok, active_evidence()} end,
        executor: failing_executor
      ]

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, escalated} = FailedService.execute(flow)

      tags = Agent.get(audit, & &1) |> Enum.map(& &1.event_tag)
      assert :failure_or_instability in tags
      assert :cooldown_expired in tags
      assert escalated.machine.state == :escalated
    end
  end

  # ── M4-CRIT-8: No user data modification ─────────────────────────────────────

  describe "M4-CRIT-8: no user data modified or deleted" do
    test "executor is called with exact argv from catalog — no shell, no expansion" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, _} = FailedService.execute(flow)

      # The executor receives action_id atom, exact service name, and allow_list.
      # It must NOT receive arbitrary strings or combined shell expressions.
      assert [{:restart_service, @service, [@service]}] =
               Agent.get(executions, & &1)
    end

    test "cancellation before execution does not invoke executor" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, canceled} = FailedService.cancel(flow, "operator canceled")

      assert canceled.machine.state == :cancelled
      assert canceled.task.status.state == :canceled
      assert Agent.get(executions, & &1) == []
    end
  end

  # ── Additional: Audit sink failure ────────────────────────────────────────────

  describe "audit sink failure" do
    test "pre-start audit failure blocks flow creation; no execution" do
      {_audit, executions} = make_agents()

      opts = [
        task_id: @task,
        allow_list: [@service],
        now_fun: fn -> @now end,
        audit_fun: fn _event -> {:error, :sink_unavailable} end,
        verify_fun: fn _, _ -> {:ok, active_evidence()} end,
        executor: executor_fun(executions)
      ]

      assert {:error, {:audit_unavailable, :sink_unavailable}} =
               FailedService.start(failed_evidence(), opts)

      assert Agent.get(executions, & &1) == []
    end
  end

  # ── Additional: cancellation ──────────────────────────────────────────────────

  describe "cancellation" do
    test "cancel/2 from :executing transitions to :cancelled without execution" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      assert flow.machine.state == :executing

      {:ok, canceled} = FailedService.cancel(flow, "test cancel")

      assert canceled.machine.state == :cancelled
      assert canceled.task.status.state == :canceled
      assert StateMachine.terminal?(canceled.machine)

      # No execution occurred.
      assert Agent.get(executions, & &1) == []
    end

    test "cancel/2 on a completed flow returns error" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, completed} = FailedService.execute(flow)

      assert {:error, :already_terminal, ^completed} =
               FailedService.cancel(completed, "late cancel")
    end
  end

  # ── Additional: task artifact shape ──────────────────────────────────────────

  describe "task artifact shape" do
    test "initial task is :working with recovery_started message" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)

      assert flow.task.status.state == :working
      [%{data: payload}] = flow.task.status.message.parts
      assert payload["event"] == "recovery_started"
      assert payload["data"]["service"] == @service
    end

    test "terminal task contains correlation_id, recovery_state, outcome in artifact" do
      {audit, executions} = make_agents()
      opts = base_opts(audit, executions)

      {:ok, flow} = FailedService.start(failed_evidence(), opts)
      {:ok, completed} = FailedService.execute(flow)

      [artifact] = completed.task.artifacts
      [%{data: data}] = artifact.parts
      assert is_binary(data["correlation_id"])
      assert data["recovery_state"] == "completed"
      assert data["outcome"] == "recovery_completed"
    end
  end
end

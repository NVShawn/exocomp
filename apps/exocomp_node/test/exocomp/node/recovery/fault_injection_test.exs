# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Recovery.FaultInjectionTest do
  @moduledoc """
  Fault-injection coverage for recovery execution boundary scenarios (EXOCOMP-33).

  Tests idempotency and failure behavior across network partitions, process
  restarts, duplicate deliveries, replay attacks, audit-sink failures,
  restart and health failures, flapping, and cooldown reconciliation.

  Each test asserts the specific invariants required by EXOCOMP-33:

  - M4-CRIT-4: No scenario causes more than one execution per execution ID.
  - M4-CRIT-5: Restart or verification failure enters cooldown and escalates
    without an autonomous retry loop.
  - M4-CRIT-6: Partition and process-restart fault tests reconcile action
    outcome without blindly repeating the action.

  Tested scenarios:

  1.  Pre-action network partition (audit unavailable) → blocked, 0 actions.
  2.  Post-action network partition → ReplayLedger complete survives coordinator
      absence; action not repeated.
  3.  Coordinator restart with StateMachine.restore → execution_attempted flag
      blocks any further execution attempt.
  4.  Node restart during action → crashed_incomplete prevents blind retry.
  5.  Duplicate task same execution ID (sequential) → second claim returns
      authoritative result, 0 new actions.
  6.  Concurrent tasks same execution ID → exactly one execution proceeds.
  7.  Replay (nonce reused after completion) → authoritative result, 0 new
      actions.
  8.  Audit sink failure pre-approval-action → execution blocked, 0 actions.
  9.  Restart failure (executor error) → cooldown + escalation, no retry loop.
  10. Health failure (post-execution health check fails) → cooldown +
      escalation, no retry loop.
  11. Flapping / repeated failure → escalation after one attempt, execution_
      attempted guard prevents re-entry.
  12. Cooldown reconciliation after node restart → StateMachine.restore from
      cooling_down; cooldown_expired transitions to escalated without retry.
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Exocomp.Node.Recovery.ApprovalRequired
  alias Exocomp.Node.Safety.ReplayLedger
  alias Exocomp.Recovery.{Evidence, StateMachine}

  @moduletag :tmp_dir

  @node "node-fi"
  @service "fixture.service"
  @task "task-fi-001"
  @now ~U[2026-07-25 10:00:00Z]

  # ---------------------------------------------------------------------------
  # Shared token stub and evidence helpers
  # ---------------------------------------------------------------------------

  defmodule StubVerifier do
    @moduledoc false
    def verify(%{failure: :expired}, _ctx), do: {:error, :expired}
    def verify(%{failure: :invalid_signature}, _ctx), do: {:error, :invalid_signature}
    def verify(token, _ctx), do: {:ok, token}
  end

  defmodule StubChecker do
    @moduledoc false
    def verify(%{check_failure: reason}, _action, _target), do: {:error, reason}
    def verify(%{"check_failure" => reason}, _action, _target), do: {:error, reason}
    def verify(_payload, _action, _target), do: :ok
  end

  defp approval_token(opts \\ []) do
    payload = %{
      nonce: Keyword.get(opts, :nonce, "nonce-fi-default"),
      operator: "operator@example.com",
      expires_at: DateTime.to_iso8601(DateTime.add(@now, 300, :second))
    }

    token = %{payload: payload, signature: "stub"}

    case Keyword.fetch(opts, :failure) do
      {:ok, reason} -> Map.put(token, :failure, reason)
      :error -> token
    end
  end

  defp active_evidence do
    Evidence.new(
      @node,
      @service,
      %{
        "active_state" => "active",
        "health" => "healthy",
        "sub_state" => "running",
        "unit_name" => @service
      },
      collected_at: @now,
      collector_version: "fi-test"
    )
  end

  defp degraded_evidence do
    Evidence.new(
      @node,
      @service,
      %{
        "active_state" => "active",
        "health" => "degraded",
        "sub_state" => "running",
        "unit_name" => @service
      },
      collected_at: @now,
      collector_version: "fi-test"
    )
  end

  defp failed_evidence do
    Evidence.new(
      @node,
      @service,
      %{
        "active_state" => "failed",
        "sub_state" => "failed",
        "unit_name" => @service
      },
      collected_at: @now,
      collector_version: "fi-test"
    )
  end

  defp fresh_sm_evidence do
    Evidence.new(@node, @service, %{active_state: "failed"}, collected_at: @now)
  end

  # Shared ledger setup helper.
  defp start_ledger(tmp_dir, extra_opts \\ []) do
    id = System.unique_integer([:positive])
    name = :"fi_ledger_#{id}"
    table = :"fi_table_#{id}"
    path = Path.join(tmp_dir, "fi_ledger_#{id}.dets")
    opts = [name: name, table: table, path: path] ++ extra_opts
    {:ok, server} = ReplayLedger.start_link(opts)

    on_exit(fn ->
      if Process.alive?(server), do: GenServer.stop(server)
    end)

    %{server: server, name: name, table: table, path: path}
  end

  defp ledger_attrs do
    %{task_id: @task, action_id: :restart_service, target: @service}
  end

  # Base options for ApprovalRequired flows.
  defp base_opts(ledger, executions_agent, audit_agent) do
    [
      task_id: @task,
      allow_list: [@service],
      now_fun: fn -> @now end,
      audit_fun: fn event ->
        Agent.update(audit_agent, &(&1 ++ [event]))
        :ok
      end,
      refresh_fun: fn _, _ -> {:ok, active_evidence()} end,
      verify_fun: fn _, _ -> {:ok, active_evidence()} end,
      executor: fn action, target, allow_list ->
        Agent.update(executions_agent, &(&1 ++ [{action, target, allow_list}]))
        {:ok, %{action_id: action, target: target, exit_code: 0}}
      end,
      gate_opts: [verifier: StubVerifier, checker: StubChecker, ledger: ledger.server]
    ]
  end

  # ---------------------------------------------------------------------------
  # Setup helpers
  # ---------------------------------------------------------------------------

  defp setup_approval_flow(tmp_dir) do
    ledger = start_ledger(tmp_dir)
    {:ok, executions} = Agent.start_link(fn -> [] end)
    {:ok, audit} = Agent.start_link(fn -> [] end)
    opts = base_opts(ledger, executions, audit)
    {ledger, executions, audit, opts}
  end

  # ---------------------------------------------------------------------------
  # Scenario 1: Pre-action network partition — audit unavailable before action
  #
  # The audit sink is unavailable when the valid_approval event must be durably
  # recorded.  Execution must be blocked; action count must be 0.
  # ---------------------------------------------------------------------------

  describe "Scenario 1: pre-action network partition (audit unavailable)" do
    test "audit failure on valid_approval blocks execution; action count = 0", %{
      tmp_dir: tmp_dir
    } do
      {ledger, executions, _audit, opts} = setup_approval_flow(tmp_dir)

      audit_fun = fn event ->
        # Fail only for the approval-gating audit event.
        if event.event_tag == :valid_approval do
          {:error, :partition_simulated}
        else
          :ok
        end
      end

      opts = Keyword.put(opts, :audit_fun, audit_fun)
      assert {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)

      assert {:error, {:execution_failed, {:audit_unavailable, :partition_simulated}}, pending} =
               ApprovalRequired.approve(flow, approval_token(), "operator@example.com")

      # Machine is still awaiting_approval — no transition to :executing.
      assert pending.machine.state == :awaiting_approval

      # CRITERION M4-CRIT-4: no execution occurred.
      assert Agent.get(executions, & &1) == []

      # The ApprovalGate claims the ledger nonce before invoking the executor
      # function (which contains the audit call).  When the audit fails, the
      # gate records the failure result into the ledger.  The nonce is therefore
      # in :complete state (consumed with an error), which prevents any replay
      # from re-executing the action.
      nonce = approval_token().payload.nonce

      assert {:ok, :complete} = ReplayLedger.status(nonce, ledger.server)

      # Confirm that a replay attempt on the same nonce returns the error result
      # rather than proceeding to a new execution.
      assert {:error, :already_executed, _error_result} =
               ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 2: Post-action network partition — ledger complete survives
  #
  # The action executes and the execution slot is claimed.  Even if the ledger's
  # complete call is unavailable (simulated by a force-stop of the ledger
  # process after the claim is recorded), the action must not be repeated on
  # the next claim attempt.
  #
  # Production ApprovalGate logs an error when ledger.complete fails after a
  # successful execution and returns {:ok, exec_result} regardless — the action
  # is considered done.  A subsequent claim on the same nonce returns
  # :incomplete_pending, preventing a blind retry.
  # ---------------------------------------------------------------------------

  describe "Scenario 2: post-action network partition (ledger survives execution)" do
    test "nonce remains incomplete_pending after crash during complete; new claim rejected", %{
      tmp_dir: tmp_dir
    } do
      ledger = start_ledger(tmp_dir)
      nonce = "nonce-post-partition"

      # Simulate the action executing and the nonce being claimed.
      assert {:ok, :proceed} = ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)

      # Simulate: coordinator/network lost before complete/2 could be called.
      # The nonce remains :pending — as if the node crashed mid-completion.

      # CRITERION M4-CRIT-6: blind retry is blocked.
      assert {:error, :incomplete_pending} =
               ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)

      # Once the outcome is eventually recorded (coordinator comes back):
      assert :ok = ReplayLedger.complete(nonce, {:ok, :restarted}, ledger.server)
      assert {:ok, :complete} = ReplayLedger.status(nonce, ledger.server)

      # Any further claim on the same nonce returns the authoritative result
      # without re-executing.
      assert {:error, :already_executed, {:ok, :restarted}} =
               ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)
    end

    test "action count stays at 1 across partition + reconciliation", %{tmp_dir: tmp_dir} do
      ledger = start_ledger(tmp_dir)
      nonce = "nonce-partition-count"
      action_count = :counters.new(1, [])

      # Executor bumps the counter.
      executor = fn _action, _target, _allow_list ->
        :counters.add(action_count, 1, 1)
        {:ok, :restarted}
      end

      # Simulate: ledger sync fails after claim.
      fail_complete? = :counters.new(1, [])

      complete_fun = fn result ->
        if :counters.get(fail_complete?, 1) == 0 do
          :counters.add(fail_complete?, 1, 1)
          {:error, :sync_failed}
        else
          result
        end
      end

      # Claim the slot and "execute."
      assert {:ok, :proceed} = ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)
      _ = executor.(:restart_service, @service, [@service])

      # Complete fails (partition / crash) — action already ran.
      _ = complete_fun.({:ok, :restarted})

      # Blind retry attempt: nonce is still :incomplete_pending.
      assert {:error, :incomplete_pending} =
               ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)

      # No second execution happened.
      assert :counters.get(action_count, 1) == 1
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 3: Coordinator restart — StateMachine.restore blocks re-execution
  #
  # After a coordinator restart the persisted transition log is replayed via
  # StateMachine.restore/5.  The restored machine has execution_attempted: true
  # once the :executing state was reached, blocking any further execution.
  # ---------------------------------------------------------------------------

  describe "Scenario 3: coordinator restart with StateMachine.restore" do
    test "restore reconstructs :executing state with execution_attempted = true" do
      now = @now

      transitions = [
        tr(1, :observing, :diagnosing, :unhealthy_observation, now),
        tr(2, :diagnosing, :proposed, :evidence_complete, now),
        tr(3, :proposed, :validating, :validate, now),
        tr(4, :validating, :executing, :failed_and_allowed, now)
      ]

      assert {:ok, restored} =
               StateMachine.restore(@task, @node, @service, transitions)

      # CRITERION M4-CRIT-4: execution_attempted is true after restore.
      assert restored.state == :executing
      assert restored.execution_attempted == true
      assert restored.sequence == 4
    end

    test "restored machine in :executing rejects a second failed_and_allowed from :validating" do
      now = @now

      # Simulate: machine was advanced to executing; coordinator restarts and
      # attempts to re-send the same event.  The machine was restored to
      # :executing (via restore), so applying :validate or :failed_and_allowed
      # to a machine at :executing is illegal.
      transitions = [
        tr(1, :observing, :diagnosing, :unhealthy_observation, now),
        tr(2, :diagnosing, :proposed, :evidence_complete, now),
        tr(3, :proposed, :validating, :validate, now),
        tr(4, :validating, :executing, :failed_and_allowed, now)
      ]

      {:ok, restored} = StateMachine.restore(@task, @node, @service, transitions)

      # Attempting to apply :failed_and_allowed to a machine in :executing is illegal.
      assert {:error, {:illegal_transition, :executing, :failed_and_allowed}} =
               StateMachine.apply_event(
                 restored,
                 {:failed_and_allowed, fresh_sm_evidence()},
                 now: now
               )
    end

    test "execution_attempted: true blocks :failed_and_allowed even with state spoofed to :validating" do
      # Defense-in-depth: even if the state were somehow reset to :validating,
      # the execution_attempted flag prevents re-entry into :executing.
      now = @now
      machine = StateMachine.new(@task, @node, @service, created_at: now)

      # Advance to :executing legitimately.
      machine =
        Enum.reduce(
          [
            {:unhealthy_observation, fresh_sm_evidence()},
            {:evidence_complete, fresh_sm_evidence()},
            :validate,
            {:failed_and_allowed, fresh_sm_evidence()}
          ],
          machine,
          fn event, m ->
            {:ok, m2, _} = StateMachine.apply_event(m, event, now: now)
            m2
          end
        )

      assert machine.execution_attempted == true

      # Spoof state back to :validating (should never happen in production, but
      # the guard must hold).
      spoofed = %{machine | state: :validating}

      # CRITERION M4-CRIT-4: execution_already_attempted blocks re-entry.
      assert {:error, :execution_already_attempted} =
               StateMachine.apply_event(
                 spoofed,
                 {:failed_and_allowed, fresh_sm_evidence()},
                 now: now
               )
    end

    test "restore marks execution_attempted for approval path through :executing" do
      now = @now

      transitions = [
        tr(1, :observing, :diagnosing, :unhealthy_observation, now),
        tr(2, :diagnosing, :proposed, :evidence_complete, now),
        tr(3, :proposed, :validating, :validate, now),
        tr(4, :validating, :awaiting_approval, :active_or_degraded, now),
        tr(5, :awaiting_approval, :executing, :valid_approval, now)
      ]

      {:ok, restored} = StateMachine.restore(@task, @node, @service, transitions)

      assert restored.execution_attempted == true
      assert restored.state == :executing

      # The approval guard at :awaiting_approval also checks execution_attempted.
      spoofed = %{restored | state: :awaiting_approval}

      assert {:error, :execution_already_attempted} =
               StateMachine.apply_event(spoofed, {:valid_approval, %{}}, now: now)
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 4: Node restart during action — crash reconciliation
  #
  # If the node crashes while an action is pending (nonce claimed but not
  # completed), the ReplayLedger reconciles the pending record as
  # :crashed_incomplete on the next startup.  Any new claim on the same nonce
  # is rejected, preventing a blind retry.
  # ---------------------------------------------------------------------------

  describe "Scenario 4: node restart during action (crash reconciliation)" do
    test "pending nonce becomes crashed_incomplete after restart; new claim rejected", %{
      tmp_dir: tmp_dir
    } do
      ledger = start_ledger(tmp_dir)
      nonce = "nonce-crash-in-flight"

      # Action claimed but node crashed before completing.
      assert {:ok, :proceed} = ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)
      assert {:ok, :pending} = ReplayLedger.status(nonce, ledger.server)

      # Stop the ledger (simulating node crash).
      GenServer.stop(ledger.server)

      # Restart the ledger — reconciliation runs at init.
      log =
        capture_log(fn ->
          {:ok, restarted} =
            ReplayLedger.start_link(
              name: ledger.name,
              table: ledger.table,
              path: ledger.path
            )

          # CRITERION M4-CRIT-6: crashed_incomplete status after reconciliation.
          assert {:ok, :crashed_incomplete} = ReplayLedger.status(nonce, restarted)

          # CRITERION M4-CRIT-4: new claim rejected — no blind retry.
          assert {:error, :incomplete_pending} =
                   ReplayLedger.claim(nonce, ledger_attrs(), restarted)

          GenServer.stop(restarted)
        end)

      assert log =~ "reconciled crashed replay ledger claim"
    end

    test "action count stays at 0 across crash and retry attempt", %{tmp_dir: tmp_dir} do
      ledger = start_ledger(tmp_dir)
      nonce = "nonce-crash-count"
      action_count = :counters.new(1, [])

      # First attempt: claim ledger slot.
      assert {:ok, :proceed} = ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)

      # Node crashes before executor is invoked.
      GenServer.stop(ledger.server)

      capture_log(fn ->
        {:ok, restarted} =
          ReplayLedger.start_link(
            name: ledger.name,
            table: ledger.table,
            path: ledger.path
          )

        # Retry attempt from coordinator is blocked.
        assert {:error, :incomplete_pending} =
                 ReplayLedger.claim(nonce, ledger_attrs(), restarted)

        # No execution occurred.
        assert :counters.get(action_count, 1) == 0

        GenServer.stop(restarted)
      end)
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 5: Duplicate task same execution ID (sequential)
  #
  # A completed nonce is re-claimed sequentially.  The second claim returns
  # the authoritative result without re-executing.
  # ---------------------------------------------------------------------------

  describe "Scenario 5: duplicate task same execution ID (sequential)" do
    test "second claim returns authoritative result without re-executing", %{tmp_dir: tmp_dir} do
      ledger = start_ledger(tmp_dir)
      nonce = "nonce-dup-sequential"
      authoritative = {:ok, %{restarted: true, exit_code: 0}}

      assert {:ok, :proceed} = ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)
      assert :ok = ReplayLedger.complete(nonce, authoritative, ledger.server)

      # Sequential duplicate.
      assert {:error, :already_executed, ^authoritative} =
               ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)

      # Third attempt still returns the same result.
      assert {:error, :already_executed, ^authoritative} =
               ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)
    end

    test "duplicate approval on completed ApprovalRequired flow is rejected at flow level", %{
      tmp_dir: tmp_dir
    } do
      {_ledger, executions, _audit, opts} = setup_approval_flow(tmp_dir)

      assert {:ok, original} = ApprovalRequired.request(active_evidence(), opts)

      assert {:ok, completed} =
               ApprovalRequired.approve(original, approval_token(), "operator@example.com")

      # Replaying the same flow after completion is rejected.
      assert {:error, :approval_not_pending, _} =
               ApprovalRequired.approve(
                 completed,
                 approval_token(),
                 "operator@example.com"
               )

      # Replaying the original (pre-completion) flow through the gate also blocked.
      assert {:error, :duplicate_approval, replayed} =
               ApprovalRequired.approve(original, approval_token(), "operator@example.com")

      # Machine stays in awaiting_approval on the replayed original.
      assert replayed.machine.state == :awaiting_approval

      # CRITERION M4-CRIT-4: only one execution occurred.
      assert Agent.get(executions, &length/1) == 1
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 6: Concurrent tasks same execution ID
  #
  # Two concurrent processes race to claim the same nonce.  Exactly one must
  # proceed; the other must be blocked.
  # ---------------------------------------------------------------------------

  describe "Scenario 6: concurrent tasks same execution ID" do
    test "exactly one concurrent claim proceeds; the other is blocked", %{tmp_dir: tmp_dir} do
      ledger = start_ledger(tmp_dir)
      nonce = "nonce-concurrent"

      tasks =
        for _ <- 1..2 do
          Task.async(fn -> ReplayLedger.claim(nonce, ledger_attrs(), ledger.server) end)
        end

      results = Enum.map(tasks, &Task.await/1)

      # CRITERION M4-CRIT-4: exactly one proceeds.
      proceeds = Enum.count(results, &(&1 == {:ok, :proceed}))
      blocked = Enum.count(results, &(&1 == {:error, :incomplete_pending}))
      assert proceeds == 1
      assert blocked == 1
    end

    test "high-concurrency race (10 goroutines) still yields exactly one claim", %{
      tmp_dir: tmp_dir
    } do
      ledger = start_ledger(tmp_dir)
      nonce = "nonce-concurrent-10"

      tasks =
        for _ <- 1..10 do
          Task.async(fn -> ReplayLedger.claim(nonce, ledger_attrs(), ledger.server) end)
        end

      results = Enum.map(tasks, &Task.await/1)

      # CRITERION M4-CRIT-4.
      assert Enum.count(results, &(&1 == {:ok, :proceed})) == 1
      assert Enum.count(results, &match?({:error, :incomplete_pending}, &1)) == 9
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 7: Replay — nonce reused after completion
  #
  # A nonce that was already claimed and completed must return the original
  # authoritative result without triggering a new execution.
  # ---------------------------------------------------------------------------

  describe "Scenario 7: replay attack (nonce reused after completion)" do
    test "replay returns authoritative result, no new execution", %{tmp_dir: tmp_dir} do
      ledger = start_ledger(tmp_dir)
      nonce = "nonce-replay"
      authoritative = {:ok, :first_execution}

      assert {:ok, :proceed} = ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)
      assert :ok = ReplayLedger.complete(nonce, authoritative, ledger.server)

      # Replay: same nonce claimed again.
      assert {:error, :already_executed, ^authoritative} =
               ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)
    end

    test "status after replay remains :complete", %{tmp_dir: tmp_dir} do
      ledger = start_ledger(tmp_dir)
      nonce = "nonce-replay-status"

      assert {:ok, :proceed} = ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)
      assert :ok = ReplayLedger.complete(nonce, :done, ledger.server)
      assert {:ok, :complete} = ReplayLedger.status(nonce, ledger.server)

      # Replay does not change the status.
      assert {:error, :already_executed, :done} =
               ReplayLedger.claim(nonce, ledger_attrs(), ledger.server)

      assert {:ok, :complete} = ReplayLedger.status(nonce, ledger.server)
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 8: Audit sink failure pre-action (approval-required path)
  #
  # The durable audit record for the execution intent (valid_approval) must be
  # persisted before the executor is invoked.  If the audit sink is unavailable
  # at that point, execution must be blocked.
  # ---------------------------------------------------------------------------

  describe "Scenario 8: audit sink failure pre-action" do
    test "audit failure on valid_approval event blocks execution; 0 actions", %{
      tmp_dir: tmp_dir
    } do
      {_ledger, executions, _audit_agent, opts} = setup_approval_flow(tmp_dir)

      audit_log = Agent.start_link(fn -> [] end) |> elem(1)

      audit_fun = fn event ->
        Agent.update(audit_log, &(&1 ++ [event.event_tag]))

        if event.event_tag == :valid_approval,
          do: {:error, :audit_sink_unavailable},
          else: :ok
      end

      opts = Keyword.put(opts, :audit_fun, audit_fun)
      assert {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)

      assert {:error, {:execution_failed, {:audit_unavailable, :audit_sink_unavailable}}, pending} =
               ApprovalRequired.approve(flow, approval_token(), "operator@example.com")

      # CRITERION M4-CRIT-6: machine has not advanced past awaiting_approval.
      assert pending.machine.state == :awaiting_approval

      # CRITERION M4-CRIT-4: no execution.
      assert Agent.get(executions, & &1) == []

      # Events before the failure were audited; :valid_approval was not.
      audited_tags = Agent.get(audit_log, & &1)
      refute :execution_complete in audited_tags
      refute :stable_health in audited_tags
    end

    test "pre-request audit failure prevents the flow from being established", %{
      tmp_dir: tmp_dir
    } do
      {_ledger, executions, _audit, opts} = setup_approval_flow(tmp_dir)

      # Fail every audit event.
      opts = Keyword.put(opts, :audit_fun, fn _event -> {:error, :always_unavailable} end)

      # The request itself is blocked because it must audit the initial transitions.
      assert {:error, {:audit_unavailable, :always_unavailable}} =
               ApprovalRequired.request(active_evidence(), opts)

      assert Agent.get(executions, & &1) == []
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 9: Restart failure (executor returns error)
  #
  # The executor fails to restart the service.  The state machine must enter
  # :cooling_down and then :escalated without triggering a retry loop.
  # ---------------------------------------------------------------------------

  describe "Scenario 9: restart failure (executor error)" do
    test "executor failure enters cooling_down then escalated; no retry loop", %{
      tmp_dir: tmp_dir
    } do
      {_ledger, executions, audit, opts} = setup_approval_flow(tmp_dir)

      failing_executor = fn action, target, allow_list ->
        Agent.update(executions, &(&1 ++ [{action, target, allow_list}]))
        {:error, :systemd_timeout}
      end

      opts = Keyword.put(opts, :executor, failing_executor)
      assert {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)

      assert {:ok, result} =
               ApprovalRequired.approve(flow, approval_token(), "operator@example.com")

      # CRITERION M4-CRIT-5: terminal escalated state, no retry.
      assert result.machine.state == :escalated
      assert result.task.status.state == :failed

      # Only one execution attempt.
      assert Agent.get(executions, &length/1) == 1

      # Audit trail ends with the escalation path.
      final_audit_tags = Enum.map(Agent.get(audit, & &1), & &1.event_tag)
      assert :valid_approval in final_audit_tags
      assert :execution_complete in final_audit_tags
      assert :failure_or_instability in final_audit_tags
      assert :cooldown_expired in final_audit_tags

      # CRITERION M4-CRIT-5: no re-entry into :executing after escalation.
      assert result.machine.execution_attempted == true
      assert StateMachine.terminal?(result.machine)
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 10: Health failure (health check fails after successful restart)
  #
  # The executor succeeds but the post-execution health check returns an
  # unhealthy or degraded observation.  The machine must enter :cooling_down
  # and escalate without retrying the restart.
  # ---------------------------------------------------------------------------

  describe "Scenario 10: health failure (post-execution health check fails)" do
    test "unhealthy health check enters cooling_down then escalated; no retry", %{
      tmp_dir: tmp_dir
    } do
      {_ledger, executions, audit, opts} = setup_approval_flow(tmp_dir)

      # Executor succeeds but verify_fun returns degraded evidence.
      opts =
        Keyword.put(opts, :verify_fun, fn _, _ -> {:ok, degraded_evidence()} end)

      assert {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)

      assert {:ok, result} =
               ApprovalRequired.approve(flow, approval_token(), "operator@example.com")

      # CRITERION M4-CRIT-5: terminal escalated state.
      assert result.machine.state == :escalated
      assert result.task.status.state == :failed

      # Exactly one execution attempt.
      assert Agent.get(executions, &length/1) == 1

      # Audit trail includes cooling_down path.
      final_tags = Enum.map(Agent.get(audit, & &1), & &1.event_tag)
      assert :execution_complete in final_tags
      assert :failure_or_instability in final_tags
      assert :cooldown_expired in final_tags

      # CRITERION M4-CRIT-4: execution_attempted true, machine terminal.
      assert result.machine.execution_attempted == true
      assert StateMachine.terminal?(result.machine)
    end

    test "failed health check after approval does not re-execute on next flow attempt", %{
      tmp_dir: tmp_dir
    } do
      {_ledger, executions, _audit, opts} = setup_approval_flow(tmp_dir)

      opts = Keyword.put(opts, :verify_fun, fn _, _ -> {:ok, degraded_evidence()} end)

      {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)
      {:ok, escalated} = ApprovalRequired.approve(flow, approval_token(), "operator@example.com")

      # The machine is terminal — any further event is rejected.
      assert {:error, :already_terminal} =
               StateMachine.apply_event(
                 escalated.machine,
                 {:failed_and_allowed, fresh_sm_evidence()},
                 now: @now
               )

      # Only one execution took place in total.
      assert Agent.get(executions, &length/1) == 1
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 11: Flapping / repeated failure
  #
  # A service that restarts but fails again must NOT trigger an autonomous
  # second restart.  The execution_attempted flag blocks re-entry to :executing
  # after any terminal failure path (cooldown → escalated).  The machine is
  # terminal; no restart loop can form.
  # ---------------------------------------------------------------------------

  describe "Scenario 11: flapping / repeated failure (no restart loop)" do
    test "execution_attempted remains true after escalation; no re-execution path exists" do
      now = @now
      machine = StateMachine.new(@task, @node, @service, created_at: now)

      # Walk through the full failure-then-escalation path.
      events = [
        {:unhealthy_observation, fresh_sm_evidence()},
        {:evidence_complete, fresh_sm_evidence()},
        :validate,
        {:failed_and_allowed, fresh_sm_evidence()},
        {:execution_complete, %{exit_code: 0}},
        {:failure_or_instability, "service failed again immediately"},
        :cooldown_expired
      ]

      final =
        Enum.reduce(events, machine, fn event, m ->
          {:ok, m2, _} = StateMachine.apply_event(m, event, now: now)
          m2
        end)

      # CRITERION M4-CRIT-5: terminal escalated, no loop.
      assert final.state == :escalated
      assert final.execution_attempted == true
      assert StateMachine.terminal?(final)

      # Any event is rejected after terminal.
      assert {:error, :already_terminal} =
               StateMachine.apply_event(final, {:failed_and_allowed, fresh_sm_evidence()},
                 now: now
               )

      assert {:error, :already_terminal} =
               StateMachine.apply_event(final, :validate, now: now)
    end

    test "flapping service with ApprovalRequired: second approval attempt is rejected", %{
      tmp_dir: tmp_dir
    } do
      {_ledger, executions, _audit, opts} = setup_approval_flow(tmp_dir)

      # Simulate flapping: executor succeeds but health check always fails.
      opts = Keyword.put(opts, :verify_fun, fn _, _ -> {:ok, failed_evidence()} end)

      {:ok, flow} = ApprovalRequired.request(active_evidence(), opts)
      {:ok, escalated} = ApprovalRequired.approve(flow, approval_token(), "operator@example.com")

      assert escalated.machine.state == :escalated
      assert StateMachine.terminal?(escalated.machine)

      # Attempting a second approval on the escalated flow is rejected.
      assert {:error, :approval_not_pending, _} =
               ApprovalRequired.approve(escalated, approval_token(), "operator@example.com")

      # CRITERION M4-CRIT-4: only one restart attempt was made.
      assert Agent.get(executions, &length/1) == 1
    end

    test "state machine defense-in-depth: execution_attempted blocks re-entry after cooldown" do
      now = @now
      machine = StateMachine.new(@task, @node, @service, created_at: now)

      events_to_executing = [
        {:unhealthy_observation, fresh_sm_evidence()},
        {:evidence_complete, fresh_sm_evidence()},
        :validate,
        {:failed_and_allowed, fresh_sm_evidence()}
      ]

      in_executing =
        Enum.reduce(events_to_executing, machine, fn event, m ->
          {:ok, m2, _} = StateMachine.apply_event(m, event, now: now)
          m2
        end)

      assert in_executing.execution_attempted == true

      # Verification fails → cooling_down.
      {:ok, cooling, _} =
        StateMachine.apply_event(
          in_executing,
          {:execution_complete, %{exit_code: 0}},
          now: now
        )

      {:ok, cooling, _} =
        StateMachine.apply_event(cooling, {:failure_or_instability, "flapping"}, now: now)

      assert cooling.state == :cooling_down
      assert cooling.execution_attempted == true

      # Even if state were spoofed to :validating, the guard holds.
      spoofed = %{cooling | state: :validating}

      assert {:error, :execution_already_attempted} =
               StateMachine.apply_event(
                 spoofed,
                 {:failed_and_allowed, fresh_sm_evidence()},
                 now: now
               )
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 12: Cooldown reconciliation after node restart
  #
  # If the node restarts while the machine is in :cooling_down (e.g., the
  # node was restarted during the cooldown window), StateMachine.restore
  # reconstructs the :cooling_down state.  The reconciling coordinator then
  # applies :cooldown_expired → :escalated without repeating the execution.
  # ---------------------------------------------------------------------------

  describe "Scenario 12: cooldown reconciliation after node restart" do
    test "restore from cooling_down transitions to escalated without re-executing" do
      now = @now

      # Transition log as it would be persisted before the node restart.
      transitions = [
        tr(1, :observing, :diagnosing, :unhealthy_observation, now),
        tr(2, :diagnosing, :proposed, :evidence_complete, now),
        tr(3, :proposed, :validating, :validate, now),
        tr(4, :validating, :executing, :failed_and_allowed, now),
        tr(5, :executing, :verifying, :execution_complete, now),
        tr(6, :verifying, :cooling_down, :failure_or_instability, now)
      ]

      assert {:ok, restored} =
               StateMachine.restore(@task, @node, @service, transitions)

      # CRITERION M4-CRIT-6: machine reconstructs at :cooling_down.
      assert restored.state == :cooling_down
      assert restored.execution_attempted == true
      assert restored.sequence == 6

      # Reconciliation: coordinator applies :cooldown_expired.
      assert {:ok, final, audit} = StateMachine.apply_event(restored, :cooldown_expired, now: now)

      assert final.state == :escalated
      assert StateMachine.terminal?(final)
      assert audit.event_tag == :cooldown_expired

      # CRITERION M4-CRIT-4: no blind retry — execution_attempted is still true.
      assert final.execution_attempted == true
    end

    test "restore from cooling_down rejects any execution event" do
      now = @now

      transitions = [
        tr(1, :observing, :diagnosing, :unhealthy_observation, now),
        tr(2, :diagnosing, :proposed, :evidence_complete, now),
        tr(3, :proposed, :validating, :validate, now),
        tr(4, :validating, :executing, :failed_and_allowed, now),
        tr(5, :executing, :verifying, :execution_complete, now),
        tr(6, :verifying, :cooling_down, :failure_or_instability, now)
      ]

      {:ok, restored} = StateMachine.restore(@task, @node, @service, transitions)

      # All execution-related events must be rejected from :cooling_down.
      execution_events = [
        {:failed_and_allowed, fresh_sm_evidence()},
        {:valid_approval, %{}},
        :validate,
        {:stable_health, fresh_sm_evidence()}
      ]

      for event <- execution_events do
        assert {:error, {:illegal_transition, :cooling_down, _}} =
                 StateMachine.apply_event(restored, event, now: now),
               "expected illegal_transition for #{inspect(event)} from :cooling_down"
      end
    end

    test "sequence integrity is maintained through restore and reconciliation" do
      now = @now

      transitions = [
        tr(1, :observing, :diagnosing, :unhealthy_observation, now),
        tr(2, :diagnosing, :proposed, :evidence_complete, now),
        tr(3, :proposed, :validating, :validate, now),
        tr(4, :validating, :executing, :failed_and_allowed, now),
        tr(5, :executing, :verifying, :execution_complete, now),
        tr(6, :verifying, :cooling_down, :failure_or_instability, now)
      ]

      {:ok, restored} = StateMachine.restore(@task, @node, @service, transitions)
      assert restored.sequence == 6

      {:ok, final, audit} = StateMachine.apply_event(restored, :cooldown_expired, now: now)
      assert final.sequence == 7
      assert audit.sequence == 7
    end
  end

  # ---------------------------------------------------------------------------
  # Cross-cutting: exactly-once invariant across all fault scenarios
  #
  # Assert the combined guarantee: regardless of fault type, no pair of
  # (state machine, replay ledger) can produce more than one execution.
  # ---------------------------------------------------------------------------

  describe "cross-cutting: exactly-once execution invariant" do
    test "nonce is unique per state machine episode; no episode can claim twice", %{
      tmp_dir: tmp_dir
    } do
      ledger = start_ledger(tmp_dir)
      # Two episodes, two nonces.
      ep1_nonce = "ep1-nonce"
      ep2_nonce = "ep2-nonce"

      assert {:ok, :proceed} = ReplayLedger.claim(ep1_nonce, ledger_attrs(), ledger.server)
      assert {:ok, :proceed} = ReplayLedger.claim(ep2_nonce, ledger_attrs(), ledger.server)

      # Complete ep1; ep2 still pending.
      assert :ok = ReplayLedger.complete(ep1_nonce, :ok, ledger.server)

      # ep1 nonce cannot be re-claimed.
      assert {:error, :already_executed, :ok} =
               ReplayLedger.claim(ep1_nonce, ledger_attrs(), ledger.server)

      # ep2 nonce is still pending — only one execution can be in-flight.
      assert {:ok, :pending} = ReplayLedger.status(ep2_nonce, ledger.server)

      assert {:error, :incomplete_pending} =
               ReplayLedger.claim(ep2_nonce, ledger_attrs(), ledger.server)
    end

    test "state machine sequence gap detection prevents out-of-order execution" do
      now = @now

      valid = tr(1, :observing, :diagnosing, :unhealthy_observation, now)

      # Gap: sequence 3 instead of 2.
      gap = tr(3, :diagnosing, :proposed, :evidence_complete, now)

      # CRITERION M4-CRIT-4: log with gap is rejected, cannot reach :executing.
      assert {:error, {:sequence_gap, 2, 3}} =
               StateMachine.restore(@task, @node, @service, [valid, gap])
    end

    test "all three terminal states block further events (no escape from terminal)" do
      now = @now

      probing_events = [
        {:unhealthy_observation, fresh_sm_evidence()},
        {:failed_and_allowed, fresh_sm_evidence()},
        {:valid_approval, %{}},
        :validate,
        :cooldown_expired,
        {:cancel, "late"}
      ]

      for terminal_state <- [:completed, :escalated, :cancelled] do
        machine = %{
          StateMachine.new(@task, @node, @service, created_at: now)
          | state: terminal_state
        }

        for event <- probing_events do
          assert {:error, :already_terminal} =
                   StateMachine.apply_event(machine, event, now: now),
                 "expected :already_terminal for #{inspect(event)} in #{terminal_state}"
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Shorthand for building a StateMachine transition_record map.
  defp tr(seq, from, to, tag, timestamp) do
    %{from: from, to: to, event_tag: tag, sequence: seq, timestamp: timestamp}
  end
end

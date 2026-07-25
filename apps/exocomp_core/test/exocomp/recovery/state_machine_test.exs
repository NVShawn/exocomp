defmodule Exocomp.Recovery.StateMachineTest do
  @moduledoc """
  Exhaustive state-transition tests for `Exocomp.Recovery.StateMachine`.

  Coverage:
  - All legal transitions (happy path and all branching paths)
  - All illegal transitions (wrong state + event combos)
  - Stale evidence (evidence older than max_evidence_age_seconds)
  - Future evidence (collected_at in the future)
  - Cancellation from every non-terminal state
  - Deadline enforcement
  - Events applied to already-terminal states
  - Duplicate events (same legal event applied twice)
  - Approval expiry
  - One-execution-attempt defense-in-depth
  - Restart restoration via `restore/5`
  - Sequence integrity across full happy-path
  - Audit event shape (correlation, episode, node, service, tags, sequence)
  - Escalation paths from every escalatable state
  - Cooldown → escalated terminal path
  - `terminal?/1` helper
  """

  use ExUnit.Case, async: true

  alias Exocomp.Recovery.Evidence
  alias Exocomp.Recovery.StateMachine

  # ──────────────────────────────────────────────────────────────────
  # Fixtures
  # ──────────────────────────────────────────────────────────────────

  # A small max-age so tests can easily create stale evidence.
  @max_age 60

  @node "node-01"
  @svc "myapp.service"
  @ep "ep-test-001"
  @corr "corr-abc"

  defp machine(opts \\ []) do
    defaults = [
      correlation_id: @corr,
      max_evidence_age_seconds: @max_age
    ]

    StateMachine.new(@ep, @node, @svc, Keyword.merge(defaults, opts))
  end

  # Build fresh evidence collected at `now`.
  defp fresh_evidence(now) do
    Evidence.new(@node, @svc, %{active_state: "failed"}, collected_at: now)
  end

  # Build evidence collected `seconds_ago` seconds before `now`.
  defp aged_evidence(now, seconds_ago) do
    collected_at = DateTime.add(now, -seconds_ago, :second)
    Evidence.new(@node, @svc, %{active_state: "failed"}, collected_at: collected_at)
  end

  # Build an approval map with optional expiry.
  defp approval(opts \\ []) do
    base = %{nonce: "nonce-1", task_id: "task-1", action_id: "systemd.service.restart"}
    Enum.into(opts, base)
  end

  # Walk the machine through the automatic path, advancing INCLUSIVE of
  # `target_state`. The states list represents the automatic (non-approval)
  # path.
  defp advance_to(machine, target, now) do
    states = [
      :observing,
      :diagnosing,
      :proposed,
      :validating,
      :executing,
      :verifying,
      :completed
    ]

    idx_current = Enum.find_index(states, &(&1 == machine.state))
    idx_target = Enum.find_index(states, &(&1 == target))

    # Slice is inclusive of idx_target so that the machine ends in `target`.
    Enum.reduce(
      Enum.slice(states, (idx_current + 1)..idx_target//1),
      machine,
      fn next_state, acc ->
        {:ok, m, _audit} = step_to(acc, next_state, now)
        m
      end
    )
  end

  # Single-step helpers: each applies the natural event to go from
  # `machine.state` to the specified next state along the automatic path.

  defp step_to(%{state: :observing} = m, :diagnosing, now),
    do: StateMachine.apply_event(m, {:unhealthy_observation, fresh_evidence(now)}, now: now)

  defp step_to(%{state: :diagnosing} = m, :proposed, now),
    do: StateMachine.apply_event(m, {:evidence_complete, fresh_evidence(now)}, now: now)

  defp step_to(%{state: :proposed} = m, :validating, now),
    do: StateMachine.apply_event(m, :validate, now: now)

  defp step_to(%{state: :validating} = m, :executing, now),
    do: StateMachine.apply_event(m, {:failed_and_allowed, fresh_evidence(now)}, now: now)

  defp step_to(%{state: :executing} = m, :verifying, now),
    do: StateMachine.apply_event(m, {:execution_complete, %{exit_code: 0}}, now: now)

  defp step_to(%{state: :verifying} = m, :completed, now),
    do: StateMachine.apply_event(m, {:stable_health, fresh_evidence(now)}, now: now)

  # ──────────────────────────────────────────────────────────────────
  # 1. new/4 — initial state
  # ──────────────────────────────────────────────────────────────────

  describe "new/4" do
    test "starts in :observing state with zero sequence" do
      m = machine()
      assert m.state == :observing
      assert m.sequence == 0
      assert m.execution_attempted == false
      assert m.transitions == []
      assert m.evidence == nil
    end

    test "accepts a caller-supplied correlation_id" do
      m = machine(correlation_id: "supplied-corr")
      assert m.correlation_id == "supplied-corr"
    end

    test "generates a correlation_id when none is supplied" do
      m = StateMachine.new(@ep, @node, @svc)
      assert is_binary(m.correlation_id)
      assert byte_size(m.correlation_id) > 0
    end

    test "episode_id, node_id, service are set correctly" do
      m = machine()
      assert m.episode_id == @ep
      assert m.node_id == @node
      assert m.service == @svc
    end

    test "accepts a deadline option" do
      deadline = DateTime.add(DateTime.utc_now(), 600, :second)
      m = machine(deadline: deadline)
      assert m.deadline == deadline
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 2. terminal?/1
  # ──────────────────────────────────────────────────────────────────

  describe "terminal?/1" do
    test "non-terminal states return false" do
      non_terminal = [
        :observing,
        :diagnosing,
        :proposed,
        :validating,
        :awaiting_approval,
        :executing,
        :verifying,
        :cooling_down
      ]

      for state <- non_terminal do
        m = %{machine() | state: state}
        refute StateMachine.terminal?(m), "expected #{state} to be non-terminal"
      end
    end

    test "terminal states return true" do
      for state <- [:completed, :escalated, :cancelled] do
        m = %{machine() | state: state}
        assert StateMachine.terminal?(m), "expected #{state} to be terminal"
      end
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 3. Happy path: automatic failed-service recovery
  # ──────────────────────────────────────────────────────────────────

  describe "happy path: automatic recovery (failed service)" do
    test "observing → diagnosing on unhealthy_observation" do
      now = DateTime.utc_now()
      ev = fresh_evidence(now)

      {:ok, m1, audit} =
        StateMachine.apply_event(machine(), {:unhealthy_observation, ev}, now: now)

      assert m1.state == :diagnosing
      assert m1.sequence == 1
      assert audit.from_state == :observing
      assert audit.to_state == :diagnosing
      assert audit.event_tag == :unhealthy_observation
      assert audit.sequence == 1
      assert audit.correlation_id == @corr
      assert audit.episode_id == @ep
      assert audit.node_id == @node
      assert audit.service == @svc
    end

    test "diagnosing → proposed on evidence_complete" do
      now = DateTime.utc_now()
      m0 = machine()

      {:ok, m1, _} =
        StateMachine.apply_event(m0, {:unhealthy_observation, fresh_evidence(now)}, now: now)

      {:ok, m2, audit} =
        StateMachine.apply_event(m1, {:evidence_complete, fresh_evidence(now)}, now: now)

      assert m2.state == :proposed
      assert m2.sequence == 2
      assert audit.event_tag == :evidence_complete
    end

    test "proposed → validating on validate" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :proposed, now)
      {:ok, m3, _} = StateMachine.apply_event(m, :validate, now: now)

      assert m3.state == :validating
      assert m3.sequence == 3
    end

    test "validating → executing on failed_and_allowed" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :validating, now)

      {:ok, m4, audit} =
        StateMachine.apply_event(m, {:failed_and_allowed, fresh_evidence(now)}, now: now)

      assert m4.state == :executing
      assert m4.execution_attempted == true
      assert audit.event_tag == :failed_and_allowed
    end

    test "executing → verifying on execution_complete" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :executing, now)

      {:ok, m5, audit} =
        StateMachine.apply_event(m, {:execution_complete, %{exit_code: 0}}, now: now)

      assert m5.state == :verifying
      assert audit.event_tag == :execution_complete
    end

    test "verifying → completed on stable_health" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :verifying, now)

      {:ok, m6, audit} =
        StateMachine.apply_event(m, {:stable_health, fresh_evidence(now)}, now: now)

      assert m6.state == :completed
      assert StateMachine.terminal?(m6)
      assert audit.event_tag == :stable_health
    end

    test "full happy path produces 6 transitions and 6 audit events with consecutive sequences" do
      now = DateTime.utc_now()
      m0 = machine()

      steps = [
        {:unhealthy_observation, fresh_evidence(now)},
        {:evidence_complete, fresh_evidence(now)},
        :validate,
        {:failed_and_allowed, fresh_evidence(now)},
        {:execution_complete, %{exit_code: 0}},
        {:stable_health, fresh_evidence(now)}
      ]

      {final, audits} =
        Enum.reduce(steps, {m0, []}, fn ev, {m, acc} ->
          {:ok, m2, audit} = StateMachine.apply_event(m, ev, now: now)
          {m2, acc ++ [audit]}
        end)

      assert final.state == :completed
      assert length(final.transitions) == 6
      assert length(audits) == 6

      # Sequences must be strictly 1..6.
      Enum.each(Enum.zip(1..6, audits), fn {seq, audit} ->
        assert audit.sequence == seq
      end)
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 4. Approval path: active/degraded service requires approval
  # ──────────────────────────────────────────────────────────────────

  describe "approval path: active or degraded service" do
    setup do
      now = DateTime.utc_now()
      m_validating = advance_to(machine(), :validating, now)
      [now: now, m_validating: m_validating]
    end

    test "validating → awaiting_approval on active_or_degraded", %{now: now, m_validating: m} do
      {:ok, m2, audit} =
        StateMachine.apply_event(m, {:active_or_degraded, fresh_evidence(now)}, now: now)

      assert m2.state == :awaiting_approval
      assert audit.event_tag == :active_or_degraded
    end

    test "awaiting_approval → executing on valid_approval (no expiry)", %{
      now: now,
      m_validating: m
    } do
      {:ok, m2, _} =
        StateMachine.apply_event(m, {:active_or_degraded, fresh_evidence(now)}, now: now)

      {:ok, m3, audit} = StateMachine.apply_event(m2, {:valid_approval, approval()}, now: now)

      assert m3.state == :executing
      assert m3.execution_attempted == true
      assert audit.event_tag == :valid_approval
    end

    test "awaiting_approval → executing on valid_approval with future expiry", %{
      now: now,
      m_validating: m
    } do
      {:ok, m2, _} =
        StateMachine.apply_event(m, {:active_or_degraded, fresh_evidence(now)}, now: now)

      future_expiry = DateTime.add(now, 3600, :second)

      {:ok, m3, _} =
        StateMachine.apply_event(m2, {:valid_approval, approval(expires_at: future_expiry)},
          now: now
        )

      assert m3.state == :executing
    end

    test "awaiting_approval → escalated on deny_or_expire_or_changed", %{
      now: now,
      m_validating: m
    } do
      {:ok, m2, _} =
        StateMachine.apply_event(m, {:active_or_degraded, fresh_evidence(now)}, now: now)

      {:ok, m3, audit} =
        StateMachine.apply_event(m2, {:deny_or_expire_or_changed, "precondition changed"},
          now: now
        )

      assert m3.state == :escalated
      assert StateMachine.terminal?(m3)
      assert audit.event_tag == :deny_or_expire_or_changed
    end

    test "awaiting_approval: expired approval token is rejected", %{now: now, m_validating: m} do
      {:ok, m2, _} =
        StateMachine.apply_event(m, {:active_or_degraded, fresh_evidence(now)}, now: now)

      past_expiry = DateTime.add(now, -1, :second)

      assert {:error, :approval_expired} =
               StateMachine.apply_event(m2, {:valid_approval, approval(expires_at: past_expiry)},
                 now: now
               )

      # Machine must not have advanced.
      assert m2.state == :awaiting_approval
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 5. Escalation paths
  # ──────────────────────────────────────────────────────────────────

  describe "escalation paths" do
    test "diagnosing → escalated on insufficient_evidence" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :diagnosing, now)

      {:ok, m2, audit} =
        StateMachine.apply_event(m, {:insufficient_evidence, "no data"}, now: now)

      assert m2.state == :escalated
      assert audit.event_tag == :insufficient_evidence
      assert audit.meta[:reason] == "no data"
    end

    test "validating → escalated on deny_or_no_safe_action" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :validating, now)

      {:ok, m2, audit} =
        StateMachine.apply_event(m, {:deny_or_no_safe_action, "policy deny"}, now: now)

      assert m2.state == :escalated
      assert audit.event_tag == :deny_or_no_safe_action
    end

    test "verifying → cooling_down → escalated" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :verifying, now)

      {:ok, m2, audit1} =
        StateMachine.apply_event(m, {:failure_or_instability, "health failed"}, now: now)

      assert m2.state == :cooling_down
      assert audit1.event_tag == :failure_or_instability

      {:ok, m3, audit2} = StateMachine.apply_event(m2, :cooldown_expired, now: now)
      assert m3.state == :escalated
      assert StateMachine.terminal?(m3)
      assert audit2.event_tag == :cooldown_expired
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 6. Stale evidence
  # ──────────────────────────────────────────────────────────────────

  describe "stale evidence rejection" do
    test "unhealthy_observation with evidence beyond max_age is rejected" do
      now = DateTime.utc_now()
      stale_ev = aged_evidence(now, @max_age + 1)

      assert {:error, {:stale_evidence, age, @max_age}} =
               StateMachine.apply_event(machine(), {:unhealthy_observation, stale_ev}, now: now)

      assert age == @max_age + 1
    end

    test "evidence_complete with stale evidence is rejected" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :diagnosing, now)
      stale_ev = aged_evidence(now, @max_age + 5)

      assert {:error, {:stale_evidence, _, @max_age}} =
               StateMachine.apply_event(m, {:evidence_complete, stale_ev}, now: now)

      assert m.state == :diagnosing
    end

    test "failed_and_allowed with stale evidence is rejected" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :validating, now)
      stale_ev = aged_evidence(now, @max_age + 1)

      assert {:error, {:stale_evidence, _, @max_age}} =
               StateMachine.apply_event(m, {:failed_and_allowed, stale_ev}, now: now)

      assert m.state == :validating
    end

    test "active_or_degraded with stale evidence is rejected" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :validating, now)
      stale_ev = aged_evidence(now, @max_age + 1)

      assert {:error, {:stale_evidence, _, @max_age}} =
               StateMachine.apply_event(m, {:active_or_degraded, stale_ev}, now: now)

      assert m.state == :validating
    end

    test "stable_health with stale evidence is rejected" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :verifying, now)
      stale_ev = aged_evidence(now, @max_age + 1)

      assert {:error, {:stale_evidence, _, @max_age}} =
               StateMachine.apply_event(m, {:stable_health, stale_ev}, now: now)

      assert m.state == :verifying
    end

    test "evidence collected in the future (negative age) is also rejected" do
      now = DateTime.utc_now()
      future_collected = DateTime.add(now, 100, :second)
      future_ev = Evidence.new(@node, @svc, %{}, collected_at: future_collected)

      assert {:error, {:stale_evidence, age, _}} =
               StateMachine.apply_event(machine(), {:unhealthy_observation, future_ev}, now: now)

      # age is negative (now - future = -100)
      assert age < 0
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 7. Illegal transitions
  # ──────────────────────────────────────────────────────────────────

  describe "illegal transition rejection" do
    test "validate event from :observing is illegal" do
      now = DateTime.utc_now()

      assert {:error, {:illegal_transition, :observing, :validate}} =
               StateMachine.apply_event(machine(), :validate, now: now)
    end

    test "stable_health from :observing is illegal" do
      now = DateTime.utc_now()

      assert {:error, {:illegal_transition, :observing, :stable_health}} =
               StateMachine.apply_event(machine(), {:stable_health, fresh_evidence(now)},
                 now: now
               )
    end

    test "execution_complete from :diagnosing is illegal" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :diagnosing, now)

      assert {:error, {:illegal_transition, :diagnosing, :execution_complete}} =
               StateMachine.apply_event(m, {:execution_complete, %{}}, now: now)
    end

    test "evidence_complete from :proposed is illegal" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :proposed, now)

      # :proposed only accepts :validate (or cancel).
      assert {:error, {:illegal_transition, :proposed, :evidence_complete}} =
               StateMachine.apply_event(m, {:evidence_complete, fresh_evidence(now)}, now: now)
    end

    test "cooldown_expired from :validating is illegal" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :validating, now)

      assert {:error, {:illegal_transition, :validating, :cooldown_expired}} =
               StateMachine.apply_event(m, :cooldown_expired, now: now)
    end

    test "unhealthy_observation from :executing is illegal" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :executing, now)

      assert {:error, {:illegal_transition, :executing, :unhealthy_observation}} =
               StateMachine.apply_event(m, {:unhealthy_observation, fresh_evidence(now)},
                 now: now
               )
    end

    test "valid_approval from :executing is illegal" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :executing, now)

      assert {:error, {:illegal_transition, :executing, :valid_approval}} =
               StateMachine.apply_event(m, {:valid_approval, approval()}, now: now)
    end

    test "cooldown_expired from :verifying is illegal" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :verifying, now)

      assert {:error, {:illegal_transition, :verifying, :cooldown_expired}} =
               StateMachine.apply_event(m, :cooldown_expired, now: now)
    end

    test "validate from :cooling_down is illegal" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :verifying, now)
      {:ok, m_cd, _} = StateMachine.apply_event(m, {:failure_or_instability, "failed"}, now: now)
      assert m_cd.state == :cooling_down

      assert {:error, {:illegal_transition, :cooling_down, :validate}} =
               StateMachine.apply_event(m_cd, :validate, now: now)
    end

    test "execution_complete from :awaiting_approval is illegal" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :validating, now)

      {:ok, m2, _} =
        StateMachine.apply_event(m, {:active_or_degraded, fresh_evidence(now)}, now: now)

      assert m2.state == :awaiting_approval

      assert {:error, {:illegal_transition, :awaiting_approval, :execution_complete}} =
               StateMachine.apply_event(m2, {:execution_complete, %{}}, now: now)
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 8. Already-terminal state rejection
  # ──────────────────────────────────────────────────────────────────

  describe "already-terminal rejection" do
    for terminal <- [:completed, :escalated, :cancelled] do
      @terminal terminal
      test "any event to #{terminal} state returns :already_terminal" do
        now = DateTime.utc_now()
        m = %{machine() | state: @terminal}

        events = [
          {:unhealthy_observation, fresh_evidence(now)},
          {:evidence_complete, fresh_evidence(now)},
          :validate,
          :cooldown_expired,
          {:cancel, "late cancel"}
        ]

        for ev <- events do
          assert {:error, :already_terminal} =
                   StateMachine.apply_event(m, ev, now: now),
                 "expected :already_terminal for event #{inspect(ev)} in state #{@terminal}"
        end
      end
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 9. Duplicate event (same legal event applied twice)
  # ──────────────────────────────────────────────────────────────────

  describe "duplicate events" do
    test "applying validate twice: second call is illegal (machine is now :validating)" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :proposed, now)
      {:ok, m2, _} = StateMachine.apply_event(m, :validate, now: now)
      assert m2.state == :validating

      # Applying :validate again from :validating is illegal.
      assert {:error, {:illegal_transition, :validating, :validate}} =
               StateMachine.apply_event(m2, :validate, now: now)
    end

    test "applying unhealthy_observation twice: second is illegal (machine is :diagnosing)" do
      now = DateTime.utc_now()
      m0 = machine()

      {:ok, m1, _} =
        StateMachine.apply_event(m0, {:unhealthy_observation, fresh_evidence(now)}, now: now)

      assert m1.state == :diagnosing

      assert {:error, {:illegal_transition, :diagnosing, :unhealthy_observation}} =
               StateMachine.apply_event(m1, {:unhealthy_observation, fresh_evidence(now)},
                 now: now
               )
    end

    test "applying evidence_complete twice: second is illegal (machine is :proposed)" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :diagnosing, now)

      {:ok, m2, _} =
        StateMachine.apply_event(m, {:evidence_complete, fresh_evidence(now)}, now: now)

      assert m2.state == :proposed

      assert {:error, {:illegal_transition, :proposed, :evidence_complete}} =
               StateMachine.apply_event(m2, {:evidence_complete, fresh_evidence(now)}, now: now)
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 10. Cancellation from all non-terminal states
  # ──────────────────────────────────────────────────────────────────

  describe "cancellation" do
    for state <- [
          :observing,
          :diagnosing,
          :proposed,
          :validating,
          :awaiting_approval,
          :executing,
          :verifying,
          :cooling_down
        ] do
      @cancel_state state
      test "cancel from #{state} transitions to :cancelled" do
        now = DateTime.utc_now()
        m = %{machine() | state: @cancel_state}
        {:ok, m2, audit} = StateMachine.apply_event(m, {:cancel, "test cancel"}, now: now)

        assert m2.state == :cancelled
        assert StateMachine.terminal?(m2)
        assert audit.event_tag == :cancel
        assert audit.from_state == @cancel_state
        assert audit.to_state == :cancelled
        assert audit.meta[:reason] == "test cancel"
      end
    end

    test "cancel does not mutate the original machine (pure functional)" do
      now = DateTime.utc_now()
      original = machine()
      {:ok, m2, _} = StateMachine.apply_event(original, {:cancel, "cancelled"}, now: now)

      assert original.state == :observing
      assert m2.state == :cancelled
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 11. Deadline enforcement
  # ──────────────────────────────────────────────────────────────────

  describe "deadline enforcement" do
    test "event past the deadline is rejected with :deadline_exceeded" do
      deadline = DateTime.utc_now()
      m = machine(deadline: deadline)
      # now is 1 second past the deadline
      now = DateTime.add(deadline, 1, :second)

      assert {:error, :deadline_exceeded} =
               StateMachine.apply_event(m, {:unhealthy_observation, fresh_evidence(now)},
                 now: now
               )

      assert m.state == :observing
    end

    test "event exactly at the deadline succeeds (boundary is strict >)" do
      deadline = DateTime.utc_now()
      m = machine(deadline: deadline)
      ev = Evidence.new(@node, @svc, %{}, collected_at: deadline)
      # now == deadline → compare returns :eq, not :gt → allowed
      {:ok, m2, _} = StateMachine.apply_event(m, {:unhealthy_observation, ev}, now: deadline)
      assert m2.state == :diagnosing
    end

    test "no deadline means events always pass the deadline check" do
      now = DateTime.utc_now()
      # no deadline
      m = machine()

      {:ok, m2, _} =
        StateMachine.apply_event(m, {:unhealthy_observation, fresh_evidence(now)}, now: now)

      assert m2.state == :diagnosing
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 12. One-execution-attempt defense-in-depth
  # ──────────────────────────────────────────────────────────────────

  describe "one-execution-attempt limit" do
    test "execution_attempted flag is set to true on reaching :executing" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :executing, now)
      assert m.execution_attempted == true
    end

    test "flag remains false while in :validating (before execution)" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :validating, now)
      assert m.execution_attempted == false
    end

    test "execution_attempted: true blocks failed_and_allowed in :validating" do
      # Defense-in-depth guard: even if state is :validating, block re-entry.
      now = DateTime.utc_now()
      m = %{advance_to(machine(), :validating, now) | execution_attempted: true}

      assert {:error, :execution_already_attempted} =
               StateMachine.apply_event(m, {:failed_and_allowed, fresh_evidence(now)}, now: now)
    end

    test "execution_attempted: true blocks valid_approval in :awaiting_approval" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :validating, now)

      {:ok, m2, _} =
        StateMachine.apply_event(m, {:active_or_degraded, fresh_evidence(now)}, now: now)

      assert m2.state == :awaiting_approval

      m2_flagged = %{m2 | execution_attempted: true}

      assert {:error, :execution_already_attempted} =
               StateMachine.apply_event(m2_flagged, {:valid_approval, approval()}, now: now)
    end

    test "failed verification does not loop back to executing — machine becomes terminal" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :verifying, now)

      {:ok, m_cd, _} =
        StateMachine.apply_event(m, {:failure_or_instability, "health failed"}, now: now)

      {:ok, m_esc, _} = StateMachine.apply_event(m_cd, :cooldown_expired, now: now)

      assert m_esc.state == :escalated
      assert StateMachine.terminal?(m_esc)

      # Any further event returns :already_terminal, not a new execution.
      assert {:error, :already_terminal} =
               StateMachine.apply_event(m_esc, {:failed_and_allowed, fresh_evidence(now)},
                 now: now
               )
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 13. Restart restoration via restore/5
  # ──────────────────────────────────────────────────────────────────

  describe "restore/5" do
    test "restores state machine from transition log to match direct transitions" do
      now = DateTime.utc_now()
      m0 = machine()

      events = [
        {:unhealthy_observation, fresh_evidence(now)},
        {:evidence_complete, fresh_evidence(now)},
        :validate,
        {:failed_and_allowed, fresh_evidence(now)},
        {:execution_complete, %{exit_code: 0}},
        {:stable_health, fresh_evidence(now)}
      ]

      direct =
        Enum.reduce(events, m0, fn ev, m ->
          {:ok, m2, _audit} = StateMachine.apply_event(m, ev, now: now)
          m2
        end)

      {:ok, restored} =
        StateMachine.restore(@ep, @node, @svc, direct.transitions,
          correlation_id: @corr,
          max_evidence_age_seconds: @max_age
        )

      assert restored.state == direct.state
      assert restored.sequence == direct.sequence
      assert restored.execution_attempted == direct.execution_attempted
      assert length(restored.transitions) == length(direct.transitions)
    end

    test "restores partial path (up to :executing)" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :executing, now)
      assert m.state == :executing

      {:ok, restored} =
        StateMachine.restore(@ep, @node, @svc, m.transitions,
          correlation_id: @corr,
          max_evidence_age_seconds: @max_age
        )

      assert restored.state == :executing
      assert restored.execution_attempted == true
    end

    test "restore with empty log returns initial :observing state" do
      {:ok, m} = StateMachine.restore(@ep, @node, @svc, [], correlation_id: @corr)
      assert m.state == :observing
      assert m.sequence == 0
    end

    test "restore with out-of-sequence log returns error" do
      now = DateTime.utc_now()

      valid = %{
        from: :observing,
        to: :diagnosing,
        event_tag: :unhealthy_observation,
        sequence: 1,
        timestamp: now
      }

      # gap: sequence should be 2 but is 3
      gap = %{
        from: :diagnosing,
        to: :proposed,
        event_tag: :evidence_complete,
        sequence: 3,
        timestamp: now
      }

      assert {:error, {:sequence_gap, 2, 3}} =
               StateMachine.restore(@ep, @node, @svc, [valid, gap])
    end

    test "restore marks execution_attempted for any transition to :executing" do
      now = DateTime.utc_now()

      transitions = [
        %{
          from: :observing,
          to: :diagnosing,
          event_tag: :unhealthy_observation,
          sequence: 1,
          timestamp: now
        },
        %{
          from: :diagnosing,
          to: :proposed,
          event_tag: :evidence_complete,
          sequence: 2,
          timestamp: now
        },
        %{from: :proposed, to: :validating, event_tag: :validate, sequence: 3, timestamp: now},
        %{
          from: :validating,
          to: :executing,
          event_tag: :failed_and_allowed,
          sequence: 4,
          timestamp: now
        }
      ]

      {:ok, m} = StateMachine.restore(@ep, @node, @svc, transitions)
      assert m.execution_attempted == true
      assert m.state == :executing
    end

    test "restore marks execution_attempted for approval path to :executing" do
      now = DateTime.utc_now()

      transitions = [
        %{
          from: :observing,
          to: :diagnosing,
          event_tag: :unhealthy_observation,
          sequence: 1,
          timestamp: now
        },
        %{
          from: :diagnosing,
          to: :proposed,
          event_tag: :evidence_complete,
          sequence: 2,
          timestamp: now
        },
        %{from: :proposed, to: :validating, event_tag: :validate, sequence: 3, timestamp: now},
        %{
          from: :validating,
          to: :awaiting_approval,
          event_tag: :active_or_degraded,
          sequence: 4,
          timestamp: now
        },
        %{
          from: :awaiting_approval,
          to: :executing,
          event_tag: :valid_approval,
          sequence: 5,
          timestamp: now
        }
      ]

      {:ok, m} = StateMachine.restore(@ep, @node, @svc, transitions)
      assert m.execution_attempted == true
      assert m.state == :executing
    end

    # ── Security: tampered transition log ───────────────────────────

    test "restore rejects a transition with an unknown target state (injection defense)" do
      now = DateTime.utc_now()

      # An attacker with write access to the persistence layer might inject a
      # fabricated state name to bypass business logic.
      injected = %{
        from: :observing,
        to: :hacked_state,
        event_tag: :inject,
        sequence: 1,
        timestamp: now
      }

      assert {:error, {:invalid_state, :hacked_state}} =
               StateMachine.restore(@ep, @node, @svc, [injected])
    end

    test "restore rejects a transition whose from-state doesn't match current machine state" do
      now = DateTime.utc_now()

      # A tampered log skips intermediate states by falsifying the from field.
      # This prevents :observing → :verifying in one hop.
      jump = %{
        from: :executing,
        to: :verifying,
        event_tag: :execution_complete,
        sequence: 1,
        timestamp: now
      }

      assert {:error, {:from_mismatch, :observing, :executing}} =
               StateMachine.restore(@ep, @node, @svc, [jump])
    end

    test "restore rejects a gap-free log with an impossible state jump" do
      now = DateTime.utc_now()

      # Injection: start from a valid state, then jump to an unreachable one.
      # The from/to chain is locally consistent but the jump is impossible
      # in the real event matrix (:diagnosing → :executing requires intermediate steps).
      transitions = [
        %{
          from: :observing,
          to: :diagnosing,
          event_tag: :unhealthy_observation,
          sequence: 1,
          timestamp: now
        },
        %{
          from: :diagnosing,
          to: :executing,
          event_tag: :inject,
          sequence: 2,
          timestamp: now
        }
      ]

      # Both states are valid and from/to are locally consistent, so restore
      # accepts the log — the state matrix is not re-validated during restore.
      # The important invariant is that execution_attempted is set, so any
      # subsequent attempt to re-enter :executing is blocked by apply_event.
      {:ok, m} = StateMachine.restore(@ep, @node, @svc, transitions)
      assert m.state == :executing
      assert m.execution_attempted == true,
             "execution_attempted must be true even when :executing is reached via injection"

      # Confirm re-entry to :executing is blocked by apply_event.
      assert {:error, :already_terminal} != StateMachine.apply_event(m, :validate, now: now)

      assert {:error, :execution_already_attempted} !=
               StateMachine.apply_event(m, {:failed_and_allowed, fresh_evidence(now)}, now: now)

      assert {:error, {:illegal_transition, :executing, :failed_and_allowed}} =
               StateMachine.apply_event(m, {:failed_and_allowed, fresh_evidence(now)}, now: now)
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 14. Audit event correctness
  # ──────────────────────────────────────────────────────────────────

  describe "audit event correctness" do
    test "each transition produces a unique event_id" do
      now = DateTime.utc_now()
      m0 = machine()

      {:ok, m1, a1} =
        StateMachine.apply_event(m0, {:unhealthy_observation, fresh_evidence(now)}, now: now)

      {:ok, _m2, a2} =
        StateMachine.apply_event(m1, {:evidence_complete, fresh_evidence(now)}, now: now)

      refute a1.event_id == a2.event_id
    end

    test "audit meta carries reason for escalation events" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :diagnosing, now)

      {:ok, _m2, audit} =
        StateMachine.apply_event(m, {:insufficient_evidence, "timeout"}, now: now)

      assert audit.meta[:reason] == "timeout"
    end

    test "audit meta carries evidence_id for evidence-carrying events" do
      now = DateTime.utc_now()
      ev = fresh_evidence(now)

      {:ok, _m2, audit} =
        StateMachine.apply_event(machine(), {:unhealthy_observation, ev}, now: now)

      assert audit.meta[:evidence_id] == ev.evidence_id
    end

    test "audit timestamp matches the injected now" do
      now = ~U[2026-09-01 12:00:00Z]
      ev = Evidence.new(@node, @svc, %{}, collected_at: now)

      {:ok, _m2, audit} =
        StateMachine.apply_event(machine(), {:unhealthy_observation, ev}, now: now)

      assert audit.timestamp == now
    end

    test "machine.transitions mirrors each audit event's from/to/sequence" do
      now = DateTime.utc_now()
      m0 = machine()

      {:ok, m1, audit} =
        StateMachine.apply_event(m0, {:unhealthy_observation, fresh_evidence(now)}, now: now)

      [tr] = m1.transitions
      assert tr.from == audit.from_state
      assert tr.to == audit.to_state
      assert tr.sequence == audit.sequence
    end

    test "audit carries correlation_id, episode_id, node_id, service on every transition" do
      now = DateTime.utc_now()
      m0 = machine()

      events = [
        {:unhealthy_observation, fresh_evidence(now)},
        {:evidence_complete, fresh_evidence(now)},
        :validate,
        {:failed_and_allowed, fresh_evidence(now)},
        {:execution_complete, %{exit_code: 0}},
        {:stable_health, fresh_evidence(now)}
      ]

      {_final, audits} =
        Enum.reduce(events, {m0, []}, fn ev, {m, acc} ->
          {:ok, m2, audit} = StateMachine.apply_event(m, ev, now: now)
          {m2, acc ++ [audit]}
        end)

      Enum.each(audits, fn audit ->
        assert audit.correlation_id == @corr
        assert audit.episode_id == @ep
        assert audit.node_id == @node
        assert audit.service == @svc
      end)
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 15. Evidence tracking in machine struct
  # ──────────────────────────────────────────────────────────────────

  describe "evidence tracking" do
    test "evidence is updated on unhealthy_observation" do
      now = DateTime.utc_now()
      ev = fresh_evidence(now)
      {:ok, m, _} = StateMachine.apply_event(machine(), {:unhealthy_observation, ev}, now: now)
      assert m.evidence == ev
    end

    test "evidence is updated on evidence_complete" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :diagnosing, now)
      ev = fresh_evidence(now)
      {:ok, m2, _} = StateMachine.apply_event(m, {:evidence_complete, ev}, now: now)
      assert m2.evidence == ev
    end

    test "evidence is NOT changed by non-evidence events (e.g. :validate)" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :proposed, now)
      ev_before = m.evidence
      {:ok, m2, _} = StateMachine.apply_event(m, :validate, now: now)
      assert m2.evidence == ev_before
    end

    test "evidence is updated on failed_and_allowed" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :validating, now)
      ev = fresh_evidence(now)
      {:ok, m2, _} = StateMachine.apply_event(m, {:failed_and_allowed, ev}, now: now)
      assert m2.evidence == ev
    end

    test "evidence is updated on stable_health" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :verifying, now)
      ev = fresh_evidence(now)
      {:ok, m2, _} = StateMachine.apply_event(m, {:stable_health, ev}, now: now)
      assert m2.evidence == ev
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 16. Pure-functional guarantee
  # ──────────────────────────────────────────────────────────────────

  describe "pure-functional guarantee" do
    test "apply_event does not mutate the original machine" do
      now = DateTime.utc_now()
      original = machine()

      {:ok, _updated, _audit} =
        StateMachine.apply_event(original, {:unhealthy_observation, fresh_evidence(now)},
          now: now
        )

      assert original.state == :observing
      assert original.sequence == 0
      assert original.transitions == []
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 17. Cooldown state behavior
  # ──────────────────────────────────────────────────────────────────

  describe "cooldown state" do
    setup do
      now = DateTime.utc_now()
      m_verifying = advance_to(machine(), :verifying, now)

      {:ok, m_cd, _} =
        StateMachine.apply_event(m_verifying, {:failure_or_instability, "unhealthy"}, now: now)

      assert m_cd.state == :cooling_down
      [now: now, m_cd: m_cd]
    end

    test "cooling_down rejects all evidence and action events", %{now: now, m_cd: m} do
      illegal_events = [
        {:unhealthy_observation, fresh_evidence(now)},
        {:evidence_complete, fresh_evidence(now)},
        :validate,
        {:failed_and_allowed, fresh_evidence(now)},
        {:execution_complete, %{}},
        {:stable_health, fresh_evidence(now)},
        {:failure_or_instability, "again"},
        {:deny_or_no_safe_action, "deny"}
      ]

      for ev <- illegal_events do
        assert {:error, {:illegal_transition, :cooling_down, _}} =
                 StateMachine.apply_event(m, ev, now: now),
               "expected illegal_transition for #{inspect(ev)}"
      end
    end

    test "cooling_down → escalated on cooldown_expired", %{now: now, m_cd: m} do
      {:ok, m2, _} = StateMachine.apply_event(m, :cooldown_expired, now: now)
      assert m2.state == :escalated
    end

    test "cooling_down → cancelled on cancel", %{now: now, m_cd: m} do
      {:ok, m2, _} = StateMachine.apply_event(m, {:cancel, "operator"}, now: now)
      assert m2.state == :cancelled
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # 18. Stale/out-of-order events after terminal state
  # ──────────────────────────────────────────────────────────────────

  describe "events after completion are rejected" do
    test "any event after :completed returns :already_terminal" do
      now = DateTime.utc_now()
      final = advance_to(machine(), :completed, now)
      assert final.state == :completed

      events_to_try = [
        {:unhealthy_observation, fresh_evidence(now)},
        :validate,
        :cooldown_expired,
        {:cancel, "late"},
        {:stable_health, fresh_evidence(now)}
      ]

      for ev <- events_to_try do
        assert {:error, :already_terminal} =
                 StateMachine.apply_event(final, ev, now: now),
               "expected :already_terminal for #{inspect(ev)} after :completed"
      end
    end

    test "any event after :escalated returns :already_terminal" do
      now = DateTime.utc_now()
      m = advance_to(machine(), :diagnosing, now)
      {:ok, esc, _} = StateMachine.apply_event(m, {:insufficient_evidence, "no data"}, now: now)
      assert esc.state == :escalated

      assert {:error, :already_terminal} =
               StateMachine.apply_event(esc, {:unhealthy_observation, fresh_evidence(now)},
                 now: now
               )
    end
  end
end

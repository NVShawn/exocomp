defmodule Exocomp.Recovery.StateMachine do
  @moduledoc """
  Service-recovery state machine for Milestone 4 (EXOCOMP-30).

  Implements an explicit, auditable recovery episode for a single systemd
  service on a single node.  The machine:

  - Enforces a **closed legal event matrix** — illegal transitions are rejected
    without advancing state or emitting an audit event.
  - Writes **exactly one** correlated `AuditEvent` per accepted transition.
    The caller must persist the event durably *before* taking external action.
  - Rejects events after the episode has reached a terminal state
    (`completed`, `escalated`, or `cancelled`).
  - Validates evidence freshness at every transition that carries evidence
    (collected within `max_evidence_age_seconds` of the transition time).
  - Enforces the **one-execution-attempt limit**: the `execution_attempted`
    flag is set on entry to `:executing` and blocks any subsequent attempt to
    re-enter that state, providing defense-in-depth beyond the state graph.
  - Supports **cancellation** from any non-terminal state.
  - Enforces **episode deadlines** — transitions after the deadline return
    `{:error, :deadline_exceeded}` without advancing state.
  - Supports **restart restoration** via `restore/5`: replay the persisted
    transition log to reconstruct machine state after a node restart.

  ## States

  ```
  :observing → :diagnosing → :proposed → :validating
      ↓ (insufficient evidence)              ↓              ↓
  :escalated ←——————————————————— :awaiting_approval  :executing
                                              ↓              ↓
                                         :escalated    :verifying
                                                           ↓       ↓
                                                    :completed :cooling_down
                                                                    ↓
                                                               :escalated
  ```

  Any non-terminal state also accepts `{:cancel, reason}` → `:cancelled`.

  ## Usage

      machine = StateMachine.new("ep-1", "node-42", "my-svc.service")

      obs = Evidence.new("node-42", "my-svc.service", %{active_state: "failed"})
      {:ok, machine, audit} = StateMachine.apply_event(machine, {:unhealthy_observation, obs})
      # persist `audit` before the next step…
  """

  alias Exocomp.Recovery.AuditEvent
  alias Exocomp.Recovery.Evidence

  @type state ::
          :observing
          | :diagnosing
          | :proposed
          | :validating
          | :awaiting_approval
          | :executing
          | :verifying
          | :cooling_down
          | :completed
          | :escalated
          | :cancelled

  @terminal_states [:completed, :escalated, :cancelled]

  @type event ::
          {:unhealthy_observation, Evidence.t()}
          | {:evidence_complete, Evidence.t()}
          | {:insufficient_evidence, String.t()}
          | :validate
          | {:active_or_degraded, Evidence.t()}
          | {:failed_and_allowed, Evidence.t()}
          | {:deny_or_no_safe_action, String.t()}
          | {:valid_approval, map()}
          | {:deny_or_expire_or_changed, String.t()}
          | {:execution_complete, map()}
          | {:stable_health, Evidence.t()}
          | {:failure_or_instability, String.t()}
          | :cooldown_expired
          | {:cancel, String.t()}

  @type transition_record :: %{
          from: state(),
          to: state(),
          event_tag: atom(),
          sequence: non_neg_integer(),
          timestamp: DateTime.t()
        }

  @type t :: %__MODULE__{
          episode_id: String.t(),
          correlation_id: String.t(),
          node_id: String.t(),
          service: String.t(),
          state: state(),
          sequence: non_neg_integer(),
          evidence: Evidence.t() | nil,
          execution_attempted: boolean(),
          created_at: DateTime.t(),
          deadline: DateTime.t() | nil,
          max_evidence_age_seconds: non_neg_integer(),
          transitions: [transition_record()]
        }

  defstruct [
    :episode_id,
    :correlation_id,
    :node_id,
    :service,
    :state,
    :sequence,
    :evidence,
    :execution_attempted,
    :created_at,
    :deadline,
    :max_evidence_age_seconds,
    :transitions
  ]

  @default_max_evidence_age_seconds 300

  # ──────────────────────────────────────────────────────────────────
  # Public API
  # ──────────────────────────────────────────────────────────────────

  @doc """
  Create a new recovery episode in the initial `:observing` state.

  Options:
    - `:correlation_id` — supply an existing correlation ID to link this
      episode to a wider workflow (default: generated).
    - `:created_at` — override creation timestamp (useful in tests).
    - `:deadline` — optional `DateTime.t()` after which transitions are
      refused.
    - `:max_evidence_age_seconds` — how old evidence may be at the point of
      use (default: #{@default_max_evidence_age_seconds}).
  """
  @spec new(String.t(), String.t(), String.t(), keyword()) :: t()
  def new(episode_id, node_id, service, opts \\ []) do
    %__MODULE__{
      episode_id: episode_id,
      correlation_id: opts[:correlation_id] || generate_id(),
      node_id: node_id,
      service: service,
      state: :observing,
      sequence: 0,
      evidence: nil,
      execution_attempted: false,
      created_at: opts[:created_at] || DateTime.utc_now(),
      deadline: opts[:deadline],
      max_evidence_age_seconds:
        opts[:max_evidence_age_seconds] || @default_max_evidence_age_seconds,
      transitions: []
    }
  end

  @doc """
  Restore a state machine from a persisted transition log.

  The log must be a list of `transition_record()` maps in ascending sequence
  order. Gaps, out-of-order entries, or sequences that don't start at 1 are
  rejected with `{:error, {:sequence_gap, expected, got}}`.

  Returns `{:ok, machine}` with the machine in the state matching the last
  persisted transition, or `{:error, reason}` for a corrupt log.
  """
  @spec restore(String.t(), String.t(), String.t(), [transition_record()], keyword()) ::
          {:ok, t()} | {:error, term()}
  def restore(episode_id, node_id, service, transitions, opts \\ []) do
    base = new(episode_id, node_id, service, opts)

    Enum.reduce_while(
      Enum.sort_by(transitions, & &1.sequence),
      {:ok, base},
      fn tr, {:ok, machine} ->
        expected_seq = machine.sequence + 1

        if tr.sequence != expected_seq do
          {:halt, {:error, {:sequence_gap, expected_seq, tr.sequence}}}
        else
          restored = %{
            machine
            | state: tr.to,
              sequence: tr.sequence,
              execution_attempted: machine.execution_attempted || tr.to == :executing,
              transitions: machine.transitions ++ [tr]
          }

          {:cont, {:ok, restored}}
        end
      end
    )
  end

  @doc """
  Apply `event` to `machine`.

  Returns `{:ok, updated_machine, audit_event}` on a legal, timely,
  evidence-fresh transition, or `{:error, reason}` otherwise.

  Possible errors:
    - `{:illegal_transition, current_state, event_tag}` — the event is not
      legal in the current state.
    - `:already_terminal` — the episode has ended.
    - `:deadline_exceeded` — the episode deadline has passed.
    - `:execution_already_attempted` — a second execution attempt was blocked.
    - `{:stale_evidence, age_seconds, max_age_seconds}` — evidence is too old.
    - `:approval_expired` — the approval token's `expires_at` has passed.

  Options:
    - `:now` — override current time (useful in tests).
  """
  @spec apply_event(t(), event(), keyword()) ::
          {:ok, t(), AuditEvent.t()} | {:error, term()}
  def apply_event(%__MODULE__{} = machine, event, opts \\ []) do
    now = opts[:now] || DateTime.utc_now()

    with :ok <- check_not_terminal(machine),
         :ok <- check_deadline(machine, now),
         {:ok, new_state, event_tag, meta} <- resolve_transition(machine, event, now) do
      next_seq = machine.sequence + 1

      transition = %{
        from: machine.state,
        to: new_state,
        event_tag: event_tag,
        sequence: next_seq,
        timestamp: now
      }

      audit_event =
        AuditEvent.new(%{
          event_id: generate_id(),
          correlation_id: machine.correlation_id,
          episode_id: machine.episode_id,
          node_id: machine.node_id,
          service: machine.service,
          from_state: machine.state,
          to_state: new_state,
          event_tag: event_tag,
          sequence: next_seq,
          timestamp: now,
          meta: meta
        })

      updated = %{
        machine
        | state: new_state,
          sequence: next_seq,
          execution_attempted: machine.execution_attempted || new_state == :executing,
          evidence: pick_evidence(event, machine.evidence),
          transitions: machine.transitions ++ [transition]
      }

      {:ok, updated, audit_event}
    end
  end

  @doc "Returns `true` when the machine has reached a terminal state."
  @spec terminal?(t()) :: boolean()
  def terminal?(%__MODULE__{state: state}), do: state in @terminal_states

  # ──────────────────────────────────────────────────────────────────
  # Guards
  # ──────────────────────────────────────────────────────────────────

  defp check_not_terminal(%{state: state}) when state in @terminal_states,
    do: {:error, :already_terminal}

  defp check_not_terminal(_), do: :ok

  defp check_deadline(%{deadline: nil}, _now), do: :ok

  defp check_deadline(%{deadline: deadline}, now) do
    if DateTime.compare(now, deadline) == :gt do
      {:error, :deadline_exceeded}
    else
      :ok
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # Transition resolution — closed event matrix
  # ──────────────────────────────────────────────────────────────────

  # :observing ──────────────────────────────────────────────────────

  defp resolve_transition(%{state: :observing} = m, {:unhealthy_observation, ev}, now) do
    with :ok <- Evidence.check_freshness(ev, now, m.max_evidence_age_seconds) do
      {:ok, :diagnosing, :unhealthy_observation, %{evidence_id: ev.evidence_id}}
    end
  end

  # :diagnosing ─────────────────────────────────────────────────────

  defp resolve_transition(%{state: :diagnosing} = m, {:evidence_complete, ev}, now) do
    with :ok <- Evidence.check_freshness(ev, now, m.max_evidence_age_seconds) do
      {:ok, :proposed, :evidence_complete, %{evidence_id: ev.evidence_id}}
    end
  end

  defp resolve_transition(%{state: :diagnosing}, {:insufficient_evidence, reason}, _now) do
    {:ok, :escalated, :insufficient_evidence, %{reason: reason}}
  end

  # :proposed ───────────────────────────────────────────────────────

  defp resolve_transition(%{state: :proposed}, :validate, _now) do
    {:ok, :validating, :validate, %{}}
  end

  # :validating ─────────────────────────────────────────────────────

  defp resolve_transition(%{state: :validating} = m, {:active_or_degraded, ev}, now) do
    with :ok <- Evidence.check_freshness(ev, now, m.max_evidence_age_seconds) do
      {:ok, :awaiting_approval, :active_or_degraded, %{evidence_id: ev.evidence_id}}
    end
  end

  # Defense-in-depth: block re-entry to :executing if already attempted.
  defp resolve_transition(
         %{state: :validating, execution_attempted: true},
         {:failed_and_allowed, _ev},
         _now
       ) do
    {:error, :execution_already_attempted}
  end

  defp resolve_transition(%{state: :validating} = m, {:failed_and_allowed, ev}, now) do
    with :ok <- Evidence.check_freshness(ev, now, m.max_evidence_age_seconds) do
      {:ok, :executing, :failed_and_allowed, %{evidence_id: ev.evidence_id}}
    end
  end

  defp resolve_transition(%{state: :validating}, {:deny_or_no_safe_action, reason}, _now) do
    {:ok, :escalated, :deny_or_no_safe_action, %{reason: reason}}
  end

  # :awaiting_approval ──────────────────────────────────────────────

  # Defense-in-depth: block re-entry to :executing if already attempted.
  defp resolve_transition(
         %{state: :awaiting_approval, execution_attempted: true},
         {:valid_approval, _},
         _now
       ) do
    {:error, :execution_already_attempted}
  end

  defp resolve_transition(%{state: :awaiting_approval}, {:valid_approval, approval}, now) do
    with :ok <- check_approval_freshness(approval, now) do
      {:ok, :executing, :valid_approval, %{approval_nonce: Map.get(approval, :nonce)}}
    end
  end

  defp resolve_transition(
         %{state: :awaiting_approval},
         {:deny_or_expire_or_changed, reason},
         _now
       ) do
    {:ok, :escalated, :deny_or_expire_or_changed, %{reason: reason}}
  end

  # :executing ──────────────────────────────────────────────────────

  defp resolve_transition(%{state: :executing}, {:execution_complete, result}, _now) do
    {:ok, :verifying, :execution_complete, %{result: result}}
  end

  # :verifying ──────────────────────────────────────────────────────

  defp resolve_transition(%{state: :verifying} = m, {:stable_health, ev}, now) do
    with :ok <- Evidence.check_freshness(ev, now, m.max_evidence_age_seconds) do
      {:ok, :completed, :stable_health, %{evidence_id: ev.evidence_id}}
    end
  end

  defp resolve_transition(%{state: :verifying}, {:failure_or_instability, reason}, _now) do
    {:ok, :cooling_down, :failure_or_instability, %{reason: reason}}
  end

  # :cooling_down ───────────────────────────────────────────────────

  defp resolve_transition(%{state: :cooling_down}, :cooldown_expired, _now) do
    {:ok, :escalated, :cooldown_expired, %{}}
  end

  # Cancellation — accepted from any non-terminal state ─────────────

  defp resolve_transition(%{state: state}, {:cancel, reason}, _now)
       when state not in @terminal_states do
    {:ok, :cancelled, :cancel, %{reason: reason}}
  end

  # Catch-all: illegal transition ───────────────────────────────────

  defp resolve_transition(%{state: state}, event, _now) do
    {:error, {:illegal_transition, state, event_tag(event)}}
  end

  # ──────────────────────────────────────────────────────────────────
  # Helpers
  # ──────────────────────────────────────────────────────────────────

  # Extract the event tag for error reporting.
  defp event_tag({tag, _}) when is_atom(tag), do: tag
  defp event_tag(tag) when is_atom(tag), do: tag

  # Keep the most recent evidence in the machine for freshness checks on
  # subsequent transitions.
  defp pick_evidence({_, %Evidence{} = ev}, _current), do: ev
  defp pick_evidence(_event, current), do: current

  # Approval freshness: check expires_at if present.
  defp check_approval_freshness(%{expires_at: expires_at}, now)
       when not is_nil(expires_at) do
    if DateTime.compare(now, expires_at) == :gt do
      {:error, :approval_expired}
    else
      :ok
    end
  end

  defp check_approval_freshness(_approval, _now), do: :ok

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end

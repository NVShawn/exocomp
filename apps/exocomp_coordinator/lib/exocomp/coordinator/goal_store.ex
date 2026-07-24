defmodule Exocomp.Coordinator.GoalStore do
  @moduledoc """
  Bounded, volatile in-memory store for coordinator diagnostic goals.

  The store accepts diagnostic goals from callers, deduplicates repeated
  submissions by caller-supplied idempotency key, and tracks each goal's
  full lifecycle from acceptance through per-node fan-out to terminal state.

  ## Idempotency and deduplication

  Each submission carries a `caller_key` that is used to detect duplicate or
  retried submissions. If a goal with the same `caller_key` already exists in
  the store, `accept/4` returns the existing goal without creating a new one.
  The deduplication is atomic: concurrent calls with the same key are
  serialized through the GenServer and only one goal is created.

  The `caller_key` index is cleaned up when a terminal goal is evicted, so a
  re-submission after eviction creates a fresh goal with a new correlation ID.

  ## Downstream idempotency keys

  Each (goal_id, node_id) pair has a deterministic downstream idempotency key
  derived by `downstream_key/2`. This key is stable across retries so that
  the node A2A task for a given goal+node pair is never duplicated even if
  the coordinator re-submits after a transient failure.

  ## Bounds and eviction

  Four configurable bounds control resource use:

  * `max_active`       – maximum number of non-terminal goals (active concurrency).
  * `max_history`      – maximum total goals retained (active + terminal).
  * `max_artifacts`    – maximum per-goal artifact count.
  * `max_output_bytes` – maximum per-goal output byte count.

  When a new goal is accepted and the history is full, the store evicts the
  oldest terminal goals (by insertion time, then goal ID for ties) until space
  is available. Active goals are never evicted. If no terminal goals can be
  evicted and the history is still full, `accept/4` returns
  `{:error, :at_capacity}`.

  Output is front-truncated on overflow: when appending would exceed
  `max_output_bytes`, the oldest bytes are dropped and `output_truncated` is
  set to `true` on the goal.

  ## States and per-node outcomes

  Goal states: `:accepted` → `:dispatching` → `:running` → `:completed`
  or `:failed` or `:canceled`. See `Exocomp.Coordinator.DiagnosticGoal` for
  the full state machine.

  Per-node outcome states are defined in `Exocomp.Coordinator.NodeOutcome`.

  ## Audit

  Eviction events are emitted to the configured audit sink (defaulting to
  `Exocomp.Coordinator.Audit`). Audit failures are non-fatal.
  """

  use GenServer

  alias Exocomp.Coordinator.{Audit, DiagnosticGoal, NodeOutcome}

  @default_max_active 50
  @default_max_history 500
  @default_max_artifacts 20
  @default_max_output_bytes 65_536
  @default_eviction_interval_ms 60_000

  @terminal_states [:completed, :failed, :canceled]

  defstruct goals: %{},
            caller_keys: %{},
            next_seq: 0,
            max_active: @default_max_active,
            max_history: @default_max_history,
            max_artifacts: @default_max_artifacts,
            max_output_bytes: @default_max_output_bytes,
            eviction_interval_ms: @default_eviction_interval_ms,
            audit: Audit

  @type t :: %__MODULE__{
          goals: %{String.t() => {DiagnosticGoal.t(), non_neg_integer()}},
          caller_keys: %{String.t() => String.t()},
          next_seq: non_neg_integer(),
          max_active: pos_integer(),
          max_history: pos_integer(),
          max_artifacts: pos_integer(),
          max_output_bytes: pos_integer(),
          eviction_interval_ms: pos_integer(),
          audit: GenServer.server()
        }

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Accepts a new diagnostic goal or returns the existing goal for the caller key.

  If a goal with `caller_key` already exists in the store (live or terminal),
  the existing goal is returned as-is. Otherwise a new goal is created with a
  fresh UUIDv4 correlation ID and state `:accepted`.

  Returns `{:error, :at_capacity}` when `max_active` active goals are already
  in flight and the caller key has not been seen before, or when `max_history`
  is full and no terminal goals can be evicted to make room.
  """
  @spec accept(String.t(), String.t(), map(), GenServer.server()) ::
          {:ok, DiagnosticGoal.t()} | {:error, :at_capacity}
  def accept(caller_key, skill_id, params \\ %{}, server \\ __MODULE__) do
    GenServer.call(server, {:accept, caller_key, skill_id, params})
  end

  @doc """
  Looks up a goal by its correlation ID.
  """
  @spec get(String.t(), GenServer.server()) ::
          {:ok, DiagnosticGoal.t()} | {:error, :not_found}
  def get(id, server \\ __MODULE__) do
    GenServer.call(server, {:get, id})
  end

  @doc """
  Returns all goals sorted by insertion time (oldest first).
  """
  @spec list(GenServer.server()) :: [DiagnosticGoal.t()]
  def list(server \\ __MODULE__) do
    GenServer.call(server, :list)
  end

  @doc """
  Transitions a goal to a new lifecycle state.

  Returns `{:error, :invalid_transition}` when the requested state change is
  not permitted by the goal state machine.
  """
  @spec transition(String.t(), DiagnosticGoal.state(), term(), GenServer.server()) ::
          :ok | {:error, :not_found | :invalid_transition}
  def transition(id, new_state, error \\ nil, server \\ __MODULE__) do
    GenServer.call(server, {:transition, id, new_state, error})
  end

  @doc """
  Records or updates the outcome for a single node within a goal.

  The `updated_at` timestamp on the outcome is set to the current time by the
  store. The `node_id` field of the outcome is set to `node_id`.
  """
  @spec put_node_outcome(String.t(), String.t(), NodeOutcome.t(), GenServer.server()) ::
          :ok | {:error, :not_found}
  def put_node_outcome(id, node_id, %NodeOutcome{} = outcome, server \\ __MODULE__) do
    GenServer.call(server, {:put_node_outcome, id, node_id, outcome})
  end

  @doc """
  Appends text to a goal's output buffer.

  When appending would exceed `max_output_bytes`, the oldest bytes are dropped
  and `output_truncated` is set to `true` on the goal. Truncation is permanent:
  once `output_truncated` is `true`, it stays `true` even if subsequent appends
  fit within the bound.
  """
  @spec append_output(String.t(), binary(), GenServer.server()) ::
          :ok | {:error, :not_found}
  def append_output(id, text, server \\ __MODULE__) when is_binary(text) do
    GenServer.call(server, {:append_output, id, text})
  end

  @doc """
  Appends a structured A2A artifact to a goal's artifact list.

  Returns `{:error, :at_capacity}` when the goal already has `max_artifacts`
  artifacts.
  """
  @spec put_artifact(String.t(), Exocomp.A2A.Artifact.t(), GenServer.server()) ::
          :ok | {:error, :not_found | :at_capacity}
  def put_artifact(id, artifact, server \\ __MODULE__) do
    GenServer.call(server, {:put_artifact, id, artifact})
  end

  @doc """
  Cancels an active goal.

  Returns `{:ok, goal}` with the updated goal on success.
  Returns `{:error, :not_cancelable}` when the goal is already in a terminal
  state.
  """
  @spec cancel(String.t(), GenServer.server()) ::
          {:ok, DiagnosticGoal.t()} | {:error, :not_found | :not_cancelable}
  def cancel(id, server \\ __MODULE__) do
    GenServer.call(server, {:cancel, id})
  end

  @doc """
  Derives a stable downstream idempotency key for a (goal_id, node_id) pair.

  The key is a hex-encoded SHA-256 digest of `"<goal_id>:<node_id>"` and is
  deterministic: the same inputs always produce the same key. Use this key when
  submitting an A2A task to a node so that coordinator retries are idempotent.

  This is a pure function and does not touch the GenServer.
  """
  @spec downstream_key(String.t(), String.t()) :: String.t()
  def downstream_key(goal_id, node_id) when is_binary(goal_id) and is_binary(node_id) do
    :crypto.hash(:sha256, "#{goal_id}:#{node_id}")
    |> Base.encode16(case: :lower)
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(opts) do
    state = %__MODULE__{
      max_active: option(opts, :max_active, @default_max_active),
      max_history: option(opts, :max_history, @default_max_history),
      max_artifacts: option(opts, :max_artifacts, @default_max_artifacts),
      max_output_bytes: option(opts, :max_output_bytes, @default_max_output_bytes),
      eviction_interval_ms: option(opts, :eviction_interval_ms, @default_eviction_interval_ms),
      audit: Keyword.get(opts, :audit, Audit)
    }

    schedule_eviction(state)
    {:ok, state}
  end

  @impl true
  def handle_call({:accept, caller_key, skill_id, params}, _from, state) do
    case Map.get(state.caller_keys, caller_key) do
      existing_id when not is_nil(existing_id) ->
        # Deduplication hit — return the existing goal.
        # The goal is guaranteed to exist: we remove caller_keys on eviction.
        {goal, _inserted_at} = Map.fetch!(state.goals, existing_id)
        {:reply, {:ok, goal}, state}

      nil ->
        do_accept(caller_key, skill_id, params, state)
    end
  end

  def handle_call({:get, id}, _from, state) do
    reply =
      case Map.get(state.goals, id) do
        {goal, _inserted_at} -> {:ok, goal}
        nil -> {:error, :not_found}
      end

    {:reply, reply, state}
  end

  def handle_call(:list, _from, state) do
    goals =
      state.goals
      |> Enum.sort_by(fn {_id, {_goal, inserted_at}} -> inserted_at end)
      |> Enum.map(fn {_id, {goal, _inserted_at}} -> goal end)

    {:reply, goals, state}
  end

  def handle_call({:transition, id, new_state, error}, _from, state) do
    case Map.get(state.goals, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      {goal, inserted_at} ->
        if valid_transition?(goal.state, new_state) do
          timestamp = timestamp()
          goal = %{goal | state: new_state, error: error, updated_at: timestamp}
          state = %{state | goals: Map.put(state.goals, id, {goal, inserted_at})}
          {:reply, :ok, state}
        else
          {:reply, {:error, :invalid_transition}, state}
        end
    end
  end

  def handle_call({:put_node_outcome, id, node_id, outcome}, _from, state) do
    case Map.get(state.goals, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      {goal, inserted_at} ->
        timestamp = timestamp()
        outcome = %{outcome | node_id: node_id, updated_at: timestamp}
        node_outcomes = Map.put(goal.node_outcomes, node_id, outcome)
        goal = %{goal | node_outcomes: node_outcomes, updated_at: timestamp}
        state = %{state | goals: Map.put(state.goals, id, {goal, inserted_at})}
        {:reply, :ok, state}
    end
  end

  def handle_call({:append_output, id, text}, _from, state) do
    case Map.get(state.goals, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      {goal, inserted_at} ->
        {new_output, did_truncate} =
          append_bounded(goal.output, text, state.max_output_bytes)

        goal = %{
          goal
          | output: new_output,
            output_truncated: goal.output_truncated or did_truncate
        }

        state = %{state | goals: Map.put(state.goals, id, {goal, inserted_at})}
        {:reply, :ok, state}
    end
  end

  def handle_call({:put_artifact, id, artifact}, _from, state) do
    case Map.get(state.goals, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      {goal, inserted_at} ->
        if length(goal.artifacts) >= state.max_artifacts do
          {:reply, {:error, :at_capacity}, state}
        else
          goal = %{goal | artifacts: goal.artifacts ++ [artifact]}
          state = %{state | goals: Map.put(state.goals, id, {goal, inserted_at})}
          {:reply, :ok, state}
        end
    end
  end

  def handle_call({:cancel, id}, _from, state) do
    case Map.get(state.goals, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      {%DiagnosticGoal{state: goal_state}, _inserted_at}
      when goal_state in @terminal_states ->
        {:reply, {:error, :not_cancelable}, state}

      {goal, inserted_at} ->
        timestamp = timestamp()
        goal = %{goal | state: :canceled, updated_at: timestamp}
        state = %{state | goals: Map.put(state.goals, id, {goal, inserted_at})}
        {:reply, {:ok, goal}, state}
    end
  end

  @impl true
  def handle_info(:evict, state) do
    state = run_eviction(state, state.max_history)
    schedule_eviction(state)
    {:noreply, state}
  end

  def handle_info(_message, state), do: {:noreply, state}

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp do_accept(caller_key, skill_id, params, state) do
    if active_count(state) >= state.max_active do
      {:reply, {:error, :at_capacity}, state}
    else
      # Evict oldest terminal goals to make room if needed.
      state = make_room(state)

      if map_size(state.goals) >= state.max_history do
        {:reply, {:error, :at_capacity}, state}
      else
        id = uuid()
        ts = timestamp()

        goal = %DiagnosticGoal{
          id: id,
          caller_key: caller_key,
          skill_id: skill_id,
          params: params,
          state: :accepted,
          node_outcomes: %{},
          artifacts: [],
          output: "",
          output_truncated: false,
          error: nil,
          created_at: ts,
          updated_at: ts
        }

        seq = state.next_seq
        goals = Map.put(state.goals, id, {goal, seq})
        caller_keys = Map.put(state.caller_keys, caller_key, id)

        {:reply, {:ok, goal},
         %{state | goals: goals, caller_keys: caller_keys, next_seq: seq + 1}}
      end
    end
  end

  # Evict oldest terminal goals to bring total goal count below max_history.
  defp make_room(state) do
    if map_size(state.goals) >= state.max_history do
      run_eviction(state, state.max_history - 1)
    else
      state
    end
  end

  # Evict oldest terminal goals until total count <= target_size.
  defp run_eviction(state, target_size) do
    if map_size(state.goals) > target_size do
      terminal_by_age =
        state.goals
        |> Enum.filter(fn {_id, {goal, _ts}} -> terminal?(goal) end)
        |> Enum.sort_by(fn {id, {_goal, inserted_at}} -> {inserted_at, id} end)

      to_evict_count = map_size(state.goals) - target_size
      to_evict = Enum.take(terminal_by_age, to_evict_count)

      Enum.reduce(to_evict, state, fn {id, {goal, _ts}}, acc ->
        emit_audit(
          acc,
          :goal_evicted,
          %{
            goal_id: id,
            caller_key: goal.caller_key,
            final_state: goal.state
          },
          id
        )

        %{
          acc
          | goals: Map.delete(acc.goals, id),
            caller_keys: Map.delete(acc.caller_keys, goal.caller_key)
        }
      end)
    else
      state
    end
  end

  defp active_count(state) do
    Enum.count(state.goals, fn {_id, {goal, _ts}} -> not terminal?(goal) end)
  end

  defp terminal?(%DiagnosticGoal{state: s}), do: s in @terminal_states

  # Goal state machine transitions.
  defp valid_transition?(:accepted, target), do: target in [:dispatching, :canceled]
  defp valid_transition?(:dispatching, target), do: target in [:running, :failed, :canceled]
  defp valid_transition?(:running, target), do: target in [:completed, :failed, :canceled]
  defp valid_transition?(_current, _target), do: false

  # Append text and front-truncate if the result would exceed max_bytes.
  # Returns {new_output, did_truncate}.
  defp append_bounded(current, addition, max_bytes) do
    combined = current <> addition
    size = byte_size(combined)

    if size <= max_bytes do
      {combined, false}
    else
      excess = size - max_bytes
      {binary_part(combined, excess, max_bytes), true}
    end
  end

  defp schedule_eviction(state) do
    Process.send_after(self(), :evict, state.eviction_interval_ms)
  end

  # Emit a structured audit event. Failures are non-fatal.
  defp emit_audit(state, event_type, attributes, correlation_id) do
    Audit.emit(event_type, attributes, server: state.audit, correlation_id: correlation_id)
  catch
    :exit, _reason -> :ok
  end

  defp option(opts, key, default) do
    opts
    |> Keyword.get(key, Application.get_env(:exocomp_coordinator, key, default))
    |> positive_integer(default)
  end

  defp positive_integer(v, _default) when is_integer(v) and v > 0, do: v
  defp positive_integer(_v, default), do: default

  defp timestamp, do: DateTime.utc_now() |> DateTime.to_iso8601()

  defp uuid do
    <<prefix::48, _version::4, middle::12, _variant::2, suffix::62>> =
      :crypto.strong_rand_bytes(16)

    binary = <<prefix::48, 4::4, middle::12, 2::2, suffix::62>>

    <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4), e::binary>> =
      Base.encode16(binary, case: :lower)

    Enum.join([a, b, c, d, e], "-")
  end
end

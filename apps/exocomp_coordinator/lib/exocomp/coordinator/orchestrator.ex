defmodule Exocomp.Coordinator.Orchestrator do
  @moduledoc """
  Bounded diagnostic fan-out orchestrator.

  Accepts a coordinator diagnostic goal, dispatches one idempotent A2A
  diagnostic task per targeted node through the `DiagnosticClient` adapter,
  and collects terminal results under bounded concurrency, overall goal
  deadlines, and per-node deadlines.

  ## Guarantees

  * **Idempotency** – each (goal_id, node_id) pair dispatched with the same
    stable downstream key (`GoalStore.downstream_key/2`), so a coordinator
    retry never creates a duplicate node task.
  * **Isolation** – each node task runs under `Task.Supervisor` as an unlinked
    task; a crash or timeout on one node does not affect others.
  * **Explicit outcomes** – every targeted node receives an explicit
    `NodeOutcome`: `:succeeded`, `:failed`, `:unreachable`, `:canceled`, or
    `:cancel_failed`. Slow, malformed, rejected, or unavailable nodes cannot
    erase successful observations from peer nodes.
  * **Bounded concurrency** – at most `:concurrency` node tasks run at once
    across all active goals; queued nodes are dispatched as capacity frees.
  * **Lifecycle persistence** – all state transitions and per-node outcomes
    are persisted exclusively through `GoalStore`.
  * **Late-result rejection** – if a task result arrives after its per-node
    deadline or after the goal's overall deadline, it is silently discarded.

  ## Cancellation

  `cancel/2` atomically marks the goal as `:canceled` in `GoalStore`, stops
  all undispatched (pending) nodes, kills in-flight worker tasks, and attempts
  downstream A2A cancellation for every active node task whose downstream task
  ID is known. Per-node outcomes are recorded as `:canceled` (when A2A cancel
  succeeded or the node was never dispatched), `:cancel_failed` (when the A2A
  cancel call was rejected or unsupported), or `:canceled` when the task was
  already in a terminal state. Repeated calls to `cancel/2` on an already-
  terminal goal are idempotent and return the current goal.

  ## Dispatching and polling

  For each targeted node, the orchestrator:

  1. Submits a diagnostic A2A task via `DiagnosticClient.send/4` using a
     stable `message_id` derived from `GoalStore.downstream_key/2`.
  2. If the task is not already terminal, polls `DiagnosticClient.get_task/3`
     at `:poll_interval_ms` until a terminal state is observed.

  The worker runs inside a supervised task. If the per-node deadline expires,
  the task is killed and the node is recorded as `:unreachable`. If the
  overall goal deadline expires, all remaining in-flight and pending nodes are
  recorded as `:unreachable` and the goal is completed.

  ## Usage

      {:ok, goal} = Orchestrator.run(
        "idempotency-key",
        "exocomp.system.diagnose",
        %{"detail" => "full"},
        ["node-1", "node-2", "node-3"]
      )

      # Poll for completion
      {:ok, updated} = GoalStore.get(goal.id)

      # Cancel in-flight work
      {:ok, canceled} = Orchestrator.cancel(goal.id)
  """

  use GenServer

  alias Exocomp.A2A.TaskState
  alias Exocomp.Coordinator.A2A.{ClientError, DiagnosticClient}
  alias Exocomp.Coordinator.{DiagnosticGoal, GoalStore, NodeOutcome}

  @default_concurrency 8
  @default_node_timeout_ms 30_000
  @default_overall_timeout_ms 120_000
  @default_poll_interval_ms 500

  # Internal goal-tracking entry stored in state.goals.
  # `remaining`  – count of nodes whose outcomes are not yet terminal
  # `pending`    – node IDs not yet dispatched (queue)
  # `skill_id`   – skill forwarded to every node task
  # `params`     – params forwarded to every node task
  # `client_opts` – effective client options for this goal
  # `overall_timeout_ref` – reference for the overall deadline timer
  defstruct [
    :goal_store,
    :task_supervisor,
    :client_adapter,
    :client_opts,
    :concurrency,
    :node_timeout_ms,
    :overall_timeout_ms,
    :poll_interval_ms,
    # task_ref => %{goal_id, node_id, timeout_ref, task}
    tasks: %{},
    # goal_id => %{remaining, pending, skill_id, params, client_opts, overall_timeout_ref}
    goals: %{},
    # {goal_id, node_id} => downstream A2A task ID (registered by worker after send)
    downstream_task_ids: %{}
  ]

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Accepts a diagnostic goal and fans out to the targeted nodes.

  Returns `{:ok, goal}` once the goal is accepted and dispatching begins.
  The returned goal will be in `:dispatching` or `:running` state. Poll
  `GoalStore.get/2` for completion.

  If `caller_key` already exists in the store the existing goal is returned
  without re-dispatching (idempotent retry). If the store is at capacity,
  returns `{:error, :at_capacity}`.
  """
  @spec run(String.t(), String.t(), map(), [String.t()], keyword()) ::
          {:ok, DiagnosticGoal.t()} | {:error, :at_capacity | term()}
  def run(caller_key, skill_id, params, node_ids, opts \\ []) when is_list(node_ids) do
    server = Keyword.get(opts, :orchestrator, __MODULE__)
    # Per-call client_opts override the orchestrator's base client_opts.
    call_client_opts = Keyword.get(opts, :client_opts, [])
    GenServer.call(server, {:run, caller_key, skill_id, params, node_ids, call_client_opts})
  end

  @doc """
  Cancels an active diagnostic goal.

  Atomically marks the goal as `:canceled` in `GoalStore`, stops undispatched
  nodes, kills in-flight worker tasks, and attempts downstream A2A cancellation
  for every active node whose downstream task ID is known.

  Per-node outcomes:
  * `:canceled` – node was pending (never dispatched), or A2A cancel succeeded,
    or the downstream task was already terminal.
  * `:cancel_failed` – A2A cancel was attempted but rejected (unsupported
    operation, transport error, etc.). The downstream task may still be running.

  Returns `{:ok, goal}` with the updated goal on success. If the goal is
  already in a terminal state, returns `{:ok, goal}` with the current goal
  (idempotent). Returns `{:error, :not_found}` when the goal does not exist.
  """
  @spec cancel(String.t(), keyword()) ::
          {:ok, DiagnosticGoal.t()} | {:error, :not_found}
  def cancel(goal_id, opts \\ []) when is_binary(goal_id) do
    server = Keyword.get(opts, :orchestrator, __MODULE__)
    GenServer.call(server, {:cancel, goal_id})
  end

  @doc """
  Returns the count of concurrently active node tasks across all goals.
  """
  @spec in_flight_count(GenServer.server()) :: non_neg_integer()
  def in_flight_count(server \\ __MODULE__) do
    GenServer.call(server, :in_flight_count)
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(opts) do
    state = %__MODULE__{
      goal_store: Keyword.get(opts, :goal_store, GoalStore),
      task_supervisor:
        Keyword.get(opts, :task_supervisor, Exocomp.Coordinator.DiagTaskSupervisor),
      client_adapter: Keyword.get(opts, :client_adapter, DiagnosticClient),
      client_opts: Keyword.get(opts, :client_opts, []),
      concurrency: positive_option(opts, :concurrency, @default_concurrency),
      node_timeout_ms: positive_option(opts, :node_timeout_ms, @default_node_timeout_ms),
      overall_timeout_ms: positive_option(opts, :overall_timeout_ms, @default_overall_timeout_ms),
      poll_interval_ms: positive_option(opts, :poll_interval_ms, @default_poll_interval_ms)
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:run, caller_key, skill_id, params, node_ids, call_client_opts}, _from, state) do
    case GoalStore.accept(caller_key, skill_id, params, state.goal_store) do
      {:error, :at_capacity} ->
        {:reply, {:error, :at_capacity}, state}

      {:ok, goal} ->
        cond do
          # Dedup hit: goal already being managed by this orchestrator.
          Map.has_key?(state.goals, goal.id) ->
            {:reply, {:ok, goal}, state}

          # Goal is already terminal (dedup from a prior run).
          DiagnosticGoal.terminal?(goal) ->
            {:reply, {:ok, goal}, state}

          # Fresh goal: begin dispatching.
          true ->
            # Merge per-call client_opts over the base client_opts.
            effective_client_opts = Keyword.merge(state.client_opts, call_client_opts)
            state = begin_dispatch(goal, Enum.uniq(node_ids), effective_client_opts, state)
            {:ok, refreshed} = GoalStore.get(goal.id, state.goal_store)
            {:reply, {:ok, refreshed}, state}
        end
    end
  end

  def handle_call(:in_flight_count, _from, state) do
    {:reply, map_size(state.tasks), state}
  end

  def handle_call({:cancel, goal_id}, _from, state) do
    case GoalStore.cancel(goal_id, state.goal_store) do
      {:error, :not_found} ->
        {:reply, {:error, :not_found}, state}

      {:error, :not_cancelable} ->
        # Goal already terminal — idempotent: return the current goal.
        {:ok, goal} = GoalStore.get(goal_id, state.goal_store)
        {:reply, {:ok, goal}, state}

      {:ok, _canceled_goal} ->
        # Goal successfully marked :canceled in GoalStore. Stop pending and
        # in-flight work, attempt downstream A2A cancellation for known tasks.
        state = do_cancel_goal(goal_id, state)
        {:ok, refreshed} = GoalStore.get(goal_id, state.goal_store)
        {:reply, {:ok, refreshed}, state}
    end
  end

  # Task completed with a successful A2A task result.
  @impl true
  def handle_info({ref, {:ok, a2a_task}}, state) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    case Map.pop(state.tasks, ref) do
      {nil, _tasks} ->
        {:noreply, state}

      {%{goal_id: goal_id, node_id: node_id, timeout_ref: timeout_ref}, tasks} ->
        Process.cancel_timer(timeout_ref)
        state = %{state | tasks: tasks}
        state = drop_downstream_key(state, goal_id, node_id)
        state = record_node_success(goal_id, node_id, a2a_task, state)
        {:noreply, dispatch_pending(state)}
    end
  end

  # Task completed with an error.
  def handle_info({ref, {:error, error}}, state) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    case Map.pop(state.tasks, ref) do
      {nil, _tasks} ->
        {:noreply, state}

      {%{goal_id: goal_id, node_id: node_id, timeout_ref: timeout_ref}, tasks} ->
        Process.cancel_timer(timeout_ref)
        state = %{state | tasks: tasks}
        state = drop_downstream_key(state, goal_id, node_id)
        state = record_node_error(goal_id, node_id, error, state)
        {:noreply, dispatch_pending(state)}
    end
  end

  # Task exited normally — result was already delivered via {ref, result}.
  def handle_info({:DOWN, ref, :process, _pid, :normal}, state) do
    # Demonitor already called in {ref, result} handler; this is a no-op.
    {:noreply, %{state | tasks: Map.delete(state.tasks, ref)}}
  end

  # Task crashed abnormally.
  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    case Map.pop(state.tasks, ref) do
      {nil, tasks} ->
        {:noreply, %{state | tasks: tasks}}

      {%{goal_id: goal_id, node_id: node_id, timeout_ref: timeout_ref}, tasks} ->
        Process.cancel_timer(timeout_ref)
        state = %{state | tasks: tasks}
        state = drop_downstream_key(state, goal_id, node_id)
        state = record_node_outcome(goal_id, node_id, :failed, nil, {:crash, reason}, state)
        {:noreply, dispatch_pending(state)}
    end
  end

  # Per-node deadline expired.
  def handle_info({:node_timeout, ref}, state) do
    case Map.pop(state.tasks, ref) do
      {nil, _tasks} ->
        # Late timeout message — task already finished. Nothing to do.
        {:noreply, state}

      {%{goal_id: goal_id, node_id: node_id, task: task}, tasks} ->
        Task.shutdown(task, :brutal_kill)
        state = %{state | tasks: tasks}
        state = drop_downstream_key(state, goal_id, node_id)
        state = record_node_outcome(goal_id, node_id, :unreachable, nil, :node_timeout, state)
        {:noreply, dispatch_pending(state)}
    end
  end

  # Overall goal deadline expired.
  def handle_info({:goal_timeout, goal_id}, state) do
    case Map.pop(state.goals, goal_id) do
      {nil, _goals} ->
        # Goal already completed — ignore stale timer.
        {:noreply, state}

      {goal_meta, goals} ->
        state = %{state | goals: goals}
        state = force_complete_goal(goal_id, goal_meta, state)
        {:noreply, dispatch_pending(state)}
    end
  end

  # Worker notified us of the downstream A2A task ID after a successful send.
  # Store it so that cancel/2 can attempt downstream A2A cancellation.
  def handle_info({:node_dispatched, goal_id, node_id, downstream_task_id}, state) do
    # Only register if the goal is still active (not yet completed or canceled).
    if Map.has_key?(state.goals, goal_id) do
      key = {goal_id, node_id}
      updated = Map.put(state.downstream_task_ids, key, downstream_task_id)
      {:noreply, %{state | downstream_task_ids: updated}}
    else
      {:noreply, state}
    end
  end

  def handle_info(_message, state), do: {:noreply, state}

  # ---------------------------------------------------------------------------
  # Private: dispatching
  # ---------------------------------------------------------------------------

  # Begin dispatching a freshly accepted goal to its targeted nodes.
  defp begin_dispatch(goal, [], _client_opts, state) do
    # No nodes — immediately complete.
    GoalStore.transition(goal.id, :dispatching, nil, state.goal_store)
    GoalStore.transition(goal.id, :running, nil, state.goal_store)
    GoalStore.transition(goal.id, :completed, nil, state.goal_store)
    state
  end

  defp begin_dispatch(goal, node_ids, client_opts, state) do
    # Initialize every targeted node as :pending in the store.
    Enum.each(node_ids, fn node_id ->
      GoalStore.put_node_outcome(
        goal.id,
        node_id,
        %NodeOutcome{node_id: node_id, state: :pending},
        state.goal_store
      )
    end)

    GoalStore.transition(goal.id, :dispatching, nil, state.goal_store)

    overall_timeout_ref =
      Process.send_after(self(), {:goal_timeout, goal.id}, state.overall_timeout_ms)

    goal_meta = %{
      remaining: length(node_ids),
      pending: node_ids,
      skill_id: goal.skill_id,
      params: goal.params,
      client_opts: client_opts,
      overall_timeout_ref: overall_timeout_ref
    }

    state = %{state | goals: Map.put(state.goals, goal.id, goal_meta)}
    dispatch_pending(state)
  end

  # Dispatch as many pending node tasks as concurrency allows.
  defp dispatch_pending(state) do
    available = state.concurrency - map_size(state.tasks)

    if available <= 0 do
      state
    else
      {to_dispatch, state} = take_pending(state, available)

      Enum.reduce(to_dispatch, state, fn {goal_id, node_id}, s ->
        start_node_task(goal_id, node_id, s)
      end)
    end
  end

  # Collect up to `n` (goal_id, node_id) pairs from all goal pending queues.
  # Goals are visited in round-robin order; a goal with more than one pending
  # node is re-appended to the tail so other goals get a turn first.
  defp take_pending(state, n) do
    take_pending(state, n, Map.keys(state.goals), [])
  end

  defp take_pending(state, 0, _goal_ids, acc), do: {Enum.reverse(acc), state}
  defp take_pending(state, _n, [], acc), do: {Enum.reverse(acc), state}

  defp take_pending(state, n, [goal_id | rest], acc) do
    case Map.get(state.goals, goal_id) do
      %{pending: [node_id | remaining_pending]} = meta ->
        updated_meta = %{meta | pending: remaining_pending}
        updated_goals = Map.put(state.goals, goal_id, updated_meta)
        updated_state = %{state | goals: updated_goals}
        # If the goal still has more pending nodes, re-queue it at the tail
        # so other goals get a turn (fairness) and we can revisit it.
        next_ids = if remaining_pending == [], do: rest, else: rest ++ [goal_id]
        take_pending(updated_state, n - 1, next_ids, [{goal_id, node_id} | acc])

      _ ->
        take_pending(state, n, rest, acc)
    end
  end

  # Start a supervised task for one (goal, node) pair.
  defp start_node_task(goal_id, node_id, state) do
    %{skill_id: skill_id, params: params, client_opts: goal_client_opts} = state.goals[goal_id]
    downstream_key = GoalStore.downstream_key(goal_id, node_id)

    client_adapter = state.client_adapter
    poll_interval_ms = state.poll_interval_ms

    # Capture the orchestrator PID so the worker can notify it of the
    # downstream A2A task ID after a successful send.
    orchestrator_pid = self()

    client_opts =
      Keyword.merge(goal_client_opts,
        message_id: downstream_key,
        context_id: goal_id
      )

    # Update node to :running before the task starts so callers see immediate progress.
    GoalStore.put_node_outcome(
      goal_id,
      node_id,
      %NodeOutcome{node_id: node_id, state: :running},
      state.goal_store
    )

    # Transition goal to :running (no-op if already :running).
    GoalStore.transition(goal_id, :running, nil, state.goal_store)

    task =
      Task.Supervisor.async_nolink(state.task_supervisor, fn ->
        run_node_task(
          goal_id,
          node_id,
          skill_id,
          params,
          client_adapter,
          client_opts,
          poll_interval_ms,
          orchestrator_pid
        )
      end)

    timeout_ref =
      Process.send_after(self(), {:node_timeout, task.ref}, state.node_timeout_ms)

    meta = %{goal_id: goal_id, node_id: node_id, timeout_ref: timeout_ref, task: task}
    %{state | tasks: Map.put(state.tasks, task.ref, meta)}
  end

  # ---------------------------------------------------------------------------
  # Private: node worker (runs inside Task.Supervisor)
  # ---------------------------------------------------------------------------

  # Send the diagnostic task to the node and poll until a terminal result.
  defp run_node_task(
         goal_id,
         node_id,
         skill_id,
         params,
         client_adapter,
         client_opts,
         poll_interval_ms,
         orchestrator_pid
       ) do
    case client_adapter.send(node_id, skill_id, params, client_opts) do
      {:error, error} ->
        {:error, error}

      {:ok, a2a_task} ->
        # Notify the orchestrator of the downstream A2A task ID so it can
        # attempt A2A cancellation if cancel/2 is called later.
        send(orchestrator_pid, {:node_dispatched, goal_id, node_id, a2a_task.id})

        if TaskState.terminal?(a2a_task.status.state) do
          {:ok, a2a_task}
        else
          poll_until_terminal(
            node_id,
            a2a_task.id,
            client_adapter,
            client_opts,
            poll_interval_ms
          )
        end
    end
  end

  defp poll_until_terminal(node_id, task_id, client_adapter, client_opts, poll_interval_ms) do
    Process.sleep(poll_interval_ms)

    case client_adapter.get_task(node_id, task_id, client_opts) do
      {:error, error} ->
        {:error, error}

      {:ok, a2a_task} ->
        if TaskState.terminal?(a2a_task.status.state) do
          {:ok, a2a_task}
        else
          poll_until_terminal(node_id, task_id, client_adapter, client_opts, poll_interval_ms)
        end
    end
  end

  # ---------------------------------------------------------------------------
  # Private: outcome recording
  # ---------------------------------------------------------------------------

  defp record_node_success(goal_id, node_id, a2a_task, state) do
    outcome = %NodeOutcome{
      node_id: node_id,
      state: :succeeded,
      result: a2a_task,
      artifacts: a2a_task.artifacts
    }

    GoalStore.put_node_outcome(goal_id, node_id, outcome, state.goal_store)
    decrement_remaining(goal_id, state)
  end

  # Classify a ClientError into a node outcome state.
  defp record_node_error(goal_id, node_id, error, state) do
    outcome_state =
      case error do
        %ClientError{kind: :transport} -> :unreachable
        %ClientError{kind: :configuration} -> :failed
        %ClientError{kind: :protocol} -> :failed
        _ -> :failed
      end

    record_node_outcome(goal_id, node_id, outcome_state, nil, error, state)
  end

  defp record_node_outcome(goal_id, node_id, outcome_state, result, error, state) do
    outcome = %NodeOutcome{
      node_id: node_id,
      state: outcome_state,
      result: result,
      error: error,
      artifacts: []
    }

    GoalStore.put_node_outcome(goal_id, node_id, outcome, state.goal_store)
    decrement_remaining(goal_id, state)
  end

  # Decrement the remaining count for a goal. Complete it when all nodes done.
  defp decrement_remaining(goal_id, state) do
    case Map.get(state.goals, goal_id) do
      nil ->
        # Goal was already cleaned up (e.g., overall timeout or cancel fired first).
        state

      %{remaining: 1, overall_timeout_ref: timer_ref} ->
        # Last node — close the goal.
        Process.cancel_timer(timer_ref)
        GoalStore.transition(goal_id, :completed, nil, state.goal_store)
        %{state | goals: Map.delete(state.goals, goal_id)}

      %{remaining: n} = meta ->
        updated_goals = Map.put(state.goals, goal_id, %{meta | remaining: n - 1})
        %{state | goals: updated_goals}
    end
  end

  # ---------------------------------------------------------------------------
  # Private: cancellation
  # ---------------------------------------------------------------------------

  # Cancel all pending and in-flight work for a goal.
  # GoalStore.cancel/2 has already marked the goal as :canceled before this runs.
  defp do_cancel_goal(goal_id, state) do
    case Map.pop(state.goals, goal_id) do
      {nil, _goals} ->
        # Goal not in orchestrator tracking — already completed before cancel
        # reached us. GoalStore.cancel already handled the state machine side.
        state

      {goal_meta, goals} ->
        state = %{state | goals: goals}
        Process.cancel_timer(goal_meta.overall_timeout_ref)

        # Partition in-flight tasks by goal.
        {goal_tasks, other_tasks} =
          Enum.split_with(state.tasks, fn {_ref, meta} -> meta.goal_id == goal_id end)

        state = %{state | tasks: Map.new(other_tasks)}

        # Kill workers and attempt downstream A2A cancellation.
        Enum.each(goal_tasks, fn {_ref, task_meta} ->
          Process.cancel_timer(task_meta.timeout_ref)
          # Task.shutdown(:brutal_kill) kills the worker and flushes both the
          # task result message and the DOWN message from the orchestrator's mailbox.
          Task.shutdown(task_meta.task, :brutal_kill)

          downstream_task_id =
            Map.get(state.downstream_task_ids, {goal_id, task_meta.node_id})

          outcome_state =
            if is_nil(downstream_task_id) do
              # Worker was killed before it dispatched to downstream, or the
              # {:node_dispatched, ...} notification hasn't been processed yet.
              :canceled
            else
              attempt_a2a_cancel(
                task_meta.node_id,
                downstream_task_id,
                goal_meta.client_opts,
                state.client_adapter
              )
            end

          GoalStore.put_node_outcome(
            goal_id,
            task_meta.node_id,
            %NodeOutcome{
              node_id: task_meta.node_id,
              state: outcome_state,
              error: :goal_canceled
            },
            state.goal_store
          )
        end)

        # Record pending (undispatched) nodes as :canceled.
        Enum.each(goal_meta.pending, fn node_id ->
          GoalStore.put_node_outcome(
            goal_id,
            node_id,
            %NodeOutcome{node_id: node_id, state: :canceled, error: :goal_canceled},
            state.goal_store
          )
        end)

        # Clean up downstream task ID entries for this goal.
        new_downstream_ids =
          Map.reject(state.downstream_task_ids, fn {{gid, _nid}, _id} -> gid == goal_id end)

        %{state | downstream_task_ids: new_downstream_ids}
    end
  end

  # Attempt A2A cancellation of a downstream task. Returns the NodeOutcome state.
  defp attempt_a2a_cancel(node_id, task_id, client_opts, client_adapter) do
    case client_adapter.cancel(node_id, task_id, client_opts) do
      {:ok, _a2a_task} ->
        # Downstream task successfully canceled (or was already in :canceled state).
        :canceled

      {:error, %ClientError{reason: reason}}
      when reason in [:task_not_cancelable, :task_not_found] ->
        # Task was already in a terminal state before our cancel arrived.
        # From the coordinator's perspective the outcome is still :canceled.
        :canceled

      {:error, _other} ->
        # Cancel was rejected or failed (e.g. :unsupported_operation, transport
        # error). The downstream task may still be running.
        :cancel_failed
    end
  end

  # ---------------------------------------------------------------------------
  # Private: overall timeout
  # ---------------------------------------------------------------------------

  # Kill all remaining work for `goal_id` and force the goal to :completed.
  defp force_complete_goal(goal_id, goal_meta, state) do
    # Partition tasks into those belonging to this goal and the rest.
    {goal_tasks, other_tasks} =
      Enum.split_with(state.tasks, fn {_ref, meta} -> meta.goal_id == goal_id end)

    state = %{state | tasks: Map.new(other_tasks)}

    # Kill in-flight tasks and cancel their individual timeout timers.
    Enum.each(goal_tasks, fn {_ref, %{task: task, timeout_ref: timeout_ref}} ->
      Process.cancel_timer(timeout_ref)
      Task.shutdown(task, :brutal_kill)
    end)

    # Record unreachable for every in-flight node.
    Enum.each(goal_tasks, fn {_ref, %{node_id: node_id}} ->
      GoalStore.put_node_outcome(
        goal_id,
        node_id,
        %NodeOutcome{node_id: node_id, state: :unreachable, error: :overall_timeout},
        state.goal_store
      )
    end)

    # Record unreachable for every pending (not yet dispatched) node.
    Enum.each(goal_meta.pending, fn node_id ->
      GoalStore.put_node_outcome(
        goal_id,
        node_id,
        %NodeOutcome{node_id: node_id, state: :unreachable, error: :overall_timeout},
        state.goal_store
      )
    end)

    # Clean up downstream task ID entries for this goal.
    new_downstream_ids =
      Map.reject(state.downstream_task_ids, fn {{gid, _nid}, _id} -> gid == goal_id end)

    state = %{state | downstream_task_ids: new_downstream_ids}

    # Drive the goal state machine to :completed.
    # The goal may be in :dispatching or :running at this point; either path
    # is valid once we transition through :running.
    GoalStore.transition(goal_id, :running, nil, state.goal_store)
    GoalStore.transition(goal_id, :completed, nil, state.goal_store)

    state
  end

  # ---------------------------------------------------------------------------
  # Private: helpers
  # ---------------------------------------------------------------------------

  # Remove the downstream task ID entry for a (goal_id, node_id) pair.
  defp drop_downstream_key(state, goal_id, node_id) do
    %{state | downstream_task_ids: Map.delete(state.downstream_task_ids, {goal_id, node_id})}
  end

  defp positive_option(opts, key, default) do
    case Keyword.get(opts, key, default) do
      value when is_integer(value) and value > 0 ->
        value

      value ->
        raise ArgumentError, "#{key} must be a positive integer, got: #{inspect(value)}"
    end
  end
end

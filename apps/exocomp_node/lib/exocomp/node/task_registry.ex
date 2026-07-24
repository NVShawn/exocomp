defmodule Exocomp.Node.TaskRegistry do
  @moduledoc """
  Bounded, in-memory storage for the lifecycle of A2A tasks.

  Active tasks are never evicted. Terminal task history is first pruned by age
  and then, when necessary, oldest-first to keep the registry within its
  configured count bound.
  """

  use GenServer

  alias Exocomp.A2A.{Task, TaskStatus}

  @default_max_tasks 1_000
  @default_max_concurrent_tasks 10
  @default_history_ttl_ms 3_600_000
  @default_eviction_interval_ms 60_000
  @terminal_states [:completed, :failed, :canceled]

  defstruct tasks: %{},
            workers: %{},
            max_tasks: @default_max_tasks,
            max_concurrent_tasks: @default_max_concurrent_tasks,
            history_ttl_ms: @default_history_ttl_ms,
            eviction_interval_ms: @default_eviction_interval_ms

  @type state :: %__MODULE__{
          tasks: %{String.t() => {Task.t(), integer()}},
          workers: %{String.t() => pid()},
          max_tasks: pos_integer(),
          max_concurrent_tasks: pos_integer(),
          history_ttl_ms: pos_integer(),
          eviction_interval_ms: pos_integer()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec submit(term(), String.t()) :: {:ok, String.t()} | {:error, :at_capacity}
  def submit(message, skill_id), do: submit(message, skill_id, __MODULE__)

  @doc false
  @spec submit(term(), String.t(), GenServer.server()) ::
          {:ok, String.t()} | {:error, :at_capacity}
  def submit(message, skill_id, server) do
    GenServer.call(server, {:submit, message, skill_id})
  end

  @spec get(String.t()) :: {:ok, Task.t()} | {:error, :not_found}
  def get(task_id), do: get(task_id, __MODULE__)

  @doc false
  @spec get(String.t(), GenServer.server()) :: {:ok, Task.t()} | {:error, :not_found}
  def get(task_id, server), do: GenServer.call(server, {:get, task_id})

  @spec list() :: [Task.t()]
  def list, do: list(__MODULE__)

  @doc false
  @spec list(GenServer.server()) :: [Task.t()]
  def list(server), do: GenServer.call(server, :list)

  @spec transition(String.t(), atom(), term()) ::
          :ok | {:error, :not_found | :invalid_transition}
  def transition(task_id, new_state, result_or_error \\ nil) do
    transition(task_id, new_state, result_or_error, __MODULE__)
  end

  @doc false
  @spec transition(String.t(), atom(), term(), GenServer.server()) ::
          :ok | {:error, :not_found | :invalid_transition}
  def transition(task_id, new_state, result_or_error, server) do
    GenServer.call(server, {:transition, task_id, new_state, result_or_error})
  end

  @spec cancel(String.t()) :: {:ok, Task.t()} | {:error, :not_found | :not_cancelable}
  def cancel(task_id), do: cancel(task_id, __MODULE__)

  @doc false
  @spec cancel(String.t(), GenServer.server()) ::
          {:ok, Task.t()} | {:error, :not_found | :not_cancelable}
  def cancel(task_id, server), do: GenServer.call(server, {:cancel, task_id})

  @spec register_worker(String.t(), pid()) :: :ok
  def register_worker(task_id, worker_pid) do
    register_worker(task_id, worker_pid, __MODULE__)
  end

  @doc false
  @spec register_worker(String.t(), pid(), GenServer.server()) :: :ok
  def register_worker(task_id, worker_pid, server) when is_pid(worker_pid) do
    GenServer.call(server, {:register_worker, task_id, worker_pid})
  end

  @impl true
  def init(opts) do
    state = %__MODULE__{
      max_tasks: option(opts, :max_tasks, @default_max_tasks),
      max_concurrent_tasks: option(opts, :max_concurrent_tasks, @default_max_concurrent_tasks),
      history_ttl_ms: option(opts, :history_ttl_ms, @default_history_ttl_ms),
      eviction_interval_ms: option(opts, :eviction_interval_ms, @default_eviction_interval_ms)
    }

    schedule_eviction(state)
    {:ok, state}
  end

  @impl true
  def handle_call({:submit, message, skill_id}, _from, state) do
    if working_count(state) >= state.max_concurrent_tasks do
      {:reply, {:error, :at_capacity}, state}
    else
      state = make_room_for_submission(state)

      if map_size(state.tasks) >= state.max_tasks do
        {:reply, {:error, :at_capacity}, state}
      else
        task_id = uuid()
        timestamp = timestamp()

        task = %Task{
          id: task_id,
          status: %TaskStatus{state: :submitted, timestamp: timestamp},
          history: [message],
          metadata: %{"skill_id" => skill_id},
          created_at: timestamp,
          updated_at: timestamp
        }

        tasks = Map.put(state.tasks, task_id, {task, monotonic_ms()})
        {:reply, {:ok, task_id}, %{state | tasks: tasks}}
      end
    end
  end

  def handle_call({:get, task_id}, _from, state) do
    reply =
      case Map.fetch(state.tasks, task_id) do
        {:ok, {task, _inserted_at}} -> {:ok, task}
        :error -> {:error, :not_found}
      end

    {:reply, reply, state}
  end

  def handle_call(:list, _from, state) do
    tasks =
      state.tasks
      |> Enum.sort_by(fn {_task_id, {_task, inserted_at}} -> inserted_at end)
      |> Enum.map(fn {_task_id, {task, _inserted_at}} -> task end)

    {:reply, tasks, state}
  end

  def handle_call({:transition, task_id, new_state, result_or_error}, _from, state) do
    case Map.fetch(state.tasks, task_id) do
      :error ->
        {:reply, {:error, :not_found}, state}

      {:ok, {task, inserted_at}} ->
        current_state = task.status.state

        if valid_transition?(current_state, new_state) and
             working_slot_available?(state, current_state, new_state) do
          task = update_task(task, new_state, result_or_error)
          state = put_task(state, task, inserted_at)
          state = maybe_signal_and_forget_worker(state, task_id, new_state)
          {:reply, :ok, state}
        else
          {:reply, {:error, :invalid_transition}, state}
        end
    end
  end

  def handle_call({:cancel, task_id}, _from, state) do
    case Map.fetch(state.tasks, task_id) do
      :error ->
        {:reply, {:error, :not_found}, state}

      {:ok, {%Task{status: %{state: task_state}} = task, inserted_at}}
      when task_state in [:submitted, :working] ->
        task = update_task(task, :canceled, nil)
        state = put_task(state, task, inserted_at)
        state = maybe_signal_and_forget_worker(state, task_id, :canceled)
        {:reply, {:ok, task}, state}

      {:ok, {_task, _inserted_at}} ->
        {:reply, {:error, :not_cancelable}, state}
    end
  end

  def handle_call({:register_worker, task_id, worker_pid}, _from, state) do
    state =
      case Map.get(state.tasks, task_id) do
        {%Task{status: %{state: :working}}, _inserted_at} ->
          %{state | workers: Map.put(state.workers, task_id, worker_pid)}

        _other ->
          state
      end

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:evict, state) do
    state = evict(state, state.max_tasks)
    schedule_eviction(state)
    {:noreply, state}
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp valid_transition?(:submitted, new_state), do: new_state in [:working, :canceled]

  defp valid_transition?(:working, new_state),
    do: new_state in [:completed, :failed, :canceled]

  defp valid_transition?(_current_state, _new_state), do: false

  defp working_slot_available?(state, _current_state, :working) do
    working_count(state) < state.max_concurrent_tasks
  end

  defp working_slot_available?(_state, _current_state, _new_state), do: true

  defp update_task(task, new_state, result_or_error) do
    timestamp = timestamp()

    %{
      task
      | status: %TaskStatus{
          state: new_state,
          message: result_or_error,
          timestamp: timestamp
        },
        updated_at: timestamp
    }
  end

  defp put_task(state, task, inserted_at) do
    %{state | tasks: Map.put(state.tasks, task.id, {task, inserted_at})}
  end

  defp maybe_signal_and_forget_worker(state, task_id, new_state) do
    case Map.pop(state.workers, task_id) do
      {worker_pid, workers} when new_state == :canceled and is_pid(worker_pid) ->
        send(worker_pid, :shutdown)
        %{state | workers: workers}

      {nil, _workers} when new_state in @terminal_states ->
        state

      {_worker_pid, workers} when new_state in @terminal_states ->
        %{state | workers: workers}

      {_worker_pid, _workers} ->
        state
    end
  end

  defp make_room_for_submission(state) do
    if map_size(state.tasks) >= state.max_tasks do
      evict(state, state.max_tasks - 1)
    else
      state
    end
  end

  defp evict(state, target_size) do
    now = monotonic_ms()

    {_expired, retained} =
      Enum.split_with(state.tasks, fn {_task_id, {task, inserted_at}} ->
        terminal?(task) and now - inserted_at >= state.history_ttl_ms
      end)

    retained = Map.new(retained)

    tasks =
      if map_size(retained) > target_size do
        retained
        |> Enum.filter(fn {_task_id, {task, _inserted_at}} -> terminal?(task) end)
        |> Enum.sort_by(fn {task_id, {_task, inserted_at}} -> {inserted_at, task_id} end)
        |> Enum.take(map_size(retained) - target_size)
        |> Enum.reduce(retained, fn {task_id, _entry}, tasks -> Map.delete(tasks, task_id) end)
      else
        retained
      end

    workers = Map.take(state.workers, Map.keys(tasks))

    %{state | tasks: tasks, workers: workers}
  end

  defp terminal?(%Task{status: %{state: state}}), do: state in @terminal_states

  defp working_count(state) do
    Enum.count(state.tasks, fn {_task_id, {task, _inserted_at}} ->
      task.status.state == :working
    end)
  end

  defp schedule_eviction(state) do
    Process.send_after(self(), :evict, state.eviction_interval_ms)
  end

  defp option(opts, key, default) do
    opts
    |> Keyword.get(key, Application.get_env(:exocomp_node, key, default))
    |> positive_integer(default)
  end

  defp positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp positive_integer(_value, default), do: default

  defp monotonic_ms, do: System.monotonic_time(:millisecond)

  defp timestamp do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end

  defp uuid do
    <<prefix::48, _version::4, middle::12, _variant::2, suffix::62>> =
      :crypto.strong_rand_bytes(16)

    binary = <<prefix::48, 4::4, middle::12, 2::2, suffix::62>>

    <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4), e::binary>> =
      Base.encode16(binary, case: :lower)

    Enum.join([a, b, c, d, e], "-")
  end
end

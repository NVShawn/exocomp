defmodule Exocomp.Coordinator.HealthPoller do
  @moduledoc """
  Runs due node health polls concurrently with per-node isolation.

  Registry attempt tokens provide cross-process in-flight deduplication. Each
  poll runs under a `Task.Supervisor`, has an independent deadline, and records
  its typed outcome through the Registry state machine.
  """

  use GenServer

  alias Exocomp.Coordinator.{NodeProber, Registry}

  @default_interval_ms 1_000
  @default_timeout_ms 10_000
  @default_concurrency 4

  defstruct [
    :registry,
    :task_supervisor,
    :resolver_adapter,
    :probe_adapter,
    :probe_options,
    :interval_ms,
    :timeout_ms,
    :concurrency,
    :timer_ref,
    tasks: %{},
    nodes: MapSet.new()
  ]

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Triggers a scheduling pass without waiting for active workers."
  @spec poll_now(GenServer.server()) :: :ok
  def poll_now(server \\ __MODULE__), do: GenServer.call(server, :poll_now)

  @doc "Returns the node IDs currently being polled."
  @spec in_flight(GenServer.server()) :: [String.t()]
  def in_flight(server \\ __MODULE__), do: GenServer.call(server, :in_flight)

  @impl true
  def init(opts) do
    state = %__MODULE__{
      registry: Keyword.get(opts, :registry_server, Registry),
      task_supervisor:
        Keyword.get(opts, :task_supervisor, Exocomp.Coordinator.PollTaskSupervisor),
      resolver_adapter: Keyword.get(opts, :resolver_adapter, fn _entry -> :ok end),
      probe_adapter: Keyword.get(opts, :probe_adapter, &NodeProber.probe/2),
      probe_options: Keyword.get(opts, :probe_options, []),
      interval_ms: positive_option(opts, :interval_ms, @default_interval_ms),
      timeout_ms: positive_option(opts, :timeout_ms, @default_timeout_ms),
      concurrency: positive_option(opts, :concurrency, @default_concurrency)
    }

    terminate_orphan_workers(state.task_supervisor)
    Registry.recover_in_flight(:timeout, state.registry)

    if Keyword.get(opts, :start_immediately, true), do: send(self(), :poll)
    {:ok, state}
  end

  @impl true
  def handle_call(:poll_now, _from, state) do
    {:reply, :ok, dispatch_due(state)}
  end

  def handle_call(:in_flight, _from, state) do
    {:reply, state.nodes |> MapSet.to_list() |> Enum.sort(), state}
  end

  @impl true
  def handle_info(:poll, state) do
    {:noreply, state |> schedule_next() |> dispatch_due()}
  end

  def handle_info({ref, _result}, state) when is_reference(ref) do
    Process.demonitor(ref, [:flush])
    {:noreply, state |> finish(ref) |> dispatch_due()}
  end

  def handle_info({:DOWN, ref, :process, _pid, :normal}, state) do
    {:noreply, state |> finish(ref) |> dispatch_due()}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {:noreply, state |> fail(ref, :unreachable) |> dispatch_due()}
  end

  def handle_info({:poll_timeout, ref}, state) do
    case Map.get(state.tasks, ref) do
      nil ->
        {:noreply, state}

      %{task: task} = meta ->
        state = remove_task(state, ref)
        Task.shutdown(task, :brutal_kill)
        record_failure(meta, :timeout, state.registry)
        {:noreply, dispatch_due(state)}
    end
  end

  defp dispatch_due(state) do
    available = state.concurrency - map_size(state.tasks)

    state.registry
    |> Registry.due_nodes()
    |> Enum.reject(&MapSet.member?(state.nodes, &1.id))
    |> Enum.take(max(available, 0))
    |> Enum.reduce(state, &start_poll/2)
  end

  defp start_poll(entry, state) do
    case Registry.begin_poll(entry.id, state.registry) do
      {:ok, token} ->
        task =
          Task.Supervisor.async_nolink(state.task_supervisor, fn ->
            run_poll(entry, token, state)
          end)

        timeout_ref = Process.send_after(self(), {:poll_timeout, task.ref}, state.timeout_ms)
        meta = %{task: task, node_id: entry.id, token: token, timeout_ref: timeout_ref}

        %{
          state
          | tasks: Map.put(state.tasks, task.ref, meta),
            nodes: MapSet.put(state.nodes, entry.id)
        }

      {:error, _reason} ->
        state
    end
  end

  defp run_poll(entry, token, state) do
    entry = resolve(entry, state.resolver_adapter, state.registry)

    options =
      state.probe_options
      |> Keyword.put(:timeout_ms, state.timeout_ms)
      |> Keyword.put(:attempt_token, token)
      |> Keyword.put(:registry_server, state.registry)

    result = state.probe_adapter.(entry, options)
    Registry.record_observation(entry.id, token, result, state.registry)
    result
  end

  defp resolve(entry, resolver_adapter, registry) do
    case resolver_adapter.(entry) do
      {:ok, addresses} when is_list(addresses) ->
        :ok = Registry.put_candidates(entry.id, addresses, registry)
        {:ok, refreshed} = Registry.get(entry.id, registry)
        refreshed

      :ok ->
        entry

      {:error, reason} ->
        throw({:resolver_error, reason})
    end
  end

  defp finish(state, ref), do: remove_task(state, ref)

  defp fail(state, ref, outcome) do
    case Map.get(state.tasks, ref) do
      nil ->
        state

      meta ->
        record_failure(meta, outcome, state.registry)
        remove_task(state, ref)
    end
  end

  defp remove_task(state, ref) do
    case Map.pop(state.tasks, ref) do
      {nil, _tasks} ->
        state

      {meta, tasks} ->
        Process.cancel_timer(meta.timeout_ref)
        %{state | tasks: tasks, nodes: MapSet.delete(state.nodes, meta.node_id)}
    end
  end

  defp record_failure(meta, outcome, registry) do
    Registry.record_observation(meta.node_id, meta.token, outcome, registry)
  end

  defp schedule_next(state) do
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
    %{state | timer_ref: Process.send_after(self(), :poll, state.interval_ms)}
  end

  defp terminate_orphan_workers(task_supervisor) do
    task_supervisor
    |> Task.Supervisor.children()
    |> Enum.each(&Process.exit(&1, :kill))
  end

  defp positive_option(opts, key, default) do
    case Keyword.get(opts, key, default) do
      value when is_integer(value) and value > 0 -> value
      value -> raise ArgumentError, "#{key} must be a positive integer, got: #{inspect(value)}"
    end
  end
end

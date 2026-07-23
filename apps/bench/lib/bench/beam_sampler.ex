defmodule Bench.BeamSampler do
  @moduledoc """
  Periodically collects runtime metrics from the local BEAM.

  Registered processes whose mailboxes should be measured are supplied with
  the `:processes` option. Entries may be registered names or
  `{label, registered_name}` tuples. An optional standard Elixir `Registry`
  name may be supplied as `:task_registry`.
  """

  use GenServer

  alias Bench.Sample

  @default_interval 1_000
  @default_task_registry Exocomp.Registry

  @doc """
  Starts a BEAM sampler.

  Supported options are `:interval`, `:processes`, and `:task_registry`.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) when is_list(opts) do
    interval = Keyword.get(opts, :interval, @default_interval)

    if is_integer(interval) and interval > 0 do
      GenServer.start_link(__MODULE__, opts)
    else
      {:error, {:invalid_interval, interval}}
    end
  end

  @doc "Stops a sampler."
  @spec stop(GenServer.server()) :: :ok
  def stop(server), do: GenServer.stop(server)

  @doc "Takes a sample immediately and returns all observations since the last flush."
  @spec flush(GenServer.server()) :: [Sample.t()]
  def flush(server), do: GenServer.call(server, :flush)

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, @default_interval)
    scheduler_wall_time_was_enabled = :erlang.system_flag(:scheduler_wall_time, true)

    state = %{
      interval: interval,
      processes: normalize_processes(Keyword.get(opts, :processes, [])),
      task_registry: Keyword.get(opts, :task_registry, @default_task_registry),
      scheduler_wall_time_was_enabled: scheduler_wall_time_was_enabled,
      previous_scheduler_wall_time: scheduler_wall_time(),
      samples: [],
      timer: nil
    }

    {:ok, schedule(state)}
  end

  @impl true
  def handle_info(:sample, state) do
    state = state |> Map.put(:timer, nil) |> collect() |> schedule()
    {:noreply, state}
  end

  @impl true
  def handle_call(:flush, _from, state) do
    state = collect(state)
    {:reply, Enum.reverse(state.samples), %{state | samples: []}}
  end

  @impl true
  def terminate(_reason, state) do
    if is_reference(state.timer), do: Process.cancel_timer(state.timer)

    unless state.scheduler_wall_time_was_enabled do
      :erlang.system_flag(:scheduler_wall_time, false)
    end

    :ok
  end

  defp schedule(state) do
    %{state | timer: Process.send_after(self(), :sample, state.interval)}
  end

  defp collect(state) do
    timestamp = System.system_time(:millisecond)
    scheduler_wall_time = scheduler_wall_time()

    samples =
      [
        sample(
          timestamp,
          "scheduler.utilization",
          scheduler_utilization(scheduler_wall_time, state.previous_scheduler_wall_time),
          "ratio"
        ),
        sample(timestamp, "process.count", :erlang.system_info(:process_count), "count"),
        sample(timestamp, "run_queue.length", :erlang.statistics(:run_queue), "count")
      ] ++
        mailbox_samples(timestamp, state.processes) ++
        memory_samples(timestamp) ++
        task_registry_samples(timestamp, state.task_registry)

    %{
      state
      | samples: Enum.reverse(samples, state.samples),
        previous_scheduler_wall_time: scheduler_wall_time
    }
  end

  defp scheduler_wall_time do
    case :erlang.statistics(:scheduler_wall_time) do
      values when is_list(values) ->
        Map.new(values, fn {id, active, total} -> {id, {active, total}} end)

      :undefined ->
        %{}
    end
  end

  defp scheduler_utilization(current, previous) do
    {active, total} =
      Enum.reduce(current, {0, 0}, fn {id, {active, total}}, {active_sum, total_sum} ->
        case previous do
          %{^id => {old_active, old_total}} when total > old_total ->
            {
              active_sum + max(active - old_active, 0),
              total_sum + total - old_total
            }

          _ ->
            {active_sum, total_sum}
        end
      end)

    if total > 0, do: (active / total) |> max(0.0) |> min(1.0), else: 0.0
  end

  defp normalize_processes(processes) when is_list(processes) do
    Enum.map(processes, fn
      {label, name} when is_atom(name) -> {to_string(label), name}
      name when is_atom(name) -> {Atom.to_string(name), name}
    end)
  end

  defp mailbox_samples(timestamp, processes) do
    Enum.flat_map(processes, fn {label, name} ->
      with pid when is_pid(pid) <- Process.whereis(name),
           {:message_queue_len, depth} <- Process.info(pid, :message_queue_len) do
        [sample(timestamp, "mailbox.#{label}.depth", depth, "count")]
      else
        _ -> []
      end
    end)
  end

  defp memory_samples(timestamp) do
    Enum.map(:erlang.memory(), fn {category, bytes} ->
      sample(timestamp, "memory.#{category}.bytes", bytes, "bytes")
    end)
  end

  defp task_registry_samples(_timestamp, nil), do: []

  defp task_registry_samples(timestamp, registry) when is_atom(registry) do
    case task_registry_size(registry) do
      size when is_integer(size) and size >= 0 ->
        [sample(timestamp, "task_registry.size", size, "count")]

      _ ->
        []
    end
  end

  defp task_registry_size(registry) do
    cond do
      Code.ensure_loaded?(registry) and function_exported?(registry, :count, 0) ->
        apply(registry, :count, [])

      is_pid(Process.whereis(registry)) ->
        Registry.count(registry)

      true ->
        nil
    end
  rescue
    ArgumentError -> nil
  catch
    :exit, _reason -> nil
  end

  defp sample(timestamp, metric_name, value, unit) do
    %Sample{
      timestamp: timestamp,
      source: :beam,
      metric_name: metric_name,
      value: value,
      unit: unit
    }
  end
end

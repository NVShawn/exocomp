defmodule Bench.HostSampler do
  @moduledoc """
  Periodically samples Linux process resource usage for benchmark targets.

  Targets are supplied as a keyword list keyed by `:node`, `:coordinator`, and
  `:llama`. Values are Linux OS process IDs. A missing or exited process emits
  one `nil` sample per metric tagged with `:missing`.
  """

  use GenServer

  alias Bench.Sample

  @targets [:node, :coordinator, :llama]
  @default_interval 1_000
  @metric_units [
    {"cpu.percent", "percent"},
    {"memory.rss.bytes", "bytes"},
    {"memory.pss.bytes", "bytes"},
    {"file_descriptors.open", "count"},
    {"disk.io.bytes", "bytes"},
    {"network.io.bytes", "bytes"},
    {"page_faults", "count"}
  ]

  @type target :: :node | :coordinator | :llama
  @type os_pid :: pos_integer() | String.t() | nil

  @doc """
  Starts a sampler.

  Besides the three target keys, the list may contain `:interval`,
  `:proc_root`, `:cgroup_root`, and `:clock_ticks` options.
  """
  @spec start_link([{target(), os_pid()} | {atom(), term()}]) :: GenServer.on_start()
  def start_link(opts) when is_list(opts), do: GenServer.start_link(__MODULE__, opts)

  @doc "Stops a sampler."
  @spec stop(GenServer.server()) :: :ok
  def stop(server), do: GenServer.stop(server)

  @doc """
  Takes a sample immediately and returns all observations since the last flush.
  """
  @spec flush(GenServer.server()) :: [Sample.t()]
  def flush(server), do: GenServer.call(server, :flush)

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, @default_interval)

    if is_integer(interval) and interval > 0 do
      state = %{
        targets: Enum.map(@targets, &{&1, Keyword.get(opts, &1)}),
        interval: interval,
        proc_root: Keyword.get(opts, :proc_root, "/proc"),
        cgroup_root: Keyword.get(opts, :cgroup_root, "/sys/fs/cgroup"),
        clock_ticks: Keyword.get_lazy(opts, :clock_ticks, &clock_ticks/0),
        previous_cpu: %{},
        samples: [],
        timer: nil
      }

      {:ok, schedule(state)}
    else
      {:stop, {:invalid_interval, interval}}
    end
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
  def terminate(_reason, %{timer: timer}) when is_reference(timer) do
    Process.cancel_timer(timer)
    :ok
  end

  def terminate(_reason, _state), do: :ok

  defp schedule(state) do
    %{state | timer: Process.send_after(self(), :sample, state.interval)}
  end

  defp collect(state) do
    now = System.monotonic_time(:nanosecond)
    timestamp = System.system_time(:millisecond)

    {samples, previous_cpu} =
      Enum.flat_map_reduce(state.targets, state.previous_cpu, fn {source, pid}, previous ->
        collect_target(source, normalize_pid(pid), timestamp, now, previous, state)
      end)

    %{state | samples: Enum.reverse(samples, state.samples), previous_cpu: previous_cpu}
  end

  defp collect_target(source, nil, timestamp, _now, previous, _state) do
    {missing_samples(source, timestamp), Map.delete(previous, source)}
  end

  defp collect_target(source, pid, timestamp, now, previous, state) do
    process_dir = Path.join(state.proc_root, pid)

    with {:ok, stat} <- read_stat(Path.join(process_dir, "stat")) do
      {cpu, cpu_tags} = cpu_percent(stat.cpu_ticks, now, previous[source], state.clock_ticks)
      {rss, pss} = memory_bytes(process_dir)
      descriptors = fd_count(process_dir)
      disk_io = disk_io_bytes(process_dir)
      network_io = network_io_bytes(pid, state)

      values = [
        {cpu, cpu_tags},
        {rss, unavailable_tag(rss)},
        {pss, unavailable_tag(pss)},
        {descriptors, unavailable_tag(descriptors)},
        {disk_io, unavailable_tag(disk_io)},
        {network_io, unavailable_tag(network_io)},
        {stat.page_faults, []}
      ]

      samples =
        Enum.zip(@metric_units, values)
        |> Enum.map(fn {{name, unit}, {value, tags}} ->
          sample(timestamp, source, name, value, unit, tags)
        end)

      {samples, Map.put(previous, source, {stat.cpu_ticks, now})}
    else
      _ -> {missing_samples(source, timestamp), Map.delete(previous, source)}
    end
  end

  defp missing_samples(source, timestamp) do
    Enum.map(@metric_units, fn {name, unit} ->
      sample(timestamp, source, name, nil, unit, [:missing])
    end)
  end

  defp sample(timestamp, source, name, value, unit, tags) do
    %Sample{
      timestamp: timestamp,
      source: source,
      metric_name: name,
      value: value,
      unit: unit,
      tags: tags
    }
  end

  defp normalize_pid(pid) when is_integer(pid) and pid > 0, do: Integer.to_string(pid)

  defp normalize_pid(pid) when is_binary(pid) do
    case Integer.parse(pid) do
      {parsed, ""} when parsed > 0 -> Integer.to_string(parsed)
      _ -> nil
    end
  end

  defp normalize_pid(_pid), do: nil

  defp read_stat(path) do
    with {:ok, contents} <- File.read(path),
         [_, fields] <- Regex.run(~r/^\d+ \(.*\) (.+)$/, String.trim(contents)),
         fields <- String.split(fields),
         {:ok, user_ticks} <- integer_at(fields, 11),
         {:ok, system_ticks} <- integer_at(fields, 12),
         {:ok, minor_faults} <- integer_at(fields, 7),
         {:ok, major_faults} <- integer_at(fields, 9) do
      {:ok,
       %{
         cpu_ticks: user_ticks + system_ticks,
         page_faults: minor_faults + major_faults
       }}
    else
      _ -> {:error, :invalid_stat}
    end
  end

  defp integer_at(fields, index) do
    case Enum.fetch(fields, index) do
      {:ok, value} ->
        case Integer.parse(value) do
          {integer, ""} -> {:ok, integer}
          _ -> :error
        end

      :error ->
        :error
    end
  end

  defp cpu_percent(_ticks, _now, nil, _clock_ticks), do: {nil, [:warming_up]}

  defp cpu_percent(ticks, now, {old_ticks, old_now}, clock_ticks) when now > old_now do
    elapsed_seconds = (now - old_now) / 1_000_000_000
    percent = (ticks - old_ticks) / clock_ticks / elapsed_seconds * 100
    {max(percent, 0.0), []}
  end

  defp cpu_percent(_ticks, _now, _previous, _clock_ticks), do: {nil, [:unavailable]}

  defp memory_bytes(process_dir) do
    case File.read(Path.join(process_dir, "smaps_rollup")) do
      {:ok, contents} ->
        {kilobytes(contents, "Rss"), kilobytes(contents, "Pss")}

      _ ->
        case File.read(Path.join(process_dir, "status")) do
          {:ok, contents} -> {kilobytes(contents, "VmRSS"), nil}
          _ -> {nil, nil}
        end
    end
  end

  defp kilobytes(contents, field) do
    case Regex.run(~r/^#{field}:\s+(\d+)\s+kB$/m, contents) do
      [_, value] -> String.to_integer(value) * 1_024
      _ -> nil
    end
  end

  defp fd_count(process_dir) do
    case File.ls(Path.join(process_dir, "fd")) do
      {:ok, entries} -> length(entries)
      _ -> nil
    end
  end

  defp disk_io_bytes(process_dir) do
    case File.read(Path.join(process_dir, "io")) do
      {:ok, contents} ->
        with read when is_integer(read) <- bytes_field(contents, "read_bytes"),
             written when is_integer(written) <- bytes_field(contents, "write_bytes") do
          read + written
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp bytes_field(contents, field) do
    case Regex.run(~r/^#{field}:\s+(\d+)$/m, contents) do
      [_, value] -> String.to_integer(value)
      _ -> nil
    end
  end

  defp network_io_bytes(pid, state) do
    with {:ok, cgroup} <- File.read(Path.join([state.proc_root, pid, "cgroup"])),
         {:ok, relative_path} <- unified_cgroup_path(cgroup),
         {:ok, directory} <- safe_cgroup_directory(state.cgroup_root, relative_path) do
      ["network.stat", "net.stat"]
      |> Enum.find_value(fn filename ->
        path = Path.join(directory, filename)

        case File.read(path) do
          {:ok, contents} -> network_stat_total(contents)
          _ -> nil
        end
      end)
    else
      _ -> nil
    end
  end

  defp unified_cgroup_path(contents) do
    contents
    |> String.split("\n", trim: true)
    |> Enum.find_value({:error, :no_unified_cgroup}, fn line ->
      case String.split(line, ":", parts: 3) do
        ["0", "", path] -> {:ok, path}
        _ -> nil
      end
    end)
  end

  defp safe_cgroup_directory(root, relative_path) do
    expanded_root = Path.expand(root)
    directory = Path.expand(String.trim_leading(relative_path, "/"), expanded_root)

    if directory == expanded_root or String.starts_with?(directory, expanded_root <> "/") do
      {:ok, directory}
    else
      {:error, :invalid_cgroup_path}
    end
  end

  defp network_stat_total(contents) do
    values =
      Regex.scan(~r/(?:^|\s)(?:rx_bytes|tx_bytes)\s*[:=]?\s*(\d+)/m, contents,
        capture: :all_but_first
      )

    case values do
      [] -> nil
      values -> values |> List.flatten() |> Enum.map(&String.to_integer/1) |> Enum.sum()
    end
  end

  defp unavailable_tag(nil), do: [:unavailable]
  defp unavailable_tag(_value), do: []

  defp clock_ticks do
    case System.cmd("getconf", ["CLK_TCK"], stderr_to_stdout: true) do
      {output, 0} ->
        case Integer.parse(String.trim(output)) do
          {ticks, ""} when ticks > 0 -> ticks
          _ -> 100
        end

      _ ->
        100
    end
  rescue
    ErlangError -> 100
  end
end

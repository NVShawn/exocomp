defmodule Exocomp.Node.Collectors.CPU do
  @moduledoc """
  Collector for CPU metrics from `/proc/stat` and `/proc/cpuinfo`.

  From `/proc/stat` the aggregate `cpu` line provides raw tick counts for:
  user, nice, system, idle, iowait, irq, softirq, steal.

  From `/proc/cpuinfo` the collector reports:
  - `cpu_count` — number of logical CPU cores (processor entries).
  - `cpu_model` — model name from the first processor entry.

  Collector version history:
  - 1: Initial release — cpu_count, cpu_model, cpu_user_ticks,
       cpu_nice_ticks, cpu_system_ticks, cpu_idle_ticks,
       cpu_iowait_ticks, cpu_irq_ticks, cpu_softirq_ticks, cpu_steal_ticks.
  """

  alias Exocomp.Node.Collectors.Types

  @collector_version 1
  @source __MODULE__
  # /proc/stat is small; 256 KB is a safe ceiling even with hundreds of cores
  @stat_max_bytes 262_144
  # /proc/cpuinfo can be large on many-core systems; cap at 1 MB
  @cpuinfo_max_bytes 1_048_576

  @doc """
  Collect CPU statistics.

  Options:
  - `:proc_stat`    — path to `/proc/stat`    (default `/proc/stat`).
  - `:proc_cpuinfo` — path to `/proc/cpuinfo` (default `/proc/cpuinfo`).
  """
  @spec collect(keyword()) :: Types.observation()
  def collect(opts \\ []) do
    started_at = System.monotonic_time(:microsecond)
    stat_path = Keyword.get(opts, :proc_stat, "/proc/stat")
    cpuinfo_path = Keyword.get(opts, :proc_cpuinfo, "/proc/cpuinfo")

    stat_measurements = collect_stat(stat_path)
    cpuinfo_measurements = collect_cpuinfo(cpuinfo_path)

    measurements = Map.merge(stat_measurements, cpuinfo_measurements)

    Types.build(@source, @collector_version, started_at, measurements)
  end

  # ---------------------------------------------------------------------------
  # /proc/stat
  # ---------------------------------------------------------------------------

  defp collect_stat(path) do
    tick_fields = [
      :cpu_user_ticks,
      :cpu_nice_ticks,
      :cpu_system_ticks,
      :cpu_idle_ticks,
      :cpu_iowait_ticks,
      :cpu_irq_ticks,
      :cpu_softirq_ticks,
      :cpu_steal_ticks
    ]

    case read_and_validate(path, @stat_max_bytes) do
      {:ok, raw} ->
        parse_stat_line(raw, tick_fields)

      {:error, kind, reason} ->
        Map.new(tick_fields, fn k -> {k, Types.err(kind, reason)} end)
    end
  end

  defp parse_stat_line(raw, tick_fields) do
    aggregate_line =
      raw
      |> String.split("\n", trim: true)
      |> Enum.find(fn line -> String.starts_with?(line, "cpu ") end)

    case aggregate_line do
      nil ->
        error = Types.err(:malformed, "aggregate 'cpu' line not found in /proc/stat")
        Map.new(tick_fields, fn k -> {k, error} end)

      line ->
        # Format: "cpu  <user> <nice> <system> <idle> <iowait> <irq> <softirq> <steal> ..."
        values =
          line
          |> String.split()
          |> tl()
          |> Enum.take(8)

        if length(values) < 8 do
          error = Types.err(:malformed, "aggregate cpu line has fewer than 8 tick fields")
          Map.new(tick_fields, fn k -> {k, error} end)
        else
          tick_fields
          |> Enum.zip(values)
          |> Map.new(fn {field, str} ->
            measurement =
              case Integer.parse(str) do
                {v, ""} -> Types.ok(v, "ticks")
                _ -> Types.err(:malformed, "non-integer tick value '#{str}' for #{field}")
              end

            {field, measurement}
          end)
        end
    end
  end

  # ---------------------------------------------------------------------------
  # /proc/cpuinfo
  # ---------------------------------------------------------------------------

  defp collect_cpuinfo(path) do
    case read_and_validate(path, @cpuinfo_max_bytes) do
      {:ok, raw} ->
        parse_cpuinfo(raw)

      {:error, kind, reason} ->
        %{
          cpu_count: Types.err(kind, reason),
          cpu_model: Types.err(kind, reason)
        }
    end
  end

  defp parse_cpuinfo(raw) do
    lines = String.split(raw, "\n", trim: true)

    count =
      lines
      |> Enum.count(fn line -> String.starts_with?(line, "processor") end)

    model =
      lines
      |> Enum.find_value(fn line ->
        if String.starts_with?(line, "model name") do
          line
          |> String.split(":", parts: 2)
          |> Enum.at(1, "")
          |> String.trim()
        end
      end)

    cpu_count_m =
      if count > 0,
        do: Types.ok(count, "cores"),
        else: Types.err(:malformed, "no 'processor' entries in /proc/cpuinfo")

    cpu_model_m =
      case model do
        nil -> Types.err(:unavailable, "'model name' not found in /proc/cpuinfo")
        "" -> Types.err(:malformed, "empty 'model name' field in /proc/cpuinfo")
        name -> Types.ok(name, "string")
      end

    %{cpu_count: cpu_count_m, cpu_model: cpu_model_m}
  end

  # ---------------------------------------------------------------------------
  # Shared helpers
  # ---------------------------------------------------------------------------

  defp read_and_validate(path, max_bytes) do
    case File.read(path) do
      {:ok, raw} when byte_size(raw) > max_bytes ->
        {:error, :output_limit, "#{path} exceeded #{max_bytes} byte limit"}

      {:ok, raw} ->
        {:ok, raw}

      {:error, :enoent} ->
        {:error, :unavailable, "#{path} not found"}

      {:error, posix} when is_atom(posix) ->
        {:error, :unavailable, "read error: #{posix}"}
    end
  end
end

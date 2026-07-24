defmodule Exocomp.Node.Collectors.Uptime do
  @moduledoc """
  Collector for system uptime from `/proc/uptime`.

  `/proc/uptime` contains two space-separated floating-point values:
  - Total seconds the system has been up.
  - Sum of seconds each CPU core has spent idle.

  This collector reports only the first value (total uptime) in seconds.
  The idle time field is available but excluded to keep the measurement
  focused on the most operationally useful metric.

  Collector version history:
  - 1: Initial release — uptime_seconds (float, seconds).
  """

  alias Exocomp.Node.Collectors.Types

  @collector_version 1
  @source __MODULE__
  @max_bytes 256

  @doc """
  Collect system uptime.

  Options:
  - `:proc_uptime` — path to the uptime file (default `/proc/uptime`).
    Override in tests with a fixture path.
  """
  @spec collect(keyword()) :: Types.observation()
  def collect(opts \\ []) do
    started_at = System.monotonic_time(:microsecond)
    path = Keyword.get(opts, :proc_uptime, "/proc/uptime")

    measurements = %{
      uptime_seconds: read_uptime(path)
    }

    Types.build(@source, @collector_version, started_at, measurements)
  end

  defp read_uptime(path) do
    with {:ok, raw} <- File.read(path),
         :ok <- check_size(raw),
         {:ok, seconds} <- parse_uptime(raw) do
      Types.ok(seconds, "seconds")
    else
      {:error, :enoent} ->
        Types.err(:unavailable, "#{path} not found")

      {:error, :too_large} ->
        Types.err(:output_limit, "#{path} exceeded #{@max_bytes} byte limit")

      {:error, :malformed} ->
        Types.err(:malformed, "could not parse uptime value from #{path}")

      {:error, posix} when is_atom(posix) ->
        Types.err(:unavailable, "read error: #{posix}")
    end
  end

  defp check_size(raw) when byte_size(raw) > @max_bytes, do: {:error, :too_large}
  defp check_size(_raw), do: :ok

  defp parse_uptime(raw) do
    raw
    |> String.split()
    |> case do
      [uptime_str | _] ->
        case Float.parse(uptime_str) do
          {seconds, ""} -> {:ok, seconds}
          _ -> {:error, :malformed}
        end

      _ ->
        {:error, :malformed}
    end
  end
end

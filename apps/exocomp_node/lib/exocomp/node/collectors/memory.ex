defmodule Exocomp.Node.Collectors.Memory do
  @moduledoc """
  Collector for memory metrics from `/proc/meminfo`.

  Parses `MemTotal`, `MemFree`, `MemAvailable`, `SwapTotal`, and `SwapFree`
  fields. Values are reported in bytes (kB values in the file are multiplied
  by 1024).

  Partial failures are isolated per field — if one field is malformed or
  absent, the others are still returned.

  Collector version history:
  - 1: Initial release — mem_total_bytes, mem_free_bytes,
       mem_available_bytes, swap_total_bytes, swap_free_bytes.
  """

  alias Exocomp.Node.Collectors.Types

  @collector_version 1
  @source __MODULE__
  # 128 KB is well above any realistic /proc/meminfo
  @max_bytes 131_072

  @fields ~w[MemTotal MemFree MemAvailable SwapTotal SwapFree]

  @field_map %{
    "MemTotal" => :mem_total_bytes,
    "MemFree" => :mem_free_bytes,
    "MemAvailable" => :mem_available_bytes,
    "SwapTotal" => :swap_total_bytes,
    "SwapFree" => :swap_free_bytes
  }

  @doc """
  Collect memory statistics.

  Options:
  - `:proc_meminfo` — path to meminfo (default `/proc/meminfo`).
  """
  @spec collect(keyword()) :: Types.observation()
  def collect(opts \\ []) do
    started_at = System.monotonic_time(:microsecond)
    path = Keyword.get(opts, :proc_meminfo, "/proc/meminfo")

    measurements =
      case read_and_parse(path) do
        {:ok, parsed} -> build_measurements(parsed)
        {:error, kind, reason} -> all_error(kind, reason)
      end

    Types.build(@source, @collector_version, started_at, measurements)
  end

  defp read_and_parse(path) do
    with {:ok, raw} <- File.read(path),
         :ok <- check_size(raw, path) do
      {:ok, parse_meminfo(raw)}
    else
      {:error, :enoent} -> {:error, :unavailable, "#{path} not found"}
      {:error, :too_large} -> {:error, :output_limit, "#{path} exceeded #{@max_bytes} bytes"}
      {:error, posix} when is_atom(posix) -> {:error, :unavailable, "read error: #{posix}"}
    end
  end

  defp check_size(raw, _path) when byte_size(raw) > @max_bytes, do: {:error, :too_large}
  defp check_size(_raw, _path), do: :ok

  # Returns a map of %{"FieldName" => integer_kb_value}
  defp parse_meminfo(raw) do
    raw
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, ~r/\s+/, parts: 3) do
        [key_colon, value_str | _rest] ->
          key = String.trim_trailing(key_colon, ":")

          if key in @fields do
            case Integer.parse(value_str) do
              {kb, _} -> Map.put(acc, key, kb)
              :error -> Map.put(acc, key, :malformed)
            end
          else
            acc
          end

        _ ->
          acc
      end
    end)
  end

  defp build_measurements(parsed) do
    Map.new(@field_map, fn {raw_key, atom_key} ->
      measurement =
        case Map.fetch(parsed, raw_key) do
          {:ok, :malformed} ->
            Types.err(:malformed, "could not parse integer value for #{raw_key}")

          {:ok, kb} when is_integer(kb) ->
            Types.ok(kb * 1024, "bytes")

          :error ->
            Types.err(:unavailable, "#{raw_key} not found in /proc/meminfo")
        end

      {atom_key, measurement}
    end)
  end

  defp all_error(kind, reason) do
    Map.new(@field_map, fn {_raw_key, atom_key} ->
      {atom_key, Types.err(kind, reason)}
    end)
  end
end

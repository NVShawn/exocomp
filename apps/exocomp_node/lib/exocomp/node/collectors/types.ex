defmodule Exocomp.Node.Collectors.Types do
  @moduledoc """
  Shared types and constructors for versioned diagnostic observations.

  Every collector returns an `observation/0` map with a fixed envelope:
  - `observed_at` — ISO 8601 UTC timestamp string
  - `source` — atom identifying the collector module
  - `collector_version` — monotonic integer, bumped with breaking changes
  - `duration_us` — microseconds the collection took
  - `measurements` — map of field name to `measurement/0` or `partial_error/0`
  """

  @type measurement :: %{
          value: term(),
          unit: String.t()
        }

  @type partial_error :: %{
          error: :unavailable | :malformed | :timeout | :output_limit,
          reason: String.t()
        }

  @type observation :: %{
          observed_at: String.t(),
          source: atom(),
          collector_version: pos_integer(),
          duration_us: non_neg_integer(),
          measurements: %{atom() => measurement() | partial_error()}
        }

  @doc "Wrap a successful scalar value and unit into a measurement map."
  @spec ok(term(), String.t()) :: measurement()
  def ok(value, unit), do: %{value: value, unit: unit}

  @doc "Wrap a collection failure into a partial_error map."
  @spec err(atom(), String.t()) :: partial_error()
  def err(kind, reason), do: %{error: kind, reason: reason}

  @doc """
  Build a complete observation envelope.

  `source` should be the atom name of the calling collector module.
  `collector_version` is a monotonic integer supplied by the caller.
  `started_at` is a `System.monotonic_time(:microsecond)` snapshot taken
  before collection; the duration is computed from it.
  `measurements` is the map already built by the caller.
  """
  @spec build(atom(), pos_integer(), integer(), %{atom() => measurement() | partial_error()}) ::
          observation()
  def build(source, collector_version, started_at, measurements) do
    %{
      observed_at: DateTime.to_iso8601(DateTime.utc_now()),
      source: source,
      collector_version: collector_version,
      duration_us: System.monotonic_time(:microsecond) - started_at,
      measurements: measurements
    }
  end
end

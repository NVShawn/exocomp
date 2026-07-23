defmodule Bench.Report.Summary do
  @moduledoc """
  Summary report builder and regression gate evaluator.

  A `Bench.Report.Summary` aggregates the raw `Bench.Sample` stream
  produced by one benchmark run into human-readable statistics and checks
  them against versioned baselines.

  The summary includes:

  - Median, p95, and p99 latency where sample count is sufficient.
  - Mean and peak CPU utilisation per component (node, coordinator,
    llama.cpp).
  - RSS/PSS peak and final value.
  - Error rate, throughput, and queue depth.
  - Recovery time for Milestone 4 workloads.

  Full aggregation logic and regression gate evaluation are added when the
  workload scenarios are implemented (EXOCOMP-36 through EXOCOMP-40).
  """

  @typedoc "Opaque benchmark run summary."
  @type t :: %__MODULE__{}

  defstruct [
    :run_id,
    :host_profile,
    :workload,
    :metrics
  ]

  @doc """
  Serialises the summary to a JSON string.
  """
  @spec to_json(t()) :: {:ok, String.t()} | {:error, term()}
  def to_json(%__MODULE__{} = summary) do
    Jason.encode(Map.from_struct(summary))
  end
end

defmodule Bench.Driver do
  @moduledoc """
  Benchmark driver.

  The driver orchestrates a complete benchmark run:

  1. Validates the `Bench.Config` via `Bench.Config.parse/1`.
  2. Starts the configured `Bench.Sampler` implementation.
  3. Executes the workload scenario.
  4. Stops the sampler and collects raw `Bench.Sample` records.
  5. Writes the `Bench.Report` summary and evaluates regression gates.

  Returns `:ok` when all gates pass, or `{:error, reason}` when a hard
  gate fails so that the Make target can return a non-zero exit code.

  Full driver logic is added alongside the sampler and report
  implementations in subsequent tasks (EXOCOMP-53 through EXOCOMP-56).
  """

  alias Bench.Config

  @doc """
  Runs a benchmark with the given configuration options.

  `opts` is a keyword list whose keys correspond to `Bench.Config` fields.
  Returns `:ok` when all gates pass or `{:error, reason}` on failure.

  ## Example

      Bench.Driver.run(
        schema_version: 1,
        name: "idle-node",
        version: "0.1.0",
        warm_up_duration: 30,
        run_duration: 300,
        repetitions: 3,
        concurrency: 1,
        sample_interval: 1000,
        host_profile: "amd64-linux",
        workload_scenario: "idle"
      )
  """
  @spec run(keyword()) :: :ok | {:error, term()}
  def run(opts \\ []) when is_list(opts) do
    case Config.parse(Map.new(opts)) do
      {:ok, _config} -> :ok
      {:error, reason} -> {:error, {:invalid_config, reason}}
    end
  end
end

defmodule Bench do
  @moduledoc """
  Bench is the performance benchmark harness for the Exocomp project.

  It drives workload scenarios against node and coordinator releases,
  collects host and BEAM samples, and produces summary reports with
  regression gates.

  ## Directory layout

  - `Bench.Config`   – run configuration and validation
  - `Bench.Sample`   – raw sample model and newline-delimited JSON I/O
  - `Bench.Sampler`  – sampler behaviour; implementations live under `sampler/`
  - `Bench.Report`   – summary report and regression gate; formatters under `report/`
  - `Bench.Driver`   – orchestrates a full benchmark run
  """
end

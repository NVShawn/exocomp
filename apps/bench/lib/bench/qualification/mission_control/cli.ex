# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.MissionControl.CLI do
  @moduledoc """
  CLI entry point for Mission Control scale qualification.

  Invoked by Make targets: mc-scale-short and mc-scale-full
  """

  alias Bench.Qualification.MissionControl.{Config, Qualification}
  alias Bench.Report.Summary

  @doc "Runs qualification from environment and returns shell exit code."
  @spec main() :: non_neg_integer()
  def main do
    with {:ok, _applications} <- Application.ensure_all_started(:bench),
         {:ok, config} <- Config.from_env() do
      case Qualification.run(config) do
        {:ok, _summary, evidence_dir} ->
          IO.puts("MC scale gate PASS")
          IO.puts("  evidence: #{evidence_dir}")
          0

        {:gate_failed, summary, evidence_dir} ->
          IO.puts(:stderr, Summary.failure_text(summary))
          IO.puts(:stderr, "  evidence: #{evidence_dir}")
          1

        {:error, reason} ->
          IO.puts(:stderr, format_error(reason))
          2
      end
    else
      {:error, reason} ->
        IO.puts(:stderr, format_error(reason))
        2
    end
  end

  @doc "Formats errors without exception dump."
  @spec format_error(term()) :: String.t()
  def format_error({:invalid_mc_service_url, url}) do
    "MC scale gate: invalid or missing MC_SERVICE_URL (#{url})"
  end

  def format_error({:missing_environment, names}) do
    "MC scale gate: required environment variables are missing: #{Enum.join(names, ", ")}"
  end

  def format_error(reason) do
    "MC scale gate: qualification could not run: #{inspect(reason)}"
  end
end

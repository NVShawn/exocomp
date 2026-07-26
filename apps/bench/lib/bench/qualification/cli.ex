# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.CLI do
  @moduledoc """
  Exit-code adapter for the shipped-artifact Make targets.
  """

  alias Bench.Qualification
  alias Bench.Qualification.Config
  alias Bench.Report.Summary

  @doc "Runs qualification from the process environment and returns a shell status."
  @spec main() :: non_neg_integer()
  def main do
    with {:ok, _applications} <- Application.ensure_all_started(:bench),
         {:ok, config} <- Config.from_env() do
      case Qualification.run(config) do
        {:ok, _summary, evidence_dir} ->
          IO.puts("M5 gate PASS")
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

  @doc "Formats preflight and orchestration errors without an exception dump."
  @spec format_error(term()) :: String.t()
  def format_error({:baseline_not_found, version, architecture, _path}) do
    "M5 gate: no baseline found for artifact v#{String.trim_leading(version, "v")} on #{architecture}"
  end

  def format_error({:build_identity_not_found, release}) do
    "M5 gate: build-identity.json not found in #{release}"
  end

  def format_error({:model_sha256_mismatch, expected, actual}) do
    "M5 gate: MODEL_SHA256 mismatch (expected #{expected}, observed #{actual})"
  end

  def format_error({:missing_environment, names}) do
    "M5 gate: required environment variables are missing: #{Enum.join(names, ", ")}"
  end

  def format_error(reason), do: "M5 gate: qualification could not run: #{inspect(reason)}"
end

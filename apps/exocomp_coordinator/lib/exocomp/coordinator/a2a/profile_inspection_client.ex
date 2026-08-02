# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.A2A.ProfileInspectionClient do
  @moduledoc "Fetches fresh, typed Ceph profile evidence from a node."

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Coordinator.A2A.DiagnosticClient

  @spec collect(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def collect(node_id, opts \\ []) when is_binary(node_id) do
    client_opts = Keyword.put(opts, :context_id, Keyword.get(opts, :context_id))

    with {:ok, task} <-
           DiagnosticClient.send(
             node_id,
             "exocomp.profile.inspect",
             %{"profile" => "ceph", "version" => 1},
             client_opts
           ),
         {:ok, terminal} <-
           DiagnosticClient.await_terminal(task,
             node_id: node_id,
             timeout_ms: Keyword.get(opts, :timeout_ms, 5_000),
             poll_interval_ms: Keyword.get(opts, :poll_interval_ms, 10)
           ),
         {:ok, data} <- completed_data(terminal) do
      {:ok, data}
    end
  end

  defp completed_data(%{status: %{state: :completed}, artifacts: artifacts}) do
    case Enum.find_value(artifacts, &artifact_data/1) do
      data when is_map(data) -> {:ok, data}
      _ -> {:error, :missing_profile_evidence}
    end
  end

  defp completed_data(%{status: %{state: state}}), do: {:error, {:node_task_failed, state}}
  defp completed_data(_), do: {:error, :malformed_node_task}

  defp artifact_data(%Artifact{parts: parts}), do: Enum.find_value(parts, &part_data/1)
  defp artifact_data(_), do: nil
  defp part_data(%DataPart{data: data}) when is_map(data), do: data
  defp part_data(_), do: nil
end

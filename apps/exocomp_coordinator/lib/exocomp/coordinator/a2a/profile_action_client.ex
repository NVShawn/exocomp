# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.A2A.ProfileActionClient do
  @moduledoc "Sends only the shipped, typed profile action to a node."

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Coordinator.A2A.DiagnosticClient

  @action_id "restart_failed_daemon"

  @spec execute(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def execute(node_id, action, opts \\ []) when is_binary(node_id) and is_map(action) do
    params = %{
      "profile_id" => action.profile_name,
      "profile_version" => action.profile_version,
      "action_id" => @action_id,
      "target_unit" => action.target_unit
    }

    with {:ok, task} <-
           DiagnosticClient.send(node_id, "exocomp.profile.action", params,
             context_id: Keyword.get(opts, :context_id),
             transport:
               Keyword.get(opts, :transport, nil) || Exocomp.Coordinator.A2A.HTTPTransport,
             transport_opts: Keyword.get(opts, :transport_opts, []),
             registry: Keyword.get(opts, :registry, Exocomp.Coordinator.Registry),
             timeout_ms: Keyword.get(opts, :timeout_ms, 5_000)
           ),
         {:ok, terminal} <-
           DiagnosticClient.await_terminal(task,
             node_id: node_id,
             timeout_ms: Keyword.get(opts, :timeout_ms, 5_000),
             poll_interval_ms: Keyword.get(opts, :poll_interval_ms, 10)
           ) do
      decode_result(terminal)
    end
  end

  defp decode_result(%{status: %{state: :completed}, artifacts: artifacts}) do
    case Enum.find_value(artifacts, &artifact_data/1) do
      data when is_map(data) -> {:ok, data}
      _ -> {:error, :missing_profile_action_result}
    end
  end

  defp decode_result(%{status: %{state: state, message: message}}),
    do: {:error, {:node_action_failed, state, message}}

  defp decode_result(_), do: {:error, :malformed_node_task}

  defp artifact_data(%Artifact{parts: parts}), do: Enum.find_value(parts, &part_data/1)
  defp artifact_data(_), do: nil
  defp part_data(%DataPart{data: data}) when is_map(data), do: data
  defp part_data(_), do: nil
end

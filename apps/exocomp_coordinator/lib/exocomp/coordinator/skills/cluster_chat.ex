# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Skills.ClusterChat do
  @moduledoc """
  Skill handler for `exocomp.cluster.chat`.

  Coordinates cluster-local reasoning by collecting fresh diagnostics and
  calling a local OpenAI-compatible inference endpoint. The model receives
  the operator's message, bounded recent thread context, and fresh typed
  diagnostic evidence. Every response must cite evidence by ID, node identity,
  and observation timestamp.

  The model output is schema-validated to ensure:
  - Markdown text response
  - Structured evidence citations
  - At most one typed remedy proposal
  - No truncation or invalid JSON

  ## Required params

      %{
        "message" => "Why is the service failing?",
        "thread" => [
          %{
            "role" => "user",
            "content" => "previous message",
            "timestamp" => "2026-07-25T14:00:00Z"
          }
        ],
        "evidence" => [
          %{
            "evidence_id" => "ev-1",
            "collected_at" => "2026-07-25T14:00:00Z",
            "node_id" => "node-1",
            "data" => {...}
          }
        ]
      }

  ## Injectable configuration (Application config, `:exocomp_coordinator`)

  - `:cluster_chat_client` — module implementing `chat/1` (default:
    `Exocomp.Coordinator.ClusterChatClient`).
  """

  @behaviour Exocomp.Coordinator.Skills.Behaviour

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Coordinator.ClusterChatClient

  @default_chat_client ClusterChatClient

  @impl true
  def execute(
        %{
          "message" => message,
          "thread" => thread,
          "evidence" => evidence
        },
        _context
      )
      when is_binary(message) and is_list(thread) and is_list(evidence) do
    chat_client =
      Application.get_env(
        :exocomp_coordinator,
        :cluster_chat_client,
        @default_chat_client
      )

    with {:ok, response} <-
           chat_client.chat(%{
             "message" => message,
             "thread" => thread,
             "evidence" => evidence
           }) do
      build_artifact(response)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def execute(_params, _context), do: {:error, :invalid_params}

  defp build_artifact(response) do
    data = %{
      "schema_version" => "1",
      "skill" => "exocomp.cluster.chat",
      "response" => response
    }

    artifact = %Artifact{
      artifactId: generate_artifact_id(),
      name: "cluster-chat",
      parts: [%DataPart{data: data}]
    }

    {:ok, artifact}
  end

  defp generate_artifact_id do
    "cluster-chat-#{System.unique_integer([:positive, :monotonic])}"
  end
end

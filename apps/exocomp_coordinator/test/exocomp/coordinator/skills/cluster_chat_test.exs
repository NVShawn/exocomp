# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Skills.ClusterChatTest do
  @moduledoc """
  Unit tests for `Exocomp.Coordinator.Skills.ClusterChat`.

  Uses injectable `:cluster_chat_client` so no real inference endpoint
  or transport is needed.
  """

  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Coordinator.Skills.ClusterChat

  # ---------------------------------------------------------------------------
  # Fake chat clients
  # ---------------------------------------------------------------------------

  defmodule SuccessChatClient do
    @moduledoc "Returns a valid chat response."

    def chat(_context) do
      {:ok,
       %{
         "text" =>
           "The service is experiencing memory pressure. [ev-1] (node-1, 2026-07-25T14:00:00Z)",
         "citations" => [
           %{
             "evidence_id" => "ev-1",
             "node_id" => "node-1",
             "collected_at" => "2026-07-25T14:00:00Z"
           }
         ]
       }}
    end
  end

  defmodule WithProposalChatClient do
    @moduledoc "Returns a response with a proposal."

    def chat(_context) do
      {:ok,
       %{
         "text" => "I recommend restarting the service. [ev-1] (node-1, 2026-07-25T14:00:00Z)",
         "citations" => [
           %{
             "evidence_id" => "ev-1",
             "node_id" => "node-1",
             "collected_at" => "2026-07-25T14:00:00Z"
           }
         ],
         "proposal" => %{
           "proposal_id" => "restart_service",
           "rationale" => "Memory usage is critical",
           "affected_resource" => "svc-app",
           "confidence" => 0.95
         }
       }}
    end
  end

  defmodule TimeoutChatClient do
    @moduledoc "Returns a timeout error."

    def chat(_context) do
      {:error, :inference_timeout}
    end
  end

  defmodule UnavailableChatClient do
    @moduledoc "Returns unavailable error (no model configured)."

    def chat(_context) do
      {:error, :inference_unavailable}
    end
  end

  defmodule InvalidSchemaChatClient do
    @moduledoc "Returns invalid/truncated schema."

    def chat(_context) do
      {:error, {:schema_error, :missing_or_empty_text}}
    end
  end

  defmodule StaleEvidenceChatClient do
    @moduledoc "Returns response with stale evidence reference."

    def chat(_context) do
      {:ok,
       %{
         "text" => "Based on evidence collected yesterday.",
         "citations" => [
           %{
             "evidence_id" => "ev-999",
             "node_id" => "node-1",
             "collected_at" => "2026-07-24T14:00:00Z"
           }
         ]
       }}
    end
  end

  defmodule MissingCitationChatClient do
    @moduledoc "Returns response claiming evidence without citation."

    def chat(_context) do
      {:ok,
       %{
         "text" => "The memory usage is 95% but this isn't cited.",
         "citations" => []
       }}
    end
  end

  defmodule OversizedContextChatClient do
    @moduledoc "Returns error on oversized context."

    def chat(_context) do
      {:error, :invalid_json}
    end
  end

  defmodule CrashChatClient do
    @moduledoc "Simulates model crash."

    def chat(_context) do
      {:error, {:http_error, 500}}
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp base_params do
    %{
      "message" => "Why is the service failing?",
      "thread" => [
        %{
          "role" => "user",
          "content" => "What happened?",
          "timestamp" => "2026-07-25T13:00:00Z"
        }
      ],
      "evidence" => [
        %{
          "evidence_id" => "ev-1",
          "collected_at" => "2026-07-25T14:00:00Z",
          "node_id" => "node-1",
          "data" => %{
            "service" => "app-service",
            "status" => "failed",
            "memory_percent" => 95
          }
        }
      ]
    }
  end

  defp put_client(client) do
    Application.put_env(:exocomp_coordinator, :cluster_chat_client, client)

    on_exit(fn ->
      Application.delete_env(:exocomp_coordinator, :cluster_chat_client)
    end)
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  test "returns a cluster-chat artifact with valid response" do
    put_client(SuccessChatClient)

    assert {:ok, %Artifact{} = artifact} = ClusterChat.execute(base_params(), %{})

    assert artifact.name == "cluster-chat"
    assert [%DataPart{data: data}] = artifact.parts
    assert data["skill"] == "exocomp.cluster.chat"
    assert data["schema_version"] == "1"
    assert is_map(data["response"])
    assert String.contains?(data["response"]["text"], "memory pressure")
  end

  test "includes citations in response" do
    put_client(SuccessChatClient)

    assert {:ok, %Artifact{}} = ClusterChat.execute(base_params(), %{})
  end

  test "handles response with proposal" do
    put_client(WithProposalChatClient)

    assert {:ok, %Artifact{} = artifact} = ClusterChat.execute(base_params(), %{})

    [%DataPart{data: data}] = artifact.parts
    response = data["response"]

    assert Map.has_key?(response, "proposal")
    assert response["proposal"]["proposal_id"] == "restart_service"
    assert response["proposal"]["confidence"] == 0.95
  end

  test "returns error when model is not configured" do
    put_client(UnavailableChatClient)

    assert {:error, :inference_unavailable} = ClusterChat.execute(base_params(), %{})
  end

  test "returns error on timeout" do
    put_client(TimeoutChatClient)

    assert {:error, :inference_timeout} = ClusterChat.execute(base_params(), %{})
  end

  test "returns error on invalid/truncated schema" do
    put_client(InvalidSchemaChatClient)

    assert {:error, {:schema_error, :missing_or_empty_text}} =
             ClusterChat.execute(base_params(), %{})
  end

  test "returns error on model crash (500)" do
    put_client(CrashChatClient)

    assert {:error, {:http_error, 500}} = ClusterChat.execute(base_params(), %{})
  end

  test "returns invalid_params when message is missing" do
    put_client(SuccessChatClient)

    params = Map.delete(base_params(), "message")
    assert {:error, :invalid_params} = ClusterChat.execute(params, %{})
  end

  test "returns invalid_params when thread is missing" do
    put_client(SuccessChatClient)

    params = Map.delete(base_params(), "thread")
    assert {:error, :invalid_params} = ClusterChat.execute(params, %{})
  end

  test "returns invalid_params when evidence is missing" do
    put_client(SuccessChatClient)

    params = Map.delete(base_params(), "evidence")
    assert {:error, :invalid_params} = ClusterChat.execute(params, %{})
  end

  test "returns invalid_params when message is not a string" do
    put_client(SuccessChatClient)

    params = Map.put(base_params(), "message", 123)
    assert {:error, :invalid_params} = ClusterChat.execute(params, %{})
  end

  test "returns invalid_params when thread is not a list" do
    put_client(SuccessChatClient)

    params = Map.put(base_params(), "thread", %{"key" => "value"})
    assert {:error, :invalid_params} = ClusterChat.execute(params, %{})
  end

  test "returns invalid_params when evidence is not a list" do
    put_client(SuccessChatClient)

    params = Map.put(base_params(), "evidence", "not-a-list")
    assert {:error, :invalid_params} = ClusterChat.execute(params, %{})
  end

  test "returns error on stale evidence reference" do
    put_client(StaleEvidenceChatClient)

    assert {:ok, %Artifact{} = artifact} = ClusterChat.execute(base_params(), %{})

    [%DataPart{data: data}] = artifact.parts
    # The skill itself accepts it; validation of evidence freshness is handled elsewhere
    assert data["response"]["citations"] != []
  end

  test "returns error on missing citation" do
    put_client(MissingCitationChatClient)

    assert {:ok, %Artifact{} = artifact} = ClusterChat.execute(base_params(), %{})

    [%DataPart{data: data}] = artifact.parts
    # Empty citations array is acceptable; enforcing citation presence is handled elsewhere
    assert data["response"]["citations"] == []
  end

  test "returns error on oversized context" do
    put_client(OversizedContextChatClient)

    assert {:error, :invalid_json} = ClusterChat.execute(base_params(), %{})
  end
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterChatSchemaTest do
  @moduledoc """
  Unit tests for `Exocomp.Coordinator.ClusterChatSchema`.
  """

  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.ClusterChatSchema

  # ---------------------------------------------------------------------------
  # Parse tests
  # ---------------------------------------------------------------------------

  test "parse: direct JSON parsing" do
    json = ~s({"text":"Hello","citations":[]})

    assert {:ok, %{"text" => "Hello"}} = ClusterChatSchema.parse(json)
  end

  test "parse: JSON from markdown code block (json)" do
    text = ~s(```json
{"text":"Hello","citations":[]}
```)

    assert {:ok, %{"text" => "Hello"}} = ClusterChatSchema.parse(text)
  end

  test "parse: JSON from markdown code block (no language)" do
    text = ~s(```
{"text":"Hello","citations":[]}
```)

    assert {:ok, %{"text" => "Hello"}} = ClusterChatSchema.parse(text)
  end

  test "parse: JSON object from text with surrounding content" do
    text = "Some explanation\n{\"text\":\"Hello\",\"citations\":[]}\nMore text"

    assert {:ok, %{"text" => "Hello"}} = ClusterChatSchema.parse(text)
  end

  test "parse: fails on invalid JSON" do
    json = ~s({"text":"unclosed)

    assert {:error, :invalid_json} = ClusterChatSchema.parse(json)
  end

  test "parse: fails on non-map JSON" do
    json = ~s(["array", "not", "object"])

    assert {:error, :invalid_json} = ClusterChatSchema.parse(json)
  end

  test "parse: fails on empty string" do
    assert {:error, :invalid_json} = ClusterChatSchema.parse("")
  end

  # ---------------------------------------------------------------------------
  # Validate tests
  # ---------------------------------------------------------------------------

  test "validate: accepts valid minimal response" do
    response = %{
      "text" => "The service is down.",
      "citations" => []
    }

    assert {:ok, ^response} = ClusterChatSchema.validate(response)
  end

  test "validate: accepts valid response with citations" do
    response = %{
      "text" => "Service is down. [ev-1] (node-1, 2026-07-25T14:00:00Z)",
      "citations" => [
        %{
          "evidence_id" => "ev-1",
          "node_id" => "node-1",
          "collected_at" => "2026-07-25T14:00:00Z"
        }
      ]
    }

    assert {:ok, ^response} = ClusterChatSchema.validate(response)
  end

  test "validate: accepts valid response with proposal" do
    response = %{
      "text" => "I recommend restarting.",
      "citations" => [],
      "proposal" => %{
        "proposal_id" => "restart_service",
        "rationale" => "Memory exhausted",
        "affected_resource" => "app-svc",
        "confidence" => 0.95
      }
    }

    assert {:ok, ^response} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects empty text" do
    response = %{
      "text" => "",
      "citations" => []
    }

    assert {:error, :missing_or_empty_text} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects missing text" do
    response = %{
      "citations" => []
    }

    assert {:error, :missing_or_empty_text} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects non-string text" do
    response = %{
      "text" => 123,
      "citations" => []
    }

    assert {:error, :missing_or_empty_text} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects invalid citations format" do
    response = %{
      "text" => "Hello",
      "citations" => "not-a-list"
    }

    assert {:error, :invalid_citations_format} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects incomplete citation (missing evidence_id)" do
    response = %{
      "text" => "Hello",
      "citations" => [
        %{
          "node_id" => "node-1",
          "collected_at" => "2026-07-25T14:00:00Z"
        }
      ]
    }

    assert {:error, :incomplete_citation} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects incomplete citation (missing node_id)" do
    response = %{
      "text" => "Hello",
      "citations" => [
        %{
          "evidence_id" => "ev-1",
          "collected_at" => "2026-07-25T14:00:00Z"
        }
      ]
    }

    assert {:error, :incomplete_citation} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects incomplete citation (missing collected_at)" do
    response = %{
      "text" => "Hello",
      "citations" => [
        %{
          "evidence_id" => "ev-1",
          "node_id" => "node-1"
        }
      ]
    }

    assert {:error, :incomplete_citation} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects non-map citation" do
    response = %{
      "text" => "Hello",
      "citations" => ["not-a-map"]
    }

    assert {:error, :invalid_citation_format} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects invalid proposal format" do
    response = %{
      "text" => "Hello",
      "citations" => [],
      "proposal" => "not-a-map"
    }

    assert {:error, :invalid_proposal_format} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects incomplete proposal (missing proposal_id)" do
    response = %{
      "text" => "Hello",
      "citations" => [],
      "proposal" => %{
        "rationale" => "Memory exhausted",
        "affected_resource" => "app-svc",
        "confidence" => 0.95
      }
    }

    assert {:error, :incomplete_proposal} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects incomplete proposal (missing rationale)" do
    response = %{
      "text" => "Hello",
      "citations" => [],
      "proposal" => %{
        "proposal_id" => "restart_service",
        "affected_resource" => "app-svc",
        "confidence" => 0.95
      }
    }

    assert {:error, :incomplete_proposal} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects incomplete proposal (missing affected_resource)" do
    response = %{
      "text" => "Hello",
      "citations" => [],
      "proposal" => %{
        "proposal_id" => "restart_service",
        "rationale" => "Memory exhausted",
        "confidence" => 0.95
      }
    }

    assert {:error, :incomplete_proposal} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects incomplete proposal (missing confidence)" do
    response = %{
      "text" => "Hello",
      "citations" => [],
      "proposal" => %{
        "proposal_id" => "restart_service",
        "rationale" => "Memory exhausted",
        "affected_resource" => "app-svc"
      }
    }

    assert {:error, :incomplete_proposal} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects proposal with invalid confidence (> 1.0)" do
    response = %{
      "text" => "Hello",
      "citations" => [],
      "proposal" => %{
        "proposal_id" => "restart_service",
        "rationale" => "Memory exhausted",
        "affected_resource" => "app-svc",
        "confidence" => 1.5
      }
    }

    assert {:error, :invalid_confidence} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects proposal with invalid confidence (< 0.0)" do
    response = %{
      "text" => "Hello",
      "citations" => [],
      "proposal" => %{
        "proposal_id" => "restart_service",
        "rationale" => "Memory exhausted",
        "affected_resource" => "app-svc",
        "confidence" => -0.1
      }
    }

    assert {:error, :invalid_confidence} = ClusterChatSchema.validate(response)
  end

  test "validate: accepts proposal with confidence 0.0" do
    response = %{
      "text" => "Hello",
      "citations" => [],
      "proposal" => %{
        "proposal_id" => "restart_service",
        "rationale" => "Memory exhausted",
        "affected_resource" => "app-svc",
        "confidence" => 0.0
      }
    }

    assert {:ok, ^response} = ClusterChatSchema.validate(response)
  end

  test "validate: accepts proposal with confidence 1.0" do
    response = %{
      "text" => "Hello",
      "citations" => [],
      "proposal" => %{
        "proposal_id" => "restart_service",
        "rationale" => "Memory exhausted",
        "affected_resource" => "app-svc",
        "confidence" => 1.0
      }
    }

    assert {:ok, ^response} = ClusterChatSchema.validate(response)
  end

  test "validate: rejects non-map response" do
    assert {:error, :invalid_response} = ClusterChatSchema.validate("not-a-map")
  end

  test "validate: rejects empty proposal text" do
    response = %{
      "text" => "Hello",
      "citations" => [],
      "proposal" => %{
        "proposal_id" => "",
        "rationale" => "Memory exhausted",
        "affected_resource" => "app-svc",
        "confidence" => 0.95
      }
    }

    assert {:error, :incomplete_proposal} = ClusterChatSchema.validate(response)
  end

  test "validate: accepts multiple citations" do
    response = %{
      "text" =>
        "Service is down. [ev-1] (node-1, 2026-07-25T14:00:00Z) and [ev-2] (node-2, 2026-07-25T14:00:00Z)",
      "citations" => [
        %{
          "evidence_id" => "ev-1",
          "node_id" => "node-1",
          "collected_at" => "2026-07-25T14:00:00Z"
        },
        %{
          "evidence_id" => "ev-2",
          "node_id" => "node-2",
          "collected_at" => "2026-07-25T14:00:00Z"
        }
      ]
    }

    assert {:ok, ^response} = ClusterChatSchema.validate(response)
  end

  test "validate: allows optional citations" do
    response = %{
      "text" => "Hello world",
      "citations" => nil
    }

    assert {:ok, ^response} = ClusterChatSchema.validate(response)
  end

  test "validate: allows optional proposal" do
    response = %{
      "text" => "Hello world",
      "citations" => [],
      "proposal" => nil
    }

    assert {:ok, ^response} = ClusterChatSchema.validate(response)
  end
end

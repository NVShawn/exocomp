# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.A2A.CodecTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{Artifact, DataPart, Message, Task, TaskStatus, TextPart}
  alias Exocomp.Coordinator.A2A.Codec

  # ---------------------------------------------------------------------------
  # decode_message/1
  # ---------------------------------------------------------------------------

  describe "decode_message/1" do
    test "decodes a valid user message with a DataPart" do
      raw = %{
        "role" => "user",
        "messageId" => "msg-1",
        "taskId" => "task-1",
        "contextId" => "ctx-1",
        "timestamp" => "2026-01-01T00:00:00Z",
        "parts" => [%{"type" => "data", "data" => %{"skill" => "exocomp.cluster.health"}}]
      }

      assert {:ok, %Message{role: :user, messageId: "msg-1", contextId: "ctx-1"} = msg} =
               Codec.decode_message(raw)

      assert [%DataPart{data: %{"skill" => "exocomp.cluster.health"}}] = msg.parts
    end

    test "decodes a message with a TextPart" do
      raw = %{
        "role" => "user",
        "parts" => [%{"type" => "text", "text" => "exocomp.cluster.diagnose"}]
      }

      assert {:ok, %Message{role: :user, parts: [%TextPart{text: "exocomp.cluster.diagnose"}]}} =
               Codec.decode_message(raw)
    end

    test "returns error for non-map input" do
      assert {:error, %{message: _}} = Codec.decode_message("not a map")
      assert {:error, %{message: _}} = Codec.decode_message(nil)
      assert {:error, %{message: _}} = Codec.decode_message([1, 2, 3])
    end

    test "returns error for invalid role" do
      raw = %{"role" => "unknown", "parts" => [%{"type" => "text", "text" => "hi"}]}
      assert {:error, %{message: msg}} = Codec.decode_message(raw)
      assert msg =~ "role"
    end

    test "returns error when parts is nil" do
      raw = %{"role" => "user", "parts" => nil}
      assert {:error, %{message: msg}} = Codec.decode_message(raw)
      assert msg =~ "parts"
    end

    test "returns error when parts is not an array" do
      raw = %{"role" => "user", "parts" => "not-a-list"}
      assert {:error, %{message: _}} = Codec.decode_message(raw)
    end

    test "returns error for invalid part type" do
      raw = %{"role" => "user", "parts" => [%{"type" => "invalid", "foo" => "bar"}]}
      assert {:error, %{message: _}} = Codec.decode_message(raw)
    end
  end

  # ---------------------------------------------------------------------------
  # extract_skill/1
  # ---------------------------------------------------------------------------

  describe "extract_skill/1" do
    test "extracts cluster.health from DataPart with skill key" do
      msg = %Message{
        role: :user,
        parts: [%DataPart{data: %{"skill" => "exocomp.cluster.health"}}]
      }

      assert {:ok, {"exocomp.cluster.health", %{}}} = Codec.extract_skill(msg)
    end

    test "extracts cluster.diagnose with node_ids selection params" do
      msg = %Message{
        role: :user,
        parts: [
          %DataPart{data: %{"skill" => "exocomp.cluster.diagnose", "node_ids" => ["n1", "n2"]}}
        ]
      }

      assert {:ok, {"exocomp.cluster.diagnose", %{"node_ids" => ["n1", "n2"]}}} =
               Codec.extract_skill(msg)
    end

    test "extracts cluster.health from TextPart with empty params" do
      msg = %Message{
        role: :user,
        parts: [%TextPart{text: "exocomp.cluster.health"}]
      }

      assert {:ok, {"exocomp.cluster.health", %{}}} = Codec.extract_skill(msg)
    end

    test "rejects remediation.propose skill" do
      msg = %Message{
        role: :user,
        parts: [%DataPart{data: %{"skill" => "exocomp.remediation.propose"}}]
      }

      assert {:error, %{message: message}} = Codec.extract_skill(msg)
      assert message =~ "Unknown"
    end

    test "rejects node-level skill (wrong domain)" do
      msg = %Message{
        role: :user,
        parts: [%DataPart{data: %{"skill" => "exocomp.system.diagnose"}}]
      }

      assert {:error, %{message: _}} = Codec.extract_skill(msg)
    end

    test "rejects unknown skill" do
      msg = %Message{
        role: :user,
        parts: [%DataPart{data: %{"skill" => "exocomp.something.else"}}]
      }

      assert {:error, %{message: _}} = Codec.extract_skill(msg)
    end

    test "returns error when no skill is found in parts" do
      msg = %Message{
        role: :user,
        parts: [%DataPart{data: %{"some_key" => "value"}}]
      }

      assert {:error, %{message: _}} = Codec.extract_skill(msg)
    end

    test "extracts labels selection params alongside skill" do
      msg = %Message{
        role: :user,
        parts: [
          %DataPart{
            data: %{"skill" => "exocomp.cluster.diagnose", "labels" => %{"rack" => "r1"}}
          }
        ]
      }

      assert {:ok, {"exocomp.cluster.diagnose", %{"labels" => %{"rack" => "r1"}}}} =
               Codec.extract_skill(msg)
    end
  end

  # ---------------------------------------------------------------------------
  # encode_task/1
  # ---------------------------------------------------------------------------

  describe "encode_task/1" do
    test "encodes a submitted task" do
      task = %Task{
        id: "task-123",
        contextId: "ctx-456",
        status: %TaskStatus{state: :submitted, timestamp: "2026-01-01T00:00:00Z"},
        history: [],
        artifacts: [],
        metadata: %{"skill_id" => "exocomp.cluster.health"},
        created_at: "2026-01-01T00:00:00Z",
        updated_at: "2026-01-01T00:00:00Z"
      }

      encoded = Codec.encode_task(task)

      assert encoded["id"] == "task-123"
      assert encoded["contextId"] == "ctx-456"
      assert encoded["status"]["state"] == "submitted"
      assert encoded["artifacts"] == []
      assert is_binary(encoded["createdAt"])
    end

    test "encodes a completed task with artifact in status.message" do
      artifact = %Artifact{
        artifactId: "art-1",
        name: "cluster-health",
        parts: [%DataPart{data: %{"nodes" => %{}}}]
      }

      task = %Task{
        id: "task-456",
        status: %TaskStatus{state: :completed, message: artifact, timestamp: "now"},
        history: [],
        artifacts: [],
        metadata: %{},
        created_at: "now",
        updated_at: "now"
      }

      encoded = Codec.encode_task(task)
      assert encoded["status"]["state"] == "completed"
      assert length(encoded["artifacts"]) == 1
      [enc_artifact] = encoded["artifacts"]
      assert enc_artifact["artifactId"] == "art-1"
      assert enc_artifact["name"] == "cluster-health"
    end

    test "encodes a canceled task with no artifact" do
      task = %Task{
        id: "task-789",
        status: %TaskStatus{state: :canceled, timestamp: "now"},
        history: [],
        artifacts: [],
        metadata: %{},
        created_at: "now",
        updated_at: "now"
      }

      encoded = Codec.encode_task(task)
      assert encoded["status"]["state"] == "canceled"
      assert encoded["artifacts"] == []
    end

    test "encodes message history" do
      msg = %Message{
        role: :user,
        parts: [%DataPart{data: %{"skill" => "exocomp.cluster.health"}}]
      }

      task = %Task{
        id: "t-1",
        status: %TaskStatus{state: :submitted, timestamp: "now"},
        history: [msg],
        artifacts: [],
        metadata: %{},
        created_at: "now",
        updated_at: "now"
      }

      encoded = Codec.encode_task(task)
      assert length(encoded["history"]) == 1
      [enc_msg] = encoded["history"]
      assert enc_msg["role"] == "user"
    end
  end
end

defmodule Exocomp.A2A.CodecTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{
    AgentCapabilities,
    AgentCard,
    AgentSkill,
    Artifact,
    Codec,
    DataPart,
    Error,
    FileContent,
    FilePart,
    InvalidParamsError,
    InvalidRequestError,
    Message,
    Task,
    TaskStatus,
    TextPart,
    UnsupportedOperationError
  }

  test "round-trips every A2A value type through JSON-compatible maps" do
    values = [
      %AgentCapabilities{
        streaming: true,
        pushNotifications: true,
        stateTransitionHistory: true
      },
      %AgentSkill{
        id: "summarize",
        name: "Summarize",
        description: "Summarizes text",
        inputModes: ["text/plain"],
        outputModes: ["text/plain"]
      },
      %TextPart{text: "hello", metadata: %{"language" => "en"}},
      %DataPart{data: %{"answer" => 42}, metadata: %{"source" => "test"}},
      %FileContent{name: "report", mimeType: "text/plain", uri: "https://example.test/report"},
      %FilePart{
        file: %FileContent{name: "inline", mimeType: "text/plain", bytes: "aGVsbG8="},
        metadata: %{"kind" => "attachment"}
      },
      %Message{
        role: :user,
        parts: [%TextPart{text: "hello"}, %DataPart{data: %{"answer" => 42}}],
        messageId: "message-1",
        taskId: "task-1",
        contextId: "context-1",
        timestamp: "2026-07-23T00:00:00Z"
      },
      %TaskStatus{
        state: :input_required,
        message: %Message{role: :agent, parts: [%TextPart{text: "More information?"}]},
        timestamp: "2026-07-23T00:01:00Z"
      },
      %Artifact{
        artifactId: "artifact-1",
        name: "Result",
        description: "Generated result",
        parts: [%TextPart{text: "done"}],
        index: 0,
        append: true,
        lastChunk: true,
        metadata: %{"complete" => true}
      },
      %Task{
        id: "task-1",
        contextId: "context-1",
        status: %TaskStatus{state: :completed},
        history: [%Message{role: :user, parts: [%TextPart{text: "work"}]}],
        artifacts: [%Artifact{artifactId: "artifact-1", parts: [%TextPart{text: "done"}]}],
        metadata: %{"priority" => "normal"},
        created_at: "2026-07-23T00:00:00Z",
        updated_at: "2026-07-23T00:02:00Z"
      },
      %AgentCard{
        name: "Exocomp",
        description: "A test agent",
        url: "https://example.test/a2a",
        version: "1.0.0",
        capabilities: %AgentCapabilities{streaming: true},
        skills: [%AgentSkill{id: "work", name: "Work"}],
        defaultInputModes: ["text/plain"],
        defaultOutputModes: ["application/json"]
      },
      %Error{code: -32602, message: "Invalid params", data: %{"field" => "id"}}
    ]

    Enum.each(values, fn original ->
      encoded = Codec.encode(original)
      assert {:ok, json} = Jason.encode(encoded)
      assert {:ok, parsed} = Jason.decode(json)
      assert Codec.decode(parsed, original.__struct__) == {:ok, original}
    end)
  end

  test "omits nil optional fields and uses camelCase keys" do
    encoded =
      Codec.encode(%Task{
        id: "task-1",
        status: %TaskStatus{state: :submitted},
        created_at: "now"
      })

    assert encoded["createdAt"] == "now"
    refute Map.has_key?(encoded, "created_at")
    refute Map.has_key?(encoded, "contextId")
    assert encoded["history"] == []
    assert encoded["artifacts"] == []
  end

  test "returns InvalidParamsError for missing and wrongly typed required fields" do
    assert {:error, %InvalidParamsError{code: -32602}} =
             Codec.decode(%{"parts" => []}, Message)

    assert {:error, %InvalidParamsError{code: -32602}} =
             Codec.decode(%{"role" => "user", "parts" => "not-a-list"}, Message)
  end

  test "returns InvalidRequestError when the JSON value is not an object" do
    assert {:error, %InvalidRequestError{code: -32600}} = Codec.decode([], Message)
  end

  test "dispatches parts by type and rejects an unknown part type" do
    assert {:ok, %TextPart{text: "hello"}} =
             Codec.decode(%{"type" => "text", "text" => "hello"}, :part)

    assert {:error, %UnsupportedOperationError{code: -32004}} =
             Codec.decode(%{"type" => "video", "uri" => "clip.mp4"}, :part)
  end

  test "rejects an unrecognised TaskState" do
    assert {:error, %InvalidParamsError{code: -32602}} =
             Codec.decode(%{"state" => "paused"}, TaskStatus)
  end

  test "requires exactly one file source" do
    base = %{"name" => "file", "mimeType" => "text/plain"}

    assert {:error, %InvalidParamsError{}} = Codec.decode(base, FileContent)

    assert {:error, %InvalidParamsError{}} =
             Codec.decode(Map.merge(base, %{"uri" => "uri", "bytes" => "bytes"}), FileContent)
  end
end

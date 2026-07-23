defmodule Exocomp.A2A.InvalidPayloadTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{
    AgentCard,
    Codec,
    InvalidParamsError,
    InvalidRequestError,
    Message,
    Task,
    UnsupportedOperationError
  }

  test "Message without 'role' returns InvalidParamsError (-32602)" do
    payload = %{"parts" => [%{"type" => "text", "text" => "hi"}]}
    assert {:error, %InvalidParamsError{code: -32602}} = Codec.decode(payload, Message)
  end

  test "Task without 'id' returns InvalidParamsError (-32602)" do
    payload = %{"status" => %{"state" => "submitted"}}
    assert {:error, %InvalidParamsError{code: -32602}} = Codec.decode(payload, Task)
  end

  test "Part with unknown type 'video' returns UnsupportedOperationError (-32004)" do
    payload = %{"type" => "video", "uri" => "https://example.test/clip.mp4"}
    assert {:error, %UnsupportedOperationError{code: -32004}} = Codec.decode(payload, :part)
  end

  test "non-map value returns InvalidRequestError (-32600)" do
    assert {:error, %InvalidRequestError{code: -32600}} = Codec.decode("not a map", Message)
    assert {:error, %InvalidRequestError{code: -32600}} = Codec.decode(42, Task)
    assert {:error, %InvalidRequestError{code: -32600}} = Codec.decode([], AgentCard)
  end

  test "AgentCard missing 'name' returns InvalidParamsError (-32602)" do
    payload = %{
      "description" => "An agent",
      "url" => "https://example.test/a2a",
      "version" => "1.0"
    }

    assert {:error, %InvalidParamsError{code: -32602}} = Codec.decode(payload, AgentCard)
  end
end

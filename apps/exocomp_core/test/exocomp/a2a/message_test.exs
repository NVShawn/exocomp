defmodule Exocomp.A2A.MessageTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{Message, TextPart}

  test "can be constructed with required fields" do
    part = %TextPart{text: "Hello"}
    msg = %Message{role: :user, parts: [part]}
    assert msg.role == :user
    assert msg.parts == [part]
    assert msg.messageId == nil
    assert msg.taskId == nil
    assert msg.contextId == nil
    assert msg.timestamp == nil
  end

  test "can be constructed with agent role" do
    msg = %Message{role: :agent, parts: []}
    assert msg.role == :agent
  end

  test "can be constructed with all optional fields" do
    msg = %Message{
      role: :user,
      parts: [],
      messageId: "msg-001",
      taskId: "task-001",
      contextId: "ctx-001",
      timestamp: "2026-01-01T00:00:00Z"
    }

    assert msg.messageId == "msg-001"
    assert msg.taskId == "task-001"
    assert msg.contextId == "ctx-001"
    assert msg.timestamp == "2026-01-01T00:00:00Z"
  end

  test "raises when required field role is missing" do
    assert_raise ArgumentError, fn ->
      struct!(Message, parts: [])
    end
  end

  test "raises when required field parts is missing" do
    assert_raise ArgumentError, fn ->
      struct!(Message, role: :user)
    end
  end
end

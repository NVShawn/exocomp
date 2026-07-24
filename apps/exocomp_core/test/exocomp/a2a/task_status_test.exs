defmodule Exocomp.A2A.TaskStatusTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{TaskStatus, Message}

  test "can be constructed with required state field" do
    status = %TaskStatus{state: :submitted}
    assert status.state == :submitted
    assert status.message == nil
    assert status.timestamp == nil
  end

  test "can be constructed with all fields" do
    msg = %Message{role: :agent, parts: []}

    status = %TaskStatus{
      state: :working,
      message: msg,
      timestamp: "2026-01-01T00:00:00Z"
    }

    assert status.state == :working
    assert status.message == msg
    assert status.timestamp == "2026-01-01T00:00:00Z"
  end

  test "supports all TaskState values" do
    for state <- Exocomp.A2A.TaskState.values() do
      status = %TaskStatus{state: state}
      assert status.state == state
    end
  end

  test "raises when required field state is missing" do
    assert_raise ArgumentError, fn ->
      struct!(TaskStatus, [])
    end
  end
end

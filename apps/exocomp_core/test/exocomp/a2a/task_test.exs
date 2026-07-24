defmodule Exocomp.A2A.TaskTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{Task, TaskStatus, Message, Artifact, TextPart}

  test "can be constructed with required fields" do
    status = %TaskStatus{state: :submitted}
    task = %Task{id: "task-001", status: status}
    assert task.id == "task-001"
    assert task.status == status
    assert task.contextId == nil
    assert task.history == []
    assert task.artifacts == []
    assert task.metadata == nil
    assert task.created_at == nil
    assert task.updated_at == nil
  end

  test "can be constructed with all fields" do
    status = %TaskStatus{state: :completed}
    msg = %Message{role: :user, parts: [%TextPart{text: "do it"}]}
    artifact = %Artifact{artifactId: "art-1", parts: [%TextPart{text: "done"}]}

    task = %Task{
      id: "task-002",
      contextId: "ctx-001",
      status: status,
      history: [msg],
      artifacts: [artifact],
      metadata: %{"priority" => "high"},
      created_at: "2026-01-01T00:00:00Z",
      updated_at: "2026-01-02T00:00:00Z"
    }

    assert task.contextId == "ctx-001"
    assert task.history == [msg]
    assert task.artifacts == [artifact]
    assert task.metadata == %{"priority" => "high"}
    assert task.created_at == "2026-01-01T00:00:00Z"
    assert task.updated_at == "2026-01-02T00:00:00Z"
  end

  test "raises when required field id is missing" do
    assert_raise ArgumentError, fn ->
      struct!(Task, status: %TaskStatus{state: :submitted})
    end
  end

  test "raises when required field status is missing" do
    assert_raise ArgumentError, fn ->
      struct!(Task, id: "task-xyz")
    end
  end
end

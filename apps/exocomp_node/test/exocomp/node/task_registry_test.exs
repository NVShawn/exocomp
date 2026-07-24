defmodule Exocomp.Node.TaskRegistryTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{Message, TextPart}
  alias Exocomp.Node.TaskRegistry

  defp start_registry(opts \\ []) do
    name = :"task_registry_#{System.unique_integer([:positive])}"
    start_supervised!({TaskRegistry, Keyword.put(opts, :name, name)})
    name
  end

  defp message(text \\ "do the work") do
    %Message{role: :user, parts: [%TextPart{text: text}], messageId: "message-1"}
  end

  defp submit!(registry, text \\ "do the work") do
    assert {:ok, task_id} = TaskRegistry.submit(message(text), "skill-1", registry)
    task_id
  end

  test "submit creates a UUID task in submitted state" do
    registry = start_registry()

    assert {:ok, task_id} = TaskRegistry.submit(message(), "skill-1", registry)
    assert task_id =~ ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

    assert {:ok, task} = TaskRegistry.get(task_id, registry)
    assert task.id == task_id
    assert task.status.state == :submitted
    assert task.history == [message()]
    assert task.metadata == %{"skill_id" => "skill-1"}
    assert is_binary(task.created_at)
    assert task.updated_at == task.created_at
  end

  test "get returns not_found for an unknown id" do
    registry = start_registry()
    assert TaskRegistry.get("missing", registry) == {:error, :not_found}
  end

  test "list returns all active and recent terminal tasks" do
    registry = start_registry()
    first_id = submit!(registry, "first")
    second_id = submit!(registry, "second")
    assert :ok = TaskRegistry.transition(first_id, :working, nil, registry)
    assert :ok = TaskRegistry.transition(first_id, :completed, "result", registry)

    assert registry |> TaskRegistry.list() |> Enum.map(& &1.id) |> MapSet.new() ==
             MapSet.new([first_id, second_id])
  end

  test "supports every valid state transition" do
    registry = start_registry()

    completed_id = submit!(registry, "complete")
    assert :ok = TaskRegistry.transition(completed_id, :working, nil, registry)
    assert :ok = TaskRegistry.transition(completed_id, :completed, "done", registry)
    assert {:ok, completed} = TaskRegistry.get(completed_id, registry)
    assert completed.status.state == :completed
    assert completed.status.message == "done"

    failed_id = submit!(registry, "fail")
    assert :ok = TaskRegistry.transition(failed_id, :working, nil, registry)
    assert :ok = TaskRegistry.transition(failed_id, :failed, "boom", registry)

    submitted_cancel_id = submit!(registry, "cancel queued")
    assert :ok = TaskRegistry.transition(submitted_cancel_id, :canceled, nil, registry)

    working_cancel_id = submit!(registry, "cancel running")
    assert :ok = TaskRegistry.transition(working_cancel_id, :working, nil, registry)
    assert :ok = TaskRegistry.transition(working_cancel_id, :canceled, nil, registry)
  end

  test "rejects invalid and over-capacity transitions" do
    registry = start_registry(max_concurrent_tasks: 1)
    first_id = submit!(registry, "first")
    second_id = submit!(registry, "second")

    assert TaskRegistry.transition(first_id, :completed, nil, registry) ==
             {:error, :invalid_transition}

    assert :ok = TaskRegistry.transition(first_id, :working, nil, registry)

    assert TaskRegistry.transition(second_id, :working, nil, registry) ==
             {:error, :invalid_transition}

    assert TaskRegistry.transition("missing", :working, nil, registry) ==
             {:error, :not_found}
  end

  test "cancel changes a submitted task to canceled" do
    registry = start_registry()
    task_id = submit!(registry)

    assert {:ok, task} = TaskRegistry.cancel(task_id, registry)
    assert task.status.state == :canceled
    assert {:ok, ^task} = TaskRegistry.get(task_id, registry)
  end

  test "cancel changes a working task to canceled and signals its worker" do
    registry = start_registry()
    task_id = submit!(registry)
    assert :ok = TaskRegistry.transition(task_id, :working, nil, registry)
    assert :ok = TaskRegistry.register_worker(task_id, self(), registry)

    assert {:ok, task} = TaskRegistry.cancel(task_id, registry)
    assert task.status.state == :canceled
    assert_receive :shutdown
  end

  test "transitioning a working task to canceled also signals its worker" do
    registry = start_registry()
    task_id = submit!(registry)
    assert :ok = TaskRegistry.transition(task_id, :working, nil, registry)
    assert :ok = TaskRegistry.register_worker(task_id, self(), registry)

    assert :ok = TaskRegistry.transition(task_id, :canceled, nil, registry)
    assert_receive :shutdown
  end

  test "cancel rejects terminal and unknown tasks" do
    registry = start_registry()
    task_id = submit!(registry)
    assert :ok = TaskRegistry.transition(task_id, :working, nil, registry)
    assert :ok = TaskRegistry.transition(task_id, :completed, nil, registry)

    assert TaskRegistry.cancel(task_id, registry) == {:error, :not_cancelable}
    assert TaskRegistry.cancel("missing", registry) == {:error, :not_found}
  end

  test "submit returns at_capacity while the working limit is reached" do
    registry = start_registry(max_concurrent_tasks: 1)
    task_id = submit!(registry)
    assert :ok = TaskRegistry.transition(task_id, :working, nil, registry)

    assert TaskRegistry.submit(message("next"), "skill-1", registry) ==
             {:error, :at_capacity}
  end

  test "age eviction removes expired terminal tasks but preserves active tasks" do
    registry = start_registry(history_ttl_ms: 1, eviction_interval_ms: 60_000)
    terminal_id = submit!(registry, "terminal")
    active_id = submit!(registry, "active")
    assert :ok = TaskRegistry.transition(terminal_id, :working, nil, registry)
    assert :ok = TaskRegistry.transition(terminal_id, :completed, nil, registry)

    Process.sleep(5)
    send(registry, :evict)

    assert TaskRegistry.get(terminal_id, registry) == {:error, :not_found}
    assert {:ok, active} = TaskRegistry.get(active_id, registry)
    assert active.status.state == :submitted
  end

  test "count eviction removes the oldest terminal task to make room" do
    registry = start_registry(max_tasks: 2)
    oldest_id = submit!(registry, "old terminal")
    assert :ok = TaskRegistry.transition(oldest_id, :working, nil, registry)
    assert :ok = TaskRegistry.transition(oldest_id, :completed, nil, registry)
    Process.sleep(2)

    active_id = submit!(registry, "active")
    newest_id = submit!(registry, "newest")

    assert TaskRegistry.get(oldest_id, registry) == {:error, :not_found}
    assert {:ok, _active} = TaskRegistry.get(active_id, registry)
    assert {:ok, _newest} = TaskRegistry.get(newest_id, registry)
    assert length(TaskRegistry.list(registry)) == 2
  end

  test "a registry full of active tasks rejects submission instead of evicting them" do
    registry = start_registry(max_tasks: 1)
    active_id = submit!(registry)

    assert TaskRegistry.submit(message("overflow"), "skill-1", registry) ==
             {:error, :at_capacity}

    assert {:ok, _active} = TaskRegistry.get(active_id, registry)
  end
end

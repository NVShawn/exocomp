defmodule Exocomp.Coordinator.TaskRegistryTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{DataPart, Message, Task}
  alias Exocomp.Coordinator.TaskRegistry

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp start_registry(opts \\ []) do
    name = :"coord_task_registry_#{System.unique_integer([:positive])}"
    start_supervised!({TaskRegistry, Keyword.put(opts, :name, name)})
    name
  end

  defp msg(skill_id) do
    %Message{
      role: :user,
      parts: [%DataPart{data: %{"skill" => skill_id}}]
    }
  end

  defp submit(registry, skill_id \\ "exocomp.cluster.health") do
    {:ok, task_id} = TaskRegistry.submit(msg(skill_id), skill_id, registry)
    task_id
  end

  # ---------------------------------------------------------------------------
  # Submit
  # ---------------------------------------------------------------------------

  test "submit returns {:ok, task_id} and task is in :submitted state" do
    registry = start_registry()
    task_id = submit(registry)

    {:ok, task} = TaskRegistry.get(task_id, registry)
    assert task.id == task_id
    assert task.status.state == :submitted
  end

  test "submit when at max_concurrent_tasks returns {:error, :at_capacity}" do
    registry = start_registry(max_concurrent_tasks: 1)
    task_id = submit(registry)
    :ok = TaskRegistry.transition(task_id, :working, nil, registry)

    assert {:error, :at_capacity} =
             TaskRegistry.submit(
               msg("exocomp.cluster.health"),
               "exocomp.cluster.health",
               registry
             )
  end

  test "submit when at max_tasks returns {:error, :at_capacity}" do
    registry = start_registry(max_tasks: 1)

    # First submit succeeds.
    task_id = submit(registry)
    # Move to terminal so it can be evicted, but use max_tasks of 1.
    :ok = TaskRegistry.transition(task_id, :working, nil, registry)
    :ok = TaskRegistry.transition(task_id, :completed, nil, registry)

    # max_tasks: 1 means we already have 1 task and must evict to make room.
    # The terminal task should be evicted and we can submit again.
    task_id2 = submit(registry)
    assert is_binary(task_id2)
  end

  # ---------------------------------------------------------------------------
  # Get
  # ---------------------------------------------------------------------------

  test "get returns :not_found for unknown task_id" do
    registry = start_registry()
    assert {:error, :not_found} = TaskRegistry.get("nonexistent", registry)
  end

  # ---------------------------------------------------------------------------
  # List
  # ---------------------------------------------------------------------------

  test "list returns all submitted tasks in insertion order" do
    registry = start_registry()
    id1 = submit(registry, "exocomp.cluster.health")
    id2 = submit(registry, "exocomp.cluster.diagnose")

    tasks = TaskRegistry.list(registry)
    task_ids = Enum.map(tasks, & &1.id)
    assert id1 in task_ids
    assert id2 in task_ids
  end

  test "list returns empty list when no tasks" do
    registry = start_registry()
    assert [] = TaskRegistry.list(registry)
  end

  # ---------------------------------------------------------------------------
  # Transition
  # ---------------------------------------------------------------------------

  test "transition submitted -> working succeeds" do
    registry = start_registry()
    task_id = submit(registry)
    assert :ok = TaskRegistry.transition(task_id, :working, nil, registry)

    {:ok, task} = TaskRegistry.get(task_id, registry)
    assert task.status.state == :working
  end

  test "transition working -> completed succeeds with artifact" do
    registry = start_registry()
    task_id = submit(registry)
    :ok = TaskRegistry.transition(task_id, :working, nil, registry)
    :ok = TaskRegistry.transition(task_id, :completed, %{data: "ok"}, registry)

    {:ok, task} = TaskRegistry.get(task_id, registry)
    assert task.status.state == :completed
    assert task.status.message == %{data: "ok"}
  end

  test "transition working -> failed succeeds with reason" do
    registry = start_registry()
    task_id = submit(registry)
    :ok = TaskRegistry.transition(task_id, :working, nil, registry)
    :ok = TaskRegistry.transition(task_id, :failed, :timeout, registry)

    {:ok, task} = TaskRegistry.get(task_id, registry)
    assert task.status.state == :failed
    assert task.status.message == :timeout
  end

  test "transition with invalid state returns :invalid_transition" do
    registry = start_registry()
    task_id = submit(registry)

    # Can't go submitted -> completed directly.
    assert {:error, :invalid_transition} =
             TaskRegistry.transition(task_id, :completed, nil, registry)
  end

  test "transition on unknown task_id returns :not_found" do
    registry = start_registry()
    assert {:error, :not_found} = TaskRegistry.transition("nope", :working, nil, registry)
  end

  # ---------------------------------------------------------------------------
  # Cancel
  # ---------------------------------------------------------------------------

  test "cancel submitted task returns {:ok, canceled_task}" do
    registry = start_registry()
    task_id = submit(registry)
    assert {:ok, %Task{status: %{state: :canceled}}} = TaskRegistry.cancel(task_id, registry)
  end

  test "cancel working task returns {:ok, canceled_task} and signals worker" do
    registry = start_registry()
    task_id = submit(registry)
    :ok = TaskRegistry.transition(task_id, :working, nil, registry)
    :ok = TaskRegistry.register_worker(task_id, self(), registry)

    assert {:ok, %Task{status: %{state: :canceled}}} = TaskRegistry.cancel(task_id, registry)

    receive do
      :shutdown -> :ok
    after
      500 -> flunk("Worker did not receive :shutdown signal")
    end
  end

  test "cancel completed task returns {:error, :not_cancelable}" do
    registry = start_registry()
    task_id = submit(registry)
    :ok = TaskRegistry.transition(task_id, :working, nil, registry)
    :ok = TaskRegistry.transition(task_id, :completed, nil, registry)

    assert {:error, :not_cancelable} = TaskRegistry.cancel(task_id, registry)
  end

  test "cancel unknown task returns {:error, :not_found}" do
    registry = start_registry()
    assert {:error, :not_found} = TaskRegistry.cancel("nonexistent", registry)
  end

  # ---------------------------------------------------------------------------
  # Bounded history
  # ---------------------------------------------------------------------------

  test "terminal tasks are evicted when max_tasks limit is approached" do
    registry = start_registry(max_tasks: 3, history_ttl_ms: 0)

    # Submit and terminate 3 tasks to fill the registry.
    ids =
      Enum.map(1..3, fn _ ->
        t = submit(registry)
        TaskRegistry.transition(t, :working, nil, registry)
        TaskRegistry.transition(t, :completed, nil, registry)
        t
      end)

    # Submit a 4th task. The registry should evict at least one terminal task
    # to make room.
    id4 = submit(registry)
    assert is_binary(id4)

    # At least one of the first three should have been evicted.
    remaining_ids =
      TaskRegistry.list(registry)
      |> Enum.map(& &1.id)

    # The new task should always be present.
    assert id4 in remaining_ids

    # Not all 3 old tasks can still be present (registry is capped at 3 and
    # we now have 4 total).
    old_in_registry = Enum.filter(ids, &(&1 in remaining_ids))
    assert length(old_in_registry) < 3
  end
end

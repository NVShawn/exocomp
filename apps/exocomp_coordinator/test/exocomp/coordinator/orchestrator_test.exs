defmodule Exocomp.Coordinator.OrchestratorTest do
  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, TextPart}
  alias Exocomp.A2A.Task, as: A2ATask
  alias Exocomp.A2A.TaskStatus
  alias Exocomp.Coordinator.A2A.ClientError
  alias Exocomp.Coordinator.{DiagnosticGoal, GoalStore, NodeOutcome, Orchestrator}

  # ---------------------------------------------------------------------------
  # Fake A2A client adapter (injected via client_adapter:)
  #
  # Each test starts a per-test Agent that maps response keys to response values
  # or functions. The FakeClient reads from the Agent referenced in
  # client_opts[:agent].
  #
  # Response values accepted in the Agent map:
  #   {:send, node_id}               => {:ok, a2a_task} | {:error, client_error}
  #                                   | {:block, blocker_pid}  ← blocks until :proceed
  #   {:get_task, node_id, task_id}  => {:ok, a2a_task} | {:error, client_error}
  #                                   | {:block, _}   ← blocks, notifies owner
  #   {:cancel, node_id, task_id}    => {:ok, a2a_task} | {:error, client_error}
  #                                   | nil (default) ← :unsupported_operation
  # ---------------------------------------------------------------------------

  defmodule FakeClient do
    alias Exocomp.Coordinator.A2A.ClientError

    def send(node_id, _skill_id, _params, opts) do
      owner = Keyword.get(opts, :owner)
      agent = Keyword.fetch!(opts, :agent)

      response = Agent.get(agent, &Map.get(&1, {:send, node_id}))

      if owner, do: send(owner, {:fake_send, node_id})

      case response do
        {:block, blocker} ->
          # Wait until told to proceed (or killed by timeout).
          send(blocker, {:blocking_send, self()})

          receive do
            # Respond with an explicit result injected by the test.
            {:proceed, result} -> result
            # Plain :proceed returns unreachable (for timeout / capacity tests).
            :proceed -> {:error, make_error(:transport, :unreachable, :send, node_id)}
          end

        {:ok, _} = ok ->
          ok

        {:error, _} = err ->
          err

        nil ->
          {:error, make_error(:configuration, :unknown_node, :send, node_id)}
      end
    end

    def get_task(node_id, task_id, opts) do
      owner = Keyword.get(opts, :owner)
      agent = Keyword.fetch!(opts, :agent)
      response = Agent.get(agent, &Map.get(&1, {:get_task, node_id, task_id}))

      case response do
        {:block, _} ->
          # Notify the owner so the test knows polling is in progress.
          if owner, do: send(owner, {:blocking_get_task, node_id, self()})

          receive do
            {:proceed, result} -> result
            :proceed -> {:error, make_error(:transport, :unreachable, :get_task, node_id)}
          end

        {:ok, _} = ok ->
          ok

        {:error, _} = err ->
          err

        nil ->
          {:error, make_error(:transport, :unreachable, :get_task, node_id)}
      end
    end

    def cancel(node_id, task_id, opts) do
      agent = Keyword.fetch!(opts, :agent)
      response = Agent.get(agent, &Map.get(&1, {:cancel, node_id, task_id}))

      case response do
        {:ok, _} = ok ->
          ok

        {:error, _} = err ->
          err

        nil ->
          # Default: node does not support A2A cancel.
          {:error, make_error(:protocol, :unsupported_operation, :cancel, node_id)}
      end
    end

    defp make_error(kind, reason, operation, node_id) do
      %ClientError{kind: kind, reason: reason, operation: operation, node_id: node_id}
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp start_agent(responses \\ %{}) do
    start_supervised!({Agent, fn -> responses end}, id: unique_name(:agent))
  end

  defp update_agent(agent, key, value) do
    Agent.update(agent, &Map.put(&1, key, value))
  end

  defp make_task(id, state, artifacts \\ []) do
    %A2ATask{
      id: id,
      status: %TaskStatus{
        state: String.to_existing_atom(state),
        timestamp: "2026-07-24T00:00:00Z"
      },
      artifacts: artifacts
    }
  end

  defp make_artifact(id, text) do
    %Artifact{
      artifactId: id,
      parts: [%TextPart{text: text}]
    }
  end

  defp make_error(kind, reason, node_id) do
    %ClientError{kind: kind, reason: reason, operation: :send, node_id: node_id}
  end

  defp start_goal_store(opts \\ []) do
    name = unique_name(:goal_store)
    start_supervised!({GoalStore, Keyword.put(opts, :name, name)}, id: name)
    name
  end

  defp start_task_supervisor do
    name = unique_name(:task_sup)
    start_supervised!({Task.Supervisor, name: name}, id: name)
    name
  end

  defp start_orchestrator(goal_store, task_supervisor, opts \\ []) do
    name = unique_name(:orchestrator)

    merged =
      opts
      |> Keyword.merge(
        name: name,
        goal_store: goal_store,
        task_supervisor: task_supervisor,
        client_adapter: FakeClient,
        poll_interval_ms: 10
      )

    start_supervised!({Orchestrator, merged}, id: name)
    name
  end

  defp run(orchestrator, caller_key, node_ids, agent, opts \\ []) do
    client_opts =
      Keyword.merge(
        [agent: agent, owner: self()],
        Keyword.get(opts, :client_opts, [])
      )

    extra = Keyword.delete(opts, :client_opts)

    Orchestrator.run(
      caller_key,
      "exocomp.system.diagnose",
      %{"detail" => "full"},
      node_ids,
      [orchestrator: orchestrator, client_opts: client_opts] ++ extra
    )
  end

  defp cancel(orchestrator, goal_id) do
    Orchestrator.cancel(goal_id, orchestrator: orchestrator)
  end

  # Poll GoalStore until predicate is satisfied or attempts exhausted.
  defp eventually(assertion, attempts \\ 200)
  defp eventually(assertion, 0), do: assert(assertion.())

  defp eventually(assertion, n) do
    if assertion.() do
      :ok
    else
      Process.sleep(5)
      eventually(assertion, n - 1)
    end
  end

  defp goal_completed?(goal_store, goal_id) do
    case GoalStore.get(goal_id, goal_store) do
      {:ok, %DiagnosticGoal{state: :completed}} -> true
      _ -> false
    end
  end

  defp goal_canceled?(goal_store, goal_id) do
    case GoalStore.get(goal_id, goal_store) do
      {:ok, %DiagnosticGoal{state: :canceled}} -> true
      _ -> false
    end
  end

  defp unique_name(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"

  # Flush the orchestrator's mailbox by making a synchronous call, ensuring
  # that all previously-sent async messages have been processed. Use this after
  # receiving an async notification from a worker (e.g. {:blocking_get_task, ...})
  # to guarantee that {:node_dispatched, ...} messages have also been handled
  # before calling cancel.
  defp sync_orchestrator(orchestrator) do
    Orchestrator.in_flight_count(orchestrator)
  end

  # ---------------------------------------------------------------------------
  # Tests: existing fan-out behaviour
  # ---------------------------------------------------------------------------

  test "three-node success: all nodes succeed, goal reaches :completed" do
    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed", [make_artifact("a1", "ok-1")])},
        {:send, "node-2"} => {:ok, make_task("t2", "completed", [make_artifact("a2", "ok-2")])},
        {:send, "node-3"} => {:ok, make_task("t3", "completed", [make_artifact("a3", "ok-3")])}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-three-success", ["node-1", "node-2", "node-3"], agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed

    for node_id <- ["node-1", "node-2", "node-3"] do
      outcome = Map.fetch!(goal.node_outcomes, node_id)
      assert outcome.state == :succeeded
      assert %A2ATask{} = outcome.result
      assert length(outcome.artifacts) == 1
    end
  end

  test "partial node failure: one node fails, others succeed" do
    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")},
        {:send, "node-2"} => {:error, make_error(:protocol, :malformed_response, "node-2")},
        {:send, "node-3"} => {:ok, make_task("t3", "completed")}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-partial", ["node-1", "node-2", "node-3"], agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed

    assert goal.node_outcomes["node-1"].state == :succeeded
    assert goal.node_outcomes["node-2"].state == :failed
    assert goal.node_outcomes["node-3"].state == :succeeded

    # Failed node carries error details.
    assert %ClientError{kind: :protocol} = goal.node_outcomes["node-2"].error
  end

  test "unavailable node: transport error yields :unreachable outcome" do
    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")},
        {:send, "node-2"} => {:error, make_error(:transport, :unreachable, "node-2")}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-unavailable", ["node-1", "node-2"], agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed
    assert goal.node_outcomes["node-1"].state == :succeeded
    assert goal.node_outcomes["node-2"].state == :unreachable
  end

  test "configuration error (unknown node) yields :failed outcome, not :unreachable" do
    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")},
        # No entry for node-2 → FakeClient returns :configuration/:unknown_node
        {:send, "node-2"} => {:error, make_error(:configuration, :unknown_node, "node-2")}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-config-error", ["node-1", "node-2"], agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed
    assert goal.node_outcomes["node-1"].state == :succeeded
    assert goal.node_outcomes["node-2"].state == :failed
  end

  test "per-node timeout: slow node is killed and marked :unreachable, peer succeeds" do
    blocker = self()

    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")},
        {:send, "node-slow"} => {:block, blocker}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        node_timeout_ms: 80,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-node-timeout", ["node-1", "node-slow"], agent)

    # The slow node's worker should be blocking.
    assert_receive {:blocking_send, _slow_pid}, 1_000

    eventually(fn -> goal_completed?(goal_store, goal_id) end, 300)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed
    assert goal.node_outcomes["node-1"].state == :succeeded
    assert goal.node_outcomes["node-slow"].state == :unreachable
    assert goal.node_outcomes["node-slow"].error == :node_timeout
  end

  test "overall goal timeout: all remaining nodes marked :unreachable" do
    blocker = self()

    agent =
      start_agent(%{
        {:send, "node-1"} => {:block, blocker},
        {:send, "node-2"} => {:block, blocker}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        concurrency: 4,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 80
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-overall-timeout", ["node-1", "node-2"], agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end, 300)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed
    assert goal.node_outcomes["node-1"].state == :unreachable
    assert goal.node_outcomes["node-2"].state == :unreachable
    assert goal.node_outcomes["node-1"].error == :overall_timeout
    assert goal.node_outcomes["node-2"].error == :overall_timeout
  end

  test "overall timeout with pending nodes: pending nodes also marked :unreachable" do
    blocker = self()

    agent =
      start_agent(%{
        # Only node-1 dispatched within concurrency=1; node-2 stays pending
        {:send, "node-1"} => {:block, blocker}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        concurrency: 1,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 80
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-pending-timeout", ["node-1", "node-2"], agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end, 300)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed
    assert goal.node_outcomes["node-1"].state == :unreachable
    assert goal.node_outcomes["node-2"].state == :unreachable
  end

  test "concurrency limit: at most N node tasks run concurrently" do
    owner = self()
    concurrency = 2

    # All three nodes block until released.
    agent =
      start_agent(%{
        {:send, "node-1"} => {:block, owner},
        {:send, "node-2"} => {:block, owner},
        {:send, "node-3"} => {:block, owner}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        concurrency: concurrency,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-concurrency", ["node-1", "node-2", "node-3"], agent)

    # Exactly `concurrency` tasks start immediately.
    pids =
      for _ <- 1..concurrency do
        assert_receive {:blocking_send, pid}, 1_000
        pid
      end

    # The third node is still pending (no blocking_send yet).
    refute_receive {:blocking_send, _}, 30

    assert Orchestrator.in_flight_count(orchestrator) == concurrency

    # Release one task with a success result; the third node should now start.
    [first_pid | rest_pids] = pids
    send(first_pid, {:proceed, {:ok, make_task("t1", "completed")}})

    assert_receive {:blocking_send, third_pid}, 1_000
    assert Orchestrator.in_flight_count(orchestrator) <= concurrency

    # Release remaining nodes with success results.
    Enum.each(rest_pids, &send(&1, {:proceed, {:ok, make_task("t-rest", "completed")}}))
    send(third_pid, {:proceed, {:ok, make_task("t3", "completed")}})

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed
  end

  test "concurrency limit spans multiple active goals" do
    owner = self()

    agent =
      start_agent(%{
        {:send, "node-a1"} => {:block, owner},
        {:send, "node-b1"} => {:block, owner}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        concurrency: 1,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_a_id}} =
             run(orchestrator, "key-goal-a", ["node-a1"], agent)

    # Goal A's node is in flight — concurrency=1, no room for goal B.
    assert_receive {:blocking_send, pid_a}, 1_000

    assert {:ok, %DiagnosticGoal{id: goal_b_id}} =
             run(orchestrator, "key-goal-b", ["node-b1"], agent)

    refute_receive {:blocking_send, _}, 30
    assert Orchestrator.in_flight_count(orchestrator) == 1

    # Release goal A's node with a success result; goal B should now start.
    send(pid_a, {:proceed, {:ok, make_task("ta1", "completed")}})

    assert_receive {:blocking_send, pid_b}, 1_000

    send(pid_b, {:proceed, {:ok, make_task("tb1", "completed")}})

    eventually(fn ->
      goal_completed?(goal_store, goal_a_id) and goal_completed?(goal_store, goal_b_id)
    end)
  end

  test "late-result handling: result arriving after per-node timeout is discarded" do
    owner = self()

    agent =
      start_agent(%{
        {:send, "node-fast"} => {:ok, make_task("tf", "completed")},
        {:send, "node-slow"} => {:block, owner}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        node_timeout_ms: 80,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-late", ["node-fast", "node-slow"], agent)

    assert_receive {:blocking_send, slow_pid}, 1_000

    # Wait for goal to complete (fast node done, slow node timed out).
    eventually(fn -> goal_completed?(goal_store, goal_id) end, 300)

    # Goal is complete and slow node is unreachable.
    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed
    assert goal.node_outcomes["node-slow"].state == :unreachable

    # The slow worker is dead; sending :proceed is a no-op.
    refute Process.alive?(slow_pid)

    # Even if a result were injected now, the goal stays :completed.
    :ok =
      GoalStore.get(goal_id, goal_store)
      |> then(fn {:ok, g} ->
        assert g.state == :completed
        :ok
      end)
  end

  test "idempotent caller_key: duplicate run returns existing goal without re-dispatching" do
    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-idem", ["node-1"], agent)

    # Second call with the same key.
    assert {:ok, %DiagnosticGoal{id: ^goal_id}} =
             run(orchestrator, "key-idem", ["node-1"], agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    # Only one {:fake_send, "node-1"} should have arrived.
    assert_receive {:fake_send, "node-1"}
    refute_receive {:fake_send, "node-1"}, 30
  end

  test "empty node list: goal immediately reaches :completed" do
    goal_store = start_goal_store()
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup)

    agent = start_agent()

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-empty", [], agent)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed
    assert goal.node_outcomes == %{}
  end

  test "GoalStore at capacity returns :at_capacity error" do
    goal_store = start_goal_store(max_active: 1, max_history: 1)
    task_sup = start_task_supervisor()
    owner = self()

    agent =
      start_agent(%{
        {:send, "node-1"} => {:block, owner}
      })

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, _} = run(orchestrator, "key-cap-1", ["node-1"], agent)
    assert_receive {:blocking_send, _pid}, 1_000

    assert {:error, :at_capacity} = run(orchestrator, "key-cap-2", ["node-1"], agent)
  end

  test "polling: non-terminal send result is polled until terminal" do
    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "working")},
        {:get_task, "node-1", "t1"} => {:ok, make_task("t1", "working")}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, poll_interval_ms: 10)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-poll", ["node-1"], agent)

    # Give poll a few cycles, then make the task terminal.
    Process.sleep(50)
    update_agent(agent, {:get_task, "node-1", "t1"}, {:ok, make_task("t1", "completed")})

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.node_outcomes["node-1"].state == :succeeded
  end

  test "node lifecycle updates are visible through GoalStore (pending → running → succeeded)" do
    owner = self()

    agent =
      start_agent(%{
        {:send, "node-1"} => {:block, owner}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-lifecycle", ["node-1"], agent)

    # Node outcome is set to :running synchronously before the task starts,
    # so it is immediately observable after run/5 returns.
    {:ok, goal_after_run} = GoalStore.get(goal_id, goal_store)
    assert goal_after_run.node_outcomes["node-1"].state == :running

    # The task should have sent its blocking notification by now.
    assert_receive {:blocking_send, task_pid}, 1_000

    # Release the worker with a successful A2A task response.
    send(task_pid, {:proceed, {:ok, make_task("t1", "completed")}})

    # Node should transition to :succeeded once the task completes.
    eventually(fn ->
      case GoalStore.get(goal_id, goal_store) do
        {:ok, %{node_outcomes: %{"node-1" => %{state: :succeeded}}}} -> true
        _ -> false
      end
    end)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)
  end

  test "multiple goals with mixed outcomes are isolated from each other" do
    agent =
      start_agent(%{
        {:send, "node-ok"} => {:ok, make_task("tok", "completed")},
        {:send, "node-fail"} => {:error, make_error(:transport, :unreachable, "node-fail")}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup)

    assert {:ok, %DiagnosticGoal{id: goal_a}} =
             run(orchestrator, "key-mix-a", ["node-ok", "node-fail"], agent)

    assert {:ok, %DiagnosticGoal{id: goal_b}} =
             run(orchestrator, "key-mix-b", ["node-ok"], agent)

    eventually(fn ->
      goal_completed?(goal_store, goal_a) and goal_completed?(goal_store, goal_b)
    end)

    {:ok, g_a} = GoalStore.get(goal_a, goal_store)
    assert g_a.node_outcomes["node-ok"].state == :succeeded
    assert g_a.node_outcomes["node-fail"].state == :unreachable

    {:ok, g_b} = GoalStore.get(goal_b, goal_store)
    assert g_b.node_outcomes["node-ok"].state == :succeeded
  end

  test "artifacts from node task are recorded in NodeOutcome" do
    artifact = make_artifact("diag-1", "cpu load normal")

    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed", [artifact])}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-artifact", ["node-1"], agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    [%Artifact{artifactId: "diag-1"}] = goal.node_outcomes["node-1"].artifacts
  end

  test "downstream_key is stable and deterministic for (goal_id, node_id) pairs" do
    # Verify that GoalStore.downstream_key is used by the orchestrator by
    # confirming we can pre-compute the key and it matches expectations.
    # This is a pure-function test (no network needed).
    key1 = GoalStore.downstream_key("goal-abc", "node-1")
    key2 = GoalStore.downstream_key("goal-abc", "node-1")
    key3 = GoalStore.downstream_key("goal-abc", "node-2")

    assert key1 == key2
    refute key1 == key3
    assert byte_size(key1) == 64
    assert key1 =~ ~r/^[0-9a-f]{64}$/
  end

  # ---------------------------------------------------------------------------
  # Tests: cancellation
  # ---------------------------------------------------------------------------

  test "cancel before dispatch: pending nodes are marked :canceled without A2A call" do
    # concurrency=1 so node-1 runs and node-2 stays pending.
    # node-1 blocks in send so neither node completes before cancel.
    blocker = self()

    agent =
      start_agent(%{
        {:send, "node-1"} => {:block, blocker}
        # No cancel entry for node-1 — we don't expect A2A cancel to be attempted
        # for a node that hasn't finished the send call.
        # node-2 is never dispatched, so no cancel needed.
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        concurrency: 1,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-cancel-before-dispatch", ["node-1", "node-2"], agent)

    # node-1 is in-flight (blocking in send), node-2 is pending.
    assert_receive {:blocking_send, _node1_pid}, 1_000

    assert {:ok, %DiagnosticGoal{state: :canceled}} = cancel(orchestrator, goal_id)

    eventually(fn -> goal_canceled?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :canceled

    # node-1: killed before completing send → :canceled (no downstream task to cancel)
    assert goal.node_outcomes["node-1"].state == :canceled
    assert goal.node_outcomes["node-1"].error == :goal_canceled

    # node-2: never dispatched → :canceled directly
    assert goal.node_outcomes["node-2"].state == :canceled
    assert goal.node_outcomes["node-2"].error == :goal_canceled
  end

  test "cancel during fan-out: A2A cancel is attempted for dispatched nodes" do
    # node-1: send returns a non-terminal task, then blocks in get_task (polling).
    # cancel/2 should attempt client_adapter.cancel for the downstream task.
    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "working")},
        # Block in get_task so cancel can catch the node while polling.
        {:get_task, "node-1", "t1"} => {:block, :any},
        # FakeClient.cancel returns success for this downstream task.
        {:cancel, "node-1", "t1"} => {:ok, make_task("t1", "canceled")}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-cancel-fanout", ["node-1"], agent)

    # Wait for polling to start (worker is now blocking in get_task).
    assert_receive {:blocking_get_task, "node-1", _worker_pid}, 1_000

    # Sync: ensure the {:node_dispatched, ...} message has been processed by
    # the orchestrator so downstream_task_ids is populated before we cancel.
    sync_orchestrator(orchestrator)

    assert {:ok, %DiagnosticGoal{state: :canceled}} = cancel(orchestrator, goal_id)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :canceled

    # node-1: downstream A2A cancel succeeded → :canceled
    assert goal.node_outcomes["node-1"].state == :canceled
    assert goal.node_outcomes["node-1"].error == :goal_canceled
  end

  test "cancel with unsupported downstream: node is marked :cancel_failed" do
    # The downstream node's A2A agent does not support the cancel endpoint.
    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "working")},
        {:get_task, "node-1", "t1"} => {:block, :any},
        # Simulate :unsupported_operation (default when no cancel key is set,
        # but being explicit for clarity).
        {:cancel, "node-1", "t1"} =>
          {:error,
           %ClientError{
             kind: :protocol,
             reason: :unsupported_operation,
             operation: :cancel,
             node_id: "node-1"
           }}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-cancel-unsupported", ["node-1"], agent)

    assert_receive {:blocking_get_task, "node-1", _worker_pid}, 1_000
    sync_orchestrator(orchestrator)

    assert {:ok, %DiagnosticGoal{state: :canceled}} = cancel(orchestrator, goal_id)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :canceled

    # A2A cancel was unsupported — node marked :cancel_failed.
    assert goal.node_outcomes["node-1"].state == :cancel_failed
    assert goal.node_outcomes["node-1"].error == :goal_canceled
  end

  test "partial cancel failure: some nodes canceled, others cancel_failed" do
    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "working")},
        {:get_task, "node-1", "t1"} => {:block, :any},
        {:cancel, "node-1", "t1"} => {:ok, make_task("t1", "canceled")},
        {:send, "node-2"} => {:ok, make_task("t2", "working")},
        {:get_task, "node-2", "t2"} => {:block, :any},
        {:cancel, "node-2", "t2"} =>
          {:error,
           %ClientError{
             kind: :protocol,
             reason: :unsupported_operation,
             operation: :cancel,
             node_id: "node-2"
           }}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        concurrency: 4,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-cancel-partial", ["node-1", "node-2"], agent)

    # Wait for both nodes to start polling.
    assert_receive {:blocking_get_task, _, _}, 1_000
    assert_receive {:blocking_get_task, _, _}, 1_000

    sync_orchestrator(orchestrator)

    assert {:ok, %DiagnosticGoal{state: :canceled}} = cancel(orchestrator, goal_id)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :canceled

    assert goal.node_outcomes["node-1"].state == :canceled
    assert goal.node_outcomes["node-2"].state == :cancel_failed
  end

  test "repeated cancel: second call returns the same terminal goal (idempotent)" do
    blocker = self()

    agent =
      start_agent(%{
        {:send, "node-1"} => {:block, blocker}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-cancel-repeat", ["node-1"], agent)

    assert_receive {:blocking_send, _pid}, 1_000

    # First cancel.
    assert {:ok, %DiagnosticGoal{id: ^goal_id, state: :canceled}} = cancel(orchestrator, goal_id)

    # Second cancel — goal is already terminal (:canceled); returns same goal.
    assert {:ok, %DiagnosticGoal{id: ^goal_id, state: :canceled}} = cancel(orchestrator, goal_id)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :canceled
    assert goal.node_outcomes["node-1"].state in [:canceled, :cancel_failed]
  end

  test "completion/cancel race: node completing before cancel is idempotent (goal stays :completed)" do
    agent =
      start_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-cancel-race-complete", ["node-1"], agent)

    # Wait for the goal to complete before calling cancel.
    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    # Cancel on an already-completed goal returns the completed goal (idempotent).
    assert {:ok, %DiagnosticGoal{id: ^goal_id, state: :completed}} =
             cancel(orchestrator, goal_id)

    # Goal and node outcome remain unchanged.
    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed
    assert goal.node_outcomes["node-1"].state == :succeeded
  end

  test "cancel/2 returns :not_found for an unknown goal_id" do
    goal_store = start_goal_store()
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup)

    assert {:error, :not_found} = cancel(orchestrator, "nonexistent-goal-id")
  end

  test "cancel drains orchestrator in-flight count to zero" do
    blocker = self()

    agent =
      start_agent(%{
        {:send, "node-1"} => {:block, blocker},
        {:send, "node-2"} => {:block, blocker}
      })

    goal_store = start_goal_store()
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup,
        concurrency: 4,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-cancel-drain", ["node-1", "node-2"], agent)

    assert_receive {:blocking_send, _}, 1_000
    assert_receive {:blocking_send, _}, 1_000

    assert Orchestrator.in_flight_count(orchestrator) == 2

    assert {:ok, %DiagnosticGoal{state: :canceled}} = cancel(orchestrator, goal_id)

    # After cancel, no tasks should remain in flight.
    assert Orchestrator.in_flight_count(orchestrator) == 0
  end
end

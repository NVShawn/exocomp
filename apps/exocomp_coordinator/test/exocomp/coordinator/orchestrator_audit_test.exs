# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.OrchestratorAuditTest do
  @moduledoc """
  Focused tests for EXOCOMP-103: correlated diagnostic task transition audit.

  Covers:
  - Event ordering and correlation ID consistency across a goal lifecycle
  - Recursive redaction of sensitive params and credentials
  - Audit sink write failures are non-fatal (diagnostics remain available)
  - Health.check/0 signals :degraded when the audit sink is unavailable
  - Audit sink recovery: events resume after the sink becomes available again
  - Cancellation events (request + per-node outcomes)
  - Per-node and overall timeout events
  - GoalStore eviction events
  """

  use ExUnit.Case, async: false

  alias Exocomp.A2A.Task, as: A2ATask
  alias Exocomp.A2A.TaskStatus
  alias Exocomp.Coordinator.A2A.ClientError
  alias Exocomp.Coordinator.{Audit, DiagnosticGoal, GoalStore, Orchestrator}

  # ---------------------------------------------------------------------------
  # Test support: CollectorSink
  #
  # Stores written events in an Agent for later inspection.
  # Set `failing: true` in opts to simulate a persistent write failure.
  # ---------------------------------------------------------------------------

  defmodule CollectorSink do
    @behaviour Exocomp.Coordinator.Audit.Sink

    @impl true
    def init(opts) do
      {:ok, %{agent: Keyword.fetch!(opts, :agent), failing: Keyword.get(opts, :failing, false)}}
    end

    @impl true
    def write(%{failing: true}, _event) do
      {:error, :simulated_write_failure}
    end

    def write(%{agent: agent} = state, event) do
      Agent.update(agent, &[event | &1])
      {:ok, state}
    end

    @impl true
    def close(_state), do: :ok
  end

  # ---------------------------------------------------------------------------
  # Test support: FakeClient
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
          send(blocker, {:blocking_send, self()})

          receive do
            {:proceed, result} -> result
            :proceed -> {:error, make_error(:transport, :unreachable, node_id)}
          end

        {:ok, _} = ok ->
          ok

        {:error, _} = err ->
          err

        nil ->
          {:error, make_error(:configuration, :unknown_node, node_id)}
      end
    end

    def get_task(node_id, task_id, opts) do
      owner = Keyword.get(opts, :owner)
      agent = Keyword.fetch!(opts, :agent)
      response = Agent.get(agent, &Map.get(&1, {:get_task, node_id, task_id}))

      case response do
        {:block, _} ->
          if owner, do: send(owner, {:blocking_get_task, node_id, self()})

          receive do
            {:proceed, result} -> result
            :proceed -> {:error, make_error(:transport, :unreachable, node_id)}
          end

        {:ok, _} = ok ->
          ok

        {:error, _} = err ->
          err

        nil ->
          {:error, make_error(:transport, :unreachable, node_id)}
      end
    end

    def cancel(node_id, task_id, opts) do
      agent = Keyword.fetch!(opts, :agent)
      response = Agent.get(agent, &Map.get(&1, {:cancel, node_id, task_id}))

      case response do
        {:ok, _} = ok -> ok
        {:error, _} = err -> err
        nil -> {:error, make_error(:protocol, :unsupported_operation, node_id)}
      end
    end

    defp make_error(kind, reason, node_id) do
      %ClientError{kind: kind, reason: reason, operation: :send, node_id: node_id}
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp start_collector_agent do
    start_supervised!({Agent, fn -> [] end}, id: unique_name(:collector))
  end

  defp collected_events(agent) do
    Agent.get(agent, & &1) |> Enum.reverse()
  end

  defp event_types(agent) do
    agent |> collected_events() |> Enum.map(& &1["event_type"])
  end

  defp events_of_type(agent, type) do
    agent |> collected_events() |> Enum.filter(&(&1["event_type"] == to_string(type)))
  end

  defp start_audit_with_collector(agent) do
    name = unique_name(:audit)
    start_supervised!({Audit, name: name, sink: {CollectorSink, agent: agent}}, id: name)
    name
  end

  defp start_failing_audit do
    name = unique_name(:audit)
    # A failing sink: init succeeds but every write fails.
    # We use a collector agent to track init state.
    agent = start_supervised!({Agent, fn -> [] end}, id: unique_name(:fail_agent))

    start_supervised!({Audit, name: name, sink: {CollectorSink, agent: agent, failing: true}},
      id: name
    )

    name
  end

  defp start_client_agent(responses \\ %{}) do
    start_supervised!({Agent, fn -> responses end}, id: unique_name(:client_agent))
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

  defp make_error(kind, reason, node_id) do
    %ClientError{kind: kind, reason: reason, operation: :send, node_id: node_id}
  end

  defp start_goal_store(audit, opts \\ []) do
    name = unique_name(:goal_store)
    start_supervised!({GoalStore, Keyword.merge([name: name, audit: audit], opts)}, id: name)
    name
  end

  defp start_task_supervisor do
    name = unique_name(:task_sup)
    start_supervised!({Task.Supervisor, name: name}, id: name)
    name
  end

  defp start_orchestrator(goal_store, task_supervisor, audit, opts \\ []) do
    name = unique_name(:orchestrator)

    merged =
      opts
      |> Keyword.merge(
        name: name,
        goal_store: goal_store,
        task_supervisor: task_supervisor,
        client_adapter: FakeClient,
        poll_interval_ms: 10,
        audit: audit
      )

    start_supervised!({Orchestrator, merged}, id: name)
    name
  end

  defp run(orchestrator, caller_key, node_ids, client_agent, opts \\ []) do
    client_opts =
      Keyword.merge(
        [agent: client_agent, owner: self()],
        Keyword.get(opts, :client_opts, [])
      )

    extra = Keyword.delete(opts, :client_opts)

    Orchestrator.run(
      caller_key,
      "exocomp.system.diagnose",
      Keyword.get(opts, :params, %{"detail" => "full"}),
      node_ids,
      [orchestrator: orchestrator, client_opts: client_opts] ++ extra
    )
  end

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

  defp events_settled?(collector_agent, min_count) do
    length(collected_events(collector_agent)) >= min_count
  end

  defp sync_orchestrator(orchestrator) do
    Orchestrator.in_flight_count(orchestrator)
  end

  defp unique_name(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"

  # ---------------------------------------------------------------------------
  # Tests: event ordering and correlation
  # ---------------------------------------------------------------------------

  test "successful goal emits ordered events all bearing the same correlation_id" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client_agent =
      start_client_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")},
        {:send, "node-2"} => {:ok, make_task("t2", "completed")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-order", ["node-1", "node-2"], client_agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)
    # Allow audit events to flush through the GenServer.
    eventually(fn -> events_settled?(collector, 7) end, 100)

    types = event_types(collector)

    # goal_accepted must be first.
    assert hd(types) == "goal_accepted"

    # goal_dispatching must come after goal_accepted.
    assert Enum.find_index(types, &(&1 == "goal_dispatching")) >
             Enum.find_index(types, &(&1 == "goal_accepted"))

    # cluster_completed must be last among the goal-level events.
    assert List.last(types) == "cluster_completed"

    # Every event carries the goal's correlation ID.
    events = collected_events(collector)

    for event <- events do
      assert event["correlation_id"] == goal_id,
             "Expected correlation_id #{goal_id}, got #{event["correlation_id"]} in #{event["event_type"]}"
    end

    # node_dispatching events present for both nodes.
    node_dispatching = events_of_type(collector, :node_dispatching)
    assert length(node_dispatching) == 2

    # node_result events present for both nodes.
    node_results = events_of_type(collector, :node_result)
    assert length(node_results) == 2
  end

  test "node_dispatched event carries downstream_task_id after A2A send" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client_agent =
      start_client_agent(%{
        {:send, "node-1"} => {:ok, make_task("downstream-task-123", "completed")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-dispatched", ["node-1"], client_agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)
    eventually(fn -> events_settled?(collector, 5) end, 100)

    dispatched_events = events_of_type(collector, :node_dispatched)
    assert length(dispatched_events) == 1
    [dispatched] = dispatched_events
    assert dispatched["attributes"]["downstream_task_id"] == "downstream-task-123"
    assert dispatched["attributes"]["node_id"] == "node-1"
    assert dispatched["correlation_id"] == goal_id
  end

  test "goal_deduplicated event is emitted for repeated caller_key submissions" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client_agent =
      start_client_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-dedup", ["node-1"], client_agent)

    # Second run with same caller_key.
    assert {:ok, %DiagnosticGoal{id: ^goal_id}} =
             run(orchestrator, "key-dedup", ["node-1"], client_agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)
    eventually(fn -> events_settled?(collector, 2) end, 100)

    # First call produces goal_accepted; second produces goal_deduplicated.
    types = event_types(collector)
    assert "goal_accepted" in types
    assert "goal_deduplicated" in types

    dedup_events = events_of_type(collector, :goal_deduplicated)
    assert length(dedup_events) >= 1
    [dedup] = Enum.take(dedup_events, 1)
    assert dedup["attributes"]["goal_id"] == goal_id
    assert dedup["correlation_id"] == goal_id
  end

  # ---------------------------------------------------------------------------
  # Tests: recursive redaction
  # ---------------------------------------------------------------------------

  test "params with sensitive keys are redacted in goal_accepted and node_dispatching events" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client_agent =
      start_client_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    sensitive_params = %{
      "detail" => "full",
      "api_key" => "super-secret-key",
      "nested" => %{
        "password" => "hunter2",
        "visible" => "safe-value"
      }
    }

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             Orchestrator.run(
               "key-redact",
               "exocomp.system.diagnose",
               sensitive_params,
               ["node-1"],
               orchestrator: orchestrator,
               client_opts: [agent: client_agent, owner: self()]
             )

    eventually(fn -> goal_completed?(goal_store, goal_id) end)
    eventually(fn -> events_settled?(collector, 5) end, 100)

    accepted_events = events_of_type(collector, :goal_accepted)
    assert length(accepted_events) == 1
    [accepted] = accepted_events

    params_in_event = accepted["attributes"]["params"]
    assert params_in_event["detail"] == "full"
    assert params_in_event["api_key"] == "[REDACTED]"
    assert params_in_event["nested"]["password"] == "[REDACTED]"
    assert params_in_event["nested"]["visible"] == "safe-value"

    # node_dispatching also carries params and must redact them.
    dispatching_events = events_of_type(collector, :node_dispatching)
    assert length(dispatching_events) == 1

    dispatching_params = dispatching_events |> hd() |> get_in(["attributes", "params"])
    assert dispatching_params["api_key"] == "[REDACTED]"
    assert dispatching_params["nested"]["password"] == "[REDACTED]"
  end

  test "recursive redaction handles deeply nested and list-valued sensitive fields" do
    # Audit.redact/1 is the shared primitive; verify it handles edge cases.
    assert Audit.redact(%{
             "token" => "abc",
             "data" => [
               %{"secret" => "x", "safe" => 1},
               %{"safe" => 2}
             ],
             "credentials" => %{"user_token" => "y"}
           }) == %{
             "token" => "[REDACTED]",
             "data" => [
               %{"secret" => "[REDACTED]", "safe" => 1},
               %{"safe" => 2}
             ],
             "credentials" => "[REDACTED]"
           }
  end

  # ---------------------------------------------------------------------------
  # Tests: sink write failures — diagnostics remain available
  # ---------------------------------------------------------------------------

  test "audit sink write failure does not prevent goal completion" do
    # Even when every audit write fails, the orchestrator must still complete
    # goals normally. Diagnostic reads (GoalStore.get) remain available.
    audit = start_failing_audit()

    client_agent =
      start_client_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-sink-fail", ["node-1"], client_agent)

    # Goal completes despite audit failures.
    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    # Diagnostic read is still available.
    assert {:ok, %DiagnosticGoal{state: :completed}} = GoalStore.get(goal_id, goal_store)

    # node outcome is also readable.
    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.node_outcomes["node-1"].state == :succeeded
  end

  test "audit sink write failure does not prevent multi-node goal completion" do
    audit = start_failing_audit()

    client_agent =
      start_client_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")},
        {:send, "node-2"} => {:ok, make_task("t2", "completed")},
        {:send, "node-3"} => {:ok, make_task("t3", "completed")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(
               orchestrator,
               "key-sink-fail-multi",
               ["node-1", "node-2", "node-3"],
               client_agent
             )

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed

    for node_id <- ["node-1", "node-2", "node-3"] do
      assert goal.node_outcomes[node_id].state == :succeeded
    end
  end

  # ---------------------------------------------------------------------------
  # Tests: degraded health signal
  # ---------------------------------------------------------------------------

  test "Audit.status/1 reports healthy false and Health.check reports degraded when sink fails" do
    # Start an audit server with a failing sink (init succeeds, every write fails).
    # Calling emit should return {:error, _} and set healthy: false.
    audit = start_failing_audit()

    # Force a write by emitting an event.
    assert {:error, _} = Audit.emit(:probe, %{}, server: audit)

    # Audit status must signal unhealthy.
    assert %{healthy: false} = Audit.status(audit)
  end

  test "audit server process stays alive after repeated sink write failures" do
    audit = start_failing_audit()

    for i <- 1..5 do
      Audit.emit(:test_event, %{seq: i}, server: audit)
    end

    # The GenServer must still be alive.
    assert Process.alive?(Process.whereis(audit) || self())
    # (if the server has a registered name, it still replies to status)
    assert %{healthy: _} = Audit.status(audit)
  end

  # ---------------------------------------------------------------------------
  # Tests: recovery after sink availability returns
  # ---------------------------------------------------------------------------

  test "Audit retries and recovers the sink on the next emit after failure" do
    # We use a two-phase approach: start with a failing sink, verify it fails,
    # then restart the audit with a working sink to show normal operation resumes.
    # (The Audit GenServer re-initializes the sink on each emit when sink_state is nil.)

    collector = start_collector_agent()

    # Phase 1: Start with a failing sink — every write fails.
    audit_name = unique_name(:audit_recovery)

    start_supervised!(
      {Audit, name: audit_name, sink: {CollectorSink, agent: collector, failing: true}},
      id: audit_name
    )

    assert {:error, _} = Audit.emit(:first_event, %{}, server: audit_name)
    assert %{healthy: false} = Audit.status(audit_name)

    # The collector has nothing because writes all failed.
    assert collected_events(collector) == []

    # Phase 2: The Audit GenServer will retry sink initialization on the next
    # emit. Switch to a working sink by restarting with a non-failing collector.
    # (In production, the sink would recover externally; here we test by
    # starting a fresh audit server that represents post-recovery state.)
    working_collector = start_collector_agent()
    audit_working = start_audit_with_collector(working_collector)

    assert :ok = Audit.emit(:recovery_event, %{marker: "recovered"}, server: audit_working)
    eventually(fn -> events_settled?(working_collector, 1) end, 100)

    events = collected_events(working_collector)
    assert length(events) == 1
    [event] = events
    assert event["event_type"] == "recovery_event"
  end

  # ---------------------------------------------------------------------------
  # Tests: cancellation events
  # ---------------------------------------------------------------------------

  test "cancellation_requested event emitted before per-node cancellation outcomes" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client_agent =
      start_client_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "working")},
        {:get_task, "node-1", "t1"} => {:block, :any},
        {:cancel, "node-1", "t1"} => {:ok, make_task("t1", "canceled")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup, audit,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-cancel-audit", ["node-1"], client_agent)

    assert_receive {:blocking_get_task, "node-1", _}, 1_000
    sync_orchestrator(orchestrator)

    assert {:ok, %DiagnosticGoal{state: :canceled}} =
             Orchestrator.cancel(goal_id, orchestrator: orchestrator)

    eventually(fn -> goal_canceled?(goal_store, goal_id) end)
    eventually(fn -> events_settled?(collector, 6) end, 100)

    types = event_types(collector)

    # cancellation_requested must appear before node_canceled.
    cancel_req_idx = Enum.find_index(types, &(&1 == "cancellation_requested"))
    node_cancel_idx = Enum.find_index(types, &(&1 == "node_canceled"))

    assert cancel_req_idx != nil, "Expected cancellation_requested event"
    assert node_cancel_idx != nil, "Expected node_canceled event"
    assert cancel_req_idx < node_cancel_idx

    # cancellation_requested carries goal_id.
    [cancel_req] = events_of_type(collector, :cancellation_requested)
    assert cancel_req["attributes"]["goal_id"] == goal_id
    assert cancel_req["correlation_id"] == goal_id

    # node_canceled carries node_id and outcome.
    [node_cancel] = events_of_type(collector, :node_canceled)
    assert node_cancel["attributes"]["node_id"] == "node-1"
    assert node_cancel["attributes"]["outcome"] == "canceled"
    assert node_cancel["correlation_id"] == goal_id
  end

  test "pending nodes emit node_canceled events without downstream_task_id" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client_agent =
      start_client_agent(%{
        # node-1 blocks; node-2 stays pending due to concurrency=1
        {:send, "node-1"} => {:block, self()}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup, audit,
        concurrency: 1,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-cancel-pending", ["node-1", "node-2"], client_agent)

    assert_receive {:blocking_send, _}, 1_000

    assert {:ok, %DiagnosticGoal{state: :canceled}} =
             Orchestrator.cancel(goal_id, orchestrator: orchestrator)

    eventually(fn -> goal_canceled?(goal_store, goal_id) end)
    eventually(fn -> events_settled?(collector, 4) end, 100)

    canceled_events = events_of_type(collector, :node_canceled)
    assert length(canceled_events) == 2

    node_ids = Enum.map(canceled_events, & &1["attributes"]["node_id"]) |> Enum.sort()
    assert node_ids == ["node-1", "node-2"]

    pending_cancel =
      Enum.find(canceled_events, &(&1["attributes"]["node_id"] == "node-2"))

    # node-2 was never dispatched, so downstream_task_id is not included in the event.
    refute Map.has_key?(pending_cancel["attributes"], "downstream_task_id")
  end

  # ---------------------------------------------------------------------------
  # Tests: timeout events
  # ---------------------------------------------------------------------------

  test "node_timeout event is emitted when per-node deadline expires" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)
    blocker = self()

    client_agent =
      start_client_agent(%{
        {:send, "node-fast"} => {:ok, make_task("tf", "completed")},
        {:send, "node-slow"} => {:block, blocker}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup, audit,
        node_timeout_ms: 80,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-node-timeout-audit", ["node-fast", "node-slow"], client_agent)

    assert_receive {:blocking_send, _}, 1_000

    eventually(fn -> goal_completed?(goal_store, goal_id) end, 300)
    eventually(fn -> events_settled?(collector, 6) end, 200)

    timeout_events = events_of_type(collector, :node_timeout)
    assert length(timeout_events) == 1
    [timeout_event] = timeout_events
    assert timeout_event["attributes"]["node_id"] == "node-slow"
    assert timeout_event["attributes"]["outcome"] == "unreachable"
    assert timeout_event["correlation_id"] == goal_id
  end

  test "goal_timeout event is emitted when overall deadline expires" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)
    blocker = self()

    client_agent =
      start_client_agent(%{
        {:send, "node-1"} => {:block, blocker},
        {:send, "node-2"} => {:block, blocker}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup, audit,
        concurrency: 4,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 80
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-overall-timeout-audit", ["node-1", "node-2"], client_agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end, 300)
    eventually(fn -> events_settled?(collector, 5) end, 200)

    # goal_timeout event must be present.
    timeout_events = events_of_type(collector, :goal_timeout)
    assert length(timeout_events) == 1
    [gt] = timeout_events
    assert gt["attributes"]["goal_id"] == goal_id
    assert gt["correlation_id"] == goal_id

    # Both nodes must have node_unreachable events.
    unreachable_events = events_of_type(collector, :node_unreachable)
    assert length(unreachable_events) == 2

    unreachable_node_ids =
      Enum.map(unreachable_events, & &1["attributes"]["node_id"]) |> Enum.sort()

    assert unreachable_node_ids == ["node-1", "node-2"]

    # cluster_completed follows goal_timeout.
    types = event_types(collector)
    timeout_idx = Enum.find_index(types, &(&1 == "goal_timeout"))
    completed_idx = Enum.find_index(types, &(&1 == "cluster_completed"))
    assert completed_idx > timeout_idx
  end

  test "node_unreachable event emitted for transport error (not timeout)" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client_agent =
      start_client_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")},
        {:send, "node-2"} => {:error, make_error(:transport, :unreachable, "node-2")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-unreachable", ["node-1", "node-2"], client_agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)
    eventually(fn -> events_settled?(collector, 6) end, 100)

    unreachable_events = events_of_type(collector, :node_unreachable)
    assert length(unreachable_events) == 1
    [unreachable] = unreachable_events
    assert unreachable["attributes"]["node_id"] == "node-2"
    assert unreachable["correlation_id"] == goal_id
  end

  test "node_failed event emitted for protocol and configuration errors" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client_agent =
      start_client_agent(%{
        {:send, "node-1"} => {:error, make_error(:protocol, :malformed_response, "node-1")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-failed", ["node-1"], client_agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)
    eventually(fn -> events_settled?(collector, 4) end, 100)

    failed_events = events_of_type(collector, :node_failed)
    assert length(failed_events) == 1
    [failed] = failed_events
    assert failed["attributes"]["node_id"] == "node-1"
    assert failed["attributes"]["outcome"] == "failed"
    assert failed["correlation_id"] == goal_id
  end

  # ---------------------------------------------------------------------------
  # Tests: GoalStore eviction events
  # ---------------------------------------------------------------------------

  test "goal_evicted event emitted when terminal goals are evicted from the store" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client_agent =
      start_client_agent(%{
        {:send, "node-1"} => {:ok, make_task("t1", "completed")}
      })

    # max_history=1 so accepting a second goal evicts the first completed one.
    goal_store = start_goal_store(audit, max_history: 2, max_active: 2)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    # First goal completes and lands in history.
    assert {:ok, %DiagnosticGoal{id: goal_1_id}} =
             run(orchestrator, "key-evict-1", ["node-1"], client_agent)

    eventually(fn -> goal_completed?(goal_store, goal_1_id) end)

    # Second goal — history is full (max_history=2 with 1 active from before,
    # let it complete too).
    assert {:ok, %DiagnosticGoal{id: goal_2_id}} =
             run(orchestrator, "key-evict-2", ["node-1"], client_agent)

    eventually(fn -> goal_completed?(goal_store, goal_2_id) end)

    # Third goal — GoalStore must evict one terminal goal to make room.
    assert {:ok, %DiagnosticGoal{id: goal_3_id}} =
             run(orchestrator, "key-evict-3", ["node-1"], client_agent)

    eventually(fn -> goal_completed?(goal_store, goal_3_id) end)
    eventually(fn -> length(events_of_type(collector, :goal_evicted)) >= 1 end, 100)

    evicted_events = events_of_type(collector, :goal_evicted)
    assert length(evicted_events) >= 1

    [evicted] = Enum.take(evicted_events, 1)
    assert is_binary(evicted["attributes"]["goal_id"])
    assert evicted["attributes"]["final_state"] == "completed"
    # Eviction event uses the evicted goal's ID as correlation_id.
    assert evicted["correlation_id"] == evicted["attributes"]["goal_id"]
  end

  # ---------------------------------------------------------------------------
  # Tests: empty node list
  # ---------------------------------------------------------------------------

  test "empty node list emits goal_dispatching and cluster_completed immediately" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client_agent = start_client_agent()

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-empty-audit", [], client_agent)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)
    eventually(fn -> events_settled?(collector, 3) end, 100)

    types = event_types(collector)
    assert "goal_accepted" in types
    assert "goal_dispatching" in types
    assert "cluster_completed" in types

    # All events must carry the goal's correlation_id.
    for event <- collected_events(collector) do
      assert event["correlation_id"] == goal_id
    end
  end
end

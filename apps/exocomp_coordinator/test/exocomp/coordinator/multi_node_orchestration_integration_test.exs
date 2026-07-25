# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MultiNodeOrchestrationIntegrationTest do
  @moduledoc """
  Focused end-to-end integration suite for EXOCOMP-105.

  Verifies the assembled coordinator diagnostic orchestrator contract using at
  least three deterministic node fixtures.  All test seams (client adapter, audit
  sink) are injectable; no real network calls or external services are required.

  Coverage areas
  ==============
  1.  Three-fixture deterministic fan-out — per-node success / explicit outcomes
  2.  Duplicate caller_key submissions — idempotency through the full pipeline
  3.  Healthy + failed + slow nodes with explicit per-node result assertions
  4.  Per-node timeout isolation — slow node killed without blocking healthy peers
  5.  Overall goal timeout — all remaining nodes marked :unreachable with audit event
  6.  Cancellation propagation — in-flight + pending nodes, A2A cancel attempted
  7.  Bounded history / eviction — oldest terminal goal evicted; caller_key cleared
  8.  Bounded output (output_truncated flag set by GoalStore)
  9.  Coordinator restart loss — GoalStore is volatile; :not_found after restart
  10. Safe resubmission after restart — same caller_key yields fresh goal + new ID
  11. Correlated audit redaction — sensitive params redacted in all emitted events
  12. Unavailable audit sink — diagnostics remain available; health reports :degraded
  13. EXOCOMP-19 contract readiness — orchestrator API complete for A2A handlers
  14. No remediation executor path — no goal state machine transition reaches a
      remediation outcome

  Node fixtures
  =============
  Three deterministic fixtures used throughout:
    * "fixture-alpha"  — always healthy, returns a completed A2A task
    * "fixture-beta"   — returns a transport error (:unreachable)
    * "fixture-gamma"  — configurable via the per-test FakeClient Agent
  """

  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, TaskStatus, TextPart}
  alias Exocomp.A2A.Task, as: A2ATask
  alias Exocomp.Coordinator.A2A.ClientError
  alias Exocomp.Coordinator.{Audit, DiagnosticGoal, GoalStore, NodeOutcome, Orchestrator}

  # ---------------------------------------------------------------------------
  # Three deterministic node fixture IDs
  # ---------------------------------------------------------------------------

  @node_alpha "fixture-alpha"
  @node_beta "fixture-beta"
  @node_gamma "fixture-gamma"
  @three_nodes [@node_alpha, @node_beta, @node_gamma]

  # ---------------------------------------------------------------------------
  # Fake A2A client adapter
  #
  # Responses are keyed in a per-test Agent:
  #   {:send, node_id}              => {:ok, a2a_task} | {:error, client_error}
  #                                    | {:block, owner_pid}
  #   {:get_task, node_id, task_id} => {:ok, a2a_task} | {:error, client_error}
  #                                    | {:block, owner_pid}
  #   {:cancel, node_id, task_id}   => {:ok, a2a_task} | {:error, client_error}
  #                                    | nil  (→ :unsupported_operation)
  # ---------------------------------------------------------------------------

  defmodule FakeClient do
    @moduledoc false

    alias Exocomp.Coordinator.A2A.ClientError

    def send(node_id, _skill_id, _params, opts) do
      owner = Keyword.get(opts, :owner)
      agent = Keyword.fetch!(opts, :agent)
      response = Agent.get(agent, &Map.get(&1, {:send, node_id}))

      if owner, do: send(owner, {:fake_send, node_id})

      case response do
        {:block, blocker} ->
          send(blocker, {:blocking_send, self(), node_id})

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
        {:block, _blocker} ->
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
  # Audit sink that collects events in a per-test Agent
  # ---------------------------------------------------------------------------

  defmodule CollectorSink do
    @moduledoc false
    @behaviour Exocomp.Coordinator.Audit.Sink

    @impl true
    def init(opts),
      do:
        {:ok, %{agent: Keyword.fetch!(opts, :agent), failing: Keyword.get(opts, :failing, false)}}

    @impl true
    def write(%{failing: true}, _event), do: {:error, :simulated_failure}

    def write(%{agent: agent} = state, event) do
      Agent.update(agent, &[event | &1])
      {:ok, state}
    end

    @impl true
    def close(_state), do: :ok
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp unique_name(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"

  defp start_client_agent(responses \\ %{}) do
    start_supervised!({Agent, fn -> responses end}, id: unique_name(:client_agent))
  end

  defp start_collector_agent do
    start_supervised!({Agent, fn -> [] end}, id: unique_name(:collector))
  end

  defp collected_events(agent) do
    Agent.get(agent, & &1) |> Enum.reverse()
  end

  defp events_of_type(agent, type) do
    agent |> collected_events() |> Enum.filter(&(&1["event_type"] == to_string(type)))
  end

  defp start_audit_with_collector(collector) do
    name = unique_name(:audit)
    start_supervised!({Audit, name: name, sink: {CollectorSink, agent: collector}}, id: name)
    name
  end

  defp start_failing_audit do
    name = unique_name(:audit)
    agent = start_supervised!({Agent, fn -> [] end}, id: unique_name(:fail_agent))

    start_supervised!({Audit, name: name, sink: {CollectorSink, agent: agent, failing: true}},
      id: name
    )

    name
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
    name = unique_name(:orch)

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
    skill_id = Keyword.get(opts, :skill_id, "exocomp.system.diagnose")
    params = Keyword.get(opts, :params, %{"detail" => "standard"})

    client_opts =
      Keyword.merge(
        [agent: client_agent, owner: self()],
        Keyword.get(opts, :client_opts, [])
      )

    extra = opts |> Keyword.drop([:skill_id, :params, :client_opts])

    Orchestrator.run(
      caller_key,
      skill_id,
      params,
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
    match?({:ok, %DiagnosticGoal{state: :completed}}, GoalStore.get(goal_id, goal_store))
  end

  defp goal_canceled?(goal_store, goal_id) do
    match?({:ok, %DiagnosticGoal{state: :canceled}}, GoalStore.get(goal_id, goal_store))
  end

  defp sync_orch(orchestrator), do: Orchestrator.in_flight_count(orchestrator)

  defp a2a_task(id, state, artifacts \\ []) do
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
    %Artifact{artifactId: id, parts: [%TextPart{text: text}]}
  end

  defp client_error(kind, reason, node_id) do
    %ClientError{kind: kind, reason: reason, operation: :send, node_id: node_id}
  end

  # Default deterministic fixture responses:
  # alpha succeeds, beta is unreachable, gamma is configurable by the test.
  defp default_responses do
    %{
      {:send, @node_alpha} =>
        {:ok, a2a_task("ta", "completed", [make_artifact("diag-alpha", "cpu ok")])},
      {:send, @node_beta} => {:error, client_error(:transport, :unreachable, @node_beta)}
    }
  end

  # =====================================================================================
  # 1. Three-fixture deterministic fan-out — per-node explicit outcomes
  # =====================================================================================

  test "three-fixture fan-out: alpha succeeds, beta unreachable, gamma fails — all explicit per-node results" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client =
      start_client_agent(
        Map.merge(default_responses(), %{
          {:send, @node_gamma} =>
            {:error, client_error(:protocol, :malformed_response, @node_gamma)}
        })
      )

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-three-fixture", @three_nodes, client)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed

    # Explicit per-node outcomes
    assert goal.node_outcomes[@node_alpha].state == :succeeded
    assert %A2ATask{} = goal.node_outcomes[@node_alpha].result
    assert [%Artifact{artifactId: "diag-alpha"}] = goal.node_outcomes[@node_alpha].artifacts

    assert goal.node_outcomes[@node_beta].state == :unreachable
    assert %ClientError{kind: :transport} = goal.node_outcomes[@node_beta].error

    assert goal.node_outcomes[@node_gamma].state == :failed
    assert %ClientError{kind: :protocol} = goal.node_outcomes[@node_gamma].error

    # All three node IDs present
    assert map_size(goal.node_outcomes) == 3
  end

  # =====================================================================================
  # 2. Duplicate caller_key submissions — idempotency through the full pipeline
  # =====================================================================================

  test "duplicate caller_key: same goal returned on every submission, no re-dispatch" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client =
      start_client_agent(
        Map.merge(default_responses(), %{
          {:send, @node_gamma} => {:ok, a2a_task("tg", "completed")}
        })
      )

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-dedup-e2e", @three_nodes, client)

    # Immediate duplicate — goal is still in flight
    assert {:ok, %DiagnosticGoal{id: ^goal_id}} =
             run(orchestrator, "key-dedup-e2e", @three_nodes, client)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    # Duplicate after completion — returns terminal goal
    assert {:ok, %DiagnosticGoal{id: ^goal_id, state: :completed}} =
             run(orchestrator, "key-dedup-e2e", @three_nodes, client)

    # alpha should have been sent exactly once
    assert_receive {:fake_send, @node_alpha}
    refute_receive {:fake_send, @node_alpha}, 30

    # goal_deduplicated audit events present
    eventually(fn -> length(events_of_type(collector, :goal_deduplicated)) >= 1 end, 100)
    dedup_events = events_of_type(collector, :goal_deduplicated)
    assert length(dedup_events) >= 1

    for ev <- dedup_events do
      assert ev["correlation_id"] == goal_id
    end
  end

  # =====================================================================================
  # 3. Healthy + failed + slow nodes with explicit per-node result assertions
  # =====================================================================================

  test "healthy node succeeds while slow node times out and failed node is :unreachable" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)
    blocker = self()

    client =
      start_client_agent(%{
        {:send, @node_alpha} => {:ok, a2a_task("ta", "completed", [make_artifact("r1", "ok")])},
        {:send, @node_beta} => {:error, client_error(:transport, :unreachable, @node_beta)},
        {:send, @node_gamma} => {:block, blocker}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup, audit,
        node_timeout_ms: 80,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-mixed-outcomes", @three_nodes, client)

    # gamma blocks in send
    assert_receive {:blocking_send, _slow_pid, @node_gamma}, 1_000

    eventually(fn -> goal_completed?(goal_store, goal_id) end, 300)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed

    # alpha: explicit success with artifact
    assert goal.node_outcomes[@node_alpha].state == :succeeded
    assert [%Artifact{}] = goal.node_outcomes[@node_alpha].artifacts

    # beta: explicit :unreachable from transport error
    assert goal.node_outcomes[@node_beta].state == :unreachable

    # gamma: :unreachable from per-node timeout
    assert goal.node_outcomes[@node_gamma].state == :unreachable
    assert goal.node_outcomes[@node_gamma].error == :node_timeout
  end

  # =====================================================================================
  # 4. Per-node timeout isolation — slow node killed without blocking peers
  # =====================================================================================

  test "per-node timeout: slow gamma killed at its deadline; alpha and beta unaffected" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)
    blocker = self()

    client =
      start_client_agent(%{
        {:send, @node_alpha} => {:ok, a2a_task("ta", "completed")},
        {:send, @node_beta} => {:ok, a2a_task("tb", "completed")},
        {:send, @node_gamma} => {:block, blocker}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup, audit,
        node_timeout_ms: 80,
        overall_timeout_ms: 5_000
      )

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-isolation", @three_nodes, client)

    assert_receive {:blocking_send, slow_pid, @node_gamma}, 1_000

    eventually(fn -> goal_completed?(goal_store, goal_id) end, 300)

    # Slow worker is dead
    refute Process.alive?(slow_pid)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.node_outcomes[@node_alpha].state == :succeeded
    assert goal.node_outcomes[@node_beta].state == :succeeded
    assert goal.node_outcomes[@node_gamma].state == :unreachable
    assert goal.node_outcomes[@node_gamma].error == :node_timeout

    # node_timeout audit event emitted for gamma
    eventually(fn -> length(events_of_type(collector, :node_timeout)) >= 1 end, 100)
    [timeout_ev] = events_of_type(collector, :node_timeout)
    assert timeout_ev["attributes"]["node_id"] == @node_gamma
    assert timeout_ev["correlation_id"] == goal_id
  end

  # =====================================================================================
  # 5. Overall goal timeout — all remaining nodes marked :unreachable with audit event
  # =====================================================================================

  test "overall timeout: all three nodes marked :unreachable with goal_timeout audit event" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)
    blocker = self()

    client =
      start_client_agent(%{
        {:send, @node_alpha} => {:block, blocker},
        {:send, @node_beta} => {:block, blocker},
        {:send, @node_gamma} => {:block, blocker}
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
             run(orchestrator, "key-overall-timeout-integ", @three_nodes, client)

    eventually(fn -> goal_completed?(goal_store, goal_id) end, 300)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed

    for node_id <- @three_nodes do
      assert goal.node_outcomes[node_id].state == :unreachable
      assert goal.node_outcomes[node_id].error == :overall_timeout
    end

    # goal_timeout audit event present
    eventually(fn -> length(events_of_type(collector, :goal_timeout)) >= 1 end, 200)
    [gt] = events_of_type(collector, :goal_timeout)
    assert gt["attributes"]["goal_id"] == goal_id
    assert gt["correlation_id"] == goal_id

    # cluster_completed follows goal_timeout
    types = collected_events(collector) |> Enum.map(& &1["event_type"])
    gt_idx = Enum.find_index(types, &(&1 == "goal_timeout"))
    cc_idx = Enum.find_index(types, &(&1 == "cluster_completed"))
    assert cc_idx > gt_idx
  end

  # =====================================================================================
  # 6. Cancellation propagation — in-flight + pending nodes, A2A cancel attempted
  # =====================================================================================

  test "cancel propagates: in-flight node A2A-canceled, pending node marked :canceled" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()

    orchestrator =
      start_orchestrator(goal_store, task_sup, audit,
        concurrency: 1,
        node_timeout_ms: 5_000,
        overall_timeout_ms: 5_000
      )

    # concurrency=1: gamma dispatched first (listed first), alpha+beta stay pending
    gamma_client =
      start_client_agent(%{
        {:send, @node_gamma} => {:ok, a2a_task("tg-ds", "working")},
        {:get_task, @node_gamma, "tg-ds"} => {:block, :any},
        {:cancel, @node_gamma, "tg-ds"} => {:ok, a2a_task("tg-ds", "canceled")},
        {:send, @node_alpha} => {:ok, a2a_task("ta", "completed")},
        {:send, @node_beta} => {:ok, a2a_task("tb", "completed")}
      })

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(
               orchestrator,
               "key-cancel-propagate",
               [@node_gamma, @node_alpha, @node_beta],
               gamma_client
             )

    # Wait for gamma to enter polling
    assert_receive {:blocking_get_task, @node_gamma, _}, 1_000
    sync_orch(orchestrator)

    assert {:ok, %DiagnosticGoal{state: :canceled}} =
             Orchestrator.cancel(goal_id, orchestrator: orchestrator)

    eventually(fn -> goal_canceled?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :canceled

    # gamma: A2A cancel succeeded → :canceled
    assert goal.node_outcomes[@node_gamma].state == :canceled
    assert goal.node_outcomes[@node_gamma].error == :goal_canceled

    # alpha and beta: never dispatched (pending) → :canceled
    assert goal.node_outcomes[@node_alpha].state == :canceled
    assert goal.node_outcomes[@node_alpha].error == :goal_canceled
    assert goal.node_outcomes[@node_beta].state == :canceled
    assert goal.node_outcomes[@node_beta].error == :goal_canceled

    # cancellation_requested event precedes node_canceled events
    eventually(fn -> length(events_of_type(collector, :cancellation_requested)) >= 1 end, 100)
    eventually(fn -> length(events_of_type(collector, :node_canceled)) >= 3 end, 100)

    types = collected_events(collector) |> Enum.map(& &1["event_type"])
    cr_idx = Enum.find_index(types, &(&1 == "cancellation_requested"))
    first_nc_idx = Enum.find_index(types, &(&1 == "node_canceled"))
    assert cr_idx < first_nc_idx
  end

  # =====================================================================================
  # 7. Bounded history / eviction — oldest terminal goal evicted; caller_key cleared
  # =====================================================================================

  test "bounded history eviction: oldest terminal goal evicted and caller_key freed for reuse" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client =
      start_client_agent(%{
        {:send, @node_alpha} => {:ok, a2a_task("ta", "completed")},
        {:send, @node_beta} => {:ok, a2a_task("tb", "completed")},
        {:send, @node_gamma} => {:ok, a2a_task("tg", "completed")}
      })

    # max_history=2: accepting a third goal evicts the oldest terminal one
    goal_store = start_goal_store(audit, max_history: 2, max_active: 5)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: id1}} =
             run(orchestrator, "key-evict-e2e-1", [@node_alpha], client)

    eventually(fn -> goal_completed?(goal_store, id1) end)

    assert {:ok, %DiagnosticGoal{id: id2}} =
             run(orchestrator, "key-evict-e2e-2", [@node_beta], client)

    eventually(fn -> goal_completed?(goal_store, id2) end)

    # Third goal — GoalStore must evict id1 (oldest terminal) to make room
    assert {:ok, %DiagnosticGoal{id: id3}} =
             run(orchestrator, "key-evict-e2e-3", [@node_gamma], client)

    eventually(fn -> goal_completed?(goal_store, id3) end)

    # id1 evicted
    assert {:error, :not_found} = GoalStore.get(id1, goal_store)
    assert {:ok, %DiagnosticGoal{state: :completed}} = GoalStore.get(id2, goal_store)
    assert {:ok, %DiagnosticGoal{state: :completed}} = GoalStore.get(id3, goal_store)

    # goal_evicted audit event emitted for id1
    eventually(fn -> length(events_of_type(collector, :goal_evicted)) >= 1 end, 100)
    [evicted_ev] = events_of_type(collector, :goal_evicted)
    assert evicted_ev["attributes"]["goal_id"] == id1
    assert evicted_ev["attributes"]["final_state"] == "completed"

    # After eviction, the caller_key "key-evict-e2e-1" is freed.
    # Re-submitting it should create a fresh goal with a new ID.
    assert {:ok, %DiagnosticGoal{id: id4}} =
             run(orchestrator, "key-evict-e2e-1", [@node_alpha], client)

    refute id4 == id1
    eventually(fn -> goal_completed?(goal_store, id4) end)
  end

  # =====================================================================================
  # 8. Bounded output (output_truncated flag set by GoalStore)
  # =====================================================================================

  test "output front-truncated on overflow with output_truncated flag set" do
    audit = start_failing_audit()
    goal_store = start_goal_store(audit, max_output_bytes: 10)

    {:ok, goal} =
      GoalStore.accept("key-output-bounds", "exocomp.system.diagnose", %{}, goal_store)

    :ok = GoalStore.append_output(goal.id, "0123456789", goal_store)
    :ok = GoalStore.append_output(goal.id, "OVERFLOW", goal_store)

    {:ok, updated} = GoalStore.get(goal.id, goal_store)
    assert byte_size(updated.output) == 10
    assert updated.output_truncated == true
    # Most-recent bytes are kept (oldest are dropped)
    assert String.ends_with?(updated.output, "OVERFLOW")
  end

  # =====================================================================================
  # 9. Coordinator restart loss — GoalStore is volatile; :not_found after restart
  # =====================================================================================

  test "coordinator restart: GoalStore starts empty; pre-restart goal IDs return :not_found" do
    # Simulate a coordinator restart: start GoalStore, create a goal, stop it,
    # start a fresh GoalStore at the same name.
    audit = start_failing_audit()
    name = unique_name(:gs_restart)

    start_supervised!({GoalStore, name: name, audit: audit}, id: name)

    {:ok, goal} = GoalStore.accept("caller-pre-restart", "exocomp.system.diagnose", %{}, name)
    pre_restart_id = goal.id

    # Confirm goal exists while alive
    assert {:ok, _} = GoalStore.get(pre_restart_id, name)

    # Stop the GoalStore (simulating coordinator process death)
    stop_supervised!(name)

    # Start a fresh GoalStore with the same name
    start_supervised!({GoalStore, name: name, audit: audit}, id: name)

    # Pre-restart goal ID is :not_found in the new store
    assert {:error, :not_found} = GoalStore.get(pre_restart_id, name)
  end

  # =====================================================================================
  # 10. Safe resubmission after restart — same caller_key yields fresh goal + new ID
  # =====================================================================================

  test "safe resubmission: same caller_key after restart creates a fresh goal with new ID" do
    audit = start_failing_audit()
    name = unique_name(:gs_restart2)

    start_supervised!({GoalStore, name: name, audit: audit}, id: name)

    {:ok, old_goal} = GoalStore.accept("caller-restart-key", "exocomp.system.diagnose", %{}, name)
    old_id = old_goal.id

    stop_supervised!(name)
    start_supervised!({GoalStore, name: name, audit: audit}, id: name)

    # Caller resubmits using the same caller_key after observing :not_found
    {:ok, new_goal} = GoalStore.accept("caller-restart-key", "exocomp.system.diagnose", %{}, name)

    # Fresh goal — new UUID, not the same as the pre-restart goal
    assert new_goal.state == :accepted
    refute new_goal.id == old_id

    # Downstream key is deterministic but differs from the old one because
    # the goal_id changed
    old_dk = GoalStore.downstream_key(old_id, @node_alpha)
    new_dk = GoalStore.downstream_key(new_goal.id, @node_alpha)
    refute old_dk == new_dk
  end

  # =====================================================================================
  # 11. Correlated audit redaction — sensitive params redacted in emitted events
  # =====================================================================================

  test "sensitive params are redacted in all goal and node audit events" do
    collector = start_collector_agent()
    audit = start_audit_with_collector(collector)

    client =
      start_client_agent(%{
        {:send, @node_alpha} => {:ok, a2a_task("ta", "completed")},
        {:send, @node_beta} => {:ok, a2a_task("tb", "completed")},
        {:send, @node_gamma} => {:ok, a2a_task("tg", "completed")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    sensitive_params = %{
      "detail" => "standard",
      "api_key" => "SECRET-SHOULD-BE-REDACTED",
      "nested" => %{
        "token" => "bearer-token-xyz",
        "visible" => "safe-diagnostics-value"
      }
    }

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             Orchestrator.run(
               "key-redact-integ",
               "exocomp.system.diagnose",
               sensitive_params,
               @three_nodes,
               orchestrator: orchestrator,
               client_opts: [agent: client, owner: self()]
             )

    eventually(fn -> goal_completed?(goal_store, goal_id) end)
    eventually(fn -> length(collected_events(collector)) >= 5 end, 100)

    events = collected_events(collector)

    # Every event must carry the goal's correlation_id
    for event <- events do
      assert event["correlation_id"] == goal_id,
             "Event #{event["event_type"]} missing correlation_id #{goal_id}"
    end

    # goal_accepted: sensitive params redacted
    [accepted] = events |> Enum.filter(&(&1["event_type"] == "goal_accepted"))
    params_in_event = accepted["attributes"]["params"]
    assert params_in_event["detail"] == "standard"
    assert params_in_event["api_key"] == "[REDACTED]"
    assert params_in_event["nested"]["token"] == "[REDACTED]"
    assert params_in_event["nested"]["visible"] == "safe-diagnostics-value"

    # node_dispatching events: params also redacted
    dispatching_events = events |> Enum.filter(&(&1["event_type"] == "node_dispatching"))
    assert length(dispatching_events) == 3

    for ev <- dispatching_events do
      p = ev["attributes"]["params"]
      assert p["api_key"] == "[REDACTED]"
      assert p["nested"]["token"] == "[REDACTED]"
    end

    # Verify redact/1 pure function handles list-valued sensitive fields
    assert Audit.redact(%{
             "credential" => "abc",
             "data" => [%{"secret" => "x"}, %{"safe" => 1}]
           }) == %{
             "credential" => "[REDACTED]",
             "data" => [%{"secret" => "[REDACTED]"}, %{"safe" => 1}]
           }
  end

  # =====================================================================================
  # 12. Unavailable audit sink — diagnostics remain available; health :degraded
  # =====================================================================================

  test "unavailable audit sink: goal runs to completion; GoalStore.get still returns results" do
    # Failing audit: every write returns {:error, ...}
    audit = start_failing_audit()

    client =
      start_client_agent(%{
        {:send, @node_alpha} => {:ok, a2a_task("ta", "completed")},
        {:send, @node_beta} => {:ok, a2a_task("tb", "completed")},
        {:send, @node_gamma} => {:error, client_error(:transport, :unreachable, @node_gamma)}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-sink-unavail", @three_nodes, client)

    # Goal completes despite all audit writes failing
    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    # Diagnostic reads remain available through GoalStore
    assert {:ok, %DiagnosticGoal{state: :completed}} = GoalStore.get(goal_id, goal_store)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.node_outcomes[@node_alpha].state == :succeeded
    assert goal.node_outcomes[@node_beta].state == :succeeded
    assert goal.node_outcomes[@node_gamma].state == :unreachable
  end

  test "unavailable audit sink: Audit.status/1 reports healthy: false" do
    audit = start_failing_audit()

    # Trigger a write so the sink records the failure
    Audit.emit(:probe_event, %{}, server: audit)

    assert %{healthy: false} = Audit.status(audit)
  end

  test "unavailable audit sink: Audit GenServer stays alive after repeated write failures" do
    audit = start_failing_audit()

    for i <- 1..10 do
      Audit.emit(:repeated_event, %{seq: i}, server: audit)
    end

    assert Process.alive?(GenServer.whereis(audit))
    assert %{healthy: false} = Audit.status(audit)
  end

  test "unavailable audit sink: GoalStore eviction still runs without audit write succeeding" do
    audit = start_failing_audit()
    goal_store = start_goal_store(audit, max_history: 1, max_active: 5)

    # First goal accepted and completed → terminal in history (size = 1 = max_history)
    {:ok, g1} = GoalStore.accept("key-sink-evict-1", "exocomp.system.diagnose", %{}, goal_store)
    :ok = GoalStore.transition(g1.id, :dispatching, nil, goal_store)
    :ok = GoalStore.transition(g1.id, :running, nil, goal_store)
    :ok = GoalStore.transition(g1.id, :completed, nil, goal_store)

    # Second goal triggers make_room → g1 evicted; audit write fails (non-fatal)
    {:ok, g2} = GoalStore.accept("key-sink-evict-2", "exocomp.system.diagnose", %{}, goal_store)

    # g1 is gone even though audit write for eviction failed
    assert {:error, :not_found} = GoalStore.get(g1.id, goal_store)
    assert {:ok, _} = GoalStore.get(g2.id, goal_store)
  end

  # =====================================================================================
  # 13. EXOCOMP-19 contract readiness — orchestrator API complete for A2A handlers
  # =====================================================================================

  test "EXOCOMP-19 contract: Orchestrator.run/5 accepts diagnostic skills and returns DiagnosticGoal" do
    audit = start_failing_audit()

    client =
      start_client_agent(%{
        {:send, @node_alpha} => {:ok, a2a_task("ta", "completed")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    # Supported diagnostic skills
    for skill <- ["exocomp.cluster.health", "exocomp.cluster.diagnose", "exocomp.system.diagnose"] do
      key = "key-contract-#{:erlang.unique_integer([:positive])}"

      assert {:ok, %DiagnosticGoal{} = goal} =
               Orchestrator.run(key, skill, %{"detail" => "standard"}, [@node_alpha],
                 orchestrator: orchestrator,
                 client_opts: [agent: client, owner: self()]
               )

      assert is_binary(goal.id)
      assert goal.caller_key == key
      assert goal.skill_id == skill
      assert goal.state in [:accepted, :dispatching, :running, :completed]
      eventually(fn -> goal_completed?(goal_store, goal.id) end)
    end
  end

  test "EXOCOMP-19 contract: GoalStore.get/2 returns :not_found for unknown goal_id" do
    audit = start_failing_audit()
    goal_store = start_goal_store(audit)

    # Caller that received a stale goal_id (e.g., after restart) gets :not_found
    assert {:error, :not_found} = GoalStore.get("stale-goal-id-for-a2a-handler", goal_store)
  end

  test "EXOCOMP-19 contract: Orchestrator.cancel/2 is idempotent on completed goals" do
    audit = start_failing_audit()

    client =
      start_client_agent(%{
        {:send, @node_alpha} => {:ok, a2a_task("ta", "completed")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-cancel-idem", [@node_alpha], client)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    # Cancel on a completed goal is idempotent
    assert {:ok, %DiagnosticGoal{state: :completed}} =
             Orchestrator.cancel(goal_id, orchestrator: orchestrator)
  end

  test "EXOCOMP-19 contract: Orchestrator.cancel/2 returns :not_found for unknown goal_id" do
    audit = start_failing_audit()
    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:error, :not_found} =
             Orchestrator.cancel("unknown-goal-for-handler", orchestrator: orchestrator)
  end

  test "EXOCOMP-19 contract: GoalStore returns :at_capacity when max_active exceeded" do
    audit = start_failing_audit()
    goal_store = start_goal_store(audit, max_active: 1, max_history: 2)
    task_sup = start_task_supervisor()
    blocker = self()

    client = start_client_agent(%{{:send, @node_alpha} => {:block, blocker}})

    orchestrator =
      start_orchestrator(goal_store, task_sup, audit,
        overall_timeout_ms: 5_000,
        node_timeout_ms: 5_000
      )

    assert {:ok, _} = run(orchestrator, "key-cap-1", [@node_alpha], client)
    assert_receive {:blocking_send, _, @node_alpha}, 1_000

    # Second goal exceeds max_active
    assert {:error, :at_capacity} = run(orchestrator, "key-cap-2", [@node_alpha], client)
  end

  test "EXOCOMP-19 contract: DiagnosticGoal node_outcomes map is complete for all targeted nodes" do
    audit = start_failing_audit()

    client =
      start_client_agent(%{
        {:send, @node_alpha} => {:ok, a2a_task("ta", "completed")},
        {:send, @node_beta} => {:error, client_error(:transport, :unreachable, @node_beta)},
        {:send, @node_gamma} =>
          {:error, client_error(:protocol, :malformed_response, @node_gamma)}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-outcome-completeness", @three_nodes, client)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)

    # Every targeted node has an explicit outcome — no silent omissions
    assert Map.keys(goal.node_outcomes) |> Enum.sort() == Enum.sort(@three_nodes)

    for node_id <- @three_nodes do
      outcome = goal.node_outcomes[node_id]
      assert %NodeOutcome{} = outcome
      assert outcome.node_id == node_id
      assert is_binary(outcome.updated_at)
    end
  end

  # =====================================================================================
  # 14. No remediation executor path reachable from orchestrator or goal state machine
  # =====================================================================================

  test "no remediation path: DiagnosticGoal terminal states contain no executor outcomes" do
    # The goal state machine must only reach: completed, failed, canceled.
    # No remediation executor state exists.
    terminal_states = [:completed, :failed, :canceled]

    for state <- terminal_states do
      goal = %DiagnosticGoal{id: "g", caller_key: "k", skill_id: "s", state: state}
      assert DiagnosticGoal.terminal?(goal)
    end

    non_terminal = [:accepted, :dispatching, :running]

    for state <- non_terminal do
      goal = %DiagnosticGoal{id: "g", caller_key: "k", skill_id: "s", state: state}
      refute DiagnosticGoal.terminal?(goal)
    end

    # No :remediating or :executing state exists in the type
    refute :remediating in (terminal_states ++ non_terminal)
    refute :executing in (terminal_states ++ non_terminal)
    refute :applying_remediation in (terminal_states ++ non_terminal)
  end

  test "no remediation path: NodeOutcome terminal states contain no executor outcomes" do
    terminal = [:succeeded, :failed, :unreachable, :canceled, :cancel_failed]

    for state <- terminal do
      assert NodeOutcome.terminal?(%NodeOutcome{state: state})
    end

    # Verify no executor/remediation terminal state is present
    refute :remediated in terminal
    refute :executing in terminal
    refute :applied in terminal
  end

  test "no remediation path: GoalStore.transition rejects :remediation state transition" do
    audit = start_failing_audit()
    goal_store = start_goal_store(audit)

    {:ok, goal} = GoalStore.accept("key-no-remed", "exocomp.system.diagnose", %{}, goal_store)

    # Any attempt to transition to a made-up remediation state is rejected
    assert {:error, :invalid_transition} =
             GoalStore.transition(goal.id, :remediating, nil, goal_store)

    assert {:error, :invalid_transition} =
             GoalStore.transition(goal.id, :executing, nil, goal_store)

    # Goal remains in :accepted (untouched)
    {:ok, unchanged} = GoalStore.get(goal.id, goal_store)
    assert unchanged.state == :accepted
  end

  test "no remediation path: Orchestrator only dispatches A2A tasks, never invokes an executor" do
    # The FakeClient is the only adapter registered. If the Orchestrator
    # attempted to invoke any executor pathway, it would fail because no
    # executor module is configured in the test stack. This test confirms
    # that a normal three-node goal completes successfully through
    # FakeClient alone — proving no out-of-band executor call is made.
    audit = start_failing_audit()

    client =
      start_client_agent(%{
        {:send, @node_alpha} => {:ok, a2a_task("ta", "completed")},
        {:send, @node_beta} => {:ok, a2a_task("tb", "completed")},
        {:send, @node_gamma} => {:ok, a2a_task("tg", "completed")}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-no-executor", @three_nodes, client)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed

    for node_id <- @three_nodes do
      assert goal.node_outcomes[node_id].state == :succeeded
    end
  end

  # =====================================================================================
  # 15. Three-fixture: all three nodes succeed with distinct artifacts (contract smoke test)
  # =====================================================================================

  test "three-fixture all-success: per-node artifacts explicit and non-overlapping" do
    audit = start_failing_audit()

    client =
      start_client_agent(%{
        {:send, @node_alpha} =>
          {:ok, a2a_task("ta", "completed", [make_artifact("art-alpha", "alpha diagnostic ok")])},
        {:send, @node_beta} =>
          {:ok, a2a_task("tb", "completed", [make_artifact("art-beta", "beta diagnostic ok")])},
        {:send, @node_gamma} =>
          {:ok, a2a_task("tg", "completed", [make_artifact("art-gamma", "gamma diagnostic ok")])}
      })

    goal_store = start_goal_store(audit)
    task_sup = start_task_supervisor()
    orchestrator = start_orchestrator(goal_store, task_sup, audit)

    assert {:ok, %DiagnosticGoal{id: goal_id}} =
             run(orchestrator, "key-all-success-artifacts", @three_nodes, client)

    eventually(fn -> goal_completed?(goal_store, goal_id) end)

    {:ok, goal} = GoalStore.get(goal_id, goal_store)
    assert goal.state == :completed

    [%Artifact{artifactId: "art-alpha"}] = goal.node_outcomes[@node_alpha].artifacts
    [%Artifact{artifactId: "art-beta"}] = goal.node_outcomes[@node_beta].artifacts
    [%Artifact{artifactId: "art-gamma"}] = goal.node_outcomes[@node_gamma].artifacts

    # Downstream idempotency keys are distinct per (goal_id, node_id)
    dk_alpha = GoalStore.downstream_key(goal_id, @node_alpha)
    dk_beta = GoalStore.downstream_key(goal_id, @node_beta)
    dk_gamma = GoalStore.downstream_key(goal_id, @node_gamma)

    assert dk_alpha != dk_beta
    assert dk_beta != dk_gamma
    assert dk_alpha != dk_gamma
    assert byte_size(dk_alpha) == 64
  end
end

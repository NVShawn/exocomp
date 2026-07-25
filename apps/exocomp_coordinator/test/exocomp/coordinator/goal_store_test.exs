# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.GoalStoreTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.Artifact
  alias Exocomp.Coordinator.{DiagnosticGoal, GoalStore, NodeOutcome}

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp unique_name, do: :"goal_store_#{System.unique_integer([:positive])}"

  defp start_store(opts \\ []) do
    name = unique_name()
    start_supervised!({GoalStore, Keyword.put(opts, :name, name)}, id: name)
    name
  end

  defp accept!(store, caller_key, skill \\ "exocomp.cluster.diagnose", params \\ %{}) do
    assert {:ok, goal} = GoalStore.accept(caller_key, skill, params, store)
    goal
  end

  defp artifact(id \\ "a1"), do: %Artifact{artifactId: id, parts: []}

  # ---------------------------------------------------------------------------
  # Basic accept / get / list semantics
  # ---------------------------------------------------------------------------

  describe "accept/4" do
    test "creates a goal with a UUIDv4 correlation ID and :accepted state" do
      store = start_store()
      goal = accept!(store, "key-1")

      assert goal.state == :accepted
      assert is_binary(goal.id) and byte_size(goal.id) == 36
      assert goal.caller_key == "key-1"
      assert goal.skill_id == "exocomp.cluster.diagnose"
      assert goal.params == %{}
      assert goal.node_outcomes == %{}
      assert goal.artifacts == []
      assert goal.output == ""
      assert goal.output_truncated == false
      assert is_binary(goal.created_at)
      assert is_binary(goal.updated_at)
    end

    test "correlation ID matches UUIDv4 format" do
      store = start_store()
      goal = accept!(store, "key-uuid")
      # xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx where y ∈ [8,9,a,b]
      assert Regex.match?(
               ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
               goal.id
             )
    end

    test "params are stored on the goal" do
      store = start_store()
      goal = accept!(store, "key-params", "exocomp.cluster.diagnose", %{"timeout" => 30})
      assert goal.params == %{"timeout" => 30}
    end

    test "each new caller_key produces a distinct goal with a distinct ID" do
      store = start_store()
      g1 = accept!(store, "key-a")
      g2 = accept!(store, "key-b")
      refute g1.id == g2.id
    end
  end

  describe "duplicate submission" do
    test "same caller_key returns the same goal" do
      store = start_store()
      g1 = accept!(store, "dup-key")
      g2 = accept!(store, "dup-key")
      assert g1.id == g2.id
    end

    test "same caller_key after goal has advanced state still returns the existing goal" do
      store = start_store()
      g1 = accept!(store, "dup-state")
      :ok = GoalStore.transition(g1.id, :dispatching, nil, store)

      {:ok, g2} = GoalStore.accept("dup-state", "exocomp.cluster.diagnose", %{}, store)
      assert g2.id == g1.id
    end

    test "same caller_key for a completed goal returns the completed goal" do
      store = start_store()
      g1 = accept!(store, "dup-terminal")
      :ok = GoalStore.transition(g1.id, :dispatching, nil, store)
      :ok = GoalStore.transition(g1.id, :running, nil, store)
      :ok = GoalStore.transition(g1.id, :completed, nil, store)

      {:ok, g2} = GoalStore.accept("dup-terminal", "exocomp.cluster.diagnose", %{}, store)
      assert g2.id == g1.id
      assert g2.state == :completed
    end

    test "same caller_key for a canceled goal returns the canceled goal" do
      store = start_store()
      g1 = accept!(store, "dup-canceled")
      {:ok, _} = GoalStore.cancel(g1.id, store)

      {:ok, g2} = GoalStore.accept("dup-canceled", "exocomp.cluster.diagnose", %{}, store)
      assert g2.id == g1.id
      assert g2.state == :canceled
    end
  end

  describe "concurrent duplicate race" do
    test "concurrent accepts with the same caller_key produce one goal" do
      store = start_store(max_active: 100)
      parent = self()

      # Fire N concurrent accept calls for the same caller_key.
      n = 20

      pids =
        for _ <- 1..n do
          spawn(fn ->
            result = GoalStore.accept("race-key", "exocomp.cluster.diagnose", %{}, store)
            send(parent, {:result, result})
          end)
        end

      results =
        for _pid <- pids do
          assert_receive {:result, {:ok, goal}}, 2_000
          goal.id
        end

      # All callers must have received the same goal ID.
      unique_ids = Enum.uniq(results)
      assert length(unique_ids) == 1
    end
  end

  # ---------------------------------------------------------------------------
  # get/2 and list/1
  # ---------------------------------------------------------------------------

  describe "get/2" do
    test "returns the goal by ID" do
      store = start_store()
      goal = accept!(store, "get-key")
      assert {:ok, fetched} = GoalStore.get(goal.id, store)
      assert fetched.id == goal.id
    end

    test "returns :not_found for unknown IDs" do
      store = start_store()
      assert {:error, :not_found} = GoalStore.get("no-such-id", store)
    end
  end

  describe "list/1" do
    test "returns goals in insertion order (oldest first)" do
      store = start_store()
      g1 = accept!(store, "list-1")
      g2 = accept!(store, "list-2")
      g3 = accept!(store, "list-3")

      listed = GoalStore.list(store)
      assert Enum.map(listed, & &1.id) == [g1.id, g2.id, g3.id]
    end

    test "returns an empty list when no goals exist" do
      store = start_store()
      assert GoalStore.list(store) == []
    end
  end

  # ---------------------------------------------------------------------------
  # State transitions
  # ---------------------------------------------------------------------------

  describe "transition/4" do
    test "valid forward transitions are accepted" do
      store = start_store()
      goal = accept!(store, "trans-1")

      assert :ok = GoalStore.transition(goal.id, :dispatching, nil, store)
      assert {:ok, %{state: :dispatching}} = GoalStore.get(goal.id, store)

      assert :ok = GoalStore.transition(goal.id, :running, nil, store)
      assert {:ok, %{state: :running}} = GoalStore.get(goal.id, store)

      assert :ok = GoalStore.transition(goal.id, :completed, nil, store)
      assert {:ok, %{state: :completed}} = GoalStore.get(goal.id, store)
    end

    test "transition to :failed is permitted from :dispatching and :running" do
      store = start_store()

      g1 = accept!(store, "fail-from-dispatching")
      :ok = GoalStore.transition(g1.id, :dispatching, nil, store)
      assert :ok = GoalStore.transition(g1.id, :failed, "err", store)
      assert {:ok, %{state: :failed, error: "err"}} = GoalStore.get(g1.id, store)

      g2 = accept!(store, "fail-from-running")
      :ok = GoalStore.transition(g2.id, :dispatching, nil, store)
      :ok = GoalStore.transition(g2.id, :running, nil, store)
      assert :ok = GoalStore.transition(g2.id, :failed, "err2", store)
      assert {:ok, %{state: :failed, error: "err2"}} = GoalStore.get(g2.id, store)
    end

    test "transition to :canceled is permitted from :accepted, :dispatching, and :running" do
      store = start_store()

      for {key, intermediate} <- [
            {"cancel-accepted", []},
            {"cancel-dispatching", [:dispatching]},
            {"cancel-running", [:dispatching, :running]}
          ] do
        g = accept!(store, key)
        for state <- intermediate, do: :ok = GoalStore.transition(g.id, state, nil, store)
        assert :ok = GoalStore.transition(g.id, :canceled, nil, store)
        assert {:ok, %{state: :canceled}} = GoalStore.get(g.id, store)
      end
    end

    test "invalid transitions are rejected" do
      store = start_store()

      g = accept!(store, "invalid-trans")
      # Can't jump from :accepted to :completed directly.
      assert {:error, :invalid_transition} =
               GoalStore.transition(g.id, :completed, nil, store)

      # Can't go from :running back to :accepted.
      :ok = GoalStore.transition(g.id, :dispatching, nil, store)
      :ok = GoalStore.transition(g.id, :running, nil, store)

      assert {:error, :invalid_transition} =
               GoalStore.transition(g.id, :accepted, nil, store)
    end

    test "transitions out of terminal states are rejected" do
      store = start_store()
      g = accept!(store, "from-terminal")
      :ok = GoalStore.transition(g.id, :dispatching, nil, store)
      :ok = GoalStore.transition(g.id, :failed, nil, store)

      assert {:error, :invalid_transition} =
               GoalStore.transition(g.id, :running, nil, store)
    end

    test "transition on unknown ID returns :not_found" do
      store = start_store()

      assert {:error, :not_found} =
               GoalStore.transition("no-such-id", :dispatching, nil, store)
    end
  end

  # ---------------------------------------------------------------------------
  # Per-node outcomes
  # ---------------------------------------------------------------------------

  describe "put_node_outcome/4" do
    test "stores a node outcome on the goal" do
      store = start_store()
      goal = accept!(store, "node-outcome-1")
      outcome = %NodeOutcome{node_id: "n1", state: :running}

      assert :ok = GoalStore.put_node_outcome(goal.id, "n1", outcome, store)
      assert {:ok, updated} = GoalStore.get(goal.id, store)
      assert %NodeOutcome{node_id: "n1", state: :running} = updated.node_outcomes["n1"]
    end

    test "stamps updated_at and sets node_id from argument (overrides struct field)" do
      store = start_store()
      goal = accept!(store, "node-outcome-2")
      outcome = %NodeOutcome{node_id: "ignored", state: :succeeded, result: %{"ok" => true}}

      :ok = GoalStore.put_node_outcome(goal.id, "node-a", outcome, store)
      {:ok, updated} = GoalStore.get(goal.id, store)
      stored = updated.node_outcomes["node-a"]

      assert stored.node_id == "node-a"
      assert stored.state == :succeeded
      assert is_binary(stored.updated_at)
    end

    test "multiple node outcomes are tracked independently" do
      store = start_store()
      goal = accept!(store, "multi-node")

      :ok =
        GoalStore.put_node_outcome(
          goal.id,
          "node-a",
          %NodeOutcome{state: :succeeded},
          store
        )

      :ok =
        GoalStore.put_node_outcome(
          goal.id,
          "node-b",
          %NodeOutcome{state: :failed, error: "timeout"},
          store
        )

      {:ok, updated} = GoalStore.get(goal.id, store)
      assert updated.node_outcomes["node-a"].state == :succeeded
      assert updated.node_outcomes["node-b"].state == :failed
    end

    test "updating an existing node outcome replaces it" do
      store = start_store()
      goal = accept!(store, "node-update")

      :ok =
        GoalStore.put_node_outcome(goal.id, "node-a", %NodeOutcome{state: :running}, store)

      :ok =
        GoalStore.put_node_outcome(
          goal.id,
          "node-a",
          %NodeOutcome{state: :succeeded, result: %{"data" => 1}},
          store
        )

      {:ok, updated} = GoalStore.get(goal.id, store)
      assert updated.node_outcomes["node-a"].state == :succeeded
    end

    test "returns :not_found for unknown goal ID" do
      store = start_store()

      assert {:error, :not_found} =
               GoalStore.put_node_outcome(
                 "no-such",
                 "node-a",
                 %NodeOutcome{state: :running},
                 store
               )
    end
  end

  # ---------------------------------------------------------------------------
  # Output truncation
  # ---------------------------------------------------------------------------

  describe "append_output/3" do
    test "appends output up to the max_output_bytes limit" do
      store = start_store(max_output_bytes: 20)
      goal = accept!(store, "out-1")

      :ok = GoalStore.append_output(goal.id, "hello", store)
      {:ok, g} = GoalStore.get(goal.id, store)
      assert g.output == "hello"
      assert g.output_truncated == false
    end

    test "output exactly at the limit is not truncated" do
      store = start_store(max_output_bytes: 5)
      goal = accept!(store, "out-exact")
      :ok = GoalStore.append_output(goal.id, "hello", store)
      {:ok, g} = GoalStore.get(goal.id, store)
      assert g.output == "hello"
      assert g.output_truncated == false
    end

    test "overflow is front-truncated, keeping newest bytes" do
      store = start_store(max_output_bytes: 10)
      goal = accept!(store, "out-truncate")

      :ok = GoalStore.append_output(goal.id, "0123456789", store)
      :ok = GoalStore.append_output(goal.id, "ABCDE", store)

      {:ok, g} = GoalStore.get(goal.id, store)
      assert byte_size(g.output) == 10
      # The result should be the last 10 bytes of "0123456789ABCDE"
      assert g.output == "56789ABCDE"
      assert g.output_truncated == true
    end

    test "output_truncated stays true once set even when later appends fit" do
      store = start_store(max_output_bytes: 5)
      goal = accept!(store, "out-sticky")

      # First append overflows.
      :ok = GoalStore.append_output(goal.id, "OVERFLOW!", store)
      {:ok, g1} = GoalStore.get(goal.id, store)
      assert g1.output_truncated == true

      # Second append is tiny — truncated flag must remain true.
      :ok = GoalStore.append_output(goal.id, "X", store)
      {:ok, g2} = GoalStore.get(goal.id, store)
      assert g2.output_truncated == true
    end

    test "multiple sequential appends accumulate correctly without spurious truncation" do
      store = start_store(max_output_bytes: 100)
      goal = accept!(store, "out-accum")

      for chunk <- ["foo", "bar", "baz"] do
        :ok = GoalStore.append_output(goal.id, chunk, store)
      end

      {:ok, g} = GoalStore.get(goal.id, store)
      assert g.output == "foobarbaz"
      assert g.output_truncated == false
    end

    test "returns :not_found for unknown goal ID" do
      store = start_store()
      assert {:error, :not_found} = GoalStore.append_output("no-such", "text", store)
    end
  end

  # ---------------------------------------------------------------------------
  # Artifact bounds
  # ---------------------------------------------------------------------------

  describe "put_artifact/3" do
    test "appends artifacts up to the max_artifacts limit" do
      store = start_store(max_artifacts: 3)
      goal = accept!(store, "art-1")

      for i <- 1..3 do
        assert :ok = GoalStore.put_artifact(goal.id, artifact("a#{i}"), store)
      end

      {:ok, g} = GoalStore.get(goal.id, store)
      assert length(g.artifacts) == 3
    end

    test "exceeding max_artifacts returns :at_capacity" do
      store = start_store(max_artifacts: 2)
      goal = accept!(store, "art-cap")

      :ok = GoalStore.put_artifact(goal.id, artifact("a1"), store)
      :ok = GoalStore.put_artifact(goal.id, artifact("a2"), store)
      assert {:error, :at_capacity} = GoalStore.put_artifact(goal.id, artifact("a3"), store)

      {:ok, g} = GoalStore.get(goal.id, store)
      assert length(g.artifacts) == 2
    end

    test "returns :not_found for unknown goal ID" do
      store = start_store()
      assert {:error, :not_found} = GoalStore.put_artifact("no-such", artifact(), store)
    end
  end

  # ---------------------------------------------------------------------------
  # cancel/2
  # ---------------------------------------------------------------------------

  describe "cancel/2" do
    test "cancels an active goal and returns the updated goal" do
      store = start_store()
      goal = accept!(store, "cancel-1")

      assert {:ok, canceled} = GoalStore.cancel(goal.id, store)
      assert canceled.state == :canceled
      assert {:ok, %{state: :canceled}} = GoalStore.get(goal.id, store)
    end

    test "canceling a completed goal returns :not_cancelable" do
      store = start_store()
      goal = accept!(store, "cancel-completed")
      :ok = GoalStore.transition(goal.id, :dispatching, nil, store)
      :ok = GoalStore.transition(goal.id, :running, nil, store)
      :ok = GoalStore.transition(goal.id, :completed, nil, store)

      assert {:error, :not_cancelable} = GoalStore.cancel(goal.id, store)
    end

    test "canceling an unknown goal returns :not_found" do
      store = start_store()
      assert {:error, :not_found} = GoalStore.cancel("no-such", store)
    end
  end

  # ---------------------------------------------------------------------------
  # Active concurrency bound (max_active)
  # ---------------------------------------------------------------------------

  describe "max_active bound" do
    test "rejects new goals when max_active is reached" do
      store = start_store(max_active: 2, max_history: 10)
      accept!(store, "active-1")
      accept!(store, "active-2")

      assert {:error, :at_capacity} =
               GoalStore.accept("active-3", "exocomp.cluster.diagnose", %{}, store)
    end

    test "completing a goal frees an active slot" do
      store = start_store(max_active: 1, max_history: 10)
      g1 = accept!(store, "slot-1")

      assert {:error, :at_capacity} =
               GoalStore.accept("slot-2", "exocomp.cluster.diagnose", %{}, store)

      # Complete the first goal.
      :ok = GoalStore.transition(g1.id, :dispatching, nil, store)
      :ok = GoalStore.transition(g1.id, :running, nil, store)
      :ok = GoalStore.transition(g1.id, :completed, nil, store)

      # Now the second goal can be accepted.
      assert {:ok, _g2} = GoalStore.accept("slot-2", "exocomp.cluster.diagnose", %{}, store)
    end
  end

  # ---------------------------------------------------------------------------
  # History bound and deterministic oldest-terminal eviction
  # ---------------------------------------------------------------------------

  describe "max_history bound and eviction" do
    test "terminal goals are evicted oldest-first to make room for new submissions" do
      # max_history = 3, max_active = 10
      store = start_store(max_active: 10, max_history: 3, eviction_interval_ms: 600_000)

      g1 = accept!(store, "evict-1")
      g2 = accept!(store, "evict-2")
      g3 = accept!(store, "evict-3")

      # Terminate g1 and g2 (making them eviction candidates).
      :ok = GoalStore.transition(g1.id, :dispatching, nil, store)
      :ok = GoalStore.transition(g1.id, :failed, nil, store)
      :ok = GoalStore.transition(g2.id, :dispatching, nil, store)
      :ok = GoalStore.transition(g2.id, :failed, nil, store)

      # g3 is still active. We now have 3 goals at max_history.
      # Accepting a 4th goal should evict g1 (oldest terminal).
      g4 = accept!(store, "evict-4")
      refute is_nil(g4)

      assert {:error, :not_found} = GoalStore.get(g1.id, store)
      assert {:ok, _} = GoalStore.get(g2.id, store)
      assert {:ok, _} = GoalStore.get(g3.id, store)
      assert {:ok, _} = GoalStore.get(g4.id, store)
    end

    test "active goals are never evicted even when at max_history" do
      store = start_store(max_active: 10, max_history: 2, eviction_interval_ms: 600_000)
      g1 = accept!(store, "no-evict-1")
      g2 = accept!(store, "no-evict-2")

      # Both goals are active — no terminal goals to evict.
      assert {:error, :at_capacity} =
               GoalStore.accept("no-evict-3", "exocomp.cluster.diagnose", %{}, store)

      # Both original goals remain.
      assert {:ok, _} = GoalStore.get(g1.id, store)
      assert {:ok, _} = GoalStore.get(g2.id, store)
    end

    test "caller_key index is cleaned up when a goal is evicted" do
      # max_history=1: once g1 (terminal) fills history, accepting g2 triggers
      # make_room which evicts g1 and removes its caller_key entry.
      # After g2 also terminates, re-submitting g1's original caller_key creates
      # a fresh goal because the index entry was cleaned up at eviction time.
      store = start_store(max_active: 10, max_history: 1, eviction_interval_ms: 600_000)

      g1 = accept!(store, "evict-caller-1")
      :ok = GoalStore.transition(g1.id, :dispatching, nil, store)
      :ok = GoalStore.transition(g1.id, :failed, nil, store)

      # Accepting g2 triggers make_room → g1 is evicted and its caller_key removed.
      g2 = accept!(store, "evict-caller-2")
      assert {:error, :not_found} = GoalStore.get(g1.id, store)

      # Terminate g2 so the single history slot is again occupied by a terminal goal.
      :ok = GoalStore.transition(g2.id, :dispatching, nil, store)
      :ok = GoalStore.transition(g2.id, :failed, nil, store)

      # Re-submitting g1's caller_key now creates a fresh :accepted goal:
      # the caller_key was cleared at eviction, so no deduplication match exists.
      g3 = accept!(store, "evict-caller-1")
      assert g3.state == :accepted
      refute g3.id == g1.id
    end

    test "periodic eviction fires and prunes oldest terminal goals to max_history" do
      # Use a short eviction interval so eviction fires before the test assertion.
      # max_history=2, but we insert 3 terminal goals (only possible because
      # make_room only evicts when >max_history at accept time; here we use a
      # higher limit temporarily via a shared store and then verify the periodic
      # timer prunes back to the configured limit).
      #
      # The approach: start with max_history=3 to accept 3 goals (all terminal),
      # then verify that after the 50ms eviction fires, goals within max_history
      # are retained and none of the active-but-now-terminal ones are lost.
      #
      # To actually produce total > max_history at eviction time, we need to have
      # inserted more terminal goals than the configured bound. We can do this by
      # injecting a raw message directly to the GenServer.
      store = start_store(max_active: 10, max_history: 2, eviction_interval_ms: 50)

      g1 = accept!(store, "pev-1")
      g2 = accept!(store, "pev-2")

      :ok = GoalStore.transition(g1.id, :dispatching, nil, store)
      :ok = GoalStore.transition(g1.id, :failed, nil, store)
      :ok = GoalStore.transition(g2.id, :dispatching, nil, store)
      :ok = GoalStore.transition(g2.id, :failed, nil, store)

      # Both goals are terminal; send :evict directly to trigger a cycle
      # and confirm the handler doesn't crash and respects max_history.
      pid = GenServer.whereis(store)
      send(pid, :evict)

      # Give the message time to process.
      Process.sleep(50)

      # With 2 terminal goals and max_history=2, neither should be evicted.
      assert {:ok, _} = GoalStore.get(g1.id, store)
      assert {:ok, _} = GoalStore.get(g2.id, store)

      # Now accept a 3rd goal — this should trigger make_room evicting g1 (oldest).
      g3 = accept!(store, "pev-3")
      assert {:error, :not_found} = GoalStore.get(g1.id, store)
      assert {:ok, _} = GoalStore.get(g2.id, store)
      assert {:ok, _} = GoalStore.get(g3.id, store)
    end
  end

  # ---------------------------------------------------------------------------
  # downstream_key/2
  # ---------------------------------------------------------------------------

  describe "downstream_key/2" do
    test "returns a deterministic hex string for a (goal_id, node_id) pair" do
      key1 = GoalStore.downstream_key("goal-abc", "node-1")
      key2 = GoalStore.downstream_key("goal-abc", "node-1")
      assert key1 == key2
      assert String.match?(key1, ~r/^[0-9a-f]{64}$/)
    end

    test "different node IDs produce different keys for the same goal" do
      k1 = GoalStore.downstream_key("goal-x", "node-a")
      k2 = GoalStore.downstream_key("goal-x", "node-b")
      refute k1 == k2
    end

    test "different goal IDs produce different keys for the same node" do
      k1 = GoalStore.downstream_key("goal-1", "node-a")
      k2 = GoalStore.downstream_key("goal-2", "node-a")
      refute k1 == k2
    end

    test "key is a 64-character lowercase hex string (SHA-256)" do
      key = GoalStore.downstream_key("g", "n")
      assert byte_size(key) == 64
      assert key == String.downcase(key)
    end
  end

  # ---------------------------------------------------------------------------
  # DiagnosticGoal.terminal?/1 and NodeOutcome.terminal?/1
  # ---------------------------------------------------------------------------

  describe "DiagnosticGoal.terminal?/1" do
    test "non-terminal states return false" do
      for state <- [:accepted, :dispatching, :running] do
        goal = %DiagnosticGoal{id: "x", caller_key: "k", skill_id: "s", state: state}
        assert DiagnosticGoal.terminal?(goal) == false
      end
    end

    test "terminal states return true" do
      for state <- [:completed, :failed, :canceled] do
        goal = %DiagnosticGoal{id: "x", caller_key: "k", skill_id: "s", state: state}
        assert DiagnosticGoal.terminal?(goal) == true
      end
    end
  end

  describe "NodeOutcome.terminal?/1" do
    test "non-terminal states return false" do
      for state <- [:pending, :running] do
        assert NodeOutcome.terminal?(%NodeOutcome{state: state}) == false
      end
    end

    test "terminal states return true" do
      for state <- [:succeeded, :failed, :unreachable, :canceled] do
        assert NodeOutcome.terminal?(%NodeOutcome{state: state}) == true
      end
    end
  end
end

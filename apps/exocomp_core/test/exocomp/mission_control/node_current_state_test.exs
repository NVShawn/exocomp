# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.NodeCurrentStateTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.NodeCurrentState

  describe "new/3" do
    test "creates initial node state" do
      state = NodeCurrentState.new("org-1", "cluster-1", "node-1")

      assert state.organization_id == "org-1"
      assert state.cluster_id == "cluster-1"
      assert state.node_id == "node-1"
      assert state.connectivity == :unreachable
      assert state.health == :unreachable
      assert state.software_version == nil
      assert state.capabilities == []
      assert state.labels == %{}
      assert state.observation_seq == 0
      assert state.retired == false
      assert state.last_contact_at == nil
      assert state.updated_at != nil
    end
  end

  describe "apply_snapshot/3" do
    test "updates node state from snapshot data" do
      state = NodeCurrentState.new("org-1", "cluster-1", "node-1")

      node_data = %{
        "connectivity" => :reachable,
        "health" => :healthy,
        "software_version" => "1.2.0",
        "capabilities" => ["exec", "diagnose"],
        "labels" => %{"tier" => "worker"}
      }

      {:ok, updated} = NodeCurrentState.apply_snapshot(state, node_data, 1)

      assert updated.connectivity == :reachable
      assert updated.health == :healthy
      assert updated.software_version == "1.2.0"
      assert updated.capabilities == ["exec", "diagnose"]
      assert updated.labels == %{"tier" => "worker"}
      assert updated.observation_seq == 1
      assert updated.last_contact_at != nil
    end

    test "rejects stale snapshots" do
      state = NodeCurrentState.new("org-1", "cluster-1", "node-1") |> Map.put(:observation_seq, 5)

      node_data = %{"connectivity" => :reachable, "health" => :healthy}

      {:error, :stale} = NodeCurrentState.apply_snapshot(state, node_data, 3)
    end

    test "accepts snapshot with equal sequence number" do
      state = NodeCurrentState.new("org-1", "cluster-1", "node-1") |> Map.put(:observation_seq, 5)

      node_data = %{"connectivity" => :reachable, "health" => :degraded}

      {:ok, updated} = NodeCurrentState.apply_snapshot(state, node_data, 5)
      assert updated.observation_seq == 5
    end

    test "accepts snapshot with higher sequence number" do
      state = NodeCurrentState.new("org-1", "cluster-1", "node-1") |> Map.put(:observation_seq, 5)

      node_data = %{"connectivity" => :unreachable, "health" => :unreachable}

      {:ok, updated} = NodeCurrentState.apply_snapshot(state, node_data, 8)
      assert updated.observation_seq == 8
    end

    test "handles missing fields in snapshot data" do
      state = NodeCurrentState.new("org-1", "cluster-1", "node-1")

      node_data = %{}

      {:ok, updated} = NodeCurrentState.apply_snapshot(state, node_data, 1)

      assert updated.software_version == nil
      assert updated.capabilities == []
      assert updated.labels == %{}
      assert updated.connectivity == :unreachable
      assert updated.health == :unreachable
    end

    test "updates timestamp on snapshot" do
      state = NodeCurrentState.new("org-1", "cluster-1", "node-1")
      before_time = state.updated_at

      Process.sleep(10)

      node_data = %{"connectivity" => :reachable, "health" => :healthy}

      {:ok, updated} = NodeCurrentState.apply_snapshot(state, node_data, 1)

      assert DateTime.compare(updated.updated_at, before_time) == :gt
    end
  end

  describe "retire/1" do
    test "marks node as retired" do
      state = NodeCurrentState.new("org-1", "cluster-1", "node-1")
      assert !state.retired

      retired_state = NodeCurrentState.retire(state)

      assert retired_state.retired == true
      assert retired_state.connectivity == :unreachable
    end

    test "does not remove other state" do
      state =
        NodeCurrentState.new("org-1", "cluster-1", "node-1")
        |> Map.put(:software_version, "1.2.0")
        |> Map.put(:labels, %{"tier" => "worker"})

      retired_state = NodeCurrentState.retire(state)

      assert retired_state.software_version == "1.2.0"
      assert retired_state.labels == %{"tier" => "worker"}
      assert retired_state.node_id == "node-1"
    end

    test "updates timestamp on retire" do
      state = NodeCurrentState.new("org-1", "cluster-1", "node-1")
      before_time = state.updated_at

      Process.sleep(10)

      retired_state = NodeCurrentState.retire(state)

      assert DateTime.compare(retired_state.updated_at, before_time) == :gt
    end
  end

  describe "retired?/1" do
    test "returns false for active node" do
      state = NodeCurrentState.new("org-1", "cluster-1", "node-1")
      assert !NodeCurrentState.retired?(state)
    end

    test "returns true for retired node" do
      state = NodeCurrentState.new("org-1", "cluster-1", "node-1") |> NodeCurrentState.retire()
      assert NodeCurrentState.retired?(state)
    end
  end
end

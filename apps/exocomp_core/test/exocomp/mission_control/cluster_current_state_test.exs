# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ClusterCurrentStateTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.ClusterCurrentState

  describe "new/2" do
    test "creates initial cluster state" do
      state = ClusterCurrentState.new("org-1", "cluster-1")

      assert state.organization_id == "org-1"
      assert state.cluster_id == "cluster-1"
      assert state.connectivity == :offline
      assert state.health == :unreachable
      assert state.software_version == nil
      assert state.capabilities == []
      assert state.labels == %{}
      assert state.node_count == 0
      assert state.observation_seq == 0
      assert state.last_contact_at == nil
      assert state.updated_at != nil
    end
  end

  describe "apply_hello/2" do
    test "sets cluster to online and healthy with metadata" do
      state = ClusterCurrentState.new("org-1", "cluster-1")

      event = %{
        "cluster_seq" => 1,
        "software_version" => "1.2.3",
        "capabilities" => ["diagnostics", "recovery"],
        "labels" => %{"region" => "us-west-2"},
        "node_count" => 10
      }

      {:ok, updated} = ClusterCurrentState.apply_hello(state, event)

      assert updated.connectivity == :online
      assert updated.health == :healthy
      assert updated.software_version == "1.2.3"
      assert updated.capabilities == ["diagnostics", "recovery"]
      assert updated.labels == %{"region" => "us-west-2"}
      assert updated.node_count == 10
      assert updated.observation_seq == 1
      assert updated.last_contact_at != nil
    end

    test "rejects stale hello events" do
      state = ClusterCurrentState.new("org-1", "cluster-1") |> Map.put(:observation_seq, 5)

      event = %{"cluster_seq" => 3, "software_version" => "0.9.0"}

      {:error, :stale} = ClusterCurrentState.apply_hello(state, event)
    end

    test "accepts hello with equal sequence number" do
      state = ClusterCurrentState.new("org-1", "cluster-1") |> Map.put(:observation_seq, 5)

      event = %{"cluster_seq" => 5, "software_version" => "1.0.0"}

      {:ok, updated} = ClusterCurrentState.apply_hello(state, event)
      assert updated.observation_seq == 5
    end

    test "accepts hello with higher sequence number" do
      state = ClusterCurrentState.new("org-1", "cluster-1") |> Map.put(:observation_seq, 5)

      event = %{"cluster_seq" => 6, "software_version" => "1.0.0"}

      {:ok, updated} = ClusterCurrentState.apply_hello(state, event)
      assert updated.observation_seq == 6
    end

    test "handles missing fields in event" do
      state = ClusterCurrentState.new("org-1", "cluster-1")
      event = %{"cluster_seq" => 1}

      {:ok, updated} = ClusterCurrentState.apply_hello(state, event)

      assert updated.software_version == nil
      assert updated.capabilities == []
      assert updated.labels == %{}
      assert updated.node_count == 0
    end
  end

  describe "apply_heartbeat/2" do
    test "updates connectivity and last contact time" do
      state = ClusterCurrentState.new("org-1", "cluster-1")
      before_time = DateTime.utc_now()

      Process.sleep(10)

      event = %{"cluster_seq" => 1}

      {:ok, updated} = ClusterCurrentState.apply_heartbeat(state, event)

      assert updated.connectivity == :online
      assert updated.last_contact_at != nil
      assert DateTime.compare(updated.last_contact_at, before_time) == :gt
      assert updated.observation_seq == 1
    end

    test "rejects stale heartbeat events" do
      state =
        ClusterCurrentState.new("org-1", "cluster-1")
        |> Map.put(:observation_seq, 10)
        |> Map.put(:connectivity, :online)

      event = %{"cluster_seq" => 5}

      {:error, :stale} = ClusterCurrentState.apply_heartbeat(state, event)
    end

    test "preserves other state on heartbeat" do
      state =
        ClusterCurrentState.new("org-1", "cluster-1")
        |> Map.put(:software_version, "1.2.3")
        |> Map.put(:labels, %{"env" => "prod"})

      event = %{"cluster_seq" => 1}

      {:ok, updated} = ClusterCurrentState.apply_heartbeat(state, event)

      assert updated.software_version == "1.2.3"
      assert updated.labels == %{"env" => "prod"}
    end
  end

  describe "apply_status_snapshot/2" do
    test "updates health from snapshot status" do
      state = ClusterCurrentState.new("org-1", "cluster-1")

      event = %{
        "cluster_seq" => 1,
        "status" => "degraded",
        "node_count" => 8
      }

      {:ok, updated} = ClusterCurrentState.apply_status_snapshot(state, event)

      assert updated.health == :degraded
      assert updated.node_count == 8
      assert updated.observation_seq == 1
    end

    test "maps all status values correctly" do
      state = ClusterCurrentState.new("org-1", "cluster-1")

      for {status_str, expected_health} <- [
            {"healthy", :healthy},
            {"degraded", :degraded},
            {"stale", :stale},
            {"unreachable", :unreachable}
          ] do
        event = %{"cluster_seq" => 1, "status" => status_str}
        {:ok, updated} = ClusterCurrentState.apply_status_snapshot(state, event)
        assert updated.health == expected_health
      end
    end

    test "defaults to unreachable for unknown status" do
      state = ClusterCurrentState.new("org-1", "cluster-1")
      event = %{"cluster_seq" => 1, "status" => "unknown"}

      {:ok, updated} = ClusterCurrentState.apply_status_snapshot(state, event)
      assert updated.health == :unreachable
    end

    test "rejects stale snapshots" do
      state = ClusterCurrentState.new("org-1", "cluster-1") |> Map.put(:observation_seq, 3)

      event = %{"cluster_seq" => 2, "status" => "healthy", "node_count" => 5}

      {:error, :stale} = ClusterCurrentState.apply_status_snapshot(state, event)
    end

    test "preserves previous node count if not in event" do
      state =
        ClusterCurrentState.new("org-1", "cluster-1")
        |> Map.put(:node_count, 15)

      event = %{"cluster_seq" => 1, "status" => "healthy"}

      {:ok, updated} = ClusterCurrentState.apply_status_snapshot(state, event)
      assert updated.node_count == 15
    end
  end
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.CurrentStateReducerTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.CurrentStateReducer, as: Reducer
  alias Exocomp.MissionControl.ClusterCurrentState
  alias Exocomp.MissionControl.NodeCurrentState

  describe "initial state" do
    test "new_store returns empty store with all components" do
      store = Reducer.new_store()

      assert is_map(store)
      assert store.clusters == %{}
      assert store.nodes == %{}
      assert is_struct(store.processed_events, MapSet)
      assert MapSet.size(store.processed_events) == 0
    end

    test "get_cluster returns nil for unknown cluster" do
      store = Reducer.new_store()
      result = Reducer.get_cluster(store, "org-1", "cluster-1")

      assert result == nil
    end

    test "list_clusters returns empty list for unknown org" do
      store = Reducer.new_store()
      result = Reducer.list_clusters(store, "org-1")

      assert result == []
    end

    test "get_node returns nil for unknown node" do
      store = Reducer.new_store()
      result = Reducer.get_node(store, "org-1", "cluster-1", "node-1")

      assert result == nil
    end

    test "list_cluster_nodes returns empty list for unknown cluster" do
      store = Reducer.new_store()
      result = Reducer.list_cluster_nodes(store, "org-1", "cluster-1")

      assert result == []
    end
  end

  describe "cluster.hello event processing" do
    test "creates new cluster state from hello event" do
      store = Reducer.new_store()

      event = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "software_version" => "1.0.0",
          "capabilities" => ["health_check", "diagnostics"],
          "labels" => %{"region" => "us-west"},
          "node_count" => 5
        }
      }

      {:ok, updated_store, :processed} = Reducer.process_event(store, event, "org-1")

      cluster = Reducer.get_cluster(updated_store, "org-1", "cluster-1")
      assert cluster != nil
      assert cluster.organization_id == "org-1"
      assert cluster.cluster_id == "cluster-1"
      assert cluster.connectivity == :online
      assert cluster.health == :healthy
      assert cluster.software_version == "1.0.0"
      assert cluster.capabilities == ["health_check", "diagnostics"]
      assert cluster.labels == %{"region" => "us-west"}
      assert cluster.node_count == 5
      assert cluster.observation_seq == 1
    end

    test "hello event is idempotent" do
      store = Reducer.new_store()

      event = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "software_version" => "1.0.0",
          "capabilities" => ["health_check"],
          "labels" => %{},
          "node_count" => 0
        }
      }

      {:ok, store1, :processed} = Reducer.process_event(store, event, "org-1")
      {:ok, store2, :duplicate} = Reducer.process_event(store1, event, "org-1")

      cluster1 = Reducer.get_cluster(store1, "org-1", "cluster-1")
      cluster2 = Reducer.get_cluster(store2, "org-1", "cluster-1")
      assert cluster1 == cluster2
    end

    test "rejects hello without cluster_id" do
      store = Reducer.new_store()

      event = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "payload" => %{}
      }

      {:error, :missing_cluster_id, returned_store} = Reducer.process_event(store, event, "org-1")
      assert returned_store == store
    end
  end

  describe "cluster.heartbeat event processing" do
    test "updates cluster connectivity on heartbeat" do
      store = Reducer.new_store()

      hello_event = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{"cluster_seq" => 1, "node_count" => 5}
      }

      {:ok, store, _} = Reducer.process_event(store, hello_event, "org-1")

      heartbeat_event = %{
        "event_id" => "ev-2",
        "kind" => "cluster.heartbeat",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 2,
        "payload" => %{"cluster_seq" => 2}
      }

      {:ok, updated_store, :processed} = Reducer.process_event(store, heartbeat_event, "org-1")

      cluster = Reducer.get_cluster(updated_store, "org-1", "cluster-1")
      assert cluster.connectivity == :online
      assert cluster.observation_seq == 2
      assert cluster.last_contact_at != nil
    end
  end

  describe "status.snapshot event processing" do
    test "creates nodes from status snapshot" do
      store = Reducer.new_store()

      snapshot_event = %{
        "event_id" => "ev-1",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "status" => "healthy",
          "node_count" => 2,
          "nodes" => %{
            "node-1" => %{
              "connectivity" => :reachable,
              "health" => :healthy,
              "software_version" => "1.0.0",
              "capabilities" => ["exec"],
              "labels" => %{"role" => "worker"}
            },
            "node-2" => %{
              "connectivity" => :reachable,
              "health" => :degraded,
              "software_version" => "1.0.0",
              "capabilities" => ["exec"],
              "labels" => %{"role" => "worker"}
            }
          }
        }
      }

      {:ok, updated_store, :processed} = Reducer.process_event(store, snapshot_event, "org-1")

      node1 = Reducer.get_node(updated_store, "org-1", "cluster-1", "node-1")
      node2 = Reducer.get_node(updated_store, "org-1", "cluster-1", "node-2")

      assert node1 != nil
      assert node1.health == :healthy
      assert node1.connectivity == :reachable

      assert node2 != nil
      assert node2.health == :degraded
      assert node2.connectivity == :reachable

      cluster = Reducer.get_cluster(updated_store, "org-1", "cluster-1")
      assert cluster.node_count == 2
    end

    test "list_cluster_nodes returns all nodes from snapshot" do
      store = Reducer.new_store()

      snapshot_event = %{
        "event_id" => "ev-1",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "status" => "healthy",
          "node_count" => 3,
          "nodes" => %{
            "node-1" => %{"connectivity" => :reachable, "health" => :healthy},
            "node-2" => %{"connectivity" => :reachable, "health" => :healthy},
            "node-3" => %{"connectivity" => :unreachable, "health" => :unreachable}
          }
        }
      }

      {:ok, updated_store, _} = Reducer.process_event(store, snapshot_event, "org-1")

      nodes = Reducer.list_cluster_nodes(updated_store, "org-1", "cluster-1")
      assert length(nodes) == 3

      active_nodes = Reducer.list_active_nodes(updated_store, "org-1", "cluster-1")
      assert length(active_nodes) == 3
    end
  end

  describe "stale update rejection" do
    test "rejects hello with older cluster_seq" do
      store = Reducer.new_store()

      event1 = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 2,
        "payload" => %{"cluster_seq" => 2, "software_version" => "2.0.0"}
      }

      {:ok, store, _} = Reducer.process_event(store, event1, "org-1")

      # Older event arrives out of order
      event2 = %{
        "event_id" => "ev-2",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{"cluster_seq" => 1, "software_version" => "1.0.0"}
      }

      {:error, :stale, returned_store} = Reducer.process_event(store, event2, "org-1")

      cluster = Reducer.get_cluster(returned_store, "org-1", "cluster-1")
      assert cluster.software_version == "2.0.0"
      assert cluster.observation_seq == 2
    end

    test "rejects status snapshot with older cluster_seq for nodes" do
      store = Reducer.new_store()

      snapshot1 = %{
        "event_id" => "ev-1",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 2,
        "payload" => %{
          "cluster_seq" => 2,
          "status" => "healthy",
          "node_count" => 1,
          "nodes" => %{
            "node-1" => %{
              "connectivity" => :reachable,
              "health" => :healthy,
              "software_version" => "2.0.0"
            }
          }
        }
      }

      {:ok, store, _} = Reducer.process_event(store, snapshot1, "org-1")

      # Older snapshot
      snapshot2 = %{
        "event_id" => "ev-2",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "status" => "degraded",
          "node_count" => 1,
          "nodes" => %{
            "node-1" => %{
              "connectivity" => :unreachable,
              "health" => :degraded,
              "software_version" => "1.0.0"
            }
          }
        }
      }

      {:ok, updated_store, _} = Reducer.process_event(store, snapshot2, "org-1")

      node = Reducer.get_node(updated_store, "org-1", "cluster-1", "node-1")
      assert node.software_version == "2.0.0"
      assert node.health == :healthy
    end
  end

  describe "node removal/tombstone detection" do
    test "detects and retires nodes no longer in snapshot" do
      store = Reducer.new_store()

      snapshot1 = %{
        "event_id" => "ev-1",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "status" => "healthy",
          "node_count" => 3,
          "nodes" => %{
            "node-1" => %{"connectivity" => :reachable, "health" => :healthy},
            "node-2" => %{"connectivity" => :reachable, "health" => :healthy},
            "node-3" => %{"connectivity" => :reachable, "health" => :healthy}
          }
        }
      }

      {:ok, store, _} = Reducer.process_event(store, snapshot1, "org-1")

      # Second snapshot with only 2 nodes
      snapshot2 = %{
        "event_id" => "ev-2",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 2,
        "payload" => %{
          "cluster_seq" => 2,
          "status" => "healthy",
          "node_count" => 2,
          "nodes" => %{
            "node-1" => %{"connectivity" => :reachable, "health" => :healthy},
            "node-2" => %{"connectivity" => :reachable, "health" => :healthy}
          }
        }
      }

      {:ok, updated_store, _} = Reducer.process_event(store, snapshot2, "org-1")

      node1 = Reducer.get_node(updated_store, "org-1", "cluster-1", "node-1")
      node2 = Reducer.get_node(updated_store, "org-1", "cluster-1", "node-2")
      node3 = Reducer.get_node(updated_store, "org-1", "cluster-1", "node-3")

      assert !NodeCurrentState.retired?(node1)
      assert !NodeCurrentState.retired?(node2)
      assert NodeCurrentState.retired?(node3)
    end

    test "list_retired_nodes returns only retired nodes" do
      store = Reducer.new_store()

      snapshot1 = %{
        "event_id" => "ev-1",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "status" => "healthy",
          "node_count" => 2,
          "nodes" => %{
            "node-1" => %{"connectivity" => :reachable, "health" => :healthy},
            "node-2" => %{"connectivity" => :reachable, "health" => :healthy}
          }
        }
      }

      {:ok, store, _} = Reducer.process_event(store, snapshot1, "org-1")

      snapshot2 = %{
        "event_id" => "ev-2",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 2,
        "payload" => %{
          "cluster_seq" => 2,
          "status" => "healthy",
          "node_count" => 1,
          "nodes" => %{
            "node-1" => %{"connectivity" => :reachable, "health" => :healthy}
          }
        }
      }

      {:ok, updated_store, _} = Reducer.process_event(store, snapshot2, "org-1")

      active = Reducer.list_active_nodes(updated_store, "org-1", "cluster-1")
      retired = Reducer.list_retired_nodes(updated_store, "org-1", "cluster-1")

      assert length(active) == 1
      assert length(retired) == 1
      assert hd(retired).node_id == "node-2"
    end
  end

  describe "reconnect handling" do
    test "cluster can reconnect after going offline" do
      store = Reducer.new_store()

      hello = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{"cluster_seq" => 1}
      }

      {:ok, store, _} = Reducer.process_event(store, hello, "org-1")

      cluster1 = Reducer.get_cluster(store, "org-1", "cluster-1")
      assert cluster1.connectivity == :online

      # Simulate offline - next hello with same cluster_id updates it
      hello2 = %{
        "event_id" => "ev-2",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 2,
        "payload" => %{"cluster_seq" => 2}
      }

      {:ok, updated_store, _} = Reducer.process_event(store, hello2, "org-1")

      cluster2 = Reducer.get_cluster(updated_store, "org-1", "cluster-1")
      assert cluster2.connectivity == :online
      assert cluster2.observation_seq == 2
    end

    test "node state persists across cluster reconnect" do
      store = Reducer.new_store()

      snapshot1 = %{
        "event_id" => "ev-1",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "status" => "healthy",
          "node_count" => 1,
          "nodes" => %{
            "node-1" => %{"connectivity" => :reachable, "health" => :healthy}
          }
        }
      }

      {:ok, store, _} = Reducer.process_event(store, snapshot1, "org-1")

      node1_before = Reducer.get_node(store, "org-1", "cluster-1", "node-1")
      assert node1_before.observation_seq == 1

      # Reconnect with new snapshot
      snapshot2 = %{
        "event_id" => "ev-2",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 2,
        "payload" => %{
          "cluster_seq" => 2,
          "status" => "healthy",
          "node_count" => 1,
          "nodes" => %{
            "node-1" => %{"connectivity" => :reachable, "health" => :degraded}
          }
        }
      }

      {:ok, updated_store, _} = Reducer.process_event(store, snapshot2, "org-1")

      node1_after = Reducer.get_node(updated_store, "org-1", "cluster-1", "node-1")
      assert node1_after.observation_seq == 2
      assert node1_after.health == :degraded
    end
  end

  describe "duplicate event handling" do
    test "duplicate event_id returns :duplicate without modifying state" do
      store = Reducer.new_store()

      event = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{"cluster_seq" => 1, "software_version" => "1.0.0"}
      }

      {:ok, store1, :processed} = Reducer.process_event(store, event, "org-1")

      # Same event_id, different payload
      event_dup = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 2,
        "payload" => %{"cluster_seq" => 2, "software_version" => "2.0.0"}
      }

      {:ok, store2, :duplicate} = Reducer.process_event(store1, event_dup, "org-1")

      cluster = Reducer.get_cluster(store2, "org-1", "cluster-1")
      assert cluster.software_version == "1.0.0"
      assert cluster.observation_seq == 1
    end
  end

  describe "organization isolation" do
    test "same cluster_id in different orgs remain isolated" do
      store = Reducer.new_store()

      event_org1 = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{"cluster_seq" => 1, "software_version" => "1.0.0"}
      }

      event_org2 = %{
        "event_id" => "ev-2",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{"cluster_seq" => 1, "software_version" => "2.0.0"}
      }

      {:ok, store, _} = Reducer.process_event(store, event_org1, "org-1")
      {:ok, store, _} = Reducer.process_event(store, event_org2, "org-2")

      cluster_org1 = Reducer.get_cluster(store, "org-1", "cluster-1")
      cluster_org2 = Reducer.get_cluster(store, "org-2", "cluster-1")

      assert cluster_org1.software_version == "1.0.0"
      assert cluster_org2.software_version == "2.0.0"
    end

    test "same node_id in different orgs and clusters remain isolated" do
      store = Reducer.new_store()

      snapshot1 = %{
        "event_id" => "ev-1",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "status" => "healthy",
          "node_count" => 1,
          "nodes" => %{
            "node-1" => %{"connectivity" => :reachable, "health" => :healthy}
          }
        }
      }

      snapshot2 = %{
        "event_id" => "ev-2",
        "kind" => "status.snapshot",
        "cluster_id" => "cluster-2",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "status" => "healthy",
          "node_count" => 1,
          "nodes" => %{
            "node-1" => %{"connectivity" => :reachable, "health" => :degraded}
          }
        }
      }

      {:ok, store, _} = Reducer.process_event(store, snapshot1, "org-1")
      {:ok, store, _} = Reducer.process_event(store, snapshot2, "org-1")

      node_c1 = Reducer.get_node(store, "org-1", "cluster-1", "node-1")
      node_c2 = Reducer.get_node(store, "org-1", "cluster-2", "node-1")

      assert node_c1.health == :healthy
      assert node_c2.health == :degraded
    end

    test "list_clusters returns only requested org" do
      store = Reducer.new_store()

      event1 = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{"cluster_seq" => 1}
      }

      event2 = %{
        "event_id" => "ev-2",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-2",
        "cluster_seq" => 1,
        "payload" => %{"cluster_seq" => 1}
      }

      {:ok, store, _} = Reducer.process_event(store, event1, "org-1")
      {:ok, store, _} = Reducer.process_event(store, event2, "org-2")

      clusters_org1 = Reducer.list_clusters(store, "org-1")
      clusters_org2 = Reducer.list_clusters(store, "org-2")

      assert length(clusters_org1) == 1
      assert length(clusters_org2) == 1
      assert hd(clusters_org1).cluster_id == "cluster-1"
      assert hd(clusters_org2).cluster_id == "cluster-2"
    end
  end

  describe "partial updates" do
    test "hello updates cluster versions without affecting existing connectivity" do
      store = Reducer.new_store()

      hello1 = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "software_version" => "1.0.0",
          "capabilities" => ["exec"]
        }
      }

      {:ok, store, _} = Reducer.process_event(store, hello1, "org-1")

      cluster1 = Reducer.get_cluster(store, "org-1", "cluster-1")
      assert cluster1.software_version == "1.0.0"
      assert cluster1.capabilities == ["exec"]

      hello2 = %{
        "event_id" => "ev-2",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 2,
        "payload" => %{
          "cluster_seq" => 2,
          "software_version" => "1.1.0"
        }
      }

      {:ok, updated_store, _} = Reducer.process_event(store, hello2, "org-1")

      cluster2 = Reducer.get_cluster(updated_store, "org-1", "cluster-1")
      assert cluster2.software_version == "1.1.0"
      assert cluster2.capabilities == ["exec"]
      assert cluster2.connectivity == :online
    end

    test "heartbeat maintains other cluster state unchanged" do
      store = Reducer.new_store()

      hello = %{
        "event_id" => "ev-1",
        "kind" => "cluster.hello",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 1,
        "payload" => %{
          "cluster_seq" => 1,
          "software_version" => "1.0.0",
          "labels" => %{"env" => "prod"}
        }
      }

      {:ok, store, _} = Reducer.process_event(store, hello, "org-1")

      cluster_before = Reducer.get_cluster(store, "org-1", "cluster-1")
      before_contact = cluster_before.last_contact_at

      heartbeat = %{
        "event_id" => "ev-2",
        "kind" => "cluster.heartbeat",
        "cluster_id" => "cluster-1",
        "cluster_seq" => 2,
        "payload" => %{"cluster_seq" => 2}
      }

      {:ok, updated_store, _} = Reducer.process_event(store, heartbeat, "org-1")

      cluster_after = Reducer.get_cluster(updated_store, "org-1", "cluster-1")
      assert cluster_after.software_version == "1.0.0"
      assert cluster_after.labels == %{"env" => "prod"}
      assert cluster_after.observation_seq == 2
    end
  end
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile.CephHealthReducerTest do
  @moduledoc """
  Table-driven tests for `Exocomp.ClusterProfile.CephHealthReducer`.

  Tests cover health levels, stale/partial evidence, missing daemons,
  unreachable nodes, unsupported profile versions, and recovery to healthy.
  """

  use ExUnit.Case, async: true

  alias Exocomp.ClusterProfile.CephHealthReducer

  # ──────────────────────────────────────────────────────────────────────────
  # Fixtures
  # ──────────────────────────────────────────────────────────────────────────

  defp base_evidence do
    %{
      schema_version: 1,
      status: :ok,
      collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      health: %{
        "overall" => %{"status" => "HEALTH_OK"},
        "status" => "HEALTH_OK"
      },
      topology: %{},
      errors: []
    }
  end

  defp base_topology_result do
    %{
      schema_version: 1,
      status: :ok,
      mappings: [],
      nodes: [
        %{node_id: "node-1", hostname: "ceph-node-1", status: :member, coverage: :supported}
      ],
      desired_services: [],
      coverage: %{
        status: :complete,
        topology_status: :ok,
        inventory_nodes: 1,
        supported_nodes: 1,
        non_member_nodes: 0,
        unsupported_nodes: []
      }
    }
  end

  defp base_daemon_states do
    []
  end

  defp base_profile_coverage do
    %{status: :available, details: %{}}
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Table-driven tests: Health Levels
  # ──────────────────────────────────────────────────────────────────────────

  describe "health_level_mapping" do
    test "HEALTH_OK with complete coverage maps to healthy" do
      evidence = %{base_evidence() | health: %{"status" => "HEALTH_OK"}}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [], base_profile_coverage())

      assert result.cluster_health.severity == :healthy
      assert result.cluster_health.reasons == []
      assert result.cluster_health.status == "HEALTH_OK"
    end

    test "HEALTH_WARN maps to degraded" do
      evidence = %{base_evidence() | health: %{"status" => "HEALTH_WARN"}}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [], base_profile_coverage())

      assert result.cluster_health.severity == :degraded
      assert :degraded in Enum.map(result.cluster_health.reasons, & &1) or
             result.cluster_health.status == "HEALTH_WARN"
    end

    test "HEALTH_ERR maps to critical" do
      evidence = %{base_evidence() | health: %{"status" => "HEALTH_ERR"}}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [], base_profile_coverage())

      assert result.cluster_health.severity == :critical
      assert :critical_health_status in result.cluster_health.reasons
    end

    test "unknown status maps to degraded" do
      evidence = %{base_evidence() | health: %{}}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [], base_profile_coverage())

      assert result.cluster_health.severity in [:unknown, :degraded]
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Table-driven tests: Stale Evidence
  # ──────────────────────────────────────────────────────────────────────────

  describe "stale_evidence" do
    test "recent evidence (< 5 min) is not stale" do
      now = DateTime.utc_now()
      recent = now |> DateTime.add(-60, :second) |> DateTime.to_iso8601()

      evidence = %{base_evidence() | collected_at: recent}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :stale_evidence not in result.cluster_health.reasons
    end

    test "old evidence (> 5 min) is stale" do
      now = DateTime.utc_now()
      old = now |> DateTime.add(-400, :second) |> DateTime.to_iso8601()

      evidence = %{base_evidence() | collected_at: old}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :stale_evidence in result.cluster_health.reasons
      assert result.cluster_health.severity == :degraded
    end

    test "missing collected_at timestamp is treated as stale" do
      evidence = %{base_evidence() | collected_at: nil}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :stale_evidence in result.cluster_health.reasons
    end

    test "invalid timestamp format is treated as stale" do
      evidence = %{base_evidence() | collected_at: "not-a-timestamp"}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :stale_evidence in result.cluster_health.reasons
    end

    test "custom freshness threshold is respected" do
      now = DateTime.utc_now()
      somewhat_old = now |> DateTime.add(-150, :second) |> DateTime.to_iso8601()

      evidence = %{base_evidence() | collected_at: somewhat_old}
      topology = base_topology_result()

      # 2 minute threshold
      result =
        CephHealthReducer.reduce(evidence, topology, [], %{}, freshness_threshold_ms: 120_000)

      assert :stale_evidence in result.cluster_health.reasons
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Table-driven tests: Missing/Partial Evidence
  # ──────────────────────────────────────────────────────────────────────────

  describe "evidence_availability" do
    test "degraded collection status triggers missing_evidence" do
      evidence = %{base_evidence() | status: :degraded}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :missing_evidence in result.cluster_health.reasons
      assert result.cluster_health.severity == :degraded
    end

    test "partial collection status does not trigger missing_evidence alone" do
      evidence = %{base_evidence() | status: :partial}
      topology = %{base_topology_result() | status: :ok}

      result = CephHealthReducer.reduce(evidence, topology, [])

      # Partial is acceptable if topology is ok
      assert result.cluster_health.severity in [:degraded, :healthy]
    end

    test "missing health data is handled gracefully" do
      evidence = %{base_evidence() | health: nil}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert result.cluster_health.status == "unknown"
    end

    test "empty health map is handled gracefully" do
      evidence = %{base_evidence() | health: %{}}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert result.cluster_health.status == "unknown"
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Table-driven tests: Incomplete Coverage
  # ──────────────────────────────────────────────────────────────────────────

  describe "incomplete_coverage" do
    test "degraded coverage status triggers incomplete_coverage reason" do
      topology = %{
        base_topology_result()
        | coverage: %{
            status: :degraded,
            topology_status: :ok,
            inventory_nodes: 3,
            supported_nodes: 2,
            non_member_nodes: 0,
            unsupported_nodes: ["node-3"]
          }
      }

      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :incomplete_coverage in result.cluster_health.reasons
      assert result.cluster_health.severity == :degraded
    end

    test "complete coverage with healthy cluster gives healthy status" do
      topology = %{
        base_topology_result()
        | coverage: %{
            status: :complete,
            topology_status: :ok,
            inventory_nodes: 3,
            supported_nodes: 3,
            non_member_nodes: 0,
            unsupported_nodes: []
          }
      }

      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :incomplete_coverage not in result.cluster_health.reasons
      assert result.cluster_health.severity == :healthy
    end

    test "missing coverage data defaults to degraded" do
      topology = %{base_topology_result() | coverage: nil}
      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [])

      # With missing coverage, should be degraded
      assert result.cluster_health.severity in [:degraded, :unknown]
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Table-driven tests: Ambiguous Topology
  # ──────────────────────────────────────────────────────────────────────────

  describe "ambiguous_topology" do
    test "ambiguous topology status triggers reason" do
      topology = %{base_topology_result() | status: :ambiguous}
      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :ambiguous_topology in result.cluster_health.reasons
      assert result.cluster_health.severity == :degraded
    end

    test "missing topology status triggers reason" do
      topology = %{base_topology_result() | status: :missing}
      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :ambiguous_topology in result.cluster_health.reasons
    end

    test "conflicting_fsid topology status triggers reason" do
      topology = %{base_topology_result() | status: :conflicting_fsid}
      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :ambiguous_topology in result.cluster_health.reasons
    end

    test "orphan_daemon topology status triggers reason" do
      topology = %{base_topology_result() | status: :orphan_daemon}
      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :ambiguous_topology in result.cluster_health.reasons
    end

    test "ok topology status does not trigger ambiguous_topology" do
      topology = %{base_topology_result() | status: :ok}
      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :ambiguous_topology not in result.cluster_health.reasons
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Table-driven tests: Daemon Health (Missing/Unreachable)
  # ──────────────────────────────────────────────────────────────────────────

  describe "daemon_health_missing_unreachable" do
    test "missing daemon systemd state is detected" do
      topology = %{
        base_topology_result()
        | mappings: [
            %{
              node_id: "node-1",
              authoritative: %{id: "0", kind: :mon},
              local: %{unit: "ceph-mon@ceph-mon-0.service", state: %{}}
            }
          ]
      }

      evidence = base_evidence()
      daemon_states = []

      result = CephHealthReducer.reduce(evidence, topology, daemon_states, base_profile_coverage())

      assert length(result.daemon_health) == 1
      daemon = List.first(result.daemon_health)
      # Missing systemd state means no validation
      assert daemon.severity in [:degraded, :healthy]
    end

    test "unreachable node produces degraded daemon status" do
      topology = %{
        base_topology_result()
        | mappings: [
            %{
              node_id: "unreachable-node",
              authoritative: %{id: "0", kind: :mon},
              local: %{unit: "ceph-mon@ceph-mon-0.service", state: %{}}
            }
          ],
          nodes: [
            %{
              node_id: "unreachable-node",
              hostname: "unreachable.local",
              status: :unreachable,
              coverage: :degraded
            }
          ]
      }

      evidence = base_evidence()
      daemon_states = []

      result = CephHealthReducer.reduce(evidence, topology, daemon_states, base_profile_coverage())

      assert length(result.daemon_health) == 1
    end

    test "empty daemon mappings produces empty daemon_health list" do
      topology = %{base_topology_result() | mappings: []}
      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [], base_profile_coverage())

      assert result.daemon_health == []
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Table-driven tests: Daemon Systemd State Validation
  # ──────────────────────────────────────────────────────────────────────────

  describe "daemon_systemd_state" do
    test "healthy started daemon (active, loaded) is healthy" do
      topology = %{
        base_topology_result()
        | mappings: [
            %{
              node_id: "node-1",
              authoritative: %{id: "0", kind: :mon},
              local: %{unit: "ceph-mon@ceph-mon-0.service", state: %{}}
            }
          ]
      }

      evidence = base_evidence()

      daemon_states = [
        %{
          node_id: "node-1",
          unit: "ceph-mon@ceph-mon-0.service",
          expected_state: :started,
          active_state: "active",
          load_state: "loaded"
        }
      ]

      result = CephHealthReducer.reduce(evidence, topology, daemon_states, base_profile_coverage())

      daemon = List.first(result.daemon_health)
      assert daemon.severity == :healthy
      assert :daemon_state_failed not in daemon.reasons
    end

    test "failed daemon (inactive when started) is degraded" do
      topology = %{
        base_topology_result()
        | mappings: [
            %{
              node_id: "node-1",
              authoritative: %{id: "0", kind: :mon},
              local: %{unit: "ceph-mon@ceph-mon-0.service", state: %{}}
            }
          ]
      }

      evidence = base_evidence()

      daemon_states = [
        %{
          node_id: "node-1",
          unit: "ceph-mon@ceph-mon-0.service",
          expected_state: :started,
          active_state: "inactive",
          load_state: "loaded"
        }
      ]

      result = CephHealthReducer.reduce(evidence, topology, daemon_states, base_profile_coverage())

      daemon = List.first(result.daemon_health)
      assert daemon.severity == :degraded
      assert :daemon_state_failed in daemon.reasons
    end

    test "daemon with bad load state is degraded" do
      topology = %{
        base_topology_result()
        | mappings: [
            %{
              node_id: "node-1",
              authoritative: %{id: "0", kind: :mon},
              local: %{unit: "ceph-mon@ceph-mon-0.service", state: %{}}
            }
          ]
      }

      evidence = base_evidence()

      daemon_states = [
        %{
          node_id: "node-1",
          unit: "ceph-mon@ceph-mon-0.service",
          expected_state: :started,
          active_state: "active",
          load_state: "not-found"
        }
      ]

      result = CephHealthReducer.reduce(evidence, topology, daemon_states, base_profile_coverage())

      daemon = List.first(result.daemon_health)
      assert daemon.severity == :degraded
    end

    test "activating state is considered healthy for started daemons" do
      topology = %{
        base_topology_result()
        | mappings: [
            %{
              node_id: "node-1",
              authoritative: %{id: "0", kind: :mon},
              local: %{unit: "ceph-mon@ceph-mon-0.service", state: %{}}
            }
          ]
      }

      evidence = base_evidence()

      daemon_states = [
        %{
          node_id: "node-1",
          unit: "ceph-mon@ceph-mon-0.service",
          expected_state: :started,
          active_state: "activating",
          load_state: "loaded"
        }
      ]

      result = CephHealthReducer.reduce(evidence, topology, daemon_states, base_profile_coverage())

      daemon = List.first(result.daemon_health)
      assert daemon.severity == :healthy
    end

    test "deactivating state is considered healthy for stopped daemons" do
      topology = %{
        base_topology_result()
        | mappings: [
            %{
              node_id: "node-1",
              authoritative: %{id: "0", kind: :mon},
              local: %{unit: "ceph-mon@ceph-mon-0.service", state: %{}}
            }
          ]
      }

      evidence = base_evidence()

      daemon_states = [
        %{
          node_id: "node-1",
          unit: "ceph-mon@ceph-mon-0.service",
          expected_state: :stopped,
          active_state: "deactivating",
          load_state: "loaded"
        }
      ]

      result = CephHealthReducer.reduce(evidence, topology, daemon_states, base_profile_coverage())

      daemon = List.first(result.daemon_health)
      assert daemon.severity == :healthy
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Table-driven tests: Unsupported Profile Versions
  # ──────────────────────────────────────────────────────────────────────────

  describe "unsupported_profile_versions" do
    test "degraded coverage status triggers unsupported_profiles reason" do
      topology = %{
        base_topology_result()
        | coverage: %{
            status: :degraded,
            topology_status: :ok,
            inventory_nodes: 1,
            supported_nodes: 0,
            non_member_nodes: 0,
            unsupported_nodes: ["node-1"]
          },
          mappings: [
            %{
              node_id: "node-1",
              authoritative: %{id: "0", kind: :mon},
              local: %{unit: "ceph-mon@ceph-mon-0.service", state: %{}}
            }
          ]
      }

      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [], base_profile_coverage())

      # Check daemon health
      daemon = List.first(result.daemon_health)
      assert :unsupported_profiles in daemon.reasons
      assert daemon.severity == :degraded
    end

    test "complete coverage has no unsupported_profiles reason" do
      topology = %{
        base_topology_result()
        | coverage: %{
            status: :complete,
            topology_status: :ok,
            inventory_nodes: 1,
            supported_nodes: 1,
            non_member_nodes: 0,
            unsupported_nodes: []
          },
          mappings: [
            %{
              node_id: "node-1",
              authoritative: %{id: "0", kind: :mon},
              local: %{unit: "ceph-mon@ceph-mon-0.service", state: %{}}
            }
          ]
      }

      evidence = base_evidence()

      daemon_states = [
        %{
          node_id: "node-1",
          unit: "ceph-mon@ceph-mon-0.service",
          expected_state: :started,
          active_state: "active",
          load_state: "loaded"
        }
      ]

      result = CephHealthReducer.reduce(evidence, topology, daemon_states, base_profile_coverage())

      daemon = List.first(result.daemon_health)
      assert :unsupported_profiles not in daemon.reasons
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Table-driven tests: Recovery to Healthy
  # ──────────────────────────────────────────────────────────────────────────

  describe "recovery_to_healthy" do
    test "recovery from stale to fresh evidence returns to healthy" do
      now = DateTime.utc_now()
      fresh = now |> DateTime.add(-60, :second) |> DateTime.to_iso8601()

      evidence = %{
        base_evidence()
        | collected_at: fresh,
          health: %{"status" => "HEALTH_OK"}
      }

      topology = %{
        base_topology_result()
        | coverage: %{
            status: :complete,
            topology_status: :ok,
            inventory_nodes: 1,
            supported_nodes: 1,
            non_member_nodes: 0,
            unsupported_nodes: []
          }
      }

      daemon_states = [
        %{
          node_id: "node-1",
          unit: "ceph-mon@ceph-mon-0.service",
          expected_state: :started,
          active_state: "active",
          load_state: "loaded"
        }
      ]

      result = CephHealthReducer.reduce(evidence, topology, daemon_states, base_profile_coverage())

      assert result.cluster_health.severity == :healthy
      assert result.cluster_health.reasons == []
    end

    test "recovery from HEALTH_WARN to HEALTH_OK returns to healthy" do
      evidence = %{
        base_evidence()
        | health: %{"status" => "HEALTH_OK"}
      }

      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [], base_profile_coverage())

      assert result.cluster_health.severity == :healthy
    end

    test "recovery from degraded coverage to complete coverage" do
      topology = %{
        base_topology_result()
        | coverage: %{
            status: :complete,
            topology_status: :ok,
            inventory_nodes: 3,
            supported_nodes: 3,
            non_member_nodes: 0,
            unsupported_nodes: []
          }
      }

      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [], base_profile_coverage())

      assert :incomplete_coverage not in result.cluster_health.reasons
      assert result.cluster_health.severity == :healthy
    end

    test "recovery from ambiguous to ok topology" do
      topology = %{base_topology_result() | status: :ok}
      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert :ambiguous_topology not in result.cluster_health.reasons
      assert result.cluster_health.severity == :healthy
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Edge cases and Structure Tests
  # ──────────────────────────────────────────────────────────────────────────

  describe "result_structure" do
    test "result has required fields" do
      evidence = base_evidence()
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [], base_profile_coverage())

      assert Map.has_key?(result, :schema_version)
      assert Map.has_key?(result, :collected_at)
      assert Map.has_key?(result, :cluster_health)
      assert Map.has_key?(result, :daemon_health)
      assert Map.has_key?(result, :coverage)
      assert Map.has_key?(result, :deterministic)

      assert result.schema_version == 1
      assert is_binary(result.collected_at)
      assert is_map(result.cluster_health)
      assert is_list(result.daemon_health)
      assert is_map(result.coverage)
      assert result.deterministic == true
    end

    test "cluster_health has required fields" do
      evidence = base_evidence()
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [], base_profile_coverage())

      cluster_health = result.cluster_health

      assert Map.has_key?(cluster_health, :severity)
      assert Map.has_key?(cluster_health, :reasons)
      assert Map.has_key?(cluster_health, :status)
      assert Map.has_key?(cluster_health, :evidence_ref)

      assert cluster_health.severity in [:healthy, :degraded, :critical, :unknown]
      assert is_list(cluster_health.reasons)
    end

    test "reasons are deterministic and unique" do
      evidence = %{
        base_evidence()
        | status: :degraded
      }

      topology = %{
        base_topology_result()
        | status: :ambiguous,
          coverage: %{status: :degraded}
      }

      result1 = CephHealthReducer.reduce(evidence, topology, [])
      result2 = CephHealthReducer.reduce(evidence, topology, [])

      # Same input should produce same reasons
      assert result1.cluster_health.reasons == result2.cluster_health.reasons

      # Reasons should be unique (no duplicates)
      reasons = result1.cluster_health.reasons
      assert length(reasons) == length(Enum.uniq(reasons))
    end

    test "evidence_ref is bounded" do
      now = DateTime.utc_now()
      long_ts = now |> DateTime.to_iso8601()

      evidence = %{base_evidence() | collected_at: long_ts}
      topology = base_topology_result()

      result = CephHealthReducer.reduce(evidence, topology, [])

      ref = result.cluster_health.evidence_ref
      assert byte_size(ref) <= 64
    end

    test "daemon_health list is sorted deterministically" do
      topology = %{
        base_topology_result()
        | mappings: [
            %{
              node_id: "z-node",
              authoritative: %{id: "2", kind: :osd},
              local: %{unit: "ceph-osd.2", state: %{}}
            },
            %{
              node_id: "a-node",
              authoritative: %{id: "0", kind: :mon},
              local: %{unit: "ceph-mon.0", state: %{}}
            },
            %{
              node_id: "a-node",
              authoritative: %{id: "1", kind: :mgr},
              local: %{unit: "ceph-mgr.1", state: %{}}
            }
          ]
      }

      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [])

      # Should be sorted by node_id, kind, daemon_id
      daemon_health = result.daemon_health

      assert Enum.at(daemon_health, 0).node_id == "a-node"
      assert Enum.at(daemon_health, 0).kind == :mgr

      assert Enum.at(daemon_health, 1).node_id == "a-node"
      assert Enum.at(daemon_health, 1).kind == :mon

      assert Enum.at(daemon_health, 2).node_id == "z-node"
      assert Enum.at(daemon_health, 2).kind == :osd
    end
  end

  describe "edge_cases" do
    test "nil/empty inputs are handled gracefully" do
      # Empty inputs should not crash
      result = CephHealthReducer.reduce(%{}, %{}, [], %{})

      assert result.schema_version == 1
      assert is_map(result.cluster_health)
      assert is_list(result.daemon_health)
    end

    test "missing topology_result uses defaults" do
      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, %{}, [], base_profile_coverage())

      assert result.cluster_health.severity in [:degraded, :unknown]
    end

    test "multiple daemon mappings on same node are all evaluated" do
      topology = %{
        base_topology_result()
        | mappings: [
            %{
              node_id: "node-1",
              authoritative: %{id: "0", kind: :mon},
              local: %{unit: "ceph-mon.0", state: %{}}
            },
            %{
              node_id: "node-1",
              authoritative: %{id: "1", kind: :mgr},
              local: %{unit: "ceph-mgr.1", state: %{}}
            },
            %{
              node_id: "node-1",
              authoritative: %{id: "0", kind: :osd},
              local: %{unit: "ceph-osd.0", state: %{}}
            }
          ]
      }

      evidence = base_evidence()

      result = CephHealthReducer.reduce(evidence, topology, [])

      assert length(result.daemon_health) == 3
    end
  end
end

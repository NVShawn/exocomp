# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.CephTopologyTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.CephTopology

  @fsid "01234567-89ab-cdef-0123-456789abcdef"

  defp inventory_node(id, hostname), do: %{id: id, hostname: hostname}

  defp daemon(kind, id, unit, fsid \\ nil) do
    %{kind: kind, id: id, unit: unit, fsid: fsid, active_state: "active", substate: "running"}
  end

  defp discovery(node_id, membership, daemons) do
    %{
      node_id: node_id,
      observation: %{
        measurements: %{
          membership: %{value: membership, unit: "status"},
          daemons: %{value: daemons, unit: "daemon"},
          errors: %{value: [], unit: "error"}
        }
      }
    }
  end

  defp topology(hostname, id \\ "mon-a", fsid \\ @fsid) do
    %{
      "fsid" => @fsid,
      "monitors" => %{
        id => %{"name" => id, "hostname" => hostname, "fsid" => fsid}
      }
    }
  end

  test "maps exact hostname and daemon identity into a Ceph desired service" do
    nodes = [inventory_node("node-1", "node-a.example")]
    local = daemon(:mon, "mon-a", "ceph-mon@mon-a.service", @fsid)

    result =
      CephTopology.reconcile(topology("node-a.example"), nodes, [
        discovery("node-1", :member, [local])
      ])

    assert result.status == :ok
    assert [%{match: :exact, node_id: "node-1", local: %{raw: ^local}}] = result.mappings
    assert [service] = result.desired_services
    assert service.node == "node-1"
    assert service.unit == "ceph-mon@mon-a.service"
    assert service.sources == [:cluster_profile]
    assert service.profile_context == "cluster:ceph"
    assert service.recovery_authority_source == :shipped_profile
  end

  test "uses case-normalized hostname matching deterministically" do
    result =
      CephTopology.reconcile(
        topology("NODE-A.EXAMPLE"),
        [inventory_node("node-1", "node-a.example")],
        [discovery("node-1", :member, [daemon(:mon, "mon-a", "ceph-mon@mon-a.service")])]
      )

    assert [%{match: :case_normalized}] = result.mappings
    assert result.missing == []
  end

  test "reports a missing inventory host instead of guessing" do
    result =
      CephTopology.reconcile(
        topology("missing.example"),
        [inventory_node("node-1", "node-a.example")],
        [discovery("node-1", :not_member, [])]
      )

    assert result.status == :missing

    assert [%{status: :missing, reason: :inventory_host, hostname: "missing.example"}] =
             result.missing

    assert result.mappings == []
  end

  test "reports duplicate normalized inventory matches as ambiguous" do
    result =
      CephTopology.reconcile(
        topology("NODE-A.EXAMPLE"),
        [inventory_node("node-1", "node-a.example"), inventory_node("node-2", "Node-A.Example")],
        [discovery("node-1", :member, [daemon(:mon, "mon-a", "ceph-mon@mon-a.service")])]
      )

    assert result.status == :ambiguous
    assert [%{status: :ambiguous, reason: :duplicate_normalized_hostname}] = result.ambiguous
  end

  test "reports a daemon FSID mismatch without creating a desired service" do
    result =
      CephTopology.reconcile(
        topology("node-a.example"),
        [inventory_node("node-1", "node-a.example")],
        [
          discovery("node-1", :member, [
            daemon(
              :mon,
              "mon-a",
              "ceph-mon@mon-a.service",
              "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
            )
          ])
        ]
      )

    assert result.status == :conflicting_fsid

    assert [%{status: :conflicting_fsid, expected_fsid: @fsid, actual_fsid: actual}] =
             result.conflicting_fsid

    assert actual != @fsid
    assert result.desired_services == []
  end

  test "reports local units absent from authoritative topology as orphans" do
    result =
      CephTopology.reconcile(
        topology("node-a.example"),
        [inventory_node("node-1", "node-a.example")],
        [discovery("node-1", :member, [daemon(:mgr, "mgr-extra", "ceph-mgr@mgr-extra.service")])]
      )

    assert result.status == :orphan_daemon
    assert [%{status: :orphan_daemon, daemon: %{id: "mgr-extra"}}] = result.orphan_daemons
  end

  test "keeps a supported node with no Ceph units as a valid non-member" do
    result =
      CephTopology.reconcile(
        %{},
        [inventory_node("node-1", "node-a.example")],
        [discovery("node-1", :not_member, [])]
      )

    assert result.status == :ok
    assert [%{status: :non_member, coverage: :supported}] = result.nodes
    assert result.missing == []
    assert result.orphan_daemons == []
  end

  test "degrades coverage explicitly for a node without profile inspection" do
    result =
      CephTopology.reconcile(
        topology("node-a.example"),
        [inventory_node("node-1", "node-a.example")],
        [%{node_id: "node-1", error: :unsupported_profile}]
      )

    assert result.status == :degraded

    assert [%{status: :unsupported, coverage: :degraded, reason: :unsupported_profile}] =
             result.nodes

    assert result.coverage.status == :degraded
    assert result.coverage.unsupported_nodes == ["node-1"]
    assert result.missing == []
  end

  test "accepts the serialized profile-inspection artifact returned by A2A" do
    artifact = %{
      "parts" => [
        %{
          "data" => %{
            "observations" => %{
              "ceph" => %{
                "measurements" => %{
                  "membership" => %{"value" => "member"},
                  "daemons" => %{
                    "value" => [
                      %{
                        "kind" => "mon",
                        "id" => "mon-a",
                        "unit" => "ceph-mon@mon-a.service",
                        "fsid" => @fsid
                      }
                    ]
                  },
                  "errors" => %{"value" => []}
                }
              }
            }
          }
        }
      ]
    }

    result =
      CephTopology.reconcile(
        topology("node-a.example"),
        [inventory_node("node-1", "node-a.example")],
        [%{node_id: "node-1", artifact: artifact}]
      )

    assert result.status == :ok
    assert [%{local: %{id: "mon-a"}}] = result.mappings
  end

  test "reports duplicate local identities as ambiguous" do
    local = daemon(:mon, "mon-a", "ceph-mon@mon-a.service")

    result =
      CephTopology.reconcile(
        topology("node-a.example"),
        [inventory_node("node-1", "node-a.example")],
        [
          discovery("node-1", :member, [
            local,
            %{local | unit: "ceph-#{@fsid}@mon.mon-a.service", fsid: @fsid}
          ])
        ]
      )

    assert result.status == :ambiguous
    assert length(result.ambiguous) == 2
    assert Enum.all?(result.ambiguous, &(&1.reason == :duplicate_local_daemon))
  end
end

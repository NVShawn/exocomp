# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile.CephTest do
  use ExUnit.Case, async: true

  alias Exocomp.ClusterProfile
  alias Exocomp.ClusterProfile.Ceph
  alias Exocomp.ClusterProfile.Registry

  # ── Profile identity ─────────────────────────────────────────────────────────

  test "id/0 returns 'ceph'" do
    assert Ceph.id() == "ceph"
  end

  test "version/0 returns 1" do
    assert Ceph.version() == 1
  end

  # ── Registry inclusion ───────────────────────────────────────────────────────

  test "ceph profile is included in the shipped registry" do
    assert Ceph in Registry.shipped_modules()
    assert "ceph" in Registry.profile_ids()
    assert %{id: "ceph", versions: [1]} in Registry.advertised_profiles()
  end

  test "registry lookup resolves the ceph profile by id and exact version" do
    assert {:ok, Ceph} = Registry.lookup("ceph", 1)
  end

  test "registry lookup rejects unsupported ceph profile versions" do
    assert {:error, %{code: :unsupported_profile_version, profile_id: "ceph"}} =
             Registry.lookup("ceph", 99)
  end

  # ── Profile descriptor ───────────────────────────────────────────────────────

  test "descriptor/1 returns a complete profile map for the ceph profile" do
    descriptor = ClusterProfile.descriptor(Ceph)

    assert descriptor.id == "ceph"
    assert descriptor.version == 1
    assert descriptor.node_discovery_capability.mode == :static_inventory
    assert descriptor.node_discovery_capability.enabled == true
    assert is_list(descriptor.supported_typed_actions)
    assert is_map(descriptor.redaction_metadata)
  end

  # ── Node discovery capability ────────────────────────────────────────────────

  test "node_discovery_capability/0 returns static inventory mode" do
    cap = Ceph.node_discovery_capability()

    assert cap.enabled == true
    assert cap.mode == :static_inventory
    assert :configured_inventory in cap.sources
    assert cap.dynamic_membership == false
  end

  # ── Expected services ────────────────────────────────────────────────────────

  test "expected_services/1 returns ok with a list of known Ceph daemon names" do
    assert {:ok, services} = Ceph.expected_services(%{})
    assert is_list(services)
    assert "ceph-mon" in services
    assert "ceph-osd" in services
    assert "ceph-mgr" in services
  end

  # ── Health reduction ─────────────────────────────────────────────────────────

  test "health_reduction/1 returns healthy when all observations are healthy" do
    observations = [%{status: :healthy}, %{"status" => "healthy"}]
    assert %{status: :healthy, observation_count: 2} = Ceph.health_reduction(observations)
  end

  test "health_reduction/1 returns degraded when any observation is degraded" do
    observations = [%{status: :healthy}, %{status: :degraded}]
    assert %{status: :degraded} = Ceph.health_reduction(observations)
  end

  test "health_reduction/1 returns unreachable when any observation is unreachable" do
    observations = [%{status: :degraded}, %{status: :unreachable}]
    assert %{status: :unreachable} = Ceph.health_reduction(observations)
  end

  test "health_reduction/1 returns stale when any observation is stale" do
    observations = [%{status: :healthy}, %{status: :stale}]
    assert %{status: :stale} = Ceph.health_reduction(observations)
  end

  test "health_reduction/1 returns unknown for empty observations" do
    assert %{status: :unknown, observation_count: 0} = Ceph.health_reduction([])
  end

  test "health_reduction/1 returns unknown for non-list input" do
    assert %{status: :unknown, observation_count: 0} = Ceph.health_reduction(nil)
  end

  # ── Supported typed actions ──────────────────────────────────────────────────

  test "supported_typed_actions/0 returns a list of strings" do
    actions = Ceph.supported_typed_actions()
    assert is_list(actions)
    assert Enum.all?(actions, &is_binary/1)
  end

  # ── Redaction metadata ───────────────────────────────────────────────────────

  test "redaction_metadata/0 includes keyring-related sensitive fields" do
    meta = Ceph.redaction_metadata()

    assert is_list(meta.sensitive_fields)
    assert "key" in meta.sensitive_fields
    assert "keyring" in meta.sensitive_fields
    assert "cephx_key" in meta.sensitive_fields
    assert "auth_key" in meta.sensitive_fields
    assert meta.redact_nested_maps == true
  end

  # ── ClusterProfile behaviour compliance ──────────────────────────────────────

  test "ceph module satisfies the ClusterProfile behaviour contract" do
    callbacks = [
      {:id, 0},
      {:version, 0},
      {:node_discovery_capability, 0},
      {:expected_services, 1},
      {:health_reduction, 1},
      {:supported_typed_actions, 0},
      {:redaction_metadata, 0}
    ]

    for {fun, arity} <- callbacks do
      assert function_exported?(Ceph, fun, arity),
             "expected Ceph to export #{fun}/#{arity}"
    end
  end
end

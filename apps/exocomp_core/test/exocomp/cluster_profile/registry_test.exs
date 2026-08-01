# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile.RegistryTest do
  use ExUnit.Case, async: true

  alias Exocomp.ClusterProfile.CoverageError
  alias Exocomp.ClusterProfile.Registry

  defmodule DuplicateProfile do
    @behaviour Exocomp.ClusterProfile

    def id, do: "default"
    def version, do: 2
    def node_discovery_capability, do: %{}
    def expected_services(_context), do: {:ok, []}
    def health_reduction(observations), do: observations
    def supported_typed_actions, do: []
    def redaction_metadata, do: %{}
  end

  test "the release registry exposes the shipped default profile contract" do
    assert Exocomp.ClusterProfile.Default in Registry.shipped_modules()
    assert "default" in Registry.profile_ids()
    assert %{id: "default", versions: [1]} in Registry.advertised_profiles()

    assert {:ok, profile} = Registry.lookup("default", 1)
    assert profile.id() == "default"
    assert profile.version() == 1
    assert profile.node_discovery_capability().mode == :static_inventory
    assert {:ok, []} = profile.expected_services(%{})
    assert profile.health_reduction([%{status: :healthy}]).status == :healthy
    assert "restart_service" in profile.supported_typed_actions()
    assert profile.redaction_metadata().redact_nested_maps
  end

  test "the release registry includes the ceph profile" do
    assert Exocomp.ClusterProfile.Ceph in Registry.shipped_modules()
    assert "ceph" in Registry.profile_ids()
    assert %{id: "ceph", versions: [1]} in Registry.advertised_profiles()
  end

  test "duplicate profile IDs are rejected by static registry validation" do
    assert {:error, %CoverageError{code: :duplicate_profile_id, profile_id: "default"}} =
             Registry.validate_profiles([Exocomp.ClusterProfile.Default, DuplicateProfile])
  end

  test "unknown profile IDs return structured coverage errors" do
    assert {:error,
            %CoverageError{
              code: :unknown_profile,
              profile_id: "unknown-profile-id",
              requested_version: 1,
              supported_versions: []
            }} = Registry.lookup("unknown-profile-id", 1)
  end

  test "known profiles with unsupported versions return structured coverage errors" do
    assert {:error,
            %CoverageError{
              code: :unsupported_profile_version,
              profile_id: "default",
              requested_version: 99,
              supported_versions: [1]
            }} = Registry.lookup("default", 99)
  end

  test "local files and caller-supplied commands cannot register profiles" do
    for attempt <- [
          Registry.register(%{id: "local", version: 1}),
          Registry.register_from_file("/tmp/profile.exs"),
          Registry.register_from_command("profile-discovery --json")
        ] do
      assert {:error, %CoverageError{code: :non_shipped_profile}} = attempt
    end
  end

  test "the default profile reduces the most severe observed health state" do
    profile = Exocomp.ClusterProfile.Default

    assert %{status: :degraded} =
             profile.health_reduction([%{"status" => "healthy"}, %{status: :degraded}])

    assert %{status: :unreachable} =
             profile.health_reduction([%{status: :degraded}, %{status: :unreachable}])
  end
end

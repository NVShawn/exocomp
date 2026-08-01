# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ProfileCoverageTest do
  use ExUnit.Case, async: true

  alias Exocomp.ClusterProfile.CoverageError
  alias Exocomp.Coordinator.ProfileCoverage

  setup do
    name = :"profile_coverage_test_#{System.unique_integer([:positive])}"
    start_supervised!({ProfileCoverage, name: name})
    %{name: name}
  end

  test "degraded profiles are removed from advertisement and lookup", %{name: name} do
    assert :available == ProfileCoverage.status("ceph", name)
    assert :ok = ProfileCoverage.mark_degraded("ceph", %{reason: :unsafe_keyring}, name)
    assert :degraded == ProfileCoverage.status("ceph", name)
    refute Enum.any?(ProfileCoverage.advertised_profiles(name), &(&1.id == "ceph"))

    assert {:error, %CoverageError{code: :profile_unavailable, profile_id: "ceph"}} =
             ProfileCoverage.lookup("ceph", 1, name)
  end

  test "available profiles remain advertised and resolvable", %{name: name} do
    assert Enum.any?(ProfileCoverage.advertised_profiles(name), &(&1.id == "ceph"))
    assert {:ok, Exocomp.ClusterProfile.Ceph} = ProfileCoverage.lookup("ceph", 1, name)
  end
end

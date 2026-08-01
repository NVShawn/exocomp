# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.ProfileInspectTest do
  use ExUnit.Case, async: false

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Node.Skills.ProfileInspect

  setup do
    Application.put_env(:exocomp_node, :profile_inspect_ceph_collector, fn ->
      %{
        observed_at: "2026-08-01T00:00:00Z",
        source: Exocomp.Node.Collectors.Ceph,
        collector_version: 1,
        duration_us: 5,
        measurements: %{
          membership: %{value: :member, unit: "status"},
          daemons: %{
            value: [
              %{
                kind: :mon,
                id: "node-a",
                unit: "ceph-mon@node-a.service",
                fsid: nil,
                enablement: "enabled",
                load_state: "loaded",
                active_state: "active",
                substate: "running"
              }
            ],
            unit: "daemon"
          },
          errors: %{value: [], unit: "error"}
        }
      }
    end)

    on_exit(fn -> Application.delete_env(:exocomp_node, :profile_inspect_ceph_collector) end)
    :ok
  end

  test "returns a versioned artifact with the Ceph daemon fields" do
    assert {:ok, %Artifact{name: "profile-inspect", parts: [%DataPart{data: data}]}} =
             ProfileInspect.execute(%{"profile" => "ceph", "version" => 1}, %{})

    assert data["skill"] == "exocomp.profile.inspect"
    assert data["profile_id"] == "ceph"
    assert data["profile_version"] == 1

    profile = data["observations"]["ceph"]
    assert profile["measurements"]["membership"]["value"] == "member"

    assert [daemon] = profile["measurements"]["daemons"]["value"]
    assert daemon["kind"] == "mon"
    assert daemon["unit"] == "ceph-mon@node-a.service"
    assert daemon["fsid"] == nil
    assert daemon["substate"] == "running"
  end

  test "omitted profile selector selects the only shipped branch" do
    assert {:ok, %Artifact{}} = ProfileInspect.execute(%{}, %{})
  end

  test "rejects unsupported profiles, versions, and unknown parameters" do
    assert {:error, :unsupported_profile} =
             ProfileInspect.execute(%{"profile" => "default"}, %{})

    assert {:error, :unsupported_profile_version} =
             ProfileInspect.execute(%{"profile" => "ceph", "version" => 2}, %{})

    assert {:error, :invalid_params} =
             ProfileInspect.execute(%{"profile" => "ceph", "command" => "systemctl"}, %{})
  end

  test "conflicting profile selectors and versions fail closed" do
    assert {:error, :unsupported_profile} =
             ProfileInspect.execute(%{"profile" => "ceph", "profile_id" => "default"}, %{})

    assert {:error, :unsupported_profile_version} =
             ProfileInspect.execute(%{"version" => 1, "profile_version" => 2}, %{})
  end
end

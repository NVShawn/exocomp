# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.StartupProfileValidationTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.{Audit, Listener, ProfileCoverage}

  defmodule MessageSink do
    @behaviour Exocomp.Coordinator.Audit.Sink

    @impl true
    def init(opts), do: {:ok, Keyword.fetch!(opts, :owner)}

    @impl true
    def write(owner, event) do
      send(owner, {:audit_event, event})
      {:ok, owner}
    end

    @impl true
    def close(_owner), do: :ok
  end

  @base_config %{
    "version" => 1,
    "coordinator_id" => "coord-test",
    "tls" => %{
      "ca_cert" => "/tmp/ca.crt",
      "coord_cert" => "/tmp/coordinator.crt",
      "coord_key" => "/tmp/coordinator.key"
    },
    "listen" => %{"host" => "127.0.0.1", "port" => 0},
    "cluster_profiles" => %{
      "ceph" => %{
        "version" => 1,
        "ceph_binary_path" => "/usr/bin/ceph",
        "ceph_conf_path" => "/etc/ceph/ceph.conf",
        "keyring_path" => "/etc/ceph/ceph.client.exocomp.keyring"
      }
    }
  }

  @tag :tmp_dir
  test "unsafe keyring mode degrades coverage but keeps listener running", %{tmp_dir: tmp_dir} do
    assert_degraded_startup(
      tmp_dir,
      fn path ->
        if String.ends_with?(path, "keyring") do
          {:ok, stat(0o100644, 1000)}
        else
          {:ok, stat(0o100755, 1000)}
        end
      end,
      "keyring_unsafe_permissions"
    )
  end

  @tag :tmp_dir
  test "missing Ceph binary degrades coverage but keeps listener running", %{tmp_dir: tmp_dir} do
    assert_degraded_startup(
      tmp_dir,
      fn path ->
        if path == "/usr/bin/ceph" do
          {:error, :enoent}
        else
          {:ok, stat(0o100644, 1000)}
        end
      end,
      "file_missing"
    )
  end

  @tag :tmp_dir
  test "root-owned Ceph files degrade coverage but keep listener running", %{tmp_dir: tmp_dir} do
    assert_degraded_startup(
      tmp_dir,
      fn _path -> {:ok, stat(0o100755, 0)} end,
      "root_owned"
    )
  end

  defp assert_degraded_startup(tmp_dir, stat_fn, expected_code) do
    audit_name = unique_name("audit")
    coverage_name = unique_name("coverage")
    listener_name = unique_name("listener")
    config_path = Path.join(tmp_dir, "coordinator.json")
    File.write!(config_path, Jason.encode!(@base_config))

    start_supervised!({Audit, name: audit_name, sink: {MessageSink, owner: self()}})
    start_supervised!({ProfileCoverage, name: coverage_name})

    listener =
      start_supervised!(
        {Listener,
         name: listener_name,
         config_path: config_path,
         audit_server: audit_name,
         profile_coverage: coverage_name,
         ceph_stat_fn: stat_fn,
         bandit_start_fn: fn _config -> {:ok, self()} end}
      )

    assert Process.alive?(listener)
    assert :degraded == ProfileCoverage.status("ceph", coverage_name)
    refute Enum.any?(ProfileCoverage.advertised_profiles(coverage_name), &(&1.id == "ceph"))

    assert_receive {:audit_event, event}, 1_000
    assert event["event_type"] == "ceph_profile_validation_failed"
    assert event["attributes"]["coverage"] == "degraded"
    assert is_list(event["attributes"]["failures"])
    assert expected_code in Enum.map(event["attributes"]["failures"], & &1["code"])
    refute inspect(event) =~ "SUPER_SECRET"
  end

  defp stat(mode, uid) do
    %File.Stat{mode: mode, uid: uid, type: :regular}
  end

  defp unique_name(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"
end

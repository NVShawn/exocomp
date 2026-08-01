# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.SupervisorTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.Config
  alias Exocomp.Coordinator.MissionControl.{Supervisor, Outbox, Connection}

  @fixtures_dir Path.expand("../../../../../fixtures", __DIR__)

  setup do
    File.mkdir_p!(@fixtures_dir)
    :ok
  end

  # ---------------------------------------------------------------------------
  # Test: mission_control_children returns empty list when config is nil
  # ---------------------------------------------------------------------------

  test "mission_control_children returns empty list when config is nil" do
    old_value = Application.get_env(:exocomp_coordinator, :mission_control_config)
    Application.put_env(:exocomp_coordinator, :mission_control_config, nil)

    try do
      children = Exocomp.Coordinator.Application.mission_control_children_for_test()
      assert children == []
    after
      if old_value != nil do
        Application.put_env(:exocomp_coordinator, :mission_control_config, old_value)
      else
        Application.delete_env(:exocomp_coordinator, :mission_control_config)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Test: mission_control_children returns empty list when config is disabled
  # ---------------------------------------------------------------------------

  test "mission_control_children returns empty list when config is disabled" do
    old_value = Application.get_env(:exocomp_coordinator, :mission_control_config)

    disabled_config = %Config.MissionControl{
      enabled: false,
      url: nil,
      trust_root: nil,
      client_cert: nil,
      client_key: nil,
      heartbeat_interval_seconds: nil,
      reconnect_min_backoff_seconds: nil,
      reconnect_max_backoff_seconds: nil,
      outbox_path: nil
    }

    Application.put_env(:exocomp_coordinator, :mission_control_config, disabled_config)

    try do
      children = Exocomp.Coordinator.Application.mission_control_children_for_test()
      assert children == []
    after
      if old_value != nil do
        Application.put_env(:exocomp_coordinator, :mission_control_config, old_value)
      else
        Application.delete_env(:exocomp_coordinator, :mission_control_config)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Test: mission_control_children returns child spec when config is enabled
  # ---------------------------------------------------------------------------

  test "mission_control_children returns child spec when config is enabled" do
    ca_cert_path = Path.join(@fixtures_dir, "mc-app-test-ca.crt")
    client_cert_path = Path.join(@fixtures_dir, "mc-app-test-client.crt")
    client_key_path = Path.join(@fixtures_dir, "mc-app-test-client.key")
    outbox_dir = Path.join(@fixtures_dir, "mc-app-test-outbox")

    File.write!(ca_cert_path, "ca cert")
    File.write!(client_cert_path, "client cert")
    File.write!(client_key_path, "client key")
    File.mkdir_p!(outbox_dir)

    old_value = Application.get_env(:exocomp_coordinator, :mission_control_config)

    enabled_config = %Config.MissionControl{
      enabled: true,
      url: "wss://mission-control.example.com:443",
      trust_root: ca_cert_path,
      client_cert: client_cert_path,
      client_key: client_key_path,
      heartbeat_interval_seconds: 30,
      reconnect_min_backoff_seconds: 1,
      reconnect_max_backoff_seconds: 60,
      outbox_path: outbox_dir
    }

    Application.put_env(:exocomp_coordinator, :mission_control_config, enabled_config)

    try do
      children = Exocomp.Coordinator.Application.mission_control_children_for_test()

      # Should have exactly 1 child spec
      assert length(children) == 1

      # Verify it's a tuple with the MissionControl.Supervisor module
      [{module, config_arg}] = children
      assert module == Exocomp.Coordinator.MissionControl.Supervisor
      assert config_arg == enabled_config
    after
      if old_value != nil do
        Application.put_env(:exocomp_coordinator, :mission_control_config, old_value)
      else
        Application.delete_env(:exocomp_coordinator, :mission_control_config)
      end

      File.rm!(ca_cert_path)
      File.rm!(client_cert_path)
      File.rm!(client_key_path)
      File.rm_rf!(outbox_dir)
    end
  end

  # ---------------------------------------------------------------------------
  # Test: Supervisor starts with enabled config and registers children
  # ---------------------------------------------------------------------------

  test "supervisor starts with enabled config and both children are alive" do
    ca_cert_path = Path.join(@fixtures_dir, "mc-supervisor-ca.crt")
    client_cert_path = Path.join(@fixtures_dir, "mc-supervisor-client.crt")
    client_key_path = Path.join(@fixtures_dir, "mc-supervisor-client.key")
    outbox_dir = Path.join(@fixtures_dir, "mc-supervisor-outbox")

    File.write!(ca_cert_path, "ca cert")
    File.write!(client_cert_path, "client cert")
    File.write!(client_key_path, "client key")
    File.mkdir_p!(outbox_dir)

    config = %Config.MissionControl{
      enabled: true,
      url: "wss://mission-control.example.com:443",
      trust_root: ca_cert_path,
      client_cert: client_cert_path,
      client_key: client_key_path,
      heartbeat_interval_seconds: 30,
      reconnect_min_backoff_seconds: 1,
      reconnect_max_backoff_seconds: 60,
      outbox_path: outbox_dir
    }

    # Start the supervisor directly with the config
    {:ok, supervisor_pid} =
      Supervisor.start_link(config, name: :test_mc_supervisor_direct)

    # Verify the supervisor is alive
    assert is_pid(supervisor_pid)
    assert Process.alive?(supervisor_pid)

    # Verify Outbox and Connection are alive
    children = :supervisor.which_children(supervisor_pid)
    assert length(children) == 2

    # Extract child modules
    child_modules = Enum.map(children, fn {_id, pid, :worker, modules} -> {modules, pid} end)

    # Verify both Outbox and Connection are present and alive
    outbox_found =
      Enum.any?(child_modules, fn {modules, pid} ->
        modules == [Outbox] and is_pid(pid) and Process.alive?(pid)
      end)

    connection_found =
      Enum.any?(child_modules, fn {modules, pid} ->
        modules == [Connection] and is_pid(pid) and Process.alive?(pid)
      end)

    assert outbox_found, "Outbox child not found or not alive"
    assert connection_found, "Connection child not found or not alive"

    # Clean up
    GenServer.stop(supervisor_pid)
    File.rm!(ca_cert_path)
    File.rm!(client_cert_path)
    File.rm!(client_key_path)
    File.rm_rf!(outbox_dir)
  end
end

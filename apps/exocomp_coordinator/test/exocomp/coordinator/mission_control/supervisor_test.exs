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
  # Supervision tree starts with Mission Control configuration
  # ---------------------------------------------------------------------------

  test "supervisor starts when given valid Mission Control config" do
    ca_cert_path = Path.join(@fixtures_dir, "mc-test-ca.crt")
    client_cert_path = Path.join(@fixtures_dir, "mc-test-client.crt")
    client_key_path = Path.join(@fixtures_dir, "mc-test-client.key")
    outbox_dir = Path.join(@fixtures_dir, "mc-test-outbox")

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

    assert {:ok, supervisor_pid} =
             Exocomp.Coordinator.MissionControl.Supervisor.start_link(config,
               name: :test_mc_supervisor
             )

    assert is_pid(supervisor_pid)
    assert Process.alive?(supervisor_pid)

    # Clean up
    GenServer.stop(supervisor_pid)
    File.rm!(ca_cert_path)
    File.rm!(client_cert_path)
    File.rm!(client_key_path)
    File.rm_rf!(outbox_dir)
  end

  # ---------------------------------------------------------------------------
  # Supervision tree includes required children
  # ---------------------------------------------------------------------------

  test "supervisor starts Outbox and Connection children" do
    ca_cert_path = Path.join(@fixtures_dir, "mc-children-ca.crt")
    client_cert_path = Path.join(@fixtures_dir, "mc-children-client.crt")
    client_key_path = Path.join(@fixtures_dir, "mc-children-client.key")
    outbox_dir = Path.join(@fixtures_dir, "mc-children-outbox")

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

    {:ok, supervisor_pid} =
      Exocomp.Coordinator.MissionControl.Supervisor.start_link(config,
        name: :test_mc_supervisor_children
      )

    # Check that children are running
    children = :supervisor.which_children(supervisor_pid)

    # Should have exactly 2 children: Outbox and Connection
    assert length(children) == 2

    # Verify child module names exist
    child_modules = Enum.map(children, fn {_id, _pid, :worker, modules} -> modules end)
    assert Enum.any?(child_modules, &(&1 == [Outbox]))
    assert Enum.any?(child_modules, &(&1 == [Connection]))

    # Clean up
    GenServer.stop(supervisor_pid)
    File.rm!(ca_cert_path)
    File.rm!(client_cert_path)
    File.rm!(client_key_path)
    File.rm_rf!(outbox_dir)
  end

  # ---------------------------------------------------------------------------
  # Application integration: Mission Control only starts when enabled
  # ---------------------------------------------------------------------------

  test "mission_control_children returns empty list when config is nil" do
    # Set mission_control_config to nil
    old_value = Application.get_env(:exocomp_coordinator, :mission_control_config)
    Application.put_env(:exocomp_coordinator, :mission_control_config, nil)

    try do
      children = Exocomp.Coordinator.Application.mission_control_children_for_test()
      assert children == []
    after
      # Restore original value
      if old_value != nil do
        Application.put_env(:exocomp_coordinator, :mission_control_config, old_value)
      else
        Application.delete_env(:exocomp_coordinator, :mission_control_config)
      end
    end
  end

  test "mission_control_children returns empty list when config is disabled" do
    # Set mission_control_config to a disabled config
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
      # Restore original value
      if old_value != nil do
        Application.put_env(:exocomp_coordinator, :mission_control_config, old_value)
      else
        Application.delete_env(:exocomp_coordinator, :mission_control_config)
      end
    end
  end

  test "mission_control_children returns MissionControl.Supervisor child spec when config is enabled" do
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

      # Verify it's the MissionControl.Supervisor child spec
      [{module, _args} | _rest] = children
      assert module == Exocomp.Coordinator.MissionControl.Supervisor
    after
      # Restore original value
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
end

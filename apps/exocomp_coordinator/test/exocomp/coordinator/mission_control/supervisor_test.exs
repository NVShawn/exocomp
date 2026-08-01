# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.SupervisorTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.Config
  alias Exocomp.Coordinator.MissionControl.{Supervisor, Outbox, Connection}

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
    {enabled_config, _tmp_dir} = test_config()

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
  # Test: Application-emitted child spec starts with enabled config
  # ---------------------------------------------------------------------------

  test "Application child spec starts Outbox and Connection under MissionControlSupervisor" do
    {enabled_config, _tmp_dir} = test_config()
    old_value = Application.get_env(:exocomp_coordinator, :mission_control_config)
    Application.put_env(:exocomp_coordinator, :mission_control_config, enabled_config)

    on_exit(fn -> restore_app_env(:mission_control_config, old_value) end)

    children = Exocomp.Coordinator.Application.mission_control_children_for_test()
    assert [{Supervisor, ^enabled_config}] = children

    {:ok, root_pid} =
      Elixir.Supervisor.start_link(children, strategy: :one_for_one, name: :test_root)

    on_exit(fn -> if Process.alive?(root_pid), do: GenServer.stop(root_pid) end)

    mission_control_pid = Process.whereis(Exocomp.Coordinator.MissionControlSupervisor)
    assert is_pid(mission_control_pid)
    assert Process.alive?(mission_control_pid)

    assert is_pid(Process.whereis(Outbox))
    assert Process.alive?(Process.whereis(Outbox))
    assert is_pid(Process.whereis(Connection))
    assert Process.alive?(Process.whereis(Connection))

    assert :sys.get_state(Process.whereis(Outbox)).config == enabled_config
    assert :sys.get_state(Process.whereis(Connection)).config == enabled_config
  end

  test "Application child spec passes the config struct through to both child init callbacks" do
    {enabled_config, _tmp_dir} = test_config()
    old_value = Application.get_env(:exocomp_coordinator, :mission_control_config)
    Application.put_env(:exocomp_coordinator, :mission_control_config, enabled_config)

    on_exit(fn -> restore_app_env(:mission_control_config, old_value) end)

    children = Exocomp.Coordinator.Application.mission_control_children_for_test()
    assert [{Supervisor, ^enabled_config}] = children

    {:ok, root_pid} =
      Elixir.Supervisor.start_link(
        children,
        strategy: :one_for_one,
        name: :test_root_struct
      )

    on_exit(fn -> if Process.alive?(root_pid), do: GenServer.stop(root_pid) end)

    assert %{config: ^enabled_config} = :sys.get_state(Process.whereis(Outbox))
    assert %{config: ^enabled_config} = :sys.get_state(Process.whereis(Connection))
  end

  defp test_config do
    tmp_dir =
      Path.join(System.tmp_dir!(), "exocomp-mc-supervisor-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)
    ca_cert_path = Path.join(tmp_dir, "ca.crt")
    client_cert_path = Path.join(tmp_dir, "client.crt")
    client_key_path = Path.join(tmp_dir, "client.key")
    outbox_dir = Path.join(tmp_dir, "outbox")

    File.write!(ca_cert_path, "ca cert")
    File.write!(client_cert_path, "client cert")
    File.write!(client_key_path, "client key")
    File.mkdir_p!(outbox_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

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

    {config, tmp_dir}
  end

  defp restore_app_env(key, nil), do: Application.delete_env(:exocomp_coordinator, key)

  defp restore_app_env(key, value),
    do: Application.put_env(:exocomp_coordinator, key, value)
end

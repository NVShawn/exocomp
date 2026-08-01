# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ApplicationTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.Config

  test "starts the coordinator supervision tree in test mode" do
    assert Mix.env() == :test
    assert {:ok, _applications} = Application.ensure_all_started(:exocomp_coordinator)
    assert is_pid(Process.whereis(Exocomp.Coordinator.Supervisor))
    assert is_pid(Process.whereis(Exocomp.Coordinator.PollTaskSupervisor))
    assert is_pid(Process.whereis(Exocomp.Coordinator.HealthPoller))
    assert is_pid(Process.whereis(Exocomp.Coordinator.CommandProcessor))
  end

  # ---------------------------------------------------------------------------
  # Acceptance: Local services function when Mission Control is absent/disabled
  # ---------------------------------------------------------------------------

  test "inventory, diagnostics, and recovery operate without Mission Control enabled" do
    # Verify that Mission Control is not enabled in test environment
    mission_control_config = Application.get_env(:exocomp_coordinator, :mission_control_config)

    # Should be either nil or disabled
    is_not_enabled? =
      mission_control_config == nil or
        (is_map(mission_control_config) and Map.get(mission_control_config, :enabled) != true)

    assert is_not_enabled?,
           "Test requires Mission Control to be absent or disabled in test environment"

    # Verify that the application is running
    assert {:ok, _apps} = Application.ensure_all_started(:exocomp_coordinator)

    # Verify core services are running and operational
    assert is_pid(Process.whereis(Exocomp.Coordinator.Supervisor)),
           "Coordinator supervisor should be running"

    assert is_pid(Process.whereis(Exocomp.Coordinator.Inventory)),
           "Inventory should be running (local state management)"

    assert is_pid(Process.whereis(Exocomp.Coordinator.HealthPoller)),
           "HealthPoller should be running (diagnostics)"

    assert is_pid(Process.whereis(Exocomp.Coordinator.Orchestrator)),
           "Orchestrator should be running (remediation/recovery)"

    assert is_pid(Process.whereis(Exocomp.Coordinator.RemediationLifecycle)),
           "RemediationLifecycle should be running (recovery)"

    # Verify that Mission Control supervisor is NOT running
    mission_control_sup = Process.whereis(Exocomp.Coordinator.MissionControlSupervisor)

    assert is_nil(mission_control_sup),
           "Mission Control supervisor should not be running when disabled"
  end

  test "starts one Mission Control supervisor in the coordinator application tree" do
    stop_coordinator_application()

    old_value = Application.get_env(:exocomp_coordinator, :mission_control_config)
    {mission_control_config, tmp_dir} = mission_control_config()

    Application.put_env(
      :exocomp_coordinator,
      :mission_control_config,
      mission_control_config
    )

    on_exit(fn ->
      stop_coordinator_application()
      restore_app_env(:mission_control_config, old_value)
      File.rm_rf!(tmp_dir)
    end)

    assert {:ok, _application_pid} = Application.start(:exocomp_coordinator, :temporary)

    coordinator_supervisor = Process.whereis(Exocomp.Coordinator.Supervisor)
    assert is_pid(coordinator_supervisor)

    mission_control_children =
      Supervisor.which_children(coordinator_supervisor)
      |> Enum.filter(fn {id, _pid, _type, _modules} ->
        id == Exocomp.Coordinator.MissionControl.Supervisor
      end)

    assert [{Exocomp.Coordinator.MissionControl.Supervisor, mission_control_pid, :supervisor, _}] =
             mission_control_children

    assert is_pid(mission_control_pid)
    assert Process.alive?(mission_control_pid)
  end

  defp mission_control_config do
    tmp_dir =
      Path.join(System.tmp_dir!(), "exocomp-mc-application-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)
    ca_cert_path = Path.join(tmp_dir, "ca.crt")
    client_cert_path = Path.join(tmp_dir, "client.crt")
    client_key_path = Path.join(tmp_dir, "client.key")
    outbox_dir = Path.join(tmp_dir, "outbox")

    File.write!(ca_cert_path, "mock ca cert")
    File.write!(client_cert_path, "mock client cert")
    File.write!(client_key_path, "mock client key")
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

    {config, tmp_dir}
  end

  defp stop_coordinator_application do
    if Enum.any?(Application.started_applications(), fn {app, _description, _version} ->
         app == :exocomp_coordinator
       end) do
      :ok = Application.stop(:exocomp_coordinator)
    end

    :ok
  end

  defp restore_app_env(key, nil), do: Application.delete_env(:exocomp_coordinator, key)

  defp restore_app_env(key, value),
    do: Application.put_env(:exocomp_coordinator, key, value)
end

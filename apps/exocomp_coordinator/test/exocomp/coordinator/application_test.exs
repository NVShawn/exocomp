# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ApplicationTest do
  use ExUnit.Case, async: true

  test "starts the coordinator supervision tree in test mode" do
    assert Mix.env() == :test
    assert {:ok, _applications} = Application.ensure_all_started(:exocomp_coordinator)
    assert is_pid(Process.whereis(Exocomp.Coordinator.Supervisor))
    assert is_pid(Process.whereis(Exocomp.Coordinator.PollTaskSupervisor))
    assert is_pid(Process.whereis(Exocomp.Coordinator.HealthPoller))
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
end

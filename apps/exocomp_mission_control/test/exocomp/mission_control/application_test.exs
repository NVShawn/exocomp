# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ApplicationTest do
  use ExUnit.Case, async: true

  test "starts the Mission Control supervision tree in test mode" do
    assert Mix.env() == :test
    assert {:ok, _applications} = Application.ensure_all_started(:exocomp_mission_control)
    assert is_pid(Process.whereis(Exocomp.MissionControl.Supervisor))
    assert is_pid(Process.whereis(Exocomp.MissionControl.PubSub))
  end

  test "does not depend on node or coordinator startup" do
    applications = Application.spec(:exocomp_mission_control, :applications)

    refute :exocomp_node in applications
    refute :exocomp_coordinator in applications
  end

  test "supervises the repository" do
    assert Exocomp.MissionControl.Repo in Exocomp.MissionControl.Application.children()
  end
end

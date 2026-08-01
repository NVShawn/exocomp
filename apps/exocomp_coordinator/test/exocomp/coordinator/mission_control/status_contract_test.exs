# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.StatusContractTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.MissionControl.{StatusEvent, StatusReducer}

  @fixture_dir Path.expand("../../../../../../test/fixtures/mission_control", __DIR__)

  test "coordinator facade consumes the shared profile fixture" do
    raw = fixture("profile_coverage.json")
    assert {:ok, event} = StatusEvent.decode(raw)
    assert event.payload["source_set"] == ["cluster_profile"]
    assert event.payload["profile_context"] == "production-v1"
    assert event.payload["recovery_authority"] == "shipped_profile"
  end

  test "coordinator facade shares replay behavior with the core contract" do
    events = [fixture("service_summary_snapshot.json"), fixture("service_status_changed.json")]
    assert {:ok, state} = StatusReducer.apply_all(StatusReducer.new(), events)
    assert StatusReducer.current(state)[{"node-a", "api.service"}]["health_state"] == "unhealthy"
  end

  defp fixture(name), do: @fixture_dir |> Path.join(name) |> File.read!() |> Jason.decode!()
end

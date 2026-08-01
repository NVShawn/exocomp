# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.StatusReducerTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{StatusEvent, StatusReducer}

  @fixture_dir Path.expand("../../../../../test/fixtures/mission_control", __DIR__)

  test "snapshot plus deltas reconstructs current view" do
    events = [
      fixture("service_summary_snapshot.json"),
      fixture("desired_state_added.json"),
      fixture("service_status_changed.json")
    ]

    assert {:ok, state} = StatusReducer.apply_all(StatusReducer.new(), events)
    assert state.current[{"node-a", "api.service"}]["health_state"] == "unhealthy"
    assert state.current[{"node-a", "api.service"}]["source_set"] == ["automatic"]
    assert state.current[{"node-a", "worker.service"}]["desired_state"] == "running"
  end

  test "duplicate event delivery is idempotent" do
    raw = fixture("duplicate_delivery.json")
    [first, duplicate] = raw["events"]
    state = StatusReducer.new()
    assert {:ok, state, :applied} = StatusReducer.apply_event(state, first)
    assert {:ok, state, :duplicate} = StatusReducer.apply_event(state, duplicate)
    assert StatusReducer.size(state) == 1
    assert StatusReducer.current(state) == %{}
  end

  test "duplicate IDs with different content and reused sequences fail closed" do
    raw = fixture("desired_state_added.json")
    assert {:ok, event} = StatusEvent.decode(raw)
    changed = Map.put(raw, "payload", Map.put(raw["payload"], "desired_state", "stopped"))
    assert {:ok, other} = StatusEvent.decode(changed)

    assert {:ok, state} = StatusReducer.apply(StatusReducer.new(), event)
    assert {:error, :event_id_conflict} = StatusReducer.apply(state, other)

    sequence_conflict =
      Map.put(fixture("service_status_changed.json"), "cluster_seq", raw["cluster_seq"])

    assert {:error, :sequence_conflict} = StatusReducer.apply(state, sequence_conflict)
  end

  test "out-of-order delivery has the same view as ordered delivery" do
    raw = fixture("out_of_order_delivery.json")
    out_of_order = raw["events"]
    ordered = Enum.sort_by(out_of_order, & &1["cluster_seq"])

    assert {:ok, reverse_state} = StatusReducer.apply_all(StatusReducer.new(), out_of_order)
    assert {:ok, ordered_state} = StatusReducer.apply_all(StatusReducer.new(), ordered)
    assert StatusReducer.current(reverse_state) == StatusReducer.current(ordered_state)

    assert StatusReducer.current(reverse_state)[{"node-a", "api.service"}]["health_state"] ==
             "healthy"
  end

  defp fixture(name), do: @fixture_dir |> Path.join(name) |> File.read!() |> Jason.decode!()
end

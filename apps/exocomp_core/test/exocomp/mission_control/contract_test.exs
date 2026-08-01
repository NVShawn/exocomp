# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
Code.require_file(
  Path.expand("../../../../../test/fixtures/mission_control/contract_fixtures.exs", __DIR__)
)

defmodule Exocomp.MissionControl.ContractTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{StatusEvent, StatusReducer}
  alias Exocomp.MissionControl.ContractFixtures, as: Fixtures

  test "the shared status fixtures round-trip through the shared decoder" do
    manifest = Fixtures.manifest()
    envelope = manifest["envelopes"]["event"]

    for {name, raw} <- Enum.zip(manifest["status_event_fixtures"], Fixtures.status_fixtures()) do
      values = if is_list(raw["events"]), do: raw["events"], else: [raw]

      for {value, index} <- Enum.with_index(values) do
        label = "#{name}[#{index}]"
        Fixtures.assert_shape!(value, envelope["allowed_fields"], label)
        Fixtures.assert_required_fields!(value, envelope["required_fields"], label)
        assert {:ok, event} = StatusEvent.decode(value), label
        assert {:ok, encoded} = StatusEvent.encode_json(event), label
        assert {:ok, ^event} = StatusEvent.decode_json(encoded), label
      end
    end
  end

  test "mutating every status envelope field returns a field-level error" do
    raw = Fixtures.fixture!("desired_state_added.json")

    for field <- Fixtures.manifest()["envelopes"]["event"]["required_fields"] do
      mutated = Map.delete(raw, field)
      assert {:error, {:missing_field, ^field}} = StatusEvent.decode(mutated), field
    end

    assert {:error, {:unsupported_schema_version, 2}} =
             StatusEvent.decode(Map.put(raw, "schema_version", 2))

    assert {:error, {:unknown_field, "unexpected"}} =
             StatusEvent.decode(Map.put(raw, "unexpected", true))
  end

  test "status bounds, replay ordering, sequence gaps, and redaction are shared" do
    raw = Fixtures.fixture!("service_status_changed.json")
    assert {:error, {:event_too_large, _}} = StatusEvent.decode(raw, max_event_bytes: 10)

    replay = Fixtures.fixture!("protocol_replay.json")
    duplicate = Fixtures.fixture!(replay["duplicate"]["fixture"])
    [first, second] = duplicate["events"]
    assert {:ok, state, :applied} = StatusReducer.apply_event(StatusReducer.new(), first)
    assert {:ok, state, :duplicate} = StatusReducer.apply_event(state, second)
    assert StatusReducer.size(state) == 1

    out_of_order = Fixtures.fixture!(replay["out_of_order"]["fixture"])["events"]
    ordered = Enum.sort_by(out_of_order, & &1["cluster_seq"])
    assert {:ok, reverse_state} = StatusReducer.apply_all(StatusReducer.new(), out_of_order)
    assert {:ok, ordered_state} = StatusReducer.apply_all(StatusReducer.new(), ordered)
    assert StatusReducer.current(reverse_state) == StatusReducer.current(ordered_state)

    assert replay["sequence_gap"]["observed_sequences"] == [1, 3]
    assert replay["sequence_gap"]["missing_sequences"] == [2]

    gap_events = [
      Map.put(Fixtures.fixture!("desired_state_added.json"), "cluster_seq", 1),
      Map.put(Fixtures.fixture!("service_status_changed.json"), "cluster_seq", 3)
    ]

    assert {:ok, gap_state} = StatusReducer.apply_all(StatusReducer.new(), gap_events)
    assert StatusReducer.missing_sequences(gap_state) == [2]

    redaction = Fixtures.fixture!("redaction.json")
    assert StatusEvent.redact(redaction["input"]) == redaction["expected"]
  end
end
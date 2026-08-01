# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
Code.require_file(
  Path.expand("../../../../../../test/fixtures/mission_control/contract_fixtures.exs", __DIR__)
)

defmodule Exocomp.Coordinator.MissionControl.ContractTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.MissionControl.{Acknowledgement, Codec, Command, Event, StatusReducer}
  alias Exocomp.MissionControl.ContractFixtures, as: Fixtures

  test "the shared corpus contains every supported event, command, and acknowledgement" do
    manifest = Fixtures.manifest()
    assert manifest["corpus_version"] == 1
    assert manifest["supported_schema_versions"] == [Event.current_schema_version()]

    for {type, module, decoder} <- [
          {"event", Event, &Codec.decode_event/1},
          {"command", Command, &Codec.decode_command/1},
          {"acknowledgement", Acknowledgement, &Codec.decode_acknowledgement/1}
        ] do
      envelope = manifest["envelopes"][type]
      fixtures = Fixtures.envelope_fixtures(type)

      assert fixtures != [], "#{type} fixture corpus is empty"

      for {fixture, index} <- Enum.with_index(fixtures) do
        label = "#{type}[#{index}]"
        Fixtures.assert_shape!(fixture, envelope["allowed_fields"], label)
        Fixtures.assert_required_fields!(fixture, envelope["required_fields"], label)
        assert {:ok, decoded} = decoder.(fixture), label
        assert decoded.__struct__ == module, label

        encoded =
          case type do
            "event" -> Codec.encode_event(decoded)
            "command" -> Codec.encode_command(decoded)
            "acknowledgement" -> Codec.encode_acknowledgement(decoded)
          end

        assert {:ok, ^decoded} = decoder.(encoded), label
      end
    end
  end

  test "each required field mutation has a bounded, field-specific failure" do
    for case <- Fixtures.fixture!("protocol_errors.json") do
      type = case["envelope"]
      fixture = Fixtures.envelope_fixtures(type) |> Enum.at(case["index"])
      mutated = Fixtures.mutate(fixture, case["operation"])

      result =
        case type do
          "event" -> Codec.decode_event(mutated)
          "command" -> Codec.decode_command(mutated)
          "acknowledgement" -> Codec.decode_acknowledgement(mutated)
        end

      Fixtures.expected_reason!(result, case["expected"]["reason"], case["name"])
    end
  end

  test "the shared corpus includes explicit replay and redaction cases" do
    replay = Fixtures.fixture!("protocol_replay.json")
    assert replay["duplicate"]["expected_result"] == "duplicate"
    assert replay["out_of_order"]["expected_result"] == "reconstruct"
    assert replay["sequence_gap"]["missing_sequences"] == [2]

    events = Fixtures.fixture!(replay["out_of_order"]["fixture"])["events"]
    assert {:ok, state} = StatusReducer.apply_all(StatusReducer.new(), events)
    assert StatusReducer.current(state)[{"node-a", "api.service"}]["health_state"] == "healthy"

    redaction = Fixtures.fixture!("redaction.json")

    assert Exocomp.Coordinator.MissionControl.StatusEvent.redact(redaction["input"]) ==
             redaction["expected"]
  end

  test "the coordinator facade accepts every shared status fixture" do
    for {name, raw} <-
          Enum.zip(Fixtures.manifest()["status_event_fixtures"], Fixtures.status_fixtures()) do
      values = if is_list(raw["events"]), do: raw["events"], else: [raw]

      for {value, index} <- Enum.with_index(values) do
        assert {:ok, _event} =
                 Exocomp.Coordinator.MissionControl.StatusEvent.decode(value),
               "#{name}[#{index}]"
      end
    end
  end
end

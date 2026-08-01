# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.CodecTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Codec

  @fixture_dir Path.expand("../../../../../test/fixtures/mission_control", __DIR__)

  test "encodes and decodes batches through the shared codec" do
    raw = fixture("desired_state_added.json")
    assert {:ok, event} = Codec.decode_status_event(raw)
    assert {:ok, [decoded]} = Codec.decode_status_events([Codec.encode_status_event(event)])
    assert decoded == event
    assert [%{"event_id" => "evt-desired-added-001"}] = Codec.encode_status_events([event])
  end

  test "rejects a non-list batch and stops on the first invalid event" do
    assert {:error, _} = Codec.decode_status_events(%{})

    assert {:error, {:unsupported_schema_version, 2}} =
             Codec.decode_status_events([
               fixture("desired_state_added.json"),
               Map.put(fixture("service_status_changed.json"), "schema_version", 2)
             ])
  end

  defp fixture(name) do
    @fixture_dir
    |> Path.join(name)
    |> File.read!()
    |> Jason.decode!()
  end
end

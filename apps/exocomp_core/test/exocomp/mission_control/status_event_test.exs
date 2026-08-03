# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.StatusEventTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.StatusEvent

  @fixture_dir Path.expand("../../../../../test/fixtures/mission_control", __DIR__)

  test "decodes, encodes, and round-trips every shared status fixture" do
    for file <- Path.wildcard(Path.join(@fixture_dir, "*.json")),
        not String.contains?(file, ["duplicate", "out_of_order"]) do
      raw = file |> File.read!() |> Jason.decode!()
      assert {:ok, event} = StatusEvent.decode(raw), file
      assert {:ok, json} = StatusEvent.encode_json(event)
      assert {:ok, decoded} = StatusEvent.decode_json(json)
      assert decoded == event
    end
  end

  test "requires all envelope fields and rejects forward versions" do
    raw = fixture("desired_state_added.json")

    assert {:error, {:missing_field, "correlation_id"}} =
             StatusEvent.decode(Map.delete(raw, "correlation_id"))

    assert {:error, {:unsupported_schema_version, 2}} =
             StatusEvent.decode(Map.put(raw, "schema_version", 2))

    assert {:error, {:unsupported_schema_version, 2}} =
             StatusEvent.decode(Map.put(raw, "schema_version", 2), schema_version: 2)

    assert {:error, {:unknown_field, "unexpected"}} =
             StatusEvent.decode(Map.put(raw, "unexpected", true))
  end

  test "rejects malformed timestamps with the field-level contract error" do
    raw = fixture("desired_state_added.json")

    assert {:error, {:invalid_field, "occurred_at", :iso8601}} =
             StatusEvent.decode(Map.put(raw, "occurred_at", "not-a-timestamp"))
  end

  test "requires common service contract fields and profile context" do
    raw = fixture("desired_state_added.json")
    payload = Map.delete(raw["payload"], "evidence_refs")

    assert {:error, {:missing_field, "evidence_refs"}} =
             StatusEvent.decode(Map.put(raw, "payload", payload))

    payload =
      raw["payload"]
      |> Map.put("source_set", ["cluster_profile"])
      |> Map.put("profile_context", nil)

    assert {:error, {:invalid_field, "profile_context", :required_for_cluster_profile}} =
             StatusEvent.decode(Map.put(raw, "payload", payload))
  end

  test "bounds event payload, service count, references, and strings" do
    raw = fixture("service_status_changed.json")
    assert {:error, {:event_too_large, _}} = StatusEvent.decode(raw, max_event_bytes: 10)

    payload = Map.put(raw["payload"], "evidence_refs", List.duplicate("evidence", 33))

    assert {:error, {:invalid_field, "evidence_refs", _}} =
             StatusEvent.decode(Map.put(raw, "payload", payload))

    snapshot = fixture("service_summary_snapshot.json")
    services = List.duplicate(snapshot["payload"]["services"] |> hd(), 1_001)

    assert {:error, {:invalid_field, "services", {:too_many, 1_000}}} =
             StatusEvent.decode(put_in(snapshot, ["payload", "services"], services))
  end

  test "redacts sensitive values recursively while retaining safe evidence" do
    raw = fixture("service_status_changed.json")
    payload = Map.put(raw["payload"], "health_reason", "token=do-not-send")
    payload = put_in(payload, ["evidence_refs"], ["evidence-safe"])
    event = raw |> Map.put("payload", payload) |> StatusEvent.decode() |> elem(1)

    assert event.payload["health_reason"] == "token=do-not-send"

    assert StatusEvent.redact(%{"details" => %{"api_key" => "secret", "safe" => 1}}) ==
             %{"details" => %{"api_key" => "[REDACTED]", "safe" => 1}}
  end

  defp fixture(name), do: @fixture_dir |> Path.join(name) |> File.read!() |> Jason.decode!()
end

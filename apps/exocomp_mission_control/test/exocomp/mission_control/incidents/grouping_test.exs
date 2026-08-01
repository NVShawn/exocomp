# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Incidents.GroupingTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Incidents.{Grouping, Incident}

  @t0 ~U[2026-01-01 00:00:00Z]

  defp incident(id, overrides \\ %{}) do
    Map.merge(
      %Incident{
        id: id,
        organization_id: "org-a",
        alert_type: "service.failed",
        service: "api",
        software_version: "1.2.3",
        opened_at: @t0,
        updated_at: @t0,
        state: :open
      },
      Map.new(overrides)
    )
  end

  describe "related?/3" do
    test "matches all grouping attributes at the inclusive window boundary" do
      left = incident("a")
      right = incident("b", opened_at: DateTime.add(@t0, 60, :second))

      assert Grouping.related?(left, right, window_seconds: 60)
    end

    test "rejects a timestamp outside the configured window" do
      left = incident("a")
      right = incident("b", opened_at: DateTime.add(@t0, 61, :second))

      refute Grouping.related?(left, right, window_seconds: 60)
    end

    for field <- [:organization_id, :alert_type, :service, :software_version] do
      test "rejects a different #{field}" do
        left = incident("a")
        right = incident("b", Map.put(%{}, unquote(field), "different"))

        refute Grouping.related?(left, right)
      end
    end

    test "does not treat missing service or version as a wildcard" do
      known = incident("known")
      missing_service = incident("missing-service", service: nil)
      missing_version = incident("missing-version", software_version: nil)

      refute Grouping.related?(known, missing_service)
      refute Grouping.related?(known, missing_version)
      assert Grouping.related?(missing_service, incident("also-missing", service: nil))
    end
  end

  describe "group/2" do
    test "returns stable keys, summaries, and member ordering" do
      older = incident("older", opened_at: DateTime.add(@t0, 10, :second))
      newer = incident("newer", opened_at: DateTime.add(@t0, 20, :second))
      separate = incident("separate", alert_type: "node.unreachable")

      forward = Grouping.group([newer, separate, older], window_seconds: 60)
      reverse = Grouping.group([older, separate, newer], window_seconds: 60)

      assert forward == reverse
      assert [%{key: key, incidents: members, summary: _summary}, separate_group] = forward
      assert key.alert_type == "node.unreachable"
      assert Enum.map(members, & &1.id) == ["separate"]
      assert separate_group.key.alert_type == "service.failed"
      assert Enum.map(separate_group.incidents, & &1.id) == ["older", "newer"]
      assert separate_group.summary.incident_count == 2
      assert separate_group.summary.text == "service.failed on api (1.2.3) — 2 incidents"
    end

    test "does not alter incident identity or lifecycle state" do
      resolved = incident("resolved", state: :resolved, fingerprint: "stable-fingerprint")
      before = resolved

      assert [%{incidents: [^resolved]}] = Grouping.group([resolved])
      assert resolved == before
      assert resolved.fingerprint == "stable-fingerprint"
      assert resolved.state == :resolved
    end

    test "uses a deterministic UTC window key" do
      value = incident("a", opened_at: ~U[2026-01-01 00:01:01Z])

      assert DateTime.compare(
               Grouping.key(value, window_seconds: 60).window_start,
               ~U[2026-01-01 00:01:00Z]
             ) == :eq
    end

    test "keeps incidents exactly one window apart in the same group" do
      first = incident("first")
      boundary = incident("boundary", opened_at: DateTime.add(@t0, 60, :second))

      assert [%{incidents: [^first, ^boundary]}] =
               Grouping.group([boundary, first], window_seconds: 60)
    end
  end
end

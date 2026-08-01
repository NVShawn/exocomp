# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Incidents.QueryTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Incidents

  @now ~U[2026-01-01 01:00:00Z]
  @t0 ~U[2026-01-01 00:00:00Z]

  defp start_store do
    name = String.to_atom("incident_queries_#{System.unique_integer([:positive])}")
    start_supervised!({Incidents, name: name, now_fn: fn -> @now end}, id: name)
  end

  defp evidence(id, overrides \\ %{}) do
    Map.merge(
      %{
        organization_id: "org-a",
        cluster_id: "cluster-a",
        alert_type: "service.failed",
        source: "systemd",
        target_type: "node",
        target_identity: id,
        service: "api",
        software_version: "1.2.3",
        occurred_at: @t0,
        correlation_id: "corr-#{id}"
      },
      Map.new(overrides)
    )
  end

  test "open and recent queries are organization-scoped and deterministically ordered" do
    store = start_store()
    assert {:ok, oldest} = Incidents.record(evidence("oldest"), store)

    assert {:ok, newest} =
             Incidents.record(
               evidence("newest", occurred_at: DateTime.add(@t0, 20, :second)),
               store
             )

    assert {:ok, foreign} =
             Incidents.record(
               evidence("foreign",
                 organization_id: "org-b",
                 occurred_at: DateTime.add(@t0, 10, :second)
               ),
               store
             )

    assert Enum.map(Incidents.list_open("org-a", store), & &1.id) == [oldest.id, newest.id]
    assert Enum.map(Incidents.recent("org-a", 3_600, store), & &1.id) == [oldest.id, newest.id]
    assert Enum.map(Incidents.list_open("org-b", store), & &1.id) == [foreign.id]
    assert Incidents.list_open("org-c", store) == []
  end

  test "related query excludes itself, resolved incidents, and other organizations" do
    store = start_store()
    assert {:ok, target} = Incidents.record(evidence("target"), store)

    assert {:ok, related} =
             Incidents.record(
               evidence("related", occurred_at: DateTime.add(@t0, 30, :second)),
               store
             )

    assert {:ok, resolved} =
             Incidents.record(
               evidence("resolved",
                 occurred_at: DateTime.add(@t0, 40, :second),
                 event_type: :resolved
               ),
               store
             )

    assert {:ok, _foreign} =
             Incidents.record(
               evidence(
                 "foreign",
                 organization_id: "org-b",
                 occurred_at: DateTime.add(@t0, 30, :second)
               ),
               store
             )

    assert {:ok, [^related]} = Incidents.related("org-a", target.id, [window_seconds: 60], store)

    assert {:ok, related_with_recent} =
             Incidents.related(
               "org-a",
               target.id,
               [window_seconds: 60, include_resolved: true, recent_seconds: 3_600],
               store
             )

    assert Enum.map(related_with_recent, & &1.id) == [related.id, resolved.id]
    assert Incidents.related("org-b", target.id, [], store) == {:error, :organization_mismatch}
  end
end

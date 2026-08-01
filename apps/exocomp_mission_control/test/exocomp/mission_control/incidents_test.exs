# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.IncidentsTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Incidents
  alias Exocomp.MissionControl.Incidents.{Fingerprint, Incident, IncidentEvent}

  @t0 ~U[2026-01-01 00:00:00Z]

  defp start_store do
    name = String.to_atom("incidents_#{System.unique_integer([:positive])}")
    start_supervised!({Incidents, name: name}, id: name)
  end

  defp evidence(overrides \\ %{}) do
    Map.merge(
      %{
        organization_id: "org-a",
        cluster_id: "cluster-a",
        alert_type: "service.failed",
        source: "systemd",
        target_type: "node",
        target_identity: "node-a",
        occurred_at: @t0,
        payload: %{"message" => "safe evidence"}
      },
      Map.new(overrides)
    )
  end

  describe "fingerprints" do
    test "identical alerts have a stable fingerprint and payload is not hashed" do
      first = evidence()
      second = evidence(payload: %{"raw_log" => "password=do-not-hash"})

      assert Fingerprint.build(first) == Fingerprint.build(second)
      assert Fingerprint.build(first) == Fingerprint.build(first)
      assert byte_size(Fingerprint.build(first)) == 64
      refute Fingerprint.build(first) =~ "password"
      refute Fingerprint.build(first) =~ "do-not-hash"
    end

    test "record constructors enforce the organization-scoped schema" do
      assert {:ok, incident} = Incident.new(evidence())
      assert incident.organization_id == "org-a"
      assert incident.fingerprint == Fingerprint.build(evidence())
      assert Incident.states() == [:open, :acknowledged, :resolved]

      assert {:ok, event} =
               IncidentEvent.new(%{
                 incident_id: incident.id,
                 organization_id: incident.organization_id,
                 fingerprint: incident.fingerprint,
                 event_type: :opened,
                 occurred_at: @t0,
                 correlation_id: "corr-schema"
               })

      assert event.kind == :opened
      assert IncidentEvent.event_types() == [:opened, :updated, :acknowledged, :resolved]

      assert {:error, {:invalid_field, :organization_id}} =
               Incident.new(Map.delete(evidence(), :organization_id))
    end

    test "target and organization are part of the identity" do
      refute Fingerprint.build(evidence()) ==
               Fingerprint.build(evidence(target_identity: "node-b"))

      refute Fingerprint.build(evidence()) ==
               Fingerprint.build(evidence(organization_id: "org-b"))
    end
  end

  describe "record/2" do
    test "repeated evidence upserts one incident and appends correlated events" do
      store = start_store()
      assert {:ok, first} = Incidents.record(evidence(correlation_id: "corr-1"), store)

      assert {:ok, second} =
               Incidents.record(
                 evidence(occurred_at: DateTime.add(@t0, 5, :second), correlation_id: "corr-2"),
                 store
               )

      assert first.id == second.id
      assert second.event_count == 2
      assert {:ok, fetched} = Incidents.get("org-a", first.id, store)
      assert fetched.fingerprint == first.fingerprint
      assert {:ok, [first_event, second_event]} = Incidents.events("org-a", first.id, store)
      assert first_event.correlation_id == "corr-1"
      assert second_event.correlation_id == "corr-2"
      assert Enum.map(Incidents.list("org-a", store), & &1.id) == [first.id]
      assert Incidents.list("org-b", store) == []
    end

    test "concurrent opens produce one incident" do
      store = start_store()
      parent = self()

      for index <- 1..25 do
        spawn(fn ->
          send(parent, {:result, Incidents.record(evidence(sequence: index), store)})
        end)
      end

      results =
        for _ <- 1..25 do
          assert_receive {:result, {:ok, incident}}, 2_000
          incident
        end

      assert results |> Enum.map(& &1.id) |> Enum.uniq() |> length() == 1
      [incident] = Incidents.list("org-a", store)
      assert incident.event_count == 25
    end

    test "a resolved incident reopens on matching recurrence without losing history" do
      store = start_store()
      assert {:ok, opened} = Incidents.record(evidence(), store)

      assert {:ok, resolved} =
               Incidents.record(
                 evidence(
                   event_type: :resolved,
                   occurred_at: DateTime.add(@t0, 10, :second),
                   correlation_id: "corr-resolved"
                 ),
                 store
               )

      assert resolved.state == :resolved

      assert {:ok, reopened} =
               Incidents.record(
                 evidence(
                   occurred_at: DateTime.add(@t0, 20, :second),
                   correlation_id: "corr-reopened"
                 ),
                 store
               )

      assert reopened.id == opened.id
      assert reopened.state == :open
      assert reopened.resolved_at == nil
      assert reopened.event_count == 3

      assert Enum.map(Incidents.events(reopened.id, store), & &1.event_type) == [
               :opened,
               :resolved,
               :updated
             ]
    end

    test "events are ordered by occurrence, then stable ingestion sequence" do
      store = start_store()
      late = DateTime.add(@t0, 20, :second)
      early = DateTime.add(@t0, 10, :second)

      {:ok, incident} =
        Incidents.record(evidence(occurred_at: late, correlation_id: "late"), store)

      :ok =
        Incidents.record(evidence(occurred_at: early, correlation_id: "early"), store) |> elem(0)

      :ok =
        Incidents.record(evidence(occurred_at: early, correlation_id: "early-tie"), store)
        |> elem(0)

      assert Enum.map(Incidents.events(incident.id, store), & &1.correlation_id) == [
               "early",
               "early-tie",
               "late"
             ]
    end

    test "acknowledgement is an explicit incident state" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(event_type: :acknowledged), store)
      assert incident.state == :acknowledged

      assert {:ok, still_acknowledged} =
               Incidents.record(evidence(occurred_at: DateTime.add(@t0, 1, :second)), store)

      assert still_acknowledged.state == :acknowledged
    end
  end
end

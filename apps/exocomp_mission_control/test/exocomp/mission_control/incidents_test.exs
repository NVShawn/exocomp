# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.IncidentsTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Incidents
  alias Exocomp.MissionControl.Incidents.{Fingerprint, Incident, IncidentEvent}

  @t0 ~U[2026-01-01 00:00:00Z]

  defp start_store do
    name = String.to_atom("incidents_#{System.unique_integer([:positive])}")

    start_supervised!(
      {Incidents, name: name, now_fn: fn -> @t0 end},
      id: name
    )
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

      assert IncidentEvent.event_types() == [
               :opened,
               :updated,
               :acknowledged,
               :resolved,
               :acknowledged_by_operator,
               :assigned,
               :snoozed,
               :unsnoozed,
               :manually_resolved,
               :reopened
             ]

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

  describe "acknowledge/7 - role-based authorization" do
    test "operator can acknowledge an open incident" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)
      assert incident.state == :open

      assert {:ok, acknowledged} =
               Incidents.acknowledge(
                 "org-a",
                 incident.id,
                 "user-1@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert acknowledged.state == :acknowledged
      assert acknowledged.acknowledged_at != nil

      assert Enum.any?(
               Incidents.events(incident.id, store),
               &(&1.event_type == :acknowledged_by_operator)
             )
    end

    test "admin can acknowledge an open incident" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      assert {:ok, acknowledged} =
               Incidents.acknowledge(
                 "org-a",
                 incident.id,
                 "admin@example.com",
                 "org-a",
                 :admin,
                 store
               )

      assert acknowledged.state == :acknowledged
    end

    test "viewer is denied" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      assert {:error, :access_denied} =
               Incidents.acknowledge(
                 "org-a",
                 incident.id,
                 "viewer@example.com",
                 "org-a",
                 :viewer,
                 store
               )
    end

    test "cross-organization access is denied" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      assert {:error, :organization_mismatch} =
               Incidents.acknowledge(
                 "org-a",
                 incident.id,
                 "user@example.com",
                 "org-b",
                 :operator,
                 store
               )
    end

    test "cannot acknowledge a non-open incident" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(event_type: :acknowledged), store)

      assert {:error, :invalid_state} =
               Incidents.acknowledge(
                 "org-a",
                 incident.id,
                 "user@example.com",
                 "org-a",
                 :operator,
                 store
               )
    end

    test "operator info is recorded in the event" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      assert {:ok, _} =
               Incidents.acknowledge(
                 "org-a",
                 incident.id,
                 "alice@example.com",
                 "org-a",
                 :operator,
                 store
               )

      [event] =
        Incidents.events(incident.id, store)
        |> Enum.filter(&(&1.event_type == :acknowledged_by_operator))

      assert event.payload["operator_subject"] == "alice@example.com"
      assert event.payload["operator_organization"] == "org-a"
      assert event.payload["operator_role"] == "operator"
    end
  end

  describe "assign/8 and unassign/7" do
    test "operator can assign an incident" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)
      assert incident.assigned_to == nil

      assert {:ok, assigned} =
               Incidents.assign(
                 "org-a",
                 incident.id,
                 "alice@example.com",
                 "user-1@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert assigned.assigned_to == "alice@example.com"
    end

    test "reassignment updates the current assignment" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      assert {:ok, assigned1} =
               Incidents.assign(
                 "org-a",
                 incident.id,
                 "alice@example.com",
                 "user-1@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert assigned1.assigned_to == "alice@example.com"

      assert {:ok, assigned2} =
               Incidents.assign(
                 "org-a",
                 incident.id,
                 "bob@example.com",
                 "user-2@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert assigned2.assigned_to == "bob@example.com"
      assert assigned2.event_count == 3
    end

    test "operator can unassign an incident" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      assert {:ok, assigned} =
               Incidents.assign(
                 "org-a",
                 incident.id,
                 "alice@example.com",
                 "user-1@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert assigned.assigned_to == "alice@example.com"

      assert {:ok, unassigned} =
               Incidents.unassign(
                 "org-a",
                 incident.id,
                 "user-2@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert unassigned.assigned_to == nil
    end

    test "viewer is denied assignment" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      assert {:error, :access_denied} =
               Incidents.assign(
                 "org-a",
                 incident.id,
                 "alice@example.com",
                 "user@example.com",
                 "org-a",
                 :viewer,
                 store
               )
    end

    test "assignment events record operator info" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      assert {:ok, _} =
               Incidents.assign(
                 "org-a",
                 incident.id,
                 "alice@example.com",
                 "bob@example.com",
                 "org-a",
                 :operator,
                 store
               )

      [event] = Incidents.events(incident.id, store) |> Enum.filter(&(&1.event_type == :assigned))
      assert event.payload["assigned_to"] == "alice@example.com"
      assert event.payload["operator_subject"] == "bob@example.com"
    end
  end

  describe "snooze/8 and unsnooze/7" do
    test "operator can snooze an incident" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)
      assert incident.snoozed_until == nil

      future = DateTime.add(@t0, 3600, :second)

      assert {:ok, snoozed} =
               Incidents.snooze(
                 "org-a",
                 incident.id,
                 future,
                 "user-1@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert snoozed.snoozed_until == future
    end

    test "snooze time must be in the future" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      past = DateTime.add(@t0, -100, :second)

      assert {:error, :invalid_snooze_time} =
               Incidents.snooze(
                 "org-a",
                 incident.id,
                 past,
                 "user-1@example.com",
                 "org-a",
                 :operator,
                 store
               )
    end

    test "snooze expiry can be extended" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      future1 = DateTime.add(@t0, 1800, :second)

      assert {:ok, snoozed1} =
               Incidents.snooze(
                 "org-a",
                 incident.id,
                 future1,
                 "user-1@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert snoozed1.snoozed_until == future1

      future2 = DateTime.add(@t0, 3600, :second)

      assert {:ok, snoozed2} =
               Incidents.snooze(
                 "org-a",
                 incident.id,
                 future2,
                 "user-1@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert snoozed2.snoozed_until == future2
    end

    test "operator can unsnooze an incident" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      future = DateTime.add(@t0, 3600, :second)

      assert {:ok, snoozed} =
               Incidents.snooze(
                 "org-a",
                 incident.id,
                 future,
                 "user-1@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert snoozed.snoozed_until == future

      assert {:ok, unsnoozed} =
               Incidents.unsnooze(
                 "org-a",
                 incident.id,
                 "user-2@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert unsnoozed.snoozed_until == nil
    end

    test "snooze events record operator and time info" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      future = DateTime.add(@t0, 3600, :second)

      assert {:ok, _} =
               Incidents.snooze(
                 "org-a",
                 incident.id,
                 future,
                 "user@example.com",
                 "org-a",
                 :operator,
                 store
               )

      [event] = Incidents.events(incident.id, store) |> Enum.filter(&(&1.event_type == :snoozed))
      assert event.payload["snoozed_until"] == DateTime.to_iso8601(future)
      assert event.payload["operator_subject"] == "user@example.com"
    end

    test "viewer is denied snooze" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      future = DateTime.add(@t0, 3600, :second)

      assert {:error, :access_denied} =
               Incidents.snooze(
                 "org-a",
                 incident.id,
                 future,
                 "user@example.com",
                 "org-a",
                 :viewer,
                 store
               )
    end
  end

  describe "resolve/8 - manual resolution" do
    test "operator can manually resolve an incident with a reason" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)
      assert incident.resolution_reason == nil

      assert {:ok, resolved} =
               Incidents.resolve(
                 "org-a",
                 incident.id,
                 "Operator restarted the service",
                 "user-1@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert resolved.state == :resolved
      assert resolved.resolution_reason == "Operator restarted the service"
    end

    test "admin can manually resolve an incident" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      assert {:ok, resolved} =
               Incidents.resolve(
                 "org-a",
                 incident.id,
                 "Acknowledged and resolved",
                 "admin@example.com",
                 "org-a",
                 :admin,
                 store
               )

      assert resolved.state == :resolved
    end

    test "viewer is denied resolution" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      assert {:error, :access_denied} =
               Incidents.resolve(
                 "org-a",
                 incident.id,
                 "reason",
                 "user@example.com",
                 "org-a",
                 :viewer,
                 store
               )
    end

    test "resolution event records reason and operator info" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)

      assert {:ok, _} =
               Incidents.resolve(
                 "org-a",
                 incident.id,
                 "Service restarted successfully",
                 "alice@example.com",
                 "org-a",
                 :operator,
                 store
               )

      [event] =
        Incidents.events(incident.id, store)
        |> Enum.filter(&(&1.event_type == :manually_resolved))

      assert event.payload["reason"] == "Service restarted successfully"
      assert event.payload["operator_subject"] == "alice@example.com"
      assert event.payload["operator_role"] == "operator"
    end

    test "new unhealthy evidence reopens a manually resolved incident" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(correlation_id: "initial"), store)

      assert {:ok, resolved} =
               Incidents.resolve(
                 "org-a",
                 incident.id,
                 "Operator verified and resolved",
                 "user@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert resolved.state == :resolved

      assert {:ok, reopened} =
               Incidents.record(
                 evidence(
                   occurred_at: DateTime.add(@t0, 100, :second),
                   correlation_id: "recurrence"
                 ),
                 store
               )

      assert reopened.id == incident.id
      assert reopened.state == :open
      assert reopened.resolved_at == nil
      assert reopened.resolution_reason == "Operator verified and resolved"

      timeline = Incidents.events(incident.id, store)
      event_types = Enum.map(timeline, & &1.event_type)
      assert :reopened in event_types
    end

    test "manually resolved incident does not auto-reopen on same evidence" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(correlation_id: "initial"), store)

      assert {:ok, resolved} =
               Incidents.resolve(
                 "org-a",
                 incident.id,
                 "Resolved",
                 "user@example.com",
                 "org-a",
                 :operator,
                 store
               )

      assert resolved.state == :resolved

      # Same update event doesn't reopen
      assert {:ok, still_resolved} =
               Incidents.record(
                 evidence(
                   occurred_at: DateTime.add(@t0, 50, :second),
                   correlation_id: "update"
                 ),
                 store
               )

      assert still_resolved.id == incident.id
      assert still_resolved.state == :resolved
    end
  end

  describe "concurrent mutations" do
    test "concurrent assigns are ordered atomically" do
      store = start_store()
      assert {:ok, incident} = Incidents.record(evidence(), store)
      parent = self()

      assignees = ["alice", "bob", "charlie", "diana"]

      for assignee <- assignees do
        spawn(fn ->
          result =
            Incidents.assign(
              "org-a",
              incident.id,
              assignee,
              "user-#{assignee}@example.com",
              "org-a",
              :operator,
              store
            )

          send(parent, {:assigned, assignee, result})
        end)
      end

      for _ <- 1..4 do
        assert_receive {:assigned, _assignee, {:ok, _incident}}, 2_000
      end

      {:ok, final} = Incidents.get("org-a", incident.id, store)
      assert final.assigned_to in assignees
      # Should have 5 events: original + 4 assigns
      assert final.event_count == 5
    end
  end
end

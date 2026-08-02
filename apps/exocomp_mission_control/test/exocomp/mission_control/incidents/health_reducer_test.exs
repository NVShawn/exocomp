# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Incidents.HealthReducerTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Incidents
  alias Exocomp.MissionControl.Incidents.Incident
  alias Exocomp.MissionControl.Incidents.HealthReducer

  @t0 ~U[2026-01-01 00:00:00Z]

  describe "degraded hysteresis" do
    test "opens on the second consecutive degraded observation, not the first" do
      {state, first} =
        apply_observation(HealthReducer.new(), observation(id: "d-1", health: :degraded))

      assert first == []

      {_state, second} =
        apply_observation(state, observation(id: "d-2", health: :degraded, at: 1))

      assert [action] = second
      assert action.action == :open
      assert action.event_type == :opened
      assert action.severity == :warning
    end

    test "a healthy observation breaks a degraded run" do
      state = HealthReducer.new()
      {state, []} = apply_observation(state, observation(id: "d-1", health: :degraded))
      {state, []} = apply_observation(state, observation(id: "h-1", health: :healthy, at: 1))

      {_state, actions} =
        apply_observation(state, observation(id: "d-2", health: :degraded, at: 2))

      assert actions == []
    end

    test "counters are isolated for interleaved targets" do
      state = HealthReducer.new()
      {state, []} = apply_observation(state, observation(id: "a-1", target_identity: "node-a"))
      {state, []} = apply_observation(state, observation(id: "b-1", target_identity: "node-b"))

      {state, a_actions} =
        apply_observation(state, observation(id: "a-2", target_identity: "node-a", at: 1))

      {_state, b_actions} =
        apply_observation(state, observation(id: "b-2", target_identity: "node-b", at: 1))

      assert [%{action: :open}] = a_actions
      assert [%{action: :open}] = b_actions
    end

    test "duplicate observations are no-ops and conflicting IDs fail closed" do
      state = HealthReducer.new()
      first = observation(id: "same", health: :degraded)
      {state, []} = apply_observation(state, first)
      assert {:ok, ^state, :duplicate} = HealthReducer.reduce(state, first)

      conflict = observation(id: "same", health: :healthy)
      assert {:error, :observation_id_conflict} = HealthReducer.reduce(state, conflict)
    end
  end

  test "incident severity values are normalized and ordered deterministically" do
    assert Incident.severities() == [:info, :warning, :critical]
    assert Incident.normalize_severity("HEALTH_ERR") == :critical
    assert Incident.normalize_severity("HEALTH_WARN") == :warning
    assert Incident.severity_rank(:critical) > Incident.severity_rank(:warning)
  end

  describe "immediate evidence" do
    test "immediate unhealthy evidence bypasses ordinary health hysteresis" do
      {_state, [action]} =
        apply_observation(
          HealthReducer.new(),
          observation(id: "immediate-unreachable", health: :unreachable)
        )

      assert action.action == :open
      assert action.trigger == "immediate evidence"
    end

    for {label, overrides, expected_severity} <- [
          {"stale", [health: :stale], :warning},
          {"unreachable", [health: :unreachable], :critical},
          {"identity failure", [failure_type: :identity], :critical},
          {"authentication failure", [failure_type: :authentication], :critical},
          {"audit failure", [failure_type: :audit], :critical},
          {"policy failure", [failure_type: :policy], :critical},
          {"remediation failure", [failure_type: :remediation], :critical},
          {"coverage failure", [coverage_status: :unsupported], :warning},
          {"Ceph HEALTH_ERR",
           [source: "ceph", health: %{"overall" => %{"status" => "HEALTH_ERR"}}], :critical}
        ] do
      test "#{label} opens immediately with deterministic severity" do
        {_state, [action]} =
          apply_observation(
            HealthReducer.new(),
            observation(Keyword.merge([id: unquote(label)], unquote(Macro.escape(overrides))))
          )

        assert action.action == :open
        assert action.severity == unquote(expected_severity)
      end
    end

    test "explicit alerts open immediately and map severity without inference" do
      for {severity, expected} <- [
            {"critical", :critical},
            {"error", :critical},
            {"warning", :warning},
            {"info", :info}
          ] do
        event =
          observation(
            id: "alert-#{severity}",
            kind: "alert.opened",
            alert_type: "cluster.disk",
            severity: severity,
            health: :unknown
          )

        {_state, [action]} = apply_observation(HealthReducer.new(), event)
        assert action.action == :open
        assert action.severity == expected
      end
    end

    test "envelope payload fields are classified at the ingestion boundary" do
      event = %{
        "event_id" => "payload-alert",
        "kind" => "alert.opened",
        "occurred_at" => DateTime.to_iso8601(@t0),
        "correlation_id" => "corr-payload-alert",
        "organization_id" => "org-a",
        "cluster_id" => "cluster-a",
        "payload" => %{
          "alert_type" => "cluster.disk",
          "target_type" => "cluster",
          "target_identity" => "cluster-a",
          "severity" => "critical"
        }
      }

      {_state, [action]} = apply_observation(HealthReducer.new(), event)
      assert action.action == :open
      assert action.severity == :critical
      assert action.evidence.target_type == "cluster"
      assert action.evidence.alert_type == "cluster.disk"
    end
  end

  describe "resolution" do
    test "auto-resolves after the second consecutive healthy observation" do
      state = HealthReducer.new()
      {state, []} = apply_observation(state, observation(id: "d-1"))
      {state, [%{action: :open}]} = apply_observation(state, observation(id: "d-2", at: 1))
      {state, []} = apply_observation(state, observation(id: "h-1", health: :healthy, at: 2))

      {_state, [action]} =
        apply_observation(state, observation(id: "h-2", health: :healthy, at: 3))

      assert action.action == :resolve
      assert action.event_type == :resolved
    end

    test "a new unhealthy observation reopens after an explicit resolution" do
      state = HealthReducer.new()
      {state, []} = apply_observation(state, observation(id: "d-1"))
      {state, [%{action: :open}]} = apply_observation(state, observation(id: "d-2", at: 1))

      resolved = observation(id: "resolve", kind: "alert.resolved", at: 2)
      {state, [%{action: :resolve}]} = apply_observation(state, resolved)
      {_state, [action]} = apply_observation(state, observation(id: "recurrence", at: 3))
      assert action.action == :update
      assert action.trigger == "recurrence"
    end

    test "desired state removal resolves without a synthetic healthy observation" do
      state = HealthReducer.new()
      {state, []} = apply_observation(state, observation(id: "d-1"))
      {state, [%{action: :open}]} = apply_observation(state, observation(id: "d-2", at: 1))
      removed = observation(id: "removed", kind: "desired_state.removed", at: 2)
      {_state, [action]} = apply_observation(state, removed)
      assert action.action == :resolve
      assert action.trigger == "explicit resolution"
    end

    test "an explicit resolve event resolves an explicit alert" do
      state = HealthReducer.new()
      opened = observation(id: "alert-open", kind: "alert.opened", alert_type: "ceph.alert")
      {state, [%{action: :open}]} = apply_observation(state, opened)

      resolved =
        observation(id: "alert-resolve", kind: "alert.resolved", alert_type: "ceph.alert", at: 1)

      {_state, [action]} = apply_observation(state, resolved)
      assert action.action == :resolve
    end
  end

  describe "incident store integration" do
    test "persists open and automatic resolve transitions with one fingerprint" do
      store = start_store()
      state = HealthReducer.new()

      {state, []} = process(state, observation(id: "d-1"), store)

      {state, [%{action: :open, incident: opened}]} =
        process(state, observation(id: "d-2", at: 1), store)

      {state, []} = process(state, observation(id: "h-1", health: :healthy, at: 2), store)

      {_state, [%{action: :resolve, incident: resolved}]} =
        process(state, observation(id: "h-2", health: :healthy, at: 3), store)

      assert opened.id == resolved.id
      assert resolved.state == :resolved
      assert length(Incidents.list("org-a", store)) == 1
    end

    test "a persisted manually resolved incident reopens on new unhealthy evidence" do
      store = start_store()
      state = HealthReducer.new()
      {state, []} = process(state, observation(id: "d-1"), store)
      {state, [%{incident: incident}]} = process(state, observation(id: "d-2", at: 1), store)

      assert {:ok, manually_resolved} =
               Incidents.record(
                 observation(id: "manual", event_type: :resolved, at: 2),
                 store
               )

      assert manually_resolved.state == :resolved

      {_state, [%{action: :update, incident: reopened}]} =
        process(state, observation(id: "new-evidence", at: 3), store)

      assert reopened.id == incident.id
      assert reopened.state == :open
    end
  end

  defp apply_observation(state, observation) do
    assert {:ok, state, actions} = HealthReducer.reduce(state, observation)
    {state, actions}
  end

  defp process(state, observation, store) do
    assert {:ok, state, actions} = HealthReducer.process(state, observation, store)
    {state, actions}
  end

  defp start_store do
    name = String.to_atom("health_incidents_#{System.unique_integer([:positive])}")
    start_supervised!({Incidents, name: name}, id: name)
  end

  defp observation(overrides) do
    overrides = Map.new(overrides)
    at = Map.get(overrides, :at, 0)

    %{
      organization_id: "org-a",
      cluster_id: "cluster-a",
      target_type: "node",
      target_identity: "node-a",
      source: "health",
      alert_type: "node.health",
      health: :degraded,
      occurred_at: DateTime.add(@t0, at, :second),
      correlation_id: "corr-#{Map.get(overrides, :id, "default")}",
      id: Map.get(overrides, :id, "default")
    }
    |> Map.merge(Map.delete(overrides, :at))
    |> Map.put(:observation_id, Map.get(overrides, :id, "default"))
    |> Map.put(:payload, Map.get(overrides, :payload, %{}))
    |> Map.put(:event_id, Map.get(overrides, :id, "default"))
  end
end

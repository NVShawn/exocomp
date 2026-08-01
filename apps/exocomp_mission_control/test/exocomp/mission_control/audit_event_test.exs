# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AuditEventTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.AuditEvent

  doctest AuditEvent

  describe "new/1 - operator action" do
    test "creates an operator audit event with all required fields" do
      event =
        AuditEvent.new(
          organization_id: "org_123",
          cluster_id: "cluster_456",
          actor_type: :operator,
          actor_sub: "operator_sub_789",
          actor_display_name: "alice@example.com",
          event_type: "approval.granted",
          target: %{"type" => "proposal", "id" => "prop_999"},
          outcome: :ok
        )

      assert event.organization_id == "org_123"
      assert event.cluster_id == "cluster_456"
      assert event.actor_type == :operator
      assert event.actor_sub == "operator_sub_789"
      assert event.actor_display_name == "alice@example.com"
      assert event.event_type == "approval.granted"
      assert event.target == %{"type" => "proposal", "id" => "prop_999"}
      assert event.outcome == :ok
      assert event.outcome_details == nil
      assert event.event_id != nil
      assert String.starts_with?(event.event_id, "evt_")
      assert event.correlation_id != nil
      assert String.starts_with?(event.correlation_id, "corr_")
      assert event.occurred_at != nil
      assert is_nil(event.inserted_at)
    end

    test "uses provided correlation_id" do
      correlation_id = "corr_custom_id"

      event =
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "approval.granted",
          target: %{},
          outcome: :ok,
          correlation_id: correlation_id
        )

      assert event.correlation_id == correlation_id
    end

    test "uses provided occurred_at timestamp" do
      timestamp = ~U[2026-08-01 12:00:00Z]

      event =
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "approval.granted",
          target: %{},
          outcome: :ok,
          occurred_at: timestamp
        )

      assert event.occurred_at == timestamp
    end

    test "includes outcome_details when provided" do
      event =
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "approval.granted",
          target: %{},
          outcome: :ok,
          outcome_details: %{"executed_at" => "2026-08-01T12:00:00Z", "duration_ms" => 42}
        )

      assert event.outcome_details == %{
               "executed_at" => "2026-08-01T12:00:00Z",
               "duration_ms" => 42
             }
    end
  end

  describe "new/1 - system action" do
    test "creates a system audit event" do
      event =
        AuditEvent.new(
          organization_id: "org_123",
          cluster_id: "cluster_456",
          actor_type: :system,
          event_type: "incident.auto_resolved",
          target: %{"type" => "incident", "id" => "inc_123"},
          outcome: :ok
        )

      assert event.actor_type == :system
      assert event.actor_sub == nil
      assert event.actor_display_name == nil
    end

    test "rejects actor_sub with system actor_type" do
      assert_raise ArgumentError,
                   ~r/actor_sub should only be set when actor_type is :operator/,
                   fn ->
                     AuditEvent.new(
                       organization_id: "org_123",
                       actor_type: :system,
                       actor_sub: "should_not_work",
                       event_type: "incident.auto_resolved",
                       target: %{},
                       outcome: :ok
                     )
                   end
    end

    test "rejects actor_display_name with system actor_type" do
      assert_raise ArgumentError,
                   ~r/actor_display_name should only be set when actor_type is :operator/,
                   fn ->
                     AuditEvent.new(
                       organization_id: "org_123",
                       actor_type: :system,
                       actor_display_name: "should_not_work",
                       event_type: "incident.auto_resolved",
                       target: %{},
                       outcome: :ok
                     )
                   end
    end
  end

  describe "new/1 - cluster event" do
    test "creates a cluster audit event" do
      event =
        AuditEvent.new(
          organization_id: "org_123",
          cluster_id: "cluster_456",
          actor_type: :cluster,
          event_type: "alert.opened",
          target: %{"type" => "alert", "id" => "alert_123", "severity" => "critical"},
          outcome: :ok
        )

      assert event.actor_type == :cluster
      assert event.actor_sub == nil
      assert event.actor_display_name == nil
      assert event.cluster_id == "cluster_456"
    end
  end

  describe "new/1 - validation" do
    test "requires organization_id" do
      assert_raise KeyError, fn ->
        AuditEvent.new(
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "approval.granted",
          target: %{},
          outcome: :ok
        )
      end
    end

    test "requires actor_type" do
      assert_raise KeyError, fn ->
        AuditEvent.new(
          organization_id: "org_123",
          event_type: "approval.granted",
          target: %{},
          outcome: :ok
        )
      end
    end

    test "requires event_type" do
      assert_raise KeyError, fn ->
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :operator,
          actor_sub: "sub_123",
          target: %{},
          outcome: :ok
        )
      end
    end

    test "requires target" do
      assert_raise KeyError, fn ->
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "approval.granted",
          outcome: :ok
        )
      end
    end

    test "requires outcome" do
      assert_raise KeyError, fn ->
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "approval.granted",
          target: %{}
        )
      end
    end

    test "rejects invalid actor_type" do
      assert_raise ArgumentError, ~r/actor_type must be one of/, fn ->
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :invalid,
          event_type: "approval.granted",
          target: %{},
          outcome: :ok
        )
      end
    end

    test "rejects invalid outcome" do
      assert_raise ArgumentError, ~r/outcome must be :ok or :error/, fn ->
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "approval.granted",
          target: %{},
          outcome: :invalid
        )
      end
    end
  end

  describe "new/1 - optional fields" do
    test "cluster_id is optional" do
      event =
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :system,
          event_type: "enrollment.created",
          target: %{},
          outcome: :ok
        )

      assert is_nil(event.cluster_id)
    end

    test "actor_display_name is optional for operators" do
      event =
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "approval.granted",
          target: %{},
          outcome: :ok
        )

      assert is_nil(event.actor_display_name)
    end

    test "outcome_details is optional" do
      event =
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "approval.granted",
          target: %{},
          outcome: :ok
        )

      assert is_nil(event.outcome_details)
    end
  end

  describe "generate_event_id/0" do
    test "generates unique event IDs" do
      id1 = AuditEvent.generate_event_id()
      id2 = AuditEvent.generate_event_id()

      assert String.starts_with?(id1, "evt_")
      assert String.starts_with?(id2, "evt_")
      assert id1 != id2
    end

    test "event ID has correct format" do
      id = AuditEvent.generate_event_id()
      # event ID format is "evt_" followed by url-safe base64 without padding
      assert String.starts_with?(id, "evt_")
      base64_part = String.replace_leading(id, "evt_", "")
      # base64 part should be 22 characters (16 bytes encoded without padding)
      assert String.length(base64_part) == 22
      # Verify it contains only url-safe base64 characters
      assert Regex.match?(~r/^[A-Za-z0-9_-]+$/, base64_part)
    end
  end

  describe "generate_correlation_id/0" do
    test "generates unique correlation IDs" do
      id1 = AuditEvent.generate_correlation_id()
      id2 = AuditEvent.generate_correlation_id()

      assert String.starts_with?(id1, "corr_")
      assert String.starts_with?(id2, "corr_")
      assert id1 != id2
    end

    test "correlation ID has correct format" do
      id = AuditEvent.generate_correlation_id()
      # correlation ID format is "corr_" followed by url-safe base64 without padding
      assert String.starts_with?(id, "corr_")
      base64_part = String.replace_leading(id, "corr_", "")
      # base64 part should be 22 characters (16 bytes encoded without padding)
      assert String.length(base64_part) == 22
      # Verify it contains only url-safe base64 characters
      assert Regex.match?(~r/^[A-Za-z0-9_-]+$/, base64_part)
    end
  end

  describe "to_map/1" do
    test "converts event to JSON-safe map" do
      timestamp = ~U[2026-08-01 12:00:00Z]

      event =
        AuditEvent.new(
          organization_id: "org_123",
          cluster_id: "cluster_456",
          actor_type: :operator,
          actor_sub: "sub_123",
          actor_display_name: "alice@example.com",
          event_type: "approval.granted",
          target: %{"type" => "proposal", "id" => "prop_999"},
          outcome: :ok,
          outcome_details: %{"duration_ms" => 42},
          correlation_id: "corr_abc123",
          occurred_at: timestamp
        )

      map = AuditEvent.to_map(event)

      assert map["event_id"] == event.event_id
      assert map["organization_id"] == "org_123"
      assert map["cluster_id"] == "cluster_456"
      assert map["actor_type"] == "operator"
      assert map["actor_sub"] == "sub_123"
      assert map["actor_display_name"] == "alice@example.com"
      assert map["event_type"] == "approval.granted"
      assert map["target"] == %{"type" => "proposal", "id" => "prop_999"}
      assert map["outcome"] == "ok"
      assert map["outcome_details"] == %{"duration_ms" => 42}
      assert map["correlation_id"] == "corr_abc123"
      assert map["occurred_at"] == "2026-08-01T12:00:00Z"
      assert map["inserted_at"] == nil
    end

    test "converts atoms in target to strings" do
      event =
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :system,
          event_type: "test",
          target: %{"severity" => :critical, "status" => :open},
          outcome: :ok
        )

      map = AuditEvent.to_map(event)

      assert map["target"]["severity"] == "critical"
      assert map["target"]["status"] == "open"
    end

    test "handles nil inserted_at" do
      event =
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :system,
          event_type: "test",
          target: %{},
          outcome: :ok
        )

      map = AuditEvent.to_map(event)
      assert map["inserted_at"] == nil
    end

    test "converts inserted_at when present" do
      timestamp = ~U[2026-08-01 12:00:00Z]

      event =
        AuditEvent.new(
          organization_id: "org_123",
          actor_type: :system,
          event_type: "test",
          target: %{},
          outcome: :ok
        )
        |> Map.put(:inserted_at, timestamp)

      map = AuditEvent.to_map(event)
      assert map["inserted_at"] == "2026-08-01T12:00:00Z"
    end
  end

  describe "outcome - error events" do
    test "records error outcome with details" do
      event =
        AuditEvent.new(
          organization_id: "org_123",
          cluster_id: "cluster_456",
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "approval.denied",
          target: %{"type" => "proposal", "id" => "prop_999"},
          outcome: :error,
          outcome_details: %{"reason" => "policy_violation", "policy" => "max_restart_count"}
        )

      assert event.outcome == :error
      assert event.outcome_details["reason"] == "policy_violation"
    end
  end

  describe "correlation tracking" do
    test "multiple events can share correlation_id" do
      corr_id = "corr_shared_123"

      event1 =
        AuditEvent.new(
          organization_id: "org_123",
          cluster_id: "cluster_456",
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "proposal.created",
          target: %{"type" => "proposal", "id" => "prop_1"},
          outcome: :ok,
          correlation_id: corr_id
        )

      event2 =
        AuditEvent.new(
          organization_id: "org_123",
          cluster_id: "cluster_456",
          actor_type: :operator,
          actor_sub: "sub_123",
          event_type: "approval.granted",
          target: %{"type" => "proposal", "id" => "prop_1"},
          outcome: :ok,
          correlation_id: corr_id
        )

      assert event1.correlation_id == event2.correlation_id
      # But event_ids should be different
      assert event1.event_id != event2.event_id
    end
  end

  describe "organization scoping" do
    test "organization_id is always set and required" do
      # Required at creation
      event =
        AuditEvent.new(
          organization_id: "org_alpha",
          actor_type: :system,
          event_type: "test",
          target: %{},
          outcome: :ok
        )

      assert event.organization_id == "org_alpha"

      # Different organization produces different event
      event2 =
        AuditEvent.new(
          organization_id: "org_beta",
          actor_type: :system,
          event_type: "test",
          target: %{},
          outcome: :ok
        )

      assert event2.organization_id == "org_beta"
      assert event.organization_id != event2.organization_id
    end
  end
end

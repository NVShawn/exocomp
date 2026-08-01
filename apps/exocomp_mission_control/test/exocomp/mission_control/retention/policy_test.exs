# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.MissionControl.Retention.PolicyTest do
  use ExUnit.Case

  alias Exocomp.MissionControl.Retention.Policy

  describe "new/1" do
    test "creates a policy with default retention periods" do
      policy = Policy.new("org-123")

      assert policy.organization_id == "org-123"
      assert policy.status_history_days == 90
      assert policy.incidents_days == 365
      assert policy.conversations_days == 365
      assert policy.proposals_days == 365
      assert policy.audit_events_days == 365
      assert policy.webhook_events_days == 365
    end
  end

  describe "cutoff_timestamp/3" do
    test "calculates correct cutoff for status history" do
      policy = Policy.new("org-123")
      now = DateTime.utc_now()
      cutoff = Policy.cutoff_timestamp(policy, :status_history, now)

      # Cutoff should be 90 days ago
      expected = DateTime.add(now, -90, :day)
      # Allow 1 second tolerance for test execution time
      assert abs(DateTime.diff(cutoff, expected)) <= 1
    end

    test "calculates correct cutoff for incidents" do
      policy = Policy.new("org-123")
      now = DateTime.utc_now()
      cutoff = Policy.cutoff_timestamp(policy, :incidents, now)

      expected = DateTime.add(now, -365, :day)
      assert abs(DateTime.diff(cutoff, expected)) <= 1
    end

    test "calculates correct cutoff for conversations" do
      policy = Policy.new("org-123")
      now = DateTime.utc_now()
      cutoff = Policy.cutoff_timestamp(policy, :conversations, now)

      expected = DateTime.add(now, -365, :day)
      assert abs(DateTime.diff(cutoff, expected)) <= 1
    end

    test "calculates correct cutoff for all data types" do
      policy = Policy.new("org-123")
      now = DateTime.utc_now()

      for type <- Policy.data_types() do
        cutoff = Policy.cutoff_timestamp(policy, type, now)
        days = Policy.days_for_type(policy, type)
        expected = DateTime.add(now, -days, :day)
        assert abs(DateTime.diff(cutoff, expected)) <= 1
      end
    end
  end

  describe "days_for_type/2" do
    test "returns correct days for each type" do
      policy = Policy.new("org-123")

      assert Policy.days_for_type(policy, :status_history) == 90
      assert Policy.days_for_type(policy, :incidents) == 365
      assert Policy.days_for_type(policy, :conversations) == 365
      assert Policy.days_for_type(policy, :proposals) == 365
      assert Policy.days_for_type(policy, :audit_events) == 365
      assert Policy.days_for_type(policy, :webhook_events) == 365
    end

    test "supports custom retention periods" do
      policy = %{
        organization_id: "org-123",
        status_history_days: 60,
        incidents_days: 180,
        conversations_days: 180,
        proposals_days: 180,
        audit_events_days: 180,
        webhook_events_days: 180
      }

      assert Policy.days_for_type(policy, :status_history) == 60
      assert Policy.days_for_type(policy, :incidents) == 180
    end
  end

  describe "data_types/0" do
    test "returns all managed data types" do
      types = Policy.data_types()

      assert :status_history in types
      assert :incidents in types
      assert :conversations in types
      assert :proposals in types
      assert :audit_events in types
      assert :webhook_events in types
      assert length(types) == 6
    end
  end

  describe "cutoff boundary conditions" do
    test "handles edge case of zero retention (no data retained)" do
      policy = %{
        organization_id: "org-123",
        status_history_days: 0,
        incidents_days: 0,
        conversations_days: 0,
        proposals_days: 0,
        audit_events_days: 0,
        webhook_events_days: 0
      }

      now = DateTime.utc_now()
      cutoff = Policy.cutoff_timestamp(policy, :incidents, now)

      # With 0 days retention, cutoff should be now (or very close)
      assert abs(DateTime.diff(cutoff, now)) <= 1
    end

    test "handles very large retention periods" do
      policy = %{
        organization_id: "org-123",
        status_history_days: 3650,
        incidents_days: 3650,
        conversations_days: 3650,
        proposals_days: 3650,
        audit_events_days: 3650,
        webhook_events_days: 3650
      }

      now = DateTime.utc_now()
      cutoff = Policy.cutoff_timestamp(policy, :incidents, now)

      # 10 years ago
      expected = DateTime.add(now, -3650, :day)
      assert abs(DateTime.diff(cutoff, expected)) <= 1
    end

    test "cutoff is always in the past" do
      policy = Policy.new("org-123")
      now = DateTime.utc_now()

      for type <- Policy.data_types() do
        cutoff = Policy.cutoff_timestamp(policy, type, now)
        # Cutoff should be before now
        assert DateTime.compare(cutoff, now) == :lt
      end
    end
  end
end

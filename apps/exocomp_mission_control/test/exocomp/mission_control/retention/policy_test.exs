# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.MissionControl.Retention.PolicyTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Retention.Policy

  describe "new/1" do
    test "creates a policy with default values" do
      assert {:ok, policy} = Policy.new("org-123")
      assert policy.org_id == "org-123"
      assert policy.status_history_days == 90
      assert policy.incident_days == 365
      assert policy.audit_days == 365
      assert policy.min_status_history_days == 1
      assert policy.max_status_history_days == 3650
      assert is_struct(policy.updated_at, DateTime)
    end

    test "rejects empty org_id" do
      assert {:error, msg} = Policy.new("")
      assert msg =~ "invalid org_id"
    end

    test "rejects non-binary org_id" do
      assert {:error, msg} = Policy.new(nil)
      assert msg =~ "invalid org_id"
    end
  end

  describe "with_retention/2" do
    test "creates a policy with custom retention days" do
      assert {:ok, policy} =
               Policy.with_retention("org-123",
                 status_history_days: 60,
                 incident_days: 180
               )

      assert policy.org_id == "org-123"
      assert policy.status_history_days == 60
      assert policy.incident_days == 180
      assert policy.audit_days == 365
    end

    test "uses defaults for unspecified retention days" do
      assert {:ok, policy} = Policy.with_retention("org-123", status_history_days: 60)
      assert policy.status_history_days == 60
      assert policy.incident_days == 365
      assert policy.audit_days == 365
    end

    test "rejects status_history_days outside bounds" do
      assert {:error, msg} =
               Policy.with_retention("org-123", status_history_days: 10_000)

      assert msg =~ "status_history_days"
    end

    test "rejects incident_days outside bounds" do
      assert {:error, msg} =
               Policy.with_retention("org-123", incident_days: 10_000)

      assert msg =~ "incident_days"
    end

    test "accepts min bound for status_history_days" do
      assert {:ok, policy} = Policy.with_retention("org-123", status_history_days: 1)
      assert policy.status_history_days == 1
    end

    test "accepts max bound for status_history_days" do
      assert {:ok, policy} = Policy.with_retention("org-123", status_history_days: 3650)
      assert policy.status_history_days == 3650
    end
  end

  describe "with_bounds/2" do
    setup do
      {:ok, policy} = Policy.new("org-123")
      {:ok, base_policy: policy}
    end

    test "updates bounds", %{base_policy: policy} do
      assert {:ok, updated} =
               Policy.with_bounds(policy,
                 min_status_history_days: 7,
                 max_status_history_days: 180
               )

      assert updated.min_status_history_days == 7
      assert updated.max_status_history_days == 180
      # Current retention (90) should still be valid
      assert updated.status_history_days == 90
    end

    test "rejects bounds where min > max", %{base_policy: policy} do
      assert {:error, msg} =
               Policy.with_bounds(policy,
                 min_status_history_days: 100,
                 max_status_history_days: 50
               )

      assert msg =~ "min must be <= max"
    end

    test "validates that current retention fits within new bounds", %{base_policy: _policy} do
      # Set policy to 90 days
      assert {:ok, updated} = Policy.with_retention("org-123", status_history_days: 90)

      # Try to set bounds that don't include 90
      assert {:error, msg} =
               Policy.with_bounds(updated,
                 min_status_history_days: 100,
                 max_status_history_days: 200
               )

      assert msg =~ "status_history_days"
    end

    test "allows updating retention and bounds together" do
      assert {:ok, policy} =
               Policy.with_retention("org-123",
                 status_history_days: 60,
                 incident_days: 180
               )

      assert {:ok, updated} =
               Policy.with_bounds(policy,
                 min_status_history_days: 30,
                 max_status_history_days: 90
               )

      assert updated.status_history_days == 60
      assert updated.min_status_history_days == 30
      assert updated.max_status_history_days == 90
    end
  end

  describe "validate/1" do
    test "accepts a valid policy" do
      assert {:ok, policy} = Policy.new("org-123")
      assert {:ok, ^policy} = Policy.validate(policy)
    end

    test "rejects policy with zero status_history_days" do
      assert {:ok, policy} = Policy.new("org-123")
      invalid = %{policy | status_history_days: 0}
      assert {:error, msg} = Policy.validate(invalid)
      assert msg =~ "retention days must be a positive integer"
    end

    test "rejects policy with negative incident_days" do
      assert {:ok, policy} = Policy.new("org-123")
      invalid = %{policy | incident_days: -1}
      assert {:error, msg} = Policy.validate(invalid)
      assert msg =~ "retention days must be a positive integer"
    end

    test "rejects policy where retention exceeds max bound" do
      assert {:ok, policy} = Policy.new("org-123")
      invalid = %{policy | status_history_days: 4000}
      assert {:error, msg} = Policy.validate(invalid)
      assert msg =~ "status_history_days must be between"
    end

    test "rejects policy where retention is below min bound" do
      assert {:ok, policy} = Policy.new("org-123")
      invalid = %{policy | status_history_days: 0}
      assert {:error, msg} = Policy.validate(invalid)
      assert msg =~ "retention days must be a positive integer"
    end

    test "rejects policy with invalid bounds (min > max)" do
      assert {:ok, policy} = Policy.new("org-123")
      invalid = %{policy | min_status_history_days: 100, max_status_history_days: 50}
      assert {:error, msg} = Policy.validate(invalid)
      assert msg =~ "min must be <= max"
    end
  end

  describe "cutoff_datetime/2" do
    test "calculates correct cutoff for status history" do
      now = DateTime.utc_now()
      assert {:ok, policy} = Policy.new("org-123")

      cutoff = Policy.cutoff_datetime(policy, :status_history)

      # Cutoff should be approximately 90 days ago (within 1 day tolerance for test execution time)
      days_diff =
        DateTime.diff(now, cutoff, :second)
        |> Kernel.div(86400)

      assert days_diff in [89, 90, 91]
    end

    test "calculates correct cutoff for incidents" do
      now = DateTime.utc_now()
      assert {:ok, policy} = Policy.new("org-123")

      cutoff = Policy.cutoff_datetime(policy, :incident)

      # Cutoff should be approximately 365 days ago (within 1 day tolerance)
      days_diff =
        DateTime.diff(now, cutoff, :second)
        |> Kernel.div(86400)

      assert days_diff in [364, 365, 366]
    end

    test "calculates correct cutoff with custom retention" do
      now = DateTime.utc_now()
      assert {:ok, policy} = Policy.with_retention("org-123", status_history_days: 30)

      cutoff = Policy.cutoff_datetime(policy, :status_history)

      # Cutoff should be approximately 30 days ago (within 1 day tolerance)
      days_diff =
        DateTime.diff(now, cutoff, :second)
        |> Kernel.div(86400)

      assert days_diff in [29, 30, 31]
    end

    test "cutoff is always in the past" do
      assert {:ok, policy} = Policy.new("org-123")
      cutoff = Policy.cutoff_datetime(policy, :status_history)
      now = DateTime.utc_now()

      assert DateTime.compare(cutoff, now) == :lt
    end
  end

  describe "retention field consistency" do
    test "status_history_days default is 90" do
      assert {:ok, policy} = Policy.new("org-123")
      assert policy.status_history_days == 90
    end

    test "incident_days default is 365" do
      assert {:ok, policy} = Policy.new("org-123")
      assert policy.incident_days == 365
    end

    test "audit_days default is 365" do
      assert {:ok, policy} = Policy.new("org-123")
      assert policy.audit_days == 365
    end
  end

  describe "organization scoping" do
    test "each organization has independent retention settings" do
      assert {:ok, policy1} = Policy.new("org-1")
      assert {:ok, policy2} = Policy.new("org-2")

      assert policy1.org_id == "org-1"
      assert policy2.org_id == "org-2"

      # Modify policy1
      assert {:ok, modified1} =
               Policy.with_retention("org-1", status_history_days: 60)

      # policy2 should be unaffected
      assert modified1.status_history_days == 60
      assert policy2.status_history_days == 90
    end
  end
end

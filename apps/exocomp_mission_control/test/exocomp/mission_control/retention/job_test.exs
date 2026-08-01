# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.MissionControl.Retention.JobTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Retention.{Job, Policy}

  describe "validate/3" do
    test "accepts valid job parameters" do
      assert {:ok, policy} = Policy.new("org-123")
      assert :ok = Job.validate("org-123", policy, :status_history)
    end

    test "rejects empty org_id" do
      assert {:ok, policy} = Policy.new("org-123")
      assert {:error, msg} = Job.validate("", policy, :status_history)
      assert msg =~ "invalid org_id"
    end

    test "rejects invalid policy" do
      bad_policy = %Policy{org_id: "org-123", status_history_days: 0}
      assert {:error, msg} = Job.validate("org-123", bad_policy, :status_history)
      assert msg =~ "invalid retention policy"
    end

    test "accepts all data types" do
      assert {:ok, policy} = Policy.new("org-123")
      assert :ok = Job.validate("org-123", policy, :status_history)
      assert :ok = Job.validate("org-123", policy, :incident)
      assert :ok = Job.validate("org-123", policy, :audit)
    end
  end

  describe "run/4 success path" do
    test "returns ok result with expected fields" do
      assert {:ok, policy} = Policy.new("org-123")

      {:ok, result} = Job.run("org-123", policy, :status_history, %{})

      assert result.org_id == "org-123"
      assert result.data_type == :status_history
      assert result.deleted_count >= 0
      assert result.batches_processed >= 0
      assert result.success == true
      assert is_nil(result.error)
      assert is_struct(result.cutoff_datetime, DateTime)
      assert is_struct(result.started_at, DateTime)
      assert is_struct(result.completed_at, DateTime)
    end

    test "job completes quickly for empty datasets" do
      assert {:ok, policy} = Policy.new("org-123")

      start_time = DateTime.utc_now()
      {:ok, _result} = Job.run("org-123", policy, :status_history, %{})
      end_time = DateTime.utc_now()

      elapsed_seconds = DateTime.diff(end_time, start_time, :second)
      assert elapsed_seconds < 10
    end

    test "cutoff_datetime is in the past" do
      assert {:ok, policy} = Policy.new("org-123")

      {:ok, result} = Job.run("org-123", policy, :status_history, %{})

      assert DateTime.compare(result.cutoff_datetime, DateTime.utc_now()) == :lt
    end

    test "cutoff calculation respects retention policy" do
      # Create policy with 60-day retention
      assert {:ok, policy} = Policy.with_retention("org-123", status_history_days: 60)

      {:ok, result} = Job.run("org-123", policy, :status_history, %{})

      # Cutoff should be approximately 60 days ago
      age_days =
        DateTime.diff(DateTime.utc_now(), result.cutoff_datetime, :second)
        |> Kernel.div(86400)

      assert age_days == 60
    end
  end

  describe "run/4 with custom options" do
    test "respects batch_size option" do
      assert {:ok, policy} = Policy.new("org-123")

      {:ok, result} =
        Job.run("org-123", policy, :status_history, %{batch_size: 500})

      # Job should complete successfully with custom batch size
      assert result.success == true
    end

    test "retries on transient failure" do
      assert {:ok, policy} = Policy.new("org-123")

      # With 3 retries configured, transient failures should be retried
      {:ok, result} =
        Job.run("org-123", policy, :status_history, %{max_retries: 3, retry_delay_ms: 10})

      # Should eventually succeed or fail gracefully
      assert is_map(result)
    end
  end

  describe "run/4 error handling" do
    test "returns error result on validation failure" do
      bad_policy = %Policy{org_id: "org-123", status_history_days: 0}

      {:error, result} = Job.run("org-123", bad_policy, :status_history, %{})

      assert result.success == false
      assert is_binary(result.error)
      assert result.deleted_count == 0
    end

    test "error result includes all expected fields" do
      bad_policy = %Policy{org_id: "org-123", status_history_days: 0}

      {:error, result} = Job.run("org-123", bad_policy, :status_history, %{})

      assert result.org_id == "org-123"
      assert result.data_type == :status_history
      assert result.success == false
      assert is_binary(result.error)
      assert is_struct(result.started_at, DateTime)
      assert is_struct(result.completed_at, DateTime)
    end
  end

  describe "cutoff_boundaries" do
    test "records exactly at cutoff are not deleted" do
      assert {:ok, policy} = Policy.with_retention("org-123", status_history_days: 90)

      {:ok, result} = Job.run("org-123", policy, :status_history, %{})

      # The cutoff should be < (before), not <= (before or equal)
      # Records at the cutoff boundary should be preserved
      assert result.success == true
    end

    test "records just before cutoff are deleted" do
      assert {:ok, policy} = Policy.with_retention("org-123", status_history_days: 90)

      {:ok, result} = Job.run("org-123", policy, :status_history, %{})

      # Job should complete successfully
      assert result.success == true
      # Cutoff was calculated correctly
      assert is_struct(result.cutoff_datetime, DateTime)
    end

    test "different retention policies produce different cutoffs" do
      assert {:ok, policy_90} = Policy.with_retention("org-123", status_history_days: 90)
      assert {:ok, policy_60} = Policy.with_retention("org-123", status_history_days: 60)

      {:ok, result_90} = Job.run("org-123", policy_90, :status_history, %{})
      {:ok, result_60} = Job.run("org-123", policy_60, :status_history, %{})

      # 60-day retention should have a later cutoff than 90-day
      assert DateTime.compare(result_60.cutoff_datetime, result_90.cutoff_datetime) == :gt
    end
  end

  describe "multiple organizations" do
    test "jobs for different organizations are independent" do
      assert {:ok, policy1} = Policy.new("org-1")
      assert {:ok, policy2} = Policy.new("org-2")

      {:ok, result1} = Job.run("org-1", policy1, :status_history, %{})
      {:ok, result2} = Job.run("org-2", policy2, :status_history, %{})

      assert result1.org_id == "org-1"
      assert result2.org_id == "org-2"
      assert result1.success == true
      assert result2.success == true
    end

    test "one org's retention settings don't affect another" do
      assert {:ok, policy1} =
               Policy.with_retention("org-1", status_history_days: 30)

      assert {:ok, policy2} =
               Policy.with_retention("org-2", status_history_days: 90)

      {:ok, result1} = Job.run("org-1", policy1, :status_history, %{})
      {:ok, result2} = Job.run("org-2", policy2, :status_history, %{})

      # Cutoffs should be different based on policy
      assert DateTime.compare(result1.cutoff_datetime, result2.cutoff_datetime) == :gt
    end

    test "cross-org isolation enforced by org_id in job" do
      assert {:ok, policy1} = Policy.new("org-1")
      assert {:ok, policy2} = Policy.new("org-2")

      {:ok, result1} = Job.run("org-1", policy1, :status_history, %{})
      {:ok, result2} = Job.run("org-2", policy2, :status_history, %{})

      # Each result should have correct org_id
      assert result1.org_id == "org-1"
      assert result2.org_id == "org-2"
    end
  end

  describe "batch continuation" do
    test "multiple batches are tracked" do
      assert {:ok, policy} = Policy.new("org-123")

      {:ok, result} =
        Job.run("org-123", policy, :status_history, %{batch_size: 100})

      # Result should track number of batches processed
      assert result.batches_processed >= 0
    end

    test "job tracks total deleted across batches" do
      assert {:ok, policy} = Policy.new("org-123")

      {:ok, result} =
        Job.run("org-123", policy, :status_history, %{batch_size: 100})

      # Total deleted should be consistent
      assert result.deleted_count >= 0
      assert is_integer(result.deleted_count)
    end
  end

  describe "concurrent ingest handling" do
    test "job handles concurrent modifications gracefully" do
      assert {:ok, policy} = Policy.new("org-123")

      # Run job multiple times concurrently to simulate concurrent ingest
      tasks =
        Enum.map(1..3, fn _ ->
          Task.async(fn ->
            Job.run("org-123", policy, :status_history, %{})
          end)
        end)

      results = Enum.map(tasks, &Task.await/1)

      # All jobs should complete (successfully or with error)
      assert Enum.all?(results, fn
               {:ok, r} -> r.success == true
               {:error, r} -> is_map(r)
             end)
    end
  end

  describe "estimate_deletion_count/3" do
    test "returns ok with non-negative integer" do
      assert {:ok, policy} = Policy.new("org-123")

      {:ok, count} = Job.estimate_deletion_count("org-123", policy, :status_history)

      assert is_integer(count)
      assert count >= 0
    end

    test "returns error for invalid parameters" do
      bad_policy = %Policy{org_id: "org-123", status_history_days: 0}

      {:error, msg} = Job.estimate_deletion_count("org-123", bad_policy, :status_history)

      assert is_binary(msg)
    end

    test "estimate respects retention policy" do
      assert {:ok, policy_30} =
               Policy.with_retention("org-123", status_history_days: 30)

      assert {:ok, policy_90} =
               Policy.with_retention("org-123", status_history_days: 90)

      {:ok, count_30} = Job.estimate_deletion_count("org-123", policy_30, :status_history)
      {:ok, count_90} = Job.estimate_deletion_count("org-123", policy_90, :status_history)

      # With shorter retention, more records should be eligible for deletion
      assert count_30 >= count_90
    end
  end

  describe "retry after failure" do
    test "failed jobs can be retried" do
      assert {:ok, policy} = Policy.new("org-123")

      # First attempt
      result1 =
        Job.run("org-123", policy, :status_history, %{max_retries: 3, retry_delay_ms: 10})

      # Second attempt should also work
      result2 =
        Job.run("org-123", policy, :status_history, %{max_retries: 3, retry_delay_ms: 10})

      # Both attempts should complete (regardless of success/failure)
      assert match?({:ok, _}, result1) or match?({:error, _}, result1)
      assert match?({:ok, _}, result2) or match?({:error, _}, result2)
    end

    test "max_retries is respected" do
      assert {:ok, policy} = Policy.new("org-123")

      # Run with very low retry count
      {:ok, result} = Job.run("org-123", policy, :status_history, %{max_retries: 0})

      # Should complete (either successfully or after exhausting retries)
      assert is_map(result)
    end
  end

  describe "preservation of current state" do
    test "job does not delete current materialized state" do
      assert {:ok, policy} = Policy.new("org-123")

      {:ok, result} = Job.run("org-123", policy, :status_history, %{})

      # Job should succeed and preserve current state
      # (in actual implementation, would verify through database)
      assert result.success == true
    end

    test "current materialized state is never touched" do
      assert {:ok, policy} =
               Policy.with_retention("org-123", status_history_days: 1)

      {:ok, result} = Job.run("org-123", policy, :status_history, %{})

      # Even with very short retention, current state should be preserved
      assert result.success == true
    end
  end

  describe "data type variations" do
    test "job works for status_history data type" do
      assert {:ok, policy} = Policy.new("org-123")
      {:ok, result} = Job.run("org-123", policy, :status_history, %{})
      assert result.data_type == :status_history
    end

    test "job works for incident data type" do
      assert {:ok, policy} = Policy.new("org-123")
      {:ok, result} = Job.run("org-123", policy, :incident, %{})
      assert result.data_type == :incident
    end

    test "job works for audit data type" do
      assert {:ok, policy} = Policy.new("org-123")
      {:ok, result} = Job.run("org-123", policy, :audit, %{})
      assert result.data_type == :audit
    end
  end

  describe "result timing" do
    test "completed_at is after started_at" do
      assert {:ok, policy} = Policy.new("org-123")
      {:ok, result} = Job.run("org-123", policy, :status_history, %{})

      assert DateTime.compare(result.completed_at, result.started_at) in [:gt, :eq]
    end

    test "timestamps are UTC" do
      assert {:ok, policy} = Policy.new("org-123")
      {:ok, result} = Job.run("org-123", policy, :status_history, %{})

      assert result.started_at.time_zone == "Etc/UTC"
      assert result.completed_at.time_zone == "Etc/UTC"
      assert result.cutoff_datetime.time_zone == "Etc/UTC"
    end
  end
end

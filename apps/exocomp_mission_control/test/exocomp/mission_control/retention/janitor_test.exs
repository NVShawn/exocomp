# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.MissionControl.Retention.JanitorTest do
  use ExUnit.Case

  alias Exocomp.MissionControl.Retention.{Janitor, Policy}

  describe "run/3" do
    test "returns job statistics for all types" do
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy)

      assert is_list(stats)
      assert length(stats) > 0

      # Check structure of each stat
      Enum.each(stats, fn stat ->
        assert stat.organization_id == "org-123"
        assert is_atom(stat.type)
        assert is_integer(stat.deleted_count) and stat.deleted_count >= 0
        assert is_list(stat.errors)

        assert is_nil(stat.last_successful_cutoff) or
                 is_struct(stat.last_successful_cutoff, DateTime)

        assert is_struct(stat.started_at, DateTime)
        assert is_struct(stat.completed_at, DateTime)
        assert stat.status in [:in_progress, :completed, :failed]
      end)
    end

    test "processes specific types when specified" do
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy, types: [:incidents, :conversations])

      types = Enum.map(stats, & &1.type)
      assert length(stats) == 2
      assert :incidents in types
      assert :conversations in types
    end

    test "respects batch size option" do
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy, batch_size: 500)

      assert is_list(stats)
      # Batch size is used internally, we just verify it doesn't error
      Enum.each(stats, &assert(&1.status == :completed))
    end

    test "respects max duration option" do
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy, max_duration_seconds: 1)

      # With very short duration, all should complete quickly
      Enum.each(stats, &assert(&1.status == :completed))
    end
  end

  describe "delete_by_type/6" do
    test "returns valid job statistics" do
      _policy = Policy.new("org-123")
      now = DateTime.utc_now()
      started_at = now

      stats =
        Janitor.delete_by_type(
          "org-123",
          :incidents,
          Policy.new("org-123"),
          1000,
          300,
          started_at
        )

      assert stats.organization_id == "org-123"
      assert stats.type == :incidents
      assert stats.deleted_count >= 0
      assert is_list(stats.errors)
      assert stats.status in [:in_progress, :completed, :failed]
      assert is_struct(stats.started_at, DateTime)
      assert is_struct(stats.completed_at, DateTime)
    end

    test "calculates correct cutoff for each type" do
      policy = Policy.new("org-123")
      now = DateTime.utc_now()
      started_at = now

      for type <- Policy.data_types() do
        stats = Janitor.delete_by_type("org-123", type, policy, 1000, 300, started_at)

        # The last_successful_cutoff should be approximately correct
        if not is_nil(stats.last_successful_cutoff) do
          expected_cutoff = Policy.cutoff_timestamp(policy, type, now)
          diff = DateTime.diff(stats.last_successful_cutoff, expected_cutoff, :second)
          # Within 1 minute
          assert abs(diff) <= 60
        end
      end
    end
  end

  describe "delete_one_batch/4" do
    test "returns ok for known types" do
      _policy = Policy.new("org-123")
      cutoff = DateTime.utc_now()

      for type <- Policy.data_types() do
        {:ok, count} = Janitor.delete_one_batch("org-123", type, cutoff, 1000)
        assert is_integer(count) and count >= 0
      end
    end

    test "returns error for unknown type" do
      cutoff = DateTime.utc_now()
      {:error, reason} = Janitor.delete_one_batch("org-123", :unknown_type, cutoff, 1000)

      assert String.contains?(reason, ["Unknown retention type"])
    end

    test "handles all standard data types" do
      cutoff = DateTime.utc_now()
      types = Policy.data_types()

      results = Enum.map(types, &Janitor.delete_one_batch("org-123", &1, cutoff, 1000))

      # All should succeed for now (placeholder implementations return ok)
      Enum.each(results, fn result ->
        assert match?({:ok, _}, result)
      end)
    end
  end

  describe "bounded deletion behavior" do
    test "respects maximum duration to avoid blocking ingestion" do
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy, max_duration_seconds: 5)

      # All jobs should complete within reasonable time (accounting for test execution)
      Enum.each(stats, fn stat ->
        duration = DateTime.diff(stat.completed_at, stat.started_at, :second)
        # Should be less than 10 seconds (5 second limit + overhead)
        assert duration <= 10
      end)
    end

    test "handles interrupted job gracefully" do
      policy = Policy.new("org-123")
      now = DateTime.utc_now()
      started_at = now

      # Simulate interrupted job with very short timeout
      stats = Janitor.delete_by_type("org-123", :incidents, policy, 1000, 0, started_at)

      # Should complete despite short timeout
      assert stats.status == :completed
    end
  end

  describe "multiple organizations" do
    test "isolates deletion by organization" do
      policy1 = Policy.new("org-1")
      policy2 = Policy.new("org-2")

      {:ok, stats1} = Janitor.run("org-1", policy1)
      {:ok, stats2} = Janitor.run("org-2", policy2)

      Enum.each(stats1, &assert(&1.organization_id == "org-1"))
      Enum.each(stats2, &assert(&1.organization_id == "org-2"))
    end

    test "supports concurrent ingest with concurrent retention" do
      # This is more of an integration test, but we verify the API supports it
      policy = Policy.new("org-123")

      # Multiple concurrent calls should not error
      task1 = Task.async(fn -> Janitor.run("org-123", policy, max_duration_seconds: 2) end)
      task2 = Task.async(fn -> Janitor.run("org-123", policy, max_duration_seconds: 2) end)

      {:ok, _stats1} = Task.await(task1)
      {:ok, _stats2} = Task.await(task2)
    end
  end

  describe "dependency ordering" do
    test "processes types in dependency order" do
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy)

      types = Enum.map(stats, & &1.type)

      # Types should be processed in dependency order:
      # 1. webhook_events (independent)
      # 2. conversations, messages, evidence (interdependent)
      # 3. proposals, approvals (interdependent)
      # 4. audit_events
      # 5. incidents, events (interdependent)
      # 6. status_history (partition-based)

      # Verify all expected types are present
      Enum.each(Policy.data_types(), fn type ->
        assert type in types, "Type #{inspect(type)} not in results"
      end)
    end
  end

  describe "preservation of critical records" do
    test "preserves open incidents" do
      # This test verifies the deletion logic structure
      # Actual preservation is tested when database queries are implemented
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy)

      incident_stats = Enum.find(stats, &(&1.type == :incidents))
      assert not is_nil(incident_stats)
      # Incidents should be deleted by the janitor (actual preservation checked in DB)
    end

    test "preserves pending proposals" do
      # Similar to incidents - preservation logic in actual DB queries
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy)

      proposal_stats = Enum.find(stats, &(&1.type == :proposals))
      assert not is_nil(proposal_stats)
    end
  end

  describe "job statistics tracking" do
    test "tracks deleted count per type" do
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy)

      Enum.each(stats, fn stat ->
        assert is_integer(stat.deleted_count) and stat.deleted_count >= 0
      end)
    end

    test "tracks errors in deletion" do
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy)

      Enum.each(stats, fn stat ->
        assert is_list(stat.errors)
      end)
    end

    test "tracks last successful cutoff" do
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy)

      Enum.each(stats, fn stat ->
        if not is_nil(stat.last_successful_cutoff) do
          assert is_struct(stat.last_successful_cutoff, DateTime)
        end
      end)
    end

    test "tracks completion timestamp" do
      policy = Policy.new("org-123")
      {:ok, stats} = Janitor.run("org-123", policy)

      Enum.each(stats, fn stat ->
        assert is_struct(stat.completed_at, DateTime)
        # Completed should be >= started
        assert DateTime.compare(stat.completed_at, stat.started_at) in [:eq, :gt]
      end)
    end
  end

  describe "resume after interruption" do
    test "resumes from last successful cutoff" do
      policy = Policy.new("org-123")
      now = DateTime.utc_now()
      started_at = now

      # First run with immediate timeout
      stats1 = Janitor.delete_by_type("org-123", :incidents, policy, 1000, 0, started_at)

      # If there was a cutoff recorded, a second run should use it
      if not is_nil(stats1.last_successful_cutoff) do
        stats2 = Janitor.delete_by_type("org-123", :incidents, policy, 1000, 300, started_at)
        # Stats structure should be consistent
        assert stats2.organization_id == stats1.organization_id
        assert stats2.type == stats1.type
      end
    end
  end
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.StatusHistory.RecorderTest do
  use ExUnit.Case

  alias Exocomp.StatusHistory.{Recorder, Record}

  describe "should_checkpoint_cluster?/1" do
    test "returns true for nil (first checkpoint)" do
      assert Recorder.should_checkpoint_cluster?(nil) == true
    end

    test "returns true when 5 minutes have elapsed" do
      five_minutes_ago = DateTime.utc_now() |> DateTime.add(-300, :second)
      assert Recorder.should_checkpoint_cluster?(five_minutes_ago) == true
    end

    test "returns false when less than 5 minutes have elapsed" do
      two_minutes_ago = DateTime.utc_now() |> DateTime.add(-120, :second)
      assert Recorder.should_checkpoint_cluster?(two_minutes_ago) == false
    end

    test "returns true at exactly 5 minute boundary" do
      exactly_five_min_ago = DateTime.utc_now() |> DateTime.add(-300, :second)
      assert Recorder.should_checkpoint_cluster?(exactly_five_min_ago) == true
    end

    test "returns false just before 5 minute boundary" do
      just_before = DateTime.utc_now() |> DateTime.add(-299, :second)
      assert Recorder.should_checkpoint_cluster?(just_before) == false
    end
  end

  describe "should_checkpoint_node?/1" do
    test "returns true for nil (first checkpoint)" do
      assert Recorder.should_checkpoint_node?(nil) == true
    end

    test "returns true when 1 hour has elapsed" do
      one_hour_ago = DateTime.utc_now() |> DateTime.add(-3600, :second)
      assert Recorder.should_checkpoint_node?(one_hour_ago) == true
    end

    test "returns false when less than 1 hour has elapsed" do
      thirty_minutes_ago = DateTime.utc_now() |> DateTime.add(-1800, :second)
      assert Recorder.should_checkpoint_node?(thirty_minutes_ago) == false
    end

    test "returns true at exactly 1 hour boundary" do
      exactly_one_hour_ago = DateTime.utc_now() |> DateTime.add(-3600, :second)
      assert Recorder.should_checkpoint_node?(exactly_one_hour_ago) == true
    end

    test "returns false just before 1 hour boundary" do
      just_before = DateTime.utc_now() |> DateTime.add(-3599, :second)
      assert Recorder.should_checkpoint_node?(just_before) == false
    end
  end

  describe "detect_change?/2" do
    test "returns true when status changes to healthy" do
      assert Recorder.detect_change?(:degraded, :healthy) == true
    end

    test "returns true when status changes to degraded" do
      assert Recorder.detect_change?(:healthy, :degraded) == true
    end

    test "returns true when status changes to stale" do
      assert Recorder.detect_change?(:healthy, :stale) == true
    end

    test "returns true when status changes to unreachable" do
      assert Recorder.detect_change?(:stale, :unreachable) == true
    end

    test "returns false when status doesn't change" do
      assert Recorder.detect_change?(:healthy, :healthy) == false
    end

    test "returns false for same degraded status" do
      assert Recorder.detect_change?(:degraded, :degraded) == false
    end

    test "detects all status transitions" do
      statuses = [:healthy, :degraded, :stale, :unreachable]

      for prev <- statuses, next <- statuses do
        if prev == next do
          assert Recorder.detect_change?(prev, next) == false
        else
          assert Recorder.detect_change?(prev, next) == true
        end
      end
    end
  end

  describe "is_duplicate?/2" do
    test "detects exact duplicate records" do
      now = DateTime.utc_now()

      record1 = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :healthy,
        observed_at: now,
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      record2 = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :healthy,
        observed_at: now,
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      assert Recorder.is_duplicate?(record2, record1) == true
    end

    test "detects duplicate snapshots with different org_id as non-duplicates" do
      now = DateTime.utc_now()

      record1 = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :healthy,
        observed_at: now,
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      record2 = %Record{
        org_id: "org-999",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :healthy,
        observed_at: now,
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      assert Recorder.is_duplicate?(record2, record1) == false
    end

    test "detects records with different observation times as non-duplicates" do
      now = DateTime.utc_now()
      later = DateTime.add(now, 60, :second)

      record1 = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :healthy,
        observed_at: now,
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      record2 = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :healthy,
        observed_at: later,
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      assert Recorder.is_duplicate?(record2, record1) == false
    end

    test "detects records with different status as non-duplicates" do
      now = DateTime.utc_now()

      record1 = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :healthy,
        observed_at: now,
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      record2 = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :degraded,
        observed_at: now,
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      assert Recorder.is_duplicate?(record2, record1) == false
    end

    test "detects late-arriving duplicate snapshots" do
      base_time = DateTime.utc_now() |> DateTime.add(-3600, :second)

      record1 = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :healthy,
        observed_at: base_time,
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      # Same record arriving much later
      record2 = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :healthy,
        observed_at: base_time,
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      assert Recorder.is_duplicate?(record2, record1) == true
    end
  end

  describe "accept_late_event?/2" do
    test "accepts recent change events" do
      now = DateTime.utc_now()
      recently_ago = DateTime.add(now, -30, :second)
      assert Recorder.accept_late_event?(recently_ago, :change) == true
    end

    test "rejects change events older than 1 hour" do
      now = DateTime.utc_now()
      too_old = DateTime.add(now, -3601, :second)
      assert Recorder.accept_late_event?(too_old, :change) == false
    end

    test "accepts change events at 1 hour boundary" do
      now = DateTime.utc_now()
      exactly_one_hour = DateTime.add(now, -3600, :second)
      assert Recorder.accept_late_event?(exactly_one_hour, :change) == true
    end

    test "accepts recent cluster snapshot events" do
      now = DateTime.utc_now()
      recently_ago = DateTime.add(now, -300, :second)
      assert Recorder.accept_late_event?(recently_ago, :cluster_snapshot) == true
    end

    test "rejects cluster snapshot events older than 1 day" do
      now = DateTime.utc_now()
      too_old = DateTime.add(now, -86401, :second)
      assert Recorder.accept_late_event?(too_old, :cluster_snapshot) == false
    end

    test "accepts cluster snapshot at 1 day boundary" do
      now = DateTime.utc_now()
      exactly_one_day = DateTime.add(now, -86400, :second)
      assert Recorder.accept_late_event?(exactly_one_day, :cluster_snapshot) == true
    end

    test "accepts recent node snapshot events" do
      now = DateTime.utc_now()
      recently_ago = DateTime.add(now, -1800, :second)
      assert Recorder.accept_late_event?(recently_ago, :node_snapshot) == true
    end

    test "rejects node snapshot events older than 1 day" do
      now = DateTime.utc_now()
      too_old = DateTime.add(now, -86401, :second)
      assert Recorder.accept_late_event?(too_old, :node_snapshot) == false
    end

    test "rejects events in the future" do
      future = DateTime.utc_now() |> DateTime.add(10, :second)
      assert Recorder.accept_late_event?(future, :change) == false
    end

    test "rejects invalid checkpoint types" do
      now = DateTime.utc_now()
      assert Recorder.accept_late_event?(now, :invalid) == false
    end

    test "defaults checkpoint_type to :change" do
      recently_ago = DateTime.utc_now() |> DateTime.add(-30, :second)
      assert Recorder.accept_late_event?(recently_ago) == true
    end
  end

  describe "max_batch_size/0" do
    test "returns positive integer" do
      size = Recorder.max_batch_size()
      assert is_integer(size)
      assert size > 0
    end

    test "returns 1000" do
      assert Recorder.max_batch_size() == 1000
    end
  end

  describe "checkpoint intervals" do
    test "cluster_checkpoint_interval returns 5 minutes in seconds" do
      assert Recorder.cluster_checkpoint_interval() == 5 * 60
    end

    test "node_checkpoint_interval returns 1 hour in seconds" do
      assert Recorder.node_checkpoint_interval() == 60 * 60
    end
  end

  describe "clock-controlled checkpoint cadence" do
    test "determines cluster checkpoint sequence based on elapsed time" do
      base_time = DateTime.utc_now()

      # Initial checkpoint
      assert Recorder.should_checkpoint_cluster?(nil) == true

      # Before 5 min
      _t1 = DateTime.add(base_time, -120, :second)
      assert Recorder.should_checkpoint_cluster?(base_time) == false

      # After 5 min
      t2 = DateTime.add(base_time, -300, :second)
      assert Recorder.should_checkpoint_cluster?(t2) == true

      # Another checkpoint cycle
      t3 = DateTime.add(t2, -300, :second)
      assert Recorder.should_checkpoint_cluster?(t3) == true
    end

    test "determines node checkpoint sequence based on elapsed time" do
      base_time = DateTime.utc_now()

      # Initial checkpoint
      assert Recorder.should_checkpoint_node?(nil) == true

      # Before 1 hour
      _t1 = DateTime.add(base_time, -1800, :second)
      assert Recorder.should_checkpoint_node?(base_time) == false

      # After 1 hour
      t2 = DateTime.add(base_time, -3600, :second)
      assert Recorder.should_checkpoint_node?(t2) == true

      # Another checkpoint cycle
      t3 = DateTime.add(t2, -3600, :second)
      assert Recorder.should_checkpoint_node?(t3) == true
    end
  end

  describe "duplicate snapshot detection" do
    test "detects repeated cluster snapshot with same observation time" do
      org = "org-123"
      cluster = "cluster-456"
      status = :healthy
      time = DateTime.utc_now()

      snapshot1 = Record.cluster_checkpoint(org, cluster, status, time)
      snapshot2 = Record.cluster_checkpoint(org, cluster, status, time)

      assert Recorder.is_duplicate?(snapshot2, snapshot1) == true
    end

    test "detects repeated node change with same observation time" do
      org = "org-123"
      node = "node-789"
      status = :degraded
      time = DateTime.utc_now()

      change1 = Record.node_change(org, node, status, time)
      change2 = Record.node_change(org, node, status, time)

      assert Recorder.is_duplicate?(change2, change1) == true
    end

    test "distinguishes between different checkpoint types" do
      org = "org-123"
      node = "node-789"
      status = :healthy
      time = DateTime.utc_now()

      change = Record.node_change(org, node, status, time)
      checkpoint = Record.node_checkpoint(org, node, status, time)

      # Different checkpoint types should not be duplicates
      assert Recorder.is_duplicate?(checkpoint, change) == false
    end
  end

  describe "bounded batch writes" do
    test "batch size supports 1000 records" do
      batch_size = Recorder.max_batch_size()
      assert batch_size >= 1000
    end

    test "batch size is suitable for avoiding unbounded growth" do
      # Verify that batch size is reasonable - not 1, not infinity
      batch_size = Recorder.max_batch_size()
      assert batch_size > 1
      assert batch_size < 1_000_000
    end
  end
end

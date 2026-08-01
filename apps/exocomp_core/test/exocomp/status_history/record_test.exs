# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.StatusHistory.RecordTest do
  use ExUnit.Case

  alias Exocomp.StatusHistory.Record

  describe "cluster_checkpoint/5" do
    test "creates a record with cluster type and snapshot checkpoint type" do
      org_id = "org-123"
      cluster_id = "cluster-456"
      status = :healthy
      observed_at = DateTime.utc_now()
      metadata = %{"version" => "1.0.0"}

      record = Record.cluster_checkpoint(org_id, cluster_id, status, observed_at, metadata)

      assert record.org_id == org_id
      assert record.source_id == cluster_id
      assert record.source_type == :cluster
      assert record.status == status
      assert record.observed_at == observed_at
      assert record.checkpoint_type == :cluster_snapshot
      assert record.metadata == metadata
      assert is_struct(record.recorded_at, DateTime)
    end

    test "defaults metadata to empty map" do
      record = Record.cluster_checkpoint("org", "cluster", :healthy, DateTime.utc_now())
      assert record.metadata == %{}
    end
  end

  describe "node_change/5" do
    test "creates a record with node type and change checkpoint type" do
      org_id = "org-123"
      node_id = "node-789"
      status = :degraded
      observed_at = DateTime.utc_now()
      metadata = %{"reason" => "high_memory"}

      record = Record.node_change(org_id, node_id, status, observed_at, metadata)

      assert record.org_id == org_id
      assert record.source_id == node_id
      assert record.source_type == :node
      assert record.status == status
      assert record.observed_at == observed_at
      assert record.checkpoint_type == :change
      assert record.metadata == metadata
    end
  end

  describe "node_checkpoint/5" do
    test "creates a record with node type and node_snapshot checkpoint type" do
      org_id = "org-123"
      node_id = "node-789"
      status = :stale
      observed_at = DateTime.utc_now()
      metadata = %{"consecutive_missed" => 3}

      record = Record.node_checkpoint(org_id, node_id, status, observed_at, metadata)

      assert record.org_id == org_id
      assert record.source_id == node_id
      assert record.source_type == :node
      assert record.status == status
      assert record.checkpoint_type == :node_snapshot
      assert record.metadata == metadata
    end
  end

  describe "validate/1" do
    test "accepts valid record" do
      record = Record.cluster_checkpoint("org-123", "cluster-456", :healthy, DateTime.utc_now())
      assert {:ok, ^record} = Record.validate(record)
    end

    test "rejects missing org_id" do
      record = Record.cluster_checkpoint("", "cluster-456", :healthy, DateTime.utc_now())
      assert {:error, "invalid org_id"} = Record.validate(record)
    end

    test "rejects missing source_id" do
      record = Record.cluster_checkpoint("org-123", "", :healthy, DateTime.utc_now())
      assert {:error, "invalid source_id"} = Record.validate(record)
    end

    test "rejects invalid source_type" do
      record = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :invalid,
        status: :healthy,
        observed_at: DateTime.utc_now(),
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      assert {:error, "invalid source_type"} = Record.validate(record)
    end

    test "rejects invalid status" do
      record = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :invalid,
        observed_at: DateTime.utc_now(),
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      assert {:error, "invalid status"} = Record.validate(record)
    end

    test "rejects invalid checkpoint_type" do
      record = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :healthy,
        observed_at: DateTime.utc_now(),
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :invalid
      }

      assert {:error, "invalid checkpoint_type"} = Record.validate(record)
    end

    test "rejects missing observed_at" do
      record = %Record{
        org_id: "org-123",
        source_id: "cluster-456",
        source_type: :cluster,
        status: :healthy,
        observed_at: nil,
        recorded_at: DateTime.utc_now(),
        checkpoint_type: :cluster_snapshot
      }

      assert {:error, "invalid timestamps"} = Record.validate(record)
    end

    test "preserves observation time separately from ingestion time" do
      org_id = "org-123"
      cluster_id = "cluster-456"
      observed_at = DateTime.utc_now() |> DateTime.add(-600, :second)

      record = Record.cluster_checkpoint(org_id, cluster_id, :healthy, observed_at)

      # Observation time should be preserved as given
      assert record.observed_at == observed_at

      # Recorded time should be current
      assert DateTime.diff(record.recorded_at, DateTime.utc_now(), :second) < 5
    end

    test "all valid statuses pass validation" do
      for status <- [:healthy, :degraded, :stale, :unreachable] do
        record = Record.cluster_checkpoint("org", "cluster", status, DateTime.utc_now())
        assert {:ok, _} = Record.validate(record)
      end
    end

    test "all valid checkpoint types pass validation" do
      for checkpoint_type <- [:change, :cluster_snapshot, :node_snapshot] do
        record = %Record{
          org_id: "org-123",
          source_id: "source-456",
          source_type: :cluster,
          status: :healthy,
          observed_at: DateTime.utc_now(),
          recorded_at: DateTime.utc_now(),
          checkpoint_type: checkpoint_type
        }

        assert {:ok, _} = Record.validate(record)
      end
    end
  end
end

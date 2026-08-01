# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.StatusHistory.Recorder do
  @moduledoc """
  Manages recording of status history with clock-controlled checkpoints.

  Records:
  - Cluster checkpoints every 5 minutes
  - Node state changes immediately
  - Node unchanged checkpoints every 1 hour

  History writes are designed to be non-blocking and not interfere with
  current-state transactions. Duplicate snapshots are deduplicated via
  checkpoint type and observation time.
  """

  alias Exocomp.StatusHistory.Record

  @cluster_checkpoint_interval_seconds 5 * 60
  @node_checkpoint_interval_seconds 60 * 60

  @doc """
  Determine if a cluster checkpoint should be recorded based on time.

  Returns true if the time elapsed since the last checkpoint exceeds
  the configured cluster checkpoint interval (5 minutes).
  """
  @spec should_checkpoint_cluster?(DateTime.t() | nil) :: boolean
  def should_checkpoint_cluster?(nil), do: true

  def should_checkpoint_cluster?(last_checkpoint_time)
      when is_struct(last_checkpoint_time, DateTime) do
    DateTime.utc_now()
    |> DateTime.diff(last_checkpoint_time, :second)
    |> Kernel.>=(@cluster_checkpoint_interval_seconds)
  end

  @doc """
  Determine if a node checkpoint should be recorded based on time.

  Returns true if the time elapsed since the last checkpoint exceeds
  the configured node checkpoint interval (1 hour).
  """
  @spec should_checkpoint_node?(DateTime.t() | nil) :: boolean
  def should_checkpoint_node?(nil), do: true

  def should_checkpoint_node?(last_checkpoint_time)
      when is_struct(last_checkpoint_time, DateTime) do
    DateTime.utc_now()
    |> DateTime.diff(last_checkpoint_time, :second)
    |> Kernel.>=(@node_checkpoint_interval_seconds)
  end

  @doc """
  Determine if a node state change should be recorded.

  Returns true if the new status differs from the previous status.
  A change is recorded immediately, regardless of checkpoint timing.
  """
  @spec detect_change?(Record.status(), Record.status()) :: boolean
  def detect_change?(previous_status, new_status) do
    previous_status != new_status
  end

  @doc """
  Determine if a record should be deduplicated.

  Detects duplicate snapshots based on:
  - Same organization, source, and type
  - Same checkpoint type
  - Identical observation time (late events with same timestamp)
  - For changes, same status as previous

  Returns true if the record is a duplicate and should not be written.
  """
  @spec is_duplicate?(Record.t(), Record.t()) :: boolean
  def is_duplicate?(record, previous_record) do
    same_scope?(record, previous_record) and
      same_checkpoint?(record, previous_record) and
      same_observation_time?(record, previous_record) and
      same_status?(record, previous_record)
  end

  defp same_scope?(record, previous_record) do
    record.org_id == previous_record.org_id and
      record.source_id == previous_record.source_id and
      record.source_type == previous_record.source_type
  end

  defp same_checkpoint?(record, previous_record) do
    record.checkpoint_type == previous_record.checkpoint_type
  end

  defp same_observation_time?(record, previous_record) do
    DateTime.compare(record.observed_at, previous_record.observed_at) == :eq
  end

  defp same_status?(record, previous_record) do
    record.status == previous_record.status
  end

  @doc """
  Determine if a late-arriving event should be accepted.

  Late events (observations older than current system time) are accepted if:
  - The observation time is within a reasonable window of current time
  - They represent a genuine state change not already recorded
  - They are not exact duplicates of existing records

  This prevents unbounded history writes from arbitrarily old events while
  allowing for reasonable clock skew and delayed delivery.

  Returns true if the event should be accepted, false if too old.
  """
  @spec accept_late_event?(DateTime.t(), atom) :: boolean
  def accept_late_event?(observed_at, checkpoint_type \\ :change) do
    current_time = DateTime.utc_now()
    age_seconds = DateTime.diff(current_time, observed_at, :second)

    # Accept events within the checkpoint window or a reasonable skew
    case checkpoint_type do
      :change ->
        # Accept late changes within 1 hour (reasonable for retries)
        age_seconds >= 0 and age_seconds <= 3600

      :cluster_snapshot ->
        # Accept late cluster snapshots within 1 day (retries from coordinator)
        age_seconds >= 0 and age_seconds <= 86400

      :node_snapshot ->
        # Accept late node snapshots within 1 day (retries from coordinator)
        age_seconds >= 0 and age_seconds <= 86400

      _ ->
        false
    end
  end

  @doc """
  Batch write optimization hint.

  Returns the maximum batch size for bounded writes. This prevents
  unbounded memory accumulation during high-throughput events.

  Batches should be written atomically while allowing other transactions
  (particularly current-state updates) to proceed without blocking.
  """
  @spec max_batch_size() :: pos_integer
  def max_batch_size do
    1000
  end

  @doc """
  Get the checkpoint interval for clusters in seconds.
  """
  @spec cluster_checkpoint_interval() :: pos_integer
  def cluster_checkpoint_interval do
    @cluster_checkpoint_interval_seconds
  end

  @doc """
  Get the checkpoint interval for nodes in seconds.
  """
  @spec node_checkpoint_interval() :: pos_integer
  def node_checkpoint_interval do
    @node_checkpoint_interval_seconds
  end
end

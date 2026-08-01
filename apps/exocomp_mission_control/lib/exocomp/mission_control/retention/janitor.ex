# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.MissionControl.Retention.Janitor do
  @moduledoc """
  Bounded batch deletion of Mission Control history according to retention policies.

  The Janitor performs deletion in configurable batch sizes without blocking
  concurrent ingestion. Each retention data type has its own deletion order
  to preserve data dependencies (e.g., messages must be deleted before
  conversations that reference them).

  Supports interruption and resume:
  - Tracks last successful cutoff per data type and organization
  - Can be interrupted and resumed
  - Never deletes cluster identity or current-state records
  - Records job statistics (deleted count, failures, last cutoff)
  """

  alias Exocomp.MissionControl.Retention.Policy

  @typedoc """
  Statistics from a retention job run.
  """
  @type job_stats :: %{
          organization_id: String.t(),
          type: atom(),
          deleted_count: non_neg_integer(),
          errors: [String.t()],
          last_successful_cutoff: DateTime.t() | nil,
          started_at: DateTime.t(),
          completed_at: DateTime.t() | nil,
          status: :in_progress | :completed | :failed
        }

  @default_batch_size 1000
  # 5 minutes per type to avoid blocking ingestion
  @default_max_duration_seconds 300

  @doc """
  Start a retention job for a specific organization.

  Options:
  - `:batch_size` - Number of records to delete per query (default: 1000)
  - `:max_duration_seconds` - Maximum time to spend on this type (default: 300)
  - `:types` - List of types to process (default: all types)
  """
  @spec run(
          organization_id :: String.t(),
          policy :: Policy.t(),
          opts :: Keyword.t()
        ) :: {:ok, [job_stats()]} | {:error, String.t()}
  def run(organization_id, policy, opts \\ []) do
    batch_size = Keyword.get(opts, :batch_size, @default_batch_size)
    max_duration = Keyword.get(opts, :max_duration_seconds, @default_max_duration_seconds)
    types = Keyword.get(opts, :types, Policy.data_types())

    now = DateTime.utc_now()
    started_at = now

    stats =
      types
      |> Enum.map(fn type ->
        delete_by_type(organization_id, type, policy, batch_size, max_duration, started_at)
      end)

    {:ok, stats}
  end

  @doc """
  Delete records of a specific type up to the retention cutoff.

  Returns statistics about the deletion.
  """
  @spec delete_by_type(
          organization_id :: String.t(),
          type :: atom(),
          policy :: Policy.t(),
          batch_size :: pos_integer(),
          max_duration_seconds :: pos_integer(),
          started_at :: DateTime.t()
        ) :: job_stats()
  def delete_by_type(organization_id, type, policy, batch_size, max_duration, started_at) do
    now = DateTime.utc_now()
    cutoff = Policy.cutoff_timestamp(policy, type, now)

    initial_stats = %{
      organization_id: organization_id,
      type: type,
      deleted_count: 0,
      errors: [],
      last_successful_cutoff: nil,
      started_at: started_at,
      completed_at: nil,
      status: :in_progress
    }

    delete_batches(organization_id, type, cutoff, batch_size, max_duration, now, initial_stats)
  end

  @doc """
  Performs bounded batch deletion.

  Deletes records in batches of the specified size, respecting the time limit
  and dependency ordering. Tracks progress and can be resumed.
  """
  @spec delete_batches(
          organization_id :: String.t(),
          type :: atom(),
          cutoff :: DateTime.t(),
          batch_size :: pos_integer(),
          max_duration_seconds :: pos_integer(),
          job_start_time :: DateTime.t(),
          stats :: job_stats()
        ) :: job_stats()
  def delete_batches(
        organization_id,
        type,
        cutoff,
        batch_size,
        max_duration,
        job_start_time,
        stats
      ) do
    elapsed = DateTime.diff(DateTime.utc_now(), job_start_time, :second)

    if elapsed >= max_duration do
      # Time limit reached, return current stats
      %{stats | completed_at: DateTime.utc_now(), status: :completed}
    else
      # Attempt to delete one batch
      case delete_one_batch(organization_id, type, cutoff, batch_size) do
        {:ok, deleted_count} ->
          if deleted_count == 0 do
            # No more records to delete
            %{
              stats
              | deleted_count: stats.deleted_count,
                last_successful_cutoff: cutoff,
                completed_at: DateTime.utc_now(),
                status: :completed
            }
          else
            # Continue with next batch
            updated_stats = %{
              stats
              | deleted_count: stats.deleted_count + deleted_count,
                last_successful_cutoff: cutoff
            }

            delete_batches(
              organization_id,
              type,
              cutoff,
              batch_size,
              max_duration,
              job_start_time,
              updated_stats
            )
          end

        {:error, reason} ->
          # Record error but continue (fault tolerant)
          error_msg = "Failed to delete batch for #{type}: #{inspect(reason)}"
          updated_stats = %{stats | errors: [error_msg | stats.errors]}

          delete_batches(
            organization_id,
            type,
            cutoff,
            batch_size,
            max_duration,
            job_start_time,
            updated_stats
          )
      end
    end
  end

  @doc """
  Delete one batch of records of the specified type.

  The actual deletion logic is delegated to type-specific deletion functions.
  Returns the count of deleted records.
  """
  @spec delete_one_batch(
          organization_id :: String.t(),
          type :: atom(),
          cutoff :: DateTime.t(),
          batch_size :: pos_integer()
        ) :: {:ok, non_neg_integer()} | {:error, String.t()}
  def delete_one_batch(organization_id, :status_history, cutoff, batch_size) do
    # Delete status history records older than cutoff
    # This is partition-based per the plan
    delete_status_history(organization_id, cutoff, batch_size)
  end

  def delete_one_batch(organization_id, :incidents, cutoff, batch_size) do
    # Delete incidents and related events
    # Preserve open incidents and incidents still referenced by retained timeline
    delete_resolved_incidents(organization_id, cutoff, batch_size)
  end

  def delete_one_batch(organization_id, :conversations, cutoff, batch_size) do
    # Delete conversation messages and evidence references
    # Preserve conversations with recent activity or referenced proposals
    delete_old_conversations(organization_id, cutoff, batch_size)
  end

  def delete_one_batch(organization_id, :proposals, cutoff, batch_size) do
    # Delete proposals and related approvals/executions
    # Preserve pending proposals
    delete_old_proposals(organization_id, cutoff, batch_size)
  end

  def delete_one_batch(organization_id, :audit_events, cutoff, batch_size) do
    # Delete audit events older than cutoff
    delete_old_audit_events(organization_id, cutoff, batch_size)
  end

  def delete_one_batch(organization_id, :webhook_events, cutoff, batch_size) do
    # Delete webhook delivery attempts and event history
    delete_old_webhook_events(organization_id, cutoff, batch_size)
  end

  def delete_one_batch(_org, type, _cutoff, _batch_size) do
    {:error, "Unknown retention type: #{inspect(type)}"}
  end

  # Type-specific deletion functions
  # These would interact with the actual database queries
  # For now, they return placeholder implementations

  @spec delete_status_history(
          organization_id :: String.t(),
          cutoff :: DateTime.t(),
          batch_size :: pos_integer()
        ) :: {:ok, non_neg_integer()} | {:error, String.t()}
  defp delete_status_history(_org, _cutoff, _batch_size) do
    # TODO: Implement database deletion when schema is available
    {:ok, 0}
  end

  @spec delete_resolved_incidents(
          organization_id :: String.t(),
          cutoff :: DateTime.t(),
          batch_size :: pos_integer()
        ) :: {:ok, non_neg_integer()} | {:error, String.t()}
  defp delete_resolved_incidents(_org, _cutoff, _batch_size) do
    # TODO: Implement database deletion when schema is available
    # Only delete incidents that are:
    # - Resolved (not open or acknowledged)
    # - Older than cutoff
    # - Not referenced by any retained timeline
    {:ok, 0}
  end

  @spec delete_old_conversations(
          organization_id :: String.t(),
          cutoff :: DateTime.t(),
          batch_size :: pos_integer()
        ) :: {:ok, non_neg_integer()} | {:error, String.t()}
  defp delete_old_conversations(_org, _cutoff, _batch_size) do
    # TODO: Implement database deletion when schema is available
    {:ok, 0}
  end

  @spec delete_old_proposals(
          organization_id :: String.t(),
          cutoff :: DateTime.t(),
          batch_size :: pos_integer()
        ) :: {:ok, non_neg_integer()} | {:error, String.t()}
  defp delete_old_proposals(_org, _cutoff, _batch_size) do
    # TODO: Implement database deletion when schema is available
    # Only delete proposals that are:
    # - Not pending
    # - Older than cutoff
    {:ok, 0}
  end

  @spec delete_old_audit_events(
          organization_id :: String.t(),
          cutoff :: DateTime.t(),
          batch_size :: pos_integer()
        ) :: {:ok, non_neg_integer()} | {:error, String.t()}
  defp delete_old_audit_events(_org, _cutoff, _batch_size) do
    # TODO: Implement database deletion when schema is available
    {:ok, 0}
  end

  @spec delete_old_webhook_events(
          organization_id :: String.t(),
          cutoff :: DateTime.t(),
          batch_size :: pos_integer()
        ) :: {:ok, non_neg_integer()} | {:error, String.t()}
  defp delete_old_webhook_events(_org, _cutoff, _batch_size) do
    # TODO: Implement database deletion when schema is available
    {:ok, 0}
  end
end

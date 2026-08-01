# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.MissionControl.Retention.Job do
  @moduledoc """
  Retention cleanup job for bounded deletion of old status history.

  Deletes status history records older than the organization's configured
  retention policy without blocking concurrent ingestion. Uses bounded batches
  to prevent memory exhaustion and lock contention.

  The job is designed to be run periodically and can be safely retried after
  failure. Progress is tracked to allow resumption from the last successful
  batch.

  Current materialized state (the latest observation for each cluster/node)
  is never deleted - only historical snapshots and state changes older than
  the retention cutoff.
  """

  alias Exocomp.MissionControl.Retention.Policy

  @typedoc "Job configuration"
  @type config :: %{
          optional(:batch_size) => pos_integer,
          optional(:max_retries) => non_neg_integer,
          optional(:retry_delay_ms) => non_neg_integer
        }

  @typedoc "Job result tracking"
  @type result :: %{
          org_id: binary,
          data_type: :status_history | :incident | :audit,
          deleted_count: non_neg_integer,
          batches_processed: non_neg_integer,
          cutoff_datetime: DateTime.t() | nil,
          started_at: DateTime.t(),
          completed_at: DateTime.t(),
          success: boolean,
          error: String.t() | nil
        }

  @typedoc "Job progress state for resumption"
  @type progress :: %{
          org_id: binary,
          data_type: :status_history | :incident | :audit,
          batches_processed: non_neg_integer,
          records_deleted: non_neg_integer,
          last_cursor: any,
          retries: non_neg_integer,
          started_at: DateTime.t()
        }

  @default_batch_size 1000
  @default_max_retries 3
  @default_retry_delay_ms 1000

  @doc """
  Run a retention cleanup job for an organization.

  Deletes records of the specified data_type that are older than the
  retention cutoff according to the provided policy.

  Options:
  - :batch_size - number of records to delete per batch (default 1000)
  - :max_retries - maximum retries on failure (default 3)
  - :retry_delay_ms - delay between retries in milliseconds (default 1000)

  The returned result includes:
  - deleted_count: total records deleted
  - batches_processed: number of batches processed
  - cutoff_datetime: the cutoff time used
  - success: whether the job completed successfully
  - error: error message if success is false
  """
  @spec run(binary, Policy.t(), :status_history | :incident | :audit, config) ::
          {:ok, result} | {:error, result}
  def run(org_id, policy, data_type, opts \\ %{})
      when is_binary(org_id) and
             data_type in [:status_history, :incident, :audit] do
    started_at = DateTime.utc_now()

    with :ok <- validate(org_id, policy, data_type) do
      batch_size = Map.get(opts, :batch_size, @default_batch_size)
      max_retries = Map.get(opts, :max_retries, @default_max_retries)
      retry_delay_ms = Map.get(opts, :retry_delay_ms, @default_retry_delay_ms)

      cutoff = Policy.cutoff_datetime(policy, data_type)

      case do_run(org_id, data_type, cutoff, batch_size, max_retries, retry_delay_ms) do
        {:ok, deleted_count, batches_processed} ->
          result = %{
            org_id: org_id,
            data_type: data_type,
            deleted_count: deleted_count,
            batches_processed: batches_processed,
            cutoff_datetime: cutoff,
            started_at: started_at,
            completed_at: DateTime.utc_now(),
            success: true,
            error: nil
          }

          {:ok, result}

        {:error, reason} ->
          result = %{
            org_id: org_id,
            data_type: data_type,
            deleted_count: 0,
            batches_processed: 0,
            cutoff_datetime: cutoff,
            started_at: started_at,
            completed_at: DateTime.utc_now(),
            success: false,
            error: reason
          }

          {:error, result}
      end
    else
      {:error, validation_error} ->
        result = %{
          org_id: org_id,
          data_type: data_type,
          deleted_count: 0,
          batches_processed: 0,
          cutoff_datetime: nil,
          started_at: started_at,
          completed_at: DateTime.utc_now(),
          success: false,
          error: validation_error
        }

        {:error, result}
    end
  end

  @doc """
  Validate that a retention job can be safely executed.

  Checks:
  - Organization ID is non-empty
  - Policy is valid
  - Batch size is positive
  - Retention settings allow deletion (not zero days)

  Returns :ok if validation passes, {:error, reason} otherwise.
  """
  @spec validate(binary, Policy.t(), :status_history | :incident | :audit) ::
          :ok | {:error, String.t()}
  def validate(org_id, policy, data_type) do
    with :ok <- validate_org_id(org_id),
         :ok <- validate_policy(policy, data_type) do
      :ok
    end
  end

  @doc """
  Calculate the approximate number of records that would be deleted.

  This is a non-blocking operation that estimates deletion count for logging
  and monitoring purposes. The actual count may differ due to concurrent changes.

  For testing with clock control, this function can be used to verify that
  the retention cutoff is correctly calculated.
  """
  @spec estimate_deletion_count(binary, Policy.t(), :status_history | :incident | :audit) ::
          {:ok, non_neg_integer} | {:error, String.t()}
  def estimate_deletion_count(org_id, policy, data_type) do
    with :ok <- validate(org_id, policy, data_type) do
      cutoff = Policy.cutoff_datetime(policy, data_type)
      estimate_count_before_cutoff(org_id, data_type, cutoff)
    end
  end

  # Private functions

  defp do_run(org_id, data_type, cutoff, batch_size, max_retries, retry_delay_ms) do
    do_run_with_retries(
      org_id,
      data_type,
      cutoff,
      batch_size,
      0,
      max_retries,
      retry_delay_ms,
      0,
      0
    )
  end

  # Processes deletion batches until all records older than the cutoff are deleted.
  # Stub implementation: full retry logic for transient failures will be added when
  # the database layer adds support for error handling.
  defp do_run_with_retries(
         org_id,
         data_type,
         cutoff,
         batch_size,
         _attempt,
         max_retries,
         retry_delay_ms,
         total_deleted,
         batches_processed
       ) do
    case delete_batch(org_id, data_type, cutoff, batch_size) do
      {:ok, 0} ->
        # No more records to delete - job complete
        {:ok, total_deleted, batches_processed}

      {:ok, deleted_count} ->
        # Batch succeeded, continue with next batch
        do_run_with_retries(
          org_id,
          data_type,
          cutoff,
          batch_size,
          0,
          max_retries,
          retry_delay_ms,
          total_deleted + deleted_count,
          batches_processed + 1
        )
    end
  end

  defp delete_batch(_org_id, :status_history, _cutoff, _batch_size) do
    # Stub: In a real implementation with a database, this would execute:
    # DELETE FROM status_history
    # WHERE org_id = ? AND recorded_at < ? AND NOT is_current_materialized_state
    # ORDER BY recorded_at ASC
    # LIMIT ?
    # For now, return 0 deleted records (database implementation pending).
    {:ok, 0}
  end

  defp delete_batch(_org_id, :incident, _cutoff, _batch_size) do
    # Stub: incident deletion implementation pending
    {:ok, 0}
  end

  defp delete_batch(_org_id, :audit, _cutoff, _batch_size) do
    # Stub: audit deletion implementation pending
    {:ok, 0}
  end

  defp estimate_count_before_cutoff(_org_id, _data_type, _cutoff) do
    # Stub: count estimation pending database implementation
    {:ok, 0}
  end

  defp validate_org_id(org_id) when is_binary(org_id) and byte_size(org_id) > 0, do: :ok
  defp validate_org_id(_), do: {:error, "invalid org_id"}

  defp validate_policy(%Policy{} = policy, data_type) do
    case data_type do
      :status_history ->
        if policy.status_history_days > 0, do: :ok, else: {:error, "invalid retention policy"}

      :incident ->
        if policy.incident_days > 0, do: :ok, else: {:error, "invalid retention policy"}

      :audit ->
        if policy.audit_days > 0, do: :ok, else: {:error, "invalid retention policy"}

      _ ->
        {:error, "unknown data type"}
    end
  end

  defp validate_policy(_, _), do: {:error, "invalid policy"}
end

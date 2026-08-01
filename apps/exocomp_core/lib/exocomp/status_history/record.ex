# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.StatusHistory.Record do
  @moduledoc """
  Data structures for status history recording.

  Status history records preserve both observation time (when the state was observed)
  and ingestion time (when it was recorded), enabling accurate historical analysis
  and time-partitioned storage.
  """

  @typedoc "Organization identifier for scoping history"
  @type org_id :: binary

  @typedoc "Source identity (cluster or node)"
  @type source_id :: binary

  @typedoc "Source type: :cluster or :node"
  @type source_type :: :cluster | :node

  @typedoc "Current operational status of the resource"
  @type status :: :healthy | :degraded | :stale | :unreachable

  @typedoc """
  A single status history record.

  Fields:
  - org_id: organization scoping boundary
  - source_id: cluster or node identifier
  - source_type: :cluster or :node
  - status: current health status
  - observed_at: timestamp when status was observed (NOT when recorded)
  - recorded_at: timestamp when this record was written (for partitioning)
  - checkpoint_type: :change (state changed), :cluster_snapshot (5min), or :node_snapshot (1hr)
  - metadata: optional additional data (version, capabilities, etc.)
  """
  @type t :: %__MODULE__{
          org_id: org_id,
          source_id: source_id,
          source_type: source_type,
          status: status,
          observed_at: DateTime.t(),
          recorded_at: DateTime.t(),
          checkpoint_type: :change | :cluster_snapshot | :node_snapshot,
          metadata: map
        }

  defstruct [
    :org_id,
    :source_id,
    :source_type,
    :status,
    :observed_at,
    :recorded_at,
    :checkpoint_type,
    metadata: %{}
  ]

  @doc """
  Create a new status history record for a cluster checkpoint.

  This records a cluster status snapshot every 5 minutes, preserving
  both when the status was observed and when it was recorded.
  """
  @spec cluster_checkpoint(org_id, source_id, status, DateTime.t(), map) :: t
  def cluster_checkpoint(org_id, cluster_id, status, observed_at, metadata \\ %{}) do
    %__MODULE__{
      org_id: org_id,
      source_id: cluster_id,
      source_type: :cluster,
      status: status,
      observed_at: observed_at,
      recorded_at: DateTime.utc_now(),
      checkpoint_type: :cluster_snapshot,
      metadata: metadata
    }
  end

  @doc """
  Create a new status history record for a node state change.

  This is recorded immediately when a node's state changes, with
  exact observation and ingestion timestamps.
  """
  @spec node_change(org_id, source_id, status, DateTime.t(), map) :: t
  def node_change(org_id, node_id, status, observed_at, metadata \\ %{}) do
    %__MODULE__{
      org_id: org_id,
      source_id: node_id,
      source_type: :node,
      status: status,
      observed_at: observed_at,
      recorded_at: DateTime.utc_now(),
      checkpoint_type: :change,
      metadata: metadata
    }
  end

  @doc """
  Create a new status history record for a node unchanged checkpoint.

  This is recorded hourly for nodes whose status hasn't changed,
  confirming they remain in the same state.
  """
  @spec node_checkpoint(org_id, source_id, status, DateTime.t(), map) :: t
  def node_checkpoint(org_id, node_id, status, observed_at, metadata \\ %{}) do
    %__MODULE__{
      org_id: org_id,
      source_id: node_id,
      source_type: :node,
      status: status,
      observed_at: observed_at,
      recorded_at: DateTime.utc_now(),
      checkpoint_type: :node_snapshot,
      metadata: metadata
    }
  end

  @doc """
  Validate a status history record.

  Ensures required fields are present and have valid values.
  """
  @spec validate(t) :: {:ok, t} | {:error, String.t()}
  def validate(%__MODULE__{} = record) do
    with :ok <- validate_org_id(record.org_id),
         :ok <- validate_source_id(record.source_id),
         :ok <- validate_source_type(record.source_type),
         :ok <- validate_status(record.status),
         :ok <- validate_timestamps(record.observed_at, record.recorded_at),
         :ok <- validate_checkpoint_type(record.checkpoint_type) do
      {:ok, record}
    end
  end

  defp validate_org_id(org_id) when is_binary(org_id) and byte_size(org_id) > 0, do: :ok
  defp validate_org_id(_), do: {:error, "invalid org_id"}

  defp validate_source_id(source_id) when is_binary(source_id) and byte_size(source_id) > 0,
    do: :ok

  defp validate_source_id(_), do: {:error, "invalid source_id"}

  defp validate_source_type(type) when type in [:cluster, :node], do: :ok
  defp validate_source_type(_), do: {:error, "invalid source_type"}

  defp validate_status(status) when status in [:healthy, :degraded, :stale, :unreachable],
    do: :ok

  defp validate_status(_), do: {:error, "invalid status"}

  defp validate_timestamps(observed_at, recorded_at) do
    if is_struct(observed_at, DateTime) and is_struct(recorded_at, DateTime) do
      :ok
    else
      {:error, "invalid timestamps"}
    end
  end

  defp validate_checkpoint_type(type)
       when type in [:change, :cluster_snapshot, :node_snapshot],
       do: :ok

  defp validate_checkpoint_type(_), do: {:error, "invalid checkpoint_type"}
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ClusterCurrentState do
  @moduledoc """
  Organization-scoped current state for a single cluster.

  Persists:
  - connectivity: online/offline and last contact timestamp
  - health: current health status
  - versions: software version strings
  - capabilities: supported features
  - labels: operator-defined tags
  - node_count: count of managed nodes
  - observation_seq: sequence number for detecting stale updates

  The reducer accepts cluster.hello, cluster.heartbeat, and status.snapshot events
  and updates this state transactionally, rejecting stale snapshots based on
  sequence/observation ordering.
  """

  @typedoc """
  Current state for a cluster.

  Fields:
  - `organization_id`: organization scope (required for multi-tenancy)
  - `cluster_id`: unique cluster identifier
  - `connectivity`: `:online` or `:offline`
  - `last_contact_at`: most recent successful contact timestamp
  - `health`: `:healthy`, `:degraded`, `:stale`, or `:unreachable`
  - `software_version`: version string from cluster
  - `capabilities`: list of advertised capability strings
  - `labels`: map of operator-defined labels
  - `node_count`: current node count reported by cluster
  - `observation_seq`: sequence number from most recent observation (for stale detection)
  - `updated_at`: timestamp of last state change
  """
  @type t :: %__MODULE__{
          organization_id: String.t(),
          cluster_id: String.t(),
          connectivity: :online | :offline,
          last_contact_at: DateTime.t() | nil,
          health: :healthy | :degraded | :stale | :unreachable,
          software_version: String.t() | nil,
          capabilities: [String.t()],
          labels: map(),
          node_count: non_neg_integer(),
          observation_seq: non_neg_integer(),
          updated_at: DateTime.t()
        }

  defstruct [
    :organization_id,
    :cluster_id,
    :last_contact_at,
    :updated_at,
    connectivity: :offline,
    health: :unreachable,
    software_version: nil,
    capabilities: [],
    labels: %{},
    node_count: 0,
    observation_seq: 0
  ]

  @doc """
  Create a new cluster current state for the given organization and cluster.
  """
  @spec new(organization_id :: String.t(), cluster_id :: String.t()) :: t()
  def new(organization_id, cluster_id) do
    now = DateTime.utc_now()

    %__MODULE__{
      organization_id: organization_id,
      cluster_id: cluster_id,
      updated_at: now
    }
  end

  @doc """
  Mark cluster as online with updated metadata from hello event.

  Returns:
  - `{:ok, updated_state}` if the state was updated
  - `{:error, :stale}` if the event sequence is older than current state
  """
  @spec apply_hello(t(), event :: map()) :: {:ok, t()} | {:error, :stale}
  def apply_hello(%__MODULE__{} = state, event) when is_map(event) do
    seq = Map.get(event, "cluster_seq", 0)

    if seq < state.observation_seq do
      {:error, :stale}
    else
      now = DateTime.utc_now()

      {:ok,
       %__MODULE__{
         state
         | connectivity: :online,
           health: :healthy,
           last_contact_at: now,
           software_version: Map.get(event, "software_version"),
           capabilities: Map.get(event, "capabilities", []),
           labels: Map.get(event, "labels", %{}),
           node_count: Map.get(event, "node_count", 0),
           observation_seq: seq,
           updated_at: now
       }}
    end
  end

  @doc """
  Apply heartbeat event to update connectivity and last contact time.

  Returns:
  - `{:ok, updated_state}` if the state was updated
  - `{:error, :stale}` if the event sequence is older than current state
  """
  @spec apply_heartbeat(t(), event :: map()) :: {:ok, t()} | {:error, :stale}
  def apply_heartbeat(%__MODULE__{} = state, event) when is_map(event) do
    seq = Map.get(event, "cluster_seq", 0)

    if seq < state.observation_seq do
      {:error, :stale}
    else
      now = DateTime.utc_now()

      {:ok,
       %__MODULE__{
         state
         | connectivity: :online,
           last_contact_at: now,
           observation_seq: seq,
           updated_at: now
       }}
    end
  end

  @doc """
  Apply status snapshot to update cluster health and node information.

  Returns:
  - `{:ok, updated_state}` if the state was updated
  - `{:error, :stale}` if the event sequence is older than current state
  """
  @spec apply_status_snapshot(t(), event :: map()) :: {:ok, t()} | {:error, :stale}
  def apply_status_snapshot(%__MODULE__{} = state, event) when is_map(event) do
    seq = Map.get(event, "cluster_seq", 0)

    if seq < state.observation_seq do
      {:error, :stale}
    else
      now = DateTime.utc_now()
      health = infer_health_from_snapshot(event)

      {:ok,
       %__MODULE__{
         state
         | health: health,
           node_count: Map.get(event, "node_count", state.node_count),
           observation_seq: seq,
           updated_at: now
       }}
    end
  end

  defp infer_health_from_snapshot(event) do
    case Map.get(event, "status") do
      "healthy" -> :healthy
      "degraded" -> :degraded
      "stale" -> :stale
      "unreachable" -> :unreachable
      nil -> :unreachable
      _ -> :unreachable
    end
  end
end

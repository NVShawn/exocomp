# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.NodeCurrentState do
  @moduledoc """
  Organization-scoped current state for a single node.

  Persists:
  - connectivity: reachable/unreachable via cluster coordinator
  - health: current health status
  - versions: software version strings
  - capabilities: supported features
  - labels: operator-defined tags
  - last_contact: most recent observation timestamp
  - observation_seq: sequence number for detecting stale updates
  - retired: whether node has been removed from cluster

  The reducer updates this state when receiving node updates in status.snapshot
  events and detects node removal (tombstone) by absence in repeated snapshots.
  """

  @typedoc """
  Current state for a node.

  Fields:
  - `organization_id`: organization scope (required for multi-tenancy)
  - `cluster_id`: cluster containing this node
  - `node_id`: unique node identifier
  - `connectivity`: `:reachable` or `:unreachable`
  - `health`: `:healthy`, `:degraded`, `:stale`, or `:unreachable`
  - `software_version`: version string from node
  - `capabilities`: list of advertised capability strings
  - `labels`: map of operator-defined labels
  - `last_contact_at`: timestamp of most recent successful observation
  - `observation_seq`: sequence number from most recent observation (for stale detection)
  - `retired`: true if node removed from cluster (tombstone)
  - `updated_at`: timestamp of last state change
  """
  @type t :: %__MODULE__{
          organization_id: String.t(),
          cluster_id: String.t(),
          node_id: String.t(),
          connectivity: :reachable | :unreachable,
          health: :healthy | :degraded | :stale | :unreachable,
          software_version: String.t() | nil,
          capabilities: [String.t()],
          labels: map(),
          last_contact_at: DateTime.t() | nil,
          observation_seq: non_neg_integer(),
          retired: boolean(),
          updated_at: DateTime.t()
        }

  defstruct [
    :organization_id,
    :cluster_id,
    :node_id,
    :last_contact_at,
    :updated_at,
    connectivity: :unreachable,
    health: :unreachable,
    software_version: nil,
    capabilities: [],
    labels: %{},
    observation_seq: 0,
    retired: false
  ]

  @doc """
  Create a new node current state.
  """
  @spec new(
          organization_id :: String.t(),
          cluster_id :: String.t(),
          node_id :: String.t()
        ) :: t()
  def new(organization_id, cluster_id, node_id) do
    now = DateTime.utc_now()

    %__MODULE__{
      organization_id: organization_id,
      cluster_id: cluster_id,
      node_id: node_id,
      updated_at: now
    }
  end

  @doc """
  Update node state from snapshot.

  Returns:
  - `{:ok, updated_state}` if the state was updated
  - `{:error, :stale}` if the event sequence is older than current state
  """
  @spec apply_snapshot(t(), node_data :: map(), seq :: non_neg_integer()) ::
          {:ok, t()} | {:error, :stale}
  def apply_snapshot(%__MODULE__{} = state, node_data, seq)
      when is_map(node_data) and is_integer(seq) do
    if seq < state.observation_seq do
      {:error, :stale}
    else
      now = DateTime.utc_now()

      {:ok,
       %__MODULE__{
         state
         | connectivity: Map.get(node_data, "connectivity", :unreachable),
           health: Map.get(node_data, "health", :unreachable),
           software_version: Map.get(node_data, "software_version"),
           capabilities: Map.get(node_data, "capabilities", []),
           labels: Map.get(node_data, "labels", %{}),
           last_contact_at: now,
           observation_seq: seq,
           updated_at: now
       }}
    end
  end

  @doc """
  Mark node as retired (removed from cluster).

  This is typically called when a node no longer appears in status.snapshot
  events after appearing in previous snapshots (tombstone detection).
  """
  @spec retire(t()) :: t()
  def retire(%__MODULE__{} = state) do
    now = DateTime.utc_now()
    %__MODULE__{state | retired: true, connectivity: :unreachable, updated_at: now}
  end

  @doc """
  Check if node is retired (removed from cluster).
  """
  @spec retired?(t()) :: boolean()
  def retired?(%__MODULE__{} = state), do: state.retired
end

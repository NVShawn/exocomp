# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.CurrentStateReducer do
  @moduledoc """
  Transactional reducer for cluster and node current state.

  Processes cluster.hello, cluster.heartbeat, and status.snapshot events
  into materialized current views for clusters and nodes. Rejects stale
  updates using sequence numbers and handles:

  - Initial cluster/node state creation
  - Partial state updates from different event types
  - Stale snapshot rejection via observation sequence
  - Node removal detection (tombstoning)
  - Duplicate event idempotency
  - Organization-scoped isolation

  ## Event Processing

  - `cluster.hello`: Establishes initial cluster connection, sets versions/capabilities
  - `cluster.heartbeat`: Confirms cluster connectivity and resets timeout
  - `status.snapshot`: Reports cluster health, node counts, and full node state

  All updates are scoped to organization_id for tenant isolation.
  """

  alias Exocomp.MissionControl.ClusterCurrentState
  alias Exocomp.MissionControl.NodeCurrentState

  @typedoc """
  Current state store (in-memory during this phase, database in future phases).

  Keys:
  - `clusters`: map of {org_id, cluster_id} => ClusterCurrentState
  - `nodes`: map of {org_id, cluster_id, node_id} => NodeCurrentState
  - `processed_events`: set of event_ids (for duplicate detection)
  """
  @type store :: %{
          clusters: map(),
          nodes: map(),
          processed_events: MapSet.t()
        }

  @doc """
  Create an empty current state store.
  """
  @spec new_store() :: store()
  def new_store() do
    %{
      clusters: %{},
      nodes: %{},
      processed_events: MapSet.new()
    }
  end

  @doc """
  Process an event and update current state transactionally.

  Returns:
  - `{:ok, updated_store, :processed}` if event was new and processed
  - `{:ok, updated_store, :duplicate}` if event_id was already processed
  - `{:error, reason, store}` on failure (store unchanged)

  Supported event kinds:
  - `"cluster.hello"` - cluster connection established
  - `"cluster.heartbeat"` - cluster heartbeat (connection alive)
  - `"status.snapshot"` - full cluster and node state snapshot
  """
  @spec process_event(store(), event :: map(), organization_id :: String.t()) ::
          {:ok, store(), :processed | :duplicate}
          | {:error, atom(), store()}
  def process_event(store, event, organization_id)
      when is_map(event) and is_binary(organization_id) do
    event_id = Map.get(event, "event_id")
    kind = Map.get(event, "kind")

    # Duplicate detection
    if MapSet.member?(store.processed_events, event_id) do
      {:ok, store, :duplicate}
    else
      case kind do
        "cluster.hello" ->
          case process_cluster_hello(store, event, organization_id) do
            {:ok, updated_store} ->
              {:ok, mark_event_processed(updated_store, event_id), :processed}

            error ->
              error
          end

        "cluster.heartbeat" ->
          case process_cluster_heartbeat(store, event, organization_id) do
            {:ok, updated_store} ->
              {:ok, mark_event_processed(updated_store, event_id), :processed}

            error ->
              error
          end

        "status.snapshot" ->
          case process_status_snapshot(store, event, organization_id) do
            {:ok, updated_store} ->
              {:ok, mark_event_processed(updated_store, event_id), :processed}

            error ->
              error
          end

        _ ->
          {:error, :unknown_event_kind, store}
      end
    end
  end

  defp process_cluster_hello(store, event, organization_id) do
    cluster_id = Map.get(event, "cluster_id")

    if !cluster_id do
      {:error, :missing_cluster_id, store}
    else
      key = {organization_id, cluster_id}
      current = Map.get(store.clusters, key, ClusterCurrentState.new(organization_id, cluster_id))

      case ClusterCurrentState.apply_hello(current, Map.get(event, "payload", %{})) do
        {:ok, updated} ->
          {:ok, put_in(store.clusters[key], updated)}

        error ->
          error
      end
    end
  end

  defp process_cluster_heartbeat(store, event, organization_id) do
    cluster_id = Map.get(event, "cluster_id")

    if !cluster_id do
      {:error, :missing_cluster_id, store}
    else
      key = {organization_id, cluster_id}
      current = Map.get(store.clusters, key, ClusterCurrentState.new(organization_id, cluster_id))

      case ClusterCurrentState.apply_heartbeat(current, Map.get(event, "payload", %{})) do
        {:ok, updated} ->
          {:ok, put_in(store.clusters[key], updated)}

        error ->
          error
      end
    end
  end

  defp process_status_snapshot(store, event, organization_id) do
    cluster_id = Map.get(event, "cluster_id")
    seq = Map.get(event, "cluster_seq", 0)

    if !cluster_id do
      {:error, :missing_cluster_id, store}
    else
      payload = Map.get(event, "payload", %{})

      # Update cluster snapshot
      cluster_key = {organization_id, cluster_id}

      cluster =
        Map.get(store.clusters, cluster_key, ClusterCurrentState.new(organization_id, cluster_id))

      case ClusterCurrentState.apply_status_snapshot(
             cluster,
             Map.put(payload, "cluster_seq", seq)
           ) do
        {:ok, updated_cluster} ->
          store = put_in(store.clusters[cluster_key], updated_cluster)

          # Process nodes from snapshot
          nodes_data = Map.get(payload, "nodes", %{})
          store = process_snapshot_nodes(store, organization_id, cluster_id, nodes_data, seq)

          # Detect retired nodes (in previous snapshot but not in current one)
          store = detect_retired_nodes(store, organization_id, cluster_id, Map.keys(nodes_data))

          {:ok, store}

        error ->
          error
      end
    end
  end

  defp process_snapshot_nodes(store, organization_id, cluster_id, nodes_data, seq) do
    Enum.reduce(nodes_data, store, fn {node_id, node_data}, acc ->
      key = {organization_id, cluster_id, node_id}

      current =
        Map.get(acc.nodes, key, NodeCurrentState.new(organization_id, cluster_id, node_id))

      case NodeCurrentState.apply_snapshot(current, node_data, seq) do
        {:ok, updated} ->
          put_in(acc.nodes[key], updated)

        {:error, :stale} ->
          acc
      end
    end)
  end

  defp detect_retired_nodes(store, organization_id, cluster_id, current_node_ids) do
    # Find all nodes that were in previous snapshots but are not in current snapshot
    store.nodes
    |> Enum.filter(fn {{org, cluster, _node_id}, node} ->
      org == organization_id && cluster == cluster_id && !node.retired
    end)
    |> Enum.reduce(store, fn {{_org, _cluster, node_id}, _node}, acc ->
      if node_id not in current_node_ids do
        # Node was removed from cluster, mark as retired
        key = {organization_id, cluster_id, node_id}
        node_state = Map.get(acc.nodes, key)

        if node_state do
          retired_state = NodeCurrentState.retire(node_state)
          put_in(acc.nodes[key], retired_state)
        else
          acc
        end
      else
        acc
      end
    end)
  end

  defp mark_event_processed(store, event_id) do
    update_in(store.processed_events, &MapSet.put(&1, event_id))
  end

  # Query functions

  @doc """
  Get current state of a cluster.

  Returns `nil` if cluster has not been observed yet.
  """
  @spec get_cluster(store(), organization_id :: String.t(), cluster_id :: String.t()) ::
          ClusterCurrentState.t() | nil
  def get_cluster(store, organization_id, cluster_id) do
    Map.get(store.clusters, {organization_id, cluster_id})
  end

  @doc """
  List all clusters for an organization.
  """
  @spec list_clusters(store(), organization_id :: String.t()) :: [ClusterCurrentState.t()]
  def list_clusters(store, organization_id) do
    store.clusters
    |> Enum.filter(fn {{org, _cluster_id}, _state} -> org == organization_id end)
    |> Enum.map(fn {_key, state} -> state end)
  end

  @doc """
  Get current state of a node.

  Returns `nil` if node has not been observed yet.
  """
  @spec get_node(
          store(),
          organization_id :: String.t(),
          cluster_id :: String.t(),
          node_id :: String.t()
        ) :: NodeCurrentState.t() | nil
  def get_node(store, organization_id, cluster_id, node_id) do
    Map.get(store.nodes, {organization_id, cluster_id, node_id})
  end

  @doc """
  List all nodes for a cluster.

  Includes both active and retired nodes.
  """
  @spec list_cluster_nodes(
          store(),
          organization_id :: String.t(),
          cluster_id :: String.t()
        ) :: [NodeCurrentState.t()]
  def list_cluster_nodes(store, organization_id, cluster_id) do
    store.nodes
    |> Enum.filter(fn {{org, cluster, _node_id}, _state} ->
      org == organization_id && cluster == cluster_id
    end)
    |> Enum.map(fn {_key, state} -> state end)
  end

  @doc """
  List active (non-retired) nodes for a cluster.
  """
  @spec list_active_nodes(
          store(),
          organization_id :: String.t(),
          cluster_id :: String.t()
        ) :: [NodeCurrentState.t()]
  def list_active_nodes(store, organization_id, cluster_id) do
    store
    |> list_cluster_nodes(organization_id, cluster_id)
    |> Enum.reject(&NodeCurrentState.retired?/1)
  end

  @doc """
  List retired nodes for a cluster.
  """
  @spec list_retired_nodes(
          store(),
          organization_id :: String.t(),
          cluster_id :: String.t()
        ) :: [NodeCurrentState.t()]
  def list_retired_nodes(store, organization_id, cluster_id) do
    store
    |> list_cluster_nodes(organization_id, cluster_id)
    |> Enum.filter(&NodeCurrentState.retired?/1)
  end
end

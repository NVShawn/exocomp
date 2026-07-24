defmodule Exocomp.Coordinator.InventoryAuthorizer do
  @moduledoc """
  Validates node selections in incoming A2A requests against the coordinator's
  live inventory.

  An A2A message may include a `"node_ids"` list in its skill params to target
  a specific subset of cluster nodes. This module checks that all requested
  node IDs are present in the authorized inventory before the task is
  submitted.

  Messages with no `"node_ids"` selection are accepted unconditionally (the
  request targets all inventory nodes).

  ## Configuration

  - `:authorized_node_ids` (Application config, `:exocomp_coordinator`) —
    list of node ID strings that callers may target. When set to `nil` (the
    default), all selections are accepted. Set to a list of IDs to restrict
    access (typically populated by EXOCOMP-15 inventory loading).

  ## Usage

  The `Exocomp.Coordinator.A2ARouter` calls `authorize_selection/1` with the
  params extracted from the incoming message before submitting a task.

  This module is injected via the `:authorizer` router option so that tests can
  substitute custom implementations.
  """

  @doc """
  Check whether the node selection in `params` is authorized.

  Returns `:ok` when:
  - No `"node_ids"` key is present in params (request targets all nodes).
  - `"node_ids"` is an empty list.
  - All listed node IDs are present in the configured authorized set.

  Returns `{:error, {:unauthorized_nodes, [node_id]}}` when one or more
  requested node IDs are not in the authorized inventory.
  """
  @spec authorize_selection(map()) ::
          :ok | {:error, {:unauthorized_nodes, [String.t()]}}
  def authorize_selection(%{"node_ids" => node_ids}) when is_list(node_ids) and node_ids != [] do
    authorized = Application.get_env(:exocomp_coordinator, :authorized_node_ids, nil)

    case authorized do
      nil ->
        # No restriction configured; all selections are accepted.
        :ok

      allowed when is_list(allowed) ->
        unauthorized = Enum.reject(node_ids, &(&1 in allowed))

        if unauthorized == [] do
          :ok
        else
          {:error, {:unauthorized_nodes, unauthorized}}
        end
    end
  end

  def authorize_selection(_params), do: :ok
end

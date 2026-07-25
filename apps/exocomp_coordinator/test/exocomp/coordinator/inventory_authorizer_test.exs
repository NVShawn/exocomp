# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.InventoryAuthorizerTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.InventoryAuthorizer

  setup do
    # Ensure no lingering authorized_node_ids config from other tests
    prev = Application.get_env(:exocomp_coordinator, :authorized_node_ids)

    on_exit(fn ->
      if prev == nil do
        Application.delete_env(:exocomp_coordinator, :authorized_node_ids)
      else
        Application.put_env(:exocomp_coordinator, :authorized_node_ids, prev)
      end
    end)

    :ok
  end

  describe "authorize_selection/1" do
    test "returns :ok when no node_ids in params (no restriction)" do
      assert :ok = InventoryAuthorizer.authorize_selection(%{"skill" => "exocomp.cluster.health"})
    end

    test "returns :ok when node_ids is an empty list" do
      assert :ok = InventoryAuthorizer.authorize_selection(%{"node_ids" => []})
    end

    test "returns :ok when no authorized_node_ids is configured (nil = unrestricted)" do
      Application.delete_env(:exocomp_coordinator, :authorized_node_ids)

      assert :ok =
               InventoryAuthorizer.authorize_selection(%{
                 "node_ids" => ["any-node", "other-node"]
               })
    end

    test "returns :ok when all requested node_ids are authorized" do
      Application.put_env(:exocomp_coordinator, :authorized_node_ids, ["node-a", "node-b"])

      assert :ok =
               InventoryAuthorizer.authorize_selection(%{"node_ids" => ["node-a", "node-b"]})
    end

    test "returns :ok for subset of authorized nodes" do
      Application.put_env(:exocomp_coordinator, :authorized_node_ids, [
        "node-a",
        "node-b",
        "node-c"
      ])

      assert :ok = InventoryAuthorizer.authorize_selection(%{"node_ids" => ["node-a"]})
    end

    test "returns error when requested node_ids contain unauthorized IDs" do
      Application.put_env(:exocomp_coordinator, :authorized_node_ids, ["node-a", "node-b"])

      assert {:error, {:unauthorized_nodes, unauthorized}} =
               InventoryAuthorizer.authorize_selection(%{"node_ids" => ["node-a", "node-x"]})

      assert unauthorized == ["node-x"]
    end

    test "returns all unauthorized nodes in the error" do
      Application.put_env(:exocomp_coordinator, :authorized_node_ids, ["node-a"])

      assert {:error, {:unauthorized_nodes, unauthorized}} =
               InventoryAuthorizer.authorize_selection(%{
                 "node_ids" => ["node-b", "node-c", "node-a"]
               })

      assert Enum.sort(unauthorized) == ["node-b", "node-c"]
    end

    test "returns error when authorized list is empty and node_ids are requested" do
      Application.put_env(:exocomp_coordinator, :authorized_node_ids, [])

      assert {:error, {:unauthorized_nodes, unauthorized}} =
               InventoryAuthorizer.authorize_selection(%{"node_ids" => ["node-a"]})

      assert unauthorized == ["node-a"]
    end

    test "ignores non-node_ids keys in params" do
      Application.delete_env(:exocomp_coordinator, :authorized_node_ids)

      assert :ok =
               InventoryAuthorizer.authorize_selection(%{
                 "labels" => %{"rack" => "r1"},
                 "timeout" => 30
               })
    end
  end
end

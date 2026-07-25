defmodule Exocomp.Coordinator.InventoryTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.Inventory

  setup do
    :ok = Inventory.replace_json(inventory_json([]))
    :ok
  end

  test "loads a valid versioned inventory into the registry atomically" do
    assert :ok =
             Inventory.replace_json(
               inventory_json([inventory_node("node-a"), inventory_node("node-b")])
             )

    assert %{version: 1, nodes: [first, second]} = Inventory.current()
    assert first.id == "node-a"
    assert second.id == "node-b"
    assert Enum.map(Exocomp.Coordinator.Registry.all(), & &1.id) == ["node-a", "node-b"]
  end

  test "rejects malformed JSON and retains the active inventory" do
    assert :ok = Inventory.replace_json(inventory_json([inventory_node("node-a")]))
    active = Inventory.current()

    assert {:error, %{code: :malformed_inventory}} = Inventory.replace_json("{broken")
    assert Inventory.current() == active
    assert %{error: %{code: :malformed_inventory}} = Inventory.status()
  end

  test "rejects duplicate node IDs" do
    nodes = [
      inventory_node("node-a"),
      %{inventory_node("node-a") | "certificate_identity" => "spiffe://node/other"}
    ]

    assert {:error, %{code: :duplicate_node_id}} =
             nodes |> inventory_json() |> Inventory.replace_json()
  end

  test "rejects duplicate certificate identities" do
    nodes = [
      inventory_node("node-a"),
      %{inventory_node("node-b") | "certificate_identity" => "spiffe://node/node-a"}
    ]

    assert {:error, %{code: :duplicate_certificate_identity}} =
             nodes |> inventory_json() |> Inventory.replace_json()
  end

  test "reports unsupported versions and invalid node fields as structured errors" do
    assert {:error, %{code: :unsupported_inventory_version}} =
             :json.encode(%{"version" => 2, "nodes" => []})
             |> IO.iodata_to_binary()
             |> Inventory.parse()

    assert {:error, %{code: :invalid_inventory_schema}} =
             :json.encode(%{"version" => 1, "nodes" => "invalid"})
             |> IO.iodata_to_binary()
             |> Inventory.parse()

    invalid = %{inventory_node("node-a") | "port" => 70_000}

    assert {:error, %{code: :invalid_inventory_node, details: %{field: "port"}}} =
             invalid |> then(&inventory_json([&1])) |> Inventory.parse()
  end

  @tag :tmp_dir
  test "loads inventory from a file and exposes structured status", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "inventory.json")
    File.write!(path, inventory_json([inventory_node("node-a")]))

    assert :ok = Inventory.replace_file(path)
    assert %{source: ^path, node_count: 1, version: 1, error: nil} = Inventory.status()
  end

  @tag :tmp_dir
  test "returns a structured read error for a missing file", %{tmp_dir: tmp_dir} do
    assert {:error, %{code: :inventory_read_failed}} =
             Inventory.replace_file(Path.join(tmp_dir, "missing.json"))
  end

  defp inventory_json(nodes) do
    %{"version" => 1, "nodes" => nodes}
    |> :json.encode()
    |> IO.iodata_to_binary()
  end

  defp inventory_node(id) do
    %{
      "id" => id,
      "hostname" => "#{id}.example.test",
      "port" => 8443,
      "certificate_identity" => "spiffe://node/#{id}",
      "capabilities" => ["exocomp.node.health"],
      "labels" => %{"rack" => "r1"}
    }
  end
end

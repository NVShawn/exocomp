# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
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
             :json.encode(%{"version" => 99, "nodes" => []})
             |> IO.iodata_to_binary()
             |> Inventory.parse()

    assert {:error, %{code: :invalid_inventory_schema}} =
             :json.encode(%{"version" => 1, "nodes" => "invalid"})
             |> IO.iodata_to_binary()
             |> Inventory.parse()

    invalid = %{inventory_node("node-a") | "port" => 70_000}

    assert {:error, %{code: :invalid_inventory_node}} =
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

  describe "version 1 backward compatibility" do
    test "loads v1 inventories without monitoring field" do
      node = inventory_node("node-a")
      assert :ok = Inventory.replace_json(inventory_json([node]))
      
      assert %{version: 1, nodes: [loaded]} = Inventory.current()
      assert loaded.id == "node-a"
      assert loaded.monitoring == nil
    end

    test "rejects monitoring field in v1" do
      node = inventory_node("node-a")
      node_with_monitoring = Map.put(node, "monitoring", %{"automatic" => true, "services" => []})
      
      assert {:error, %{code: :invalid_inventory_node}} =
        node_with_monitoring |> then(&inventory_json([&1])) |> Inventory.parse()
    end

    test "v1 inventories default cluster_profile to nil" do
      node = inventory_json([inventory_node("node-a")])
      assert {:ok, %{cluster_profile: nil}} = Inventory.parse(node)
    end
  end

  describe "version 2 support" do
    test "loads v2 inventories with monitoring fields" do
      node = inventory_node_v2("node-a", %{
        "automatic" => true,
        "services" => [
          %{
            "name" => "ceph-mon.service",
            "health_check_url" => "http://127.0.0.1:6800/status"
          }
        ]
      })

      assert :ok = Inventory.replace_json(inventory_json_v2([node]))
      
      assert %{version: 2, nodes: [loaded]} = Inventory.current()
      assert loaded.id == "node-a"
      assert loaded.monitoring.automatic == true
      assert length(loaded.monitoring.services) == 1
      assert hd(loaded.monitoring.services).name == "ceph-mon.service"
    end

    test "v2 supports cluster_profile declaration" do
      node = inventory_node_v2("node-a", nil)
      
      inv = %{"version" => 2, "cluster_profile" => "production", "nodes" => [node]}
      json = inv |> :json.encode() |> IO.iodata_to_binary()
      
      assert {:ok, %{cluster_profile: "production"}} = Inventory.parse(json)
    end

    test "v2 cluster_profile defaults to nil" do
      node = inventory_node_v2("node-a", nil)
      assert {:ok, %{cluster_profile: nil}} = inventory_json_v2([node]) |> Inventory.parse()
    end

    test "v2 rejects empty cluster_profile string" do
      node = inventory_node_v2("node-a", nil)
      inv = %{"version" => 2, "cluster_profile" => "", "nodes" => [node]}
      json = inv |> :json.encode() |> IO.iodata_to_binary()
      
      assert {:error, %{code: :invalid_inventory_schema}} = Inventory.parse(json)
    end

    test "v2 monitoring field is optional per-node" do
      node_with = inventory_node_v2("node-a", %{"automatic" => false, "services" => []})
      node_without = inventory_node_v2("node-b", nil)
      
      assert :ok = Inventory.replace_json(inventory_json_v2([node_with, node_without]))
      
      assert %{nodes: [first, second]} = Inventory.current()
      assert first.monitoring != nil
      assert second.monitoring == nil
    end
  end

  describe "service name validation" do
    test "rejects service names not ending with .service" do
      node = inventory_node_v2("node-a", %{
        "automatic" => true,
        "services" => [
          %{
            "name" => "ceph-mon",
            "health_check_url" => "http://127.0.0.1:6800/status"
          }
        ]
      })

      assert {:error, %{code: :invalid_inventory_node}} =
        inventory_json_v2([node]) |> Inventory.parse()
    end

    test "rejects .service-only names" do
      node = inventory_node_v2("node-a", %{
        "automatic" => true,
        "services" => [%{"name" => ".service", "health_check_url" => "http://127.0.0.1:6800/status"}]
      })

      assert {:error, %{code: :invalid_inventory_node}} =
        inventory_json_v2([node]) |> Inventory.parse()
    end

    test "accepts valid systemd service names" do
      node = inventory_node_v2("node-a", %{
        "automatic" => true,
        "services" => [
          %{"name" => "ceph-mon.service", "health_check_url" => "http://127.0.0.1:6800/status"},
          %{"name" => "my-app@1.service", "health_check_url" => "http://127.0.0.1:8080/health"}
        ]
      })

      assert {:ok, inv} = inventory_json_v2([node]) |> Inventory.parse()
      assert length(inv.nodes) == 1
      assert length(inv.nodes |> hd |> Map.get(:monitoring) |> Map.get(:services)) == 2
    end

    test "rejects duplicate service names within a node" do
      node = inventory_node_v2("node-a", %{
        "automatic" => true,
        "services" => [
          %{"name" => "ceph-mon.service", "health_check_url" => "http://127.0.0.1:6800/status"},
          %{"name" => "ceph-mon.service", "health_check_url" => "http://127.0.0.1:6801/status"}
        ]
      })

      assert {:error, %{code: :invalid_inventory_node, details: %{value: "ceph-mon.service"}}} =
        inventory_json_v2([node]) |> Inventory.parse()
    end
  end

  describe "health check URL validation" do
    test "accepts http://127.0.0.1 loopback URLs" do
      node = inventory_node_v2("node-a", %{
        "automatic" => true,
        "services" => [
          %{"name" => "svc.service", "health_check_url" => "http://127.0.0.1:6800/status"}
        ]
      })

      assert {:ok, _inv} = inventory_json_v2([node]) |> Inventory.parse()
    end

    test "accepts http://localhost loopback URLs" do
      node = inventory_node_v2("node-a", %{
        "automatic" => true,
        "services" => [
          %{"name" => "svc.service", "health_check_url" => "http://localhost:6800/status"}
        ]
      })

      assert {:ok, _inv} = inventory_json_v2([node]) |> Inventory.parse()
    end

    test "accepts http://[::1] IPv6 loopback URLs" do
      node = inventory_node_v2("node-a", %{
        "automatic" => true,
        "services" => [
          %{"name" => "svc.service", "health_check_url" => "http://[::1]:6800/status"}
        ]
      })

      assert {:ok, _inv} = inventory_json_v2([node]) |> Inventory.parse()
    end

    test "rejects non-loopback IPs" do
      node = inventory_node_v2("node-a", %{
        "automatic" => true,
        "services" => [
          %{"name" => "svc.service", "health_check_url" => "http://192.168.1.1:6800/status"}
        ]
      })

      assert {:error, %{code: :invalid_inventory_node}} =
        inventory_json_v2([node]) |> Inventory.parse()
    end

    test "rejects https URLs" do
      node = inventory_node_v2("node-a", %{
        "automatic" => true,
        "services" => [
          %{"name" => "svc.service", "health_check_url" => "https://127.0.0.1:6800/status"}
        ]
      })

      assert {:error, %{code: :invalid_inventory_node}} =
        inventory_json_v2([node]) |> Inventory.parse()
    end

    test "rejects malformed URLs" do
      node = inventory_node_v2("node-a", %{
        "automatic" => true,
        "services" => [
          %{"name" => "svc.service", "health_check_url" => "not-a-url"}
        ]
      })

      assert {:error, %{code: :invalid_inventory_node}} =
        inventory_json_v2([node]) |> Inventory.parse()
    end
  end

  describe "automatic mode validation" do
    test "accepts boolean true for automatic" do
      node = inventory_node_v2("node-a", %{"automatic" => true, "services" => []})
      assert {:ok, _inv} = inventory_json_v2([node]) |> Inventory.parse()
    end

    test "accepts boolean false for automatic" do
      node = inventory_node_v2("node-a", %{"automatic" => false, "services" => []})
      assert {:ok, _inv} = inventory_json_v2([node]) |> Inventory.parse()
    end

    test "defaults automatic to false when omitted" do
      node = inventory_node_v2("node-a", %{"services" => []})
      assert {:ok, inv} = inventory_json_v2([node]) |> Inventory.parse()
      assert inv.nodes |> hd |> Map.get(:monitoring) |> Map.get(:automatic) == false
    end

    test "rejects non-boolean automatic values" do
      node = inventory_node_v2("node-a", %{"automatic" => "yes", "services" => []})
      assert {:error, %{code: :invalid_inventory_node, details: %{field: "monitoring.automatic"}}} =
        inventory_json_v2([node]) |> Inventory.parse()
    end

    test "rejects numeric automatic values" do
      node = inventory_node_v2("node-a", %{"automatic" => 1, "services" => []})
      assert {:error, %{code: :invalid_inventory_node, details: %{field: "monitoring.automatic"}}} =
        inventory_json_v2([node]) |> Inventory.parse()
    end
  end

  describe "atomic rejection" do
    test "invalid v2 replacement leaves prior v1 inventory unchanged" do
      v1_node = inventory_node("node-a")
      assert :ok = Inventory.replace_json(inventory_json([v1_node]))
      original = Inventory.current()

      v2_node = inventory_node_v2("node-b", %{
        "automatic" => true,
        "services" => [%{"name" => "bad.txt", "health_check_url" => "http://127.0.0.1:6800"}]
      })

      assert {:error, %{code: :invalid_inventory_node}} =
        inventory_json_v2([v2_node]) |> Inventory.replace_json()

      assert Inventory.current() == original
    end

    test "invalid service name leaves prior inventory unchanged" do
      valid = inventory_node("node-a")
      assert :ok = Inventory.replace_json(inventory_json([valid]))
      original = Inventory.current()

      invalid = inventory_node_v2("node-b", %{
        "automatic" => true,
        "services" => [%{"name" => "missing-extension", "health_check_url" => "http://127.0.0.1:6800"}]
      })

      assert {:error, %{code: :invalid_inventory_node}} =
        inventory_json_v2([invalid]) |> Inventory.replace_json()

      assert Inventory.current() == original
    end

    test "invalid health check URL leaves prior inventory unchanged" do
      valid = inventory_node("node-a")
      assert :ok = Inventory.replace_json(inventory_json([valid]))
      original = Inventory.current()

      invalid = inventory_node_v2("node-b", %{
        "automatic" => true,
        "services" => [%{"name" => "svc.service", "health_check_url" => "http://10.0.0.1:6800"}]
      })

      assert {:error, %{code: :invalid_inventory_node}} =
        inventory_json_v2([invalid]) |> Inventory.replace_json()

      assert Inventory.current() == original
    end
  end

  defp inventory_json(nodes) do
    %{"version" => 1, "nodes" => nodes}
    |> :json.encode()
    |> IO.iodata_to_binary()
  end

  defp inventory_json_v2(nodes, cluster_profile \\ nil) do
    inv = %{"version" => 2, "nodes" => nodes}
    inv = if cluster_profile, do: Map.put(inv, "cluster_profile", cluster_profile), else: inv
    inv |> :json.encode() |> IO.iodata_to_binary()
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

  defp inventory_node_v2(id, monitoring) do
    node = inventory_node(id)
    if monitoring, do: Map.put(node, "monitoring", monitoring), else: node
  end
end

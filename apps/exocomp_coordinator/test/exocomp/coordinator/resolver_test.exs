defmodule Exocomp.Coordinator.ResolverTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.{Inventory, Registry, Resolver}

  # -------------------------------------------------------------------------
  # Helpers
  # -------------------------------------------------------------------------

  defp inventory_json(nodes) do
    %{"version" => 1, "nodes" => nodes}
    |> :json.encode()
    |> IO.iodata_to_binary()
  end

  defp inventory_node(id, hostname \\ nil) do
    %{
      "id" => id,
      "hostname" => hostname || "#{id}.example.test",
      "port" => 8443,
      "certificate_identity" => "spiffe://node/#{id}",
      "capabilities" => [],
      "labels" => %{}
    }
  end

  # Returns a resolver_fn that always returns the given map of
  # hostname (charlist) -> result for each address family.
  defp static_resolver(map) do
    fn hostname, family ->
      key = {to_string(hostname), family}
      Map.get(map, key, {:error, :nxdomain})
    end
  end

  # Start a named Resolver under the test supervisor and trigger resolution.
  defp start_resolver(resolver_fn, opts \\ []) do
    name = :"resolver_test_#{System.unique_integer([:positive])}"
    # Very long interval so the timer doesn't fire during tests.
    start_supervised!(
      {Resolver,
       Keyword.merge([name: name, resolver_fn: resolver_fn, interval_ms: 3_600_000], opts)}
    )

    # Trigger synchronous resolution.
    :ok = Resolver.resolve_now(name)
    name
  end

  setup do
    # Reset inventory to empty before each test.
    :ok = Inventory.replace_json(inventory_json([]))
    :ok
  end

  # -------------------------------------------------------------------------
  # Tests
  # -------------------------------------------------------------------------

  test "successful IPv4 resolution — candidates stored, addresses untouched" do
    :ok =
      Inventory.replace_json(inventory_json([inventory_node("node-a", "node-a.example.test")]))

    resolver_fn =
      static_resolver(%{
        {"node-a.example.test", :inet} => {:ok, [{192, 0, 2, 1}]},
        {"node-a.example.test", :inet6} => {:error, :nxdomain}
      })

    name = start_resolver(resolver_fn)

    assert %{"node-a" => ["192.0.2.1"]} = Resolver.candidates(name)

    # Registry candidate_addresses updated; Registry.addresses must remain empty.
    assert {:ok, %{candidate_addresses: ["192.0.2.1"], addresses: []}} = Registry.get("node-a")
  end

  test "resolves multiple IPv4 and IPv6 addresses, normalizes and sorts deterministically" do
    :ok =
      Inventory.replace_json(inventory_json([inventory_node("node-b", "node-b.example.test")]))

    resolver_fn =
      static_resolver(%{
        {"node-b.example.test", :inet} => {:ok, [{203, 0, 113, 1}, {203, 0, 113, 2}]},
        # Dual-stack: also returns IPv6
        {"node-b.example.test", :inet6} => {:ok, [{8193, 3512, 0, 0, 0, 0, 0, 1}]}
      })

    name = start_resolver(resolver_fn)

    candidates = Resolver.candidates(name)
    assert %{"node-b" => addrs} = candidates

    # Sorted deterministically; duplicate entries would be removed.
    assert addrs == Enum.sort(addrs)
    assert "203.0.113.1" in addrs
    assert "203.0.113.2" in addrs
    # 2001:db8::1 in normalized form
    assert "2001:db8::1" in addrs
    assert length(addrs) == 3
  end

  test "deduplicates identical addresses returned by both address families" do
    :ok =
      Inventory.replace_json(inventory_json([inventory_node("node-c", "node-c.example.test")]))

    resolver_fn =
      static_resolver(%{
        {"node-c.example.test", :inet} => {:ok, [{192, 0, 2, 5}]},
        # Same address duplicated across family calls.
        {"node-c.example.test", :inet6} => {:ok, [{192, 0, 2, 5}]}
      })

    name = start_resolver(resolver_fn)

    assert %{"node-c" => ["192.0.2.5"]} = Resolver.candidates(name)
  end

  test "address-set changes are reflected on re-resolution" do
    :ok =
      Inventory.replace_json(inventory_json([inventory_node("node-d", "node-d.example.test")]))

    {:ok, agent} = Agent.start_link(fn -> {[{192, 0, 2, 10}], []} end)

    resolver_fn = fn hostname, family ->
      case {to_string(hostname), family} do
        {"node-d.example.test", :inet} ->
          {addrs, _} = Agent.get(agent, & &1)
          {:ok, addrs}

        {"node-d.example.test", :inet6} ->
          {_, addrs6} = Agent.get(agent, & &1)
          if addrs6 == [], do: {:error, :nxdomain}, else: {:ok, addrs6}

        _ ->
          {:error, :nxdomain}
      end
    end

    name = start_resolver(resolver_fn)
    assert %{"node-d" => ["192.0.2.10"]} = Resolver.candidates(name)

    # Update the DNS response to include a second address.
    Agent.update(agent, fn _ -> {[{192, 0, 2, 10}, {192, 0, 2, 11}], []} end)
    :ok = Resolver.resolve_now(name)

    assert %{"node-d" => addrs} = Resolver.candidates(name)
    assert "192.0.2.10" in addrs
    assert "192.0.2.11" in addrs
    assert length(addrs) == 2
  end

  test "NXDOMAIN for both families — stores empty candidates, does not crash" do
    :ok =
      Inventory.replace_json(inventory_json([inventory_node("node-e", "node-e.example.test")]))

    resolver_fn =
      static_resolver(%{
        {"node-e.example.test", :inet} => {:error, :nxdomain},
        {"node-e.example.test", :inet6} => {:error, :nxdomain}
      })

    name = start_resolver(resolver_fn)

    assert %{"node-e" => []} = Resolver.candidates(name)
    assert {:ok, %{candidate_addresses: []}} = Registry.get("node-e")
  end

  test "timeout error — stores empty candidates, does not crash" do
    :ok =
      Inventory.replace_json(inventory_json([inventory_node("node-f", "node-f.example.test")]))

    resolver_fn =
      static_resolver(%{
        {"node-f.example.test", :inet} => {:error, :timeout},
        {"node-f.example.test", :inet6} => {:error, :timeout}
      })

    name = start_resolver(resolver_fn)

    assert %{"node-f" => []} = Resolver.candidates(name)
  end

  test "empty result from resolver (ok with no addresses) — stores empty candidates" do
    :ok =
      Inventory.replace_json(inventory_json([inventory_node("node-g", "node-g.example.test")]))

    resolver_fn =
      static_resolver(%{
        {"node-g.example.test", :inet} => {:ok, []},
        {"node-g.example.test", :inet6} => {:ok, []}
      })

    name = start_resolver(resolver_fn)

    assert %{"node-g" => []} = Resolver.candidates(name)
  end

  test "generic resolver error — stores empty candidates, does not crash" do
    :ok =
      Inventory.replace_json(inventory_json([inventory_node("node-h", "node-h.example.test")]))

    resolver_fn =
      static_resolver(%{
        {"node-h.example.test", :inet} => {:error, :servfail},
        {"node-h.example.test", :inet6} => {:error, :servfail}
      })

    name = start_resolver(resolver_fn)

    assert %{"node-h" => []} = Resolver.candidates(name)
  end

  test "resolves multiple nodes independently" do
    :ok =
      Inventory.replace_json(
        inventory_json([
          inventory_node("node-x", "node-x.example.test"),
          inventory_node("node-y", "node-y.example.test")
        ])
      )

    resolver_fn =
      static_resolver(%{
        {"node-x.example.test", :inet} => {:ok, [{192, 0, 2, 20}]},
        {"node-x.example.test", :inet6} => {:error, :nxdomain},
        {"node-y.example.test", :inet} => {:error, :nxdomain},
        {"node-y.example.test", :inet6} => {:ok, [{8193, 3512, 0, 0, 0, 0, 0, 2}]}
      })

    name = start_resolver(resolver_fn)

    %{"node-x" => x_addrs, "node-y" => y_addrs} = Resolver.candidates(name)
    assert x_addrs == ["192.0.2.20"]
    assert "2001:db8::2" in y_addrs
  end

  test "refresh after inventory changes picks up new node" do
    # Start with one node.
    :ok =
      Inventory.replace_json(inventory_json([inventory_node("node-p", "node-p.example.test")]))

    resolver_fn =
      static_resolver(%{
        {"node-p.example.test", :inet} => {:ok, [{192, 0, 2, 30}]},
        {"node-p.example.test", :inet6} => {:error, :nxdomain},
        {"node-q.example.test", :inet} => {:ok, [{192, 0, 2, 31}]},
        {"node-q.example.test", :inet6} => {:error, :nxdomain}
      })

    name = start_resolver(resolver_fn)

    assert %{"node-p" => ["192.0.2.30"]} = Resolver.candidates(name)
    refute Map.has_key?(Resolver.candidates(name), "node-q")

    # Add a second node to the inventory.
    :ok =
      Inventory.replace_json(
        inventory_json([
          inventory_node("node-p", "node-p.example.test"),
          inventory_node("node-q", "node-q.example.test")
        ])
      )

    # Trigger a new resolution sweep.
    :ok = Resolver.resolve_now(name)

    assert %{"node-p" => ["192.0.2.30"], "node-q" => ["192.0.2.31"]} =
             Resolver.candidates(name)
  end

  test "empty inventory resolves to empty candidates map" do
    # Inventory already empty from setup.
    resolver_fn = static_resolver(%{})

    name = start_resolver(resolver_fn)

    assert %{} = Resolver.candidates(name)
  end

  test "IPv4-only success when IPv6 fails treats resolution as successful" do
    :ok =
      Inventory.replace_json(
        inventory_json([inventory_node("node-ipv4", "node-ipv4.example.test")])
      )

    resolver_fn =
      static_resolver(%{
        {"node-ipv4.example.test", :inet} => {:ok, [{10, 0, 0, 1}]},
        {"node-ipv4.example.test", :inet6} => {:error, :nxdomain}
      })

    name = start_resolver(resolver_fn)

    assert %{"node-ipv4" => ["10.0.0.1"]} = Resolver.candidates(name)

    assert {:ok, %{candidate_addresses: ["10.0.0.1"], addresses: []}} =
             Registry.get("node-ipv4")
  end
end

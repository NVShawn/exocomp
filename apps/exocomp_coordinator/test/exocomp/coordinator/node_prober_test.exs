defmodule Exocomp.Coordinator.NodeProberTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.{Audit, Inventory, NodeProber, Registry}

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Build a minimal inventory JSON binary.
  defp inventory_json(nodes) do
    %{"version" => 1, "nodes" => nodes}
    |> :json.encode()
    |> IO.iodata_to_binary()
  end

  # Build an inventory node map with conventional defaults for the given id.
  defp inventory_node(id) do
    %{
      "id" => id,
      "hostname" => "#{id}.example.test",
      "port" => 8443,
      "certificate_identity" => "spiffe://node/#{id}",
      "capabilities" => ["exocomp.node.health"],
      "labels" => %{}
    }
  end

  # Load an inventory with the given node and return the registry entry with
  # `candidate_addresses` pre-set.
  defp setup_node_with_candidates(node_id, candidate_addresses) do
    :ok = Inventory.replace_json(inventory_json([inventory_node(node_id)]))
    :ok = Registry.put_candidates(node_id, candidate_addresses)
    {:ok, entry} = Registry.get(node_id)
    entry
  end

  # A probe_fn that always returns a healthy result for any address.
  defp healthy_probe_fn do
    fn _address, _port, _hostname, _cert_identity, _timeout_ms ->
      {:ok, %{agent_card: %{"name" => "test-node"}, health: %{"status" => "ok"}}}
    end
  end

  # A probe_fn that always returns the given error for any address.
  defp error_probe_fn(error) do
    fn _address, _port, _hostname, _cert_identity, _timeout_ms ->
      {:error, error}
    end
  end

  # A probe_fn that returns identity_mismatch for any address.
  defp identity_mismatch_probe_fn(expected, actual) do
    fn _address, _port, _hostname, _cert_identity, _timeout_ms ->
      {:error, :identity_mismatch, %{expected: expected, actual: actual}}
    end
  end

  # A probe_fn that dispatches based on address.
  defp per_address_probe_fn(address_map) do
    fn address, _port, _hostname, _cert_identity, _timeout_ms ->
      Map.fetch!(address_map, address)
    end
  end

  # Start a private Audit sink backed by a temp file.  Returns the server pid
  # and a function that reads all events from the sink file.
  defp start_audit(tmp_dir) do
    path = Path.join(tmp_dir, "probe-audit.jsonl")
    name = :"audit_#{System.unique_integer([:positive])}"
    pid = start_supervised!({Audit, name: name, sink: {Audit.JSONLines, path: path}})

    read_events = fn ->
      path
      |> File.read()
      |> case do
        {:ok, content} ->
          content
          |> String.trim()
          |> String.split("\n", trim: true)
          |> Enum.map(&:json.decode/1)

        {:error, :enoent} ->
          []
      end
    end

    {pid, name, read_events}
  end

  # ---------------------------------------------------------------------------
  # Test setup
  # ---------------------------------------------------------------------------

  setup do
    :ok = Inventory.replace_json(inventory_json([]))
    :ok
  end

  # ---------------------------------------------------------------------------
  # Correct TLS identity — healthy outcome, addresses adopted
  # ---------------------------------------------------------------------------

  test "correct identity: healthy outcome and Registry.addresses updated" do
    entry = setup_node_with_candidates("node-a", ["192.0.2.1"])

    result =
      NodeProber.probe(entry, probe_fn: healthy_probe_fn())

    assert result.outcome == :healthy
    assert result.node_id == "node-a"
    assert result.verified_addresses == ["192.0.2.1"]
    assert result.agent_card == %{"name" => "test-node"}
    assert result.health == %{"status" => "ok"}
    assert result.error_details == %{}

    # Registry.addresses must be updated after successful probe.
    assert {:ok, %{addresses: ["192.0.2.1"], reachability: :healthy}} = Registry.get("node-a")
  end

  test "correct identity: multiple candidate addresses all adopted when healthy" do
    entry = setup_node_with_candidates("node-a", ["192.0.2.1", "192.0.2.2"])

    result =
      NodeProber.probe(entry, probe_fn: healthy_probe_fn())

    assert result.outcome == :healthy
    assert "192.0.2.1" in result.verified_addresses
    assert "192.0.2.2" in result.verified_addresses
    assert length(result.verified_addresses) == 2

    assert {:ok, %{addresses: addresses}} = Registry.get("node-a")
    assert "192.0.2.1" in addresses
    assert "192.0.2.2" in addresses
  end

  # ---------------------------------------------------------------------------
  # Wrong TLS identity — identity_mismatch, addresses not adopted
  # ---------------------------------------------------------------------------

  test "wrong identity: returns :identity_mismatch and does not update addresses" do
    entry = setup_node_with_candidates("node-b", ["192.0.2.10"])

    # Give the node a known initial address so we can verify it's preserved.
    :ok = Registry.update("node-b", %{addresses: ["10.0.0.1"]})

    result =
      NodeProber.probe(entry,
        probe_fn: identity_mismatch_probe_fn("spiffe://node/node-b", "spiffe://node/WRONG")
      )

    assert result.outcome == :identity_mismatch
    assert result.verified_addresses == []
    assert result.agent_card == nil
    assert result.health == nil
    assert result.error_details.expected == "spiffe://node/node-b"
    assert result.error_details.actual == "spiffe://node/WRONG"

    # Existing verified addresses must be preserved after identity mismatch.
    assert {:ok, %{addresses: ["10.0.0.1"]}} = Registry.get("node-b")
  end

  test "wrong identity: stops probing after first mismatch (does not try remaining candidates)" do
    # Track how many times the probe_fn is called.
    {:ok, call_count} = Agent.start_link(fn -> 0 end)

    probe_fn = fn _addr, _port, _host, _id, _timeout ->
      Agent.update(call_count, &(&1 + 1))
      {:error, :identity_mismatch, %{expected: "spiffe://node/node-c", actual: "spiffe://WRONG"}}
    end

    entry = setup_node_with_candidates("node-c", ["192.0.2.1", "192.0.2.2", "192.0.2.3"])
    NodeProber.probe(entry, probe_fn: probe_fn)

    # Exactly one call made — probing halted after the first mismatch.
    assert Agent.get(call_count, & &1) == 1
  end

  # ---------------------------------------------------------------------------
  # Multiple addresses — partial success and address selection
  # ---------------------------------------------------------------------------

  test "multiple addresses: adopts only the addresses that responded successfully" do
    entry = setup_node_with_candidates("node-d", ["192.0.2.1", "192.0.2.2", "192.0.2.3"])

    probe_fn =
      per_address_probe_fn(%{
        "192.0.2.1" => {:ok, %{agent_card: %{"name" => "node-d"}, health: %{"status" => "ok"}}},
        "192.0.2.2" => {:error, :timeout},
        "192.0.2.3" => {:ok, %{agent_card: %{"name" => "node-d"}, health: %{"status" => "ok"}}}
      })

    result = NodeProber.probe(entry, probe_fn: probe_fn)

    assert result.outcome == :healthy
    assert "192.0.2.1" in result.verified_addresses
    refute "192.0.2.2" in result.verified_addresses
    assert "192.0.2.3" in result.verified_addresses

    assert {:ok, %{addresses: addresses}} = Registry.get("node-d")
    assert "192.0.2.1" in addresses
    refute "192.0.2.2" in addresses
    assert "192.0.2.3" in addresses
  end

  test "multiple addresses: identity mismatch on any candidate stops the entire probe" do
    entry = setup_node_with_candidates("node-e", ["192.0.2.1", "192.0.2.2"])

    probe_fn =
      per_address_probe_fn(%{
        "192.0.2.1" => {:ok, %{agent_card: %{"name" => "node-e"}, health: %{"status" => "ok"}}},
        "192.0.2.2" =>
          {:error, :identity_mismatch,
           %{expected: "spiffe://node/node-e", actual: "spiffe://imposter"}}
      })

    result = NodeProber.probe(entry, probe_fn: probe_fn)

    assert result.outcome == :identity_mismatch
    # Even though 192.0.2.1 was ok first, the mismatch on 192.0.2.2 must be
    # reflected.  NOTE: the mismatch _stops iteration_, so depending on probe
    # order the first success may not have been processed yet.  The important
    # contract is that the final outcome is :identity_mismatch.
  end

  # ---------------------------------------------------------------------------
  # Changed-address adoption
  # ---------------------------------------------------------------------------

  test "changed address adoption: new address replaces old when probe succeeds" do
    entry = setup_node_with_candidates("node-f", ["192.0.2.100"])
    :ok = Registry.update("node-f", %{addresses: ["10.0.0.99"]})

    result =
      NodeProber.probe(entry, probe_fn: healthy_probe_fn())

    assert result.outcome == :healthy
    assert result.verified_addresses == ["192.0.2.100"]

    assert {:ok, %{addresses: ["192.0.2.100"]}} = Registry.get("node-f")
  end

  test "changed address adoption: address set updated when DNS candidates changed" do
    entry = setup_node_with_candidates("node-g", ["10.0.1.1", "10.0.1.2"])
    :ok = Registry.update("node-g", %{addresses: ["10.0.0.50"]})

    result =
      NodeProber.probe(entry, probe_fn: healthy_probe_fn())

    assert result.outcome == :healthy

    {:ok, reg_entry} = Registry.get("node-g")
    assert "10.0.1.1" in reg_entry.addresses
    assert "10.0.1.2" in reg_entry.addresses
    refute "10.0.0.50" in reg_entry.addresses
  end

  # ---------------------------------------------------------------------------
  # Failed-change preservation
  # ---------------------------------------------------------------------------

  test "failed change preservation: previous addresses kept on DNS failure (no candidates)" do
    entry = setup_node_with_candidates("node-h", [])
    :ok = Registry.update("node-h", %{addresses: ["10.0.0.1"]})

    result =
      NodeProber.probe(entry, probe_fn: healthy_probe_fn())

    # No candidates → unreachable outcome.
    assert result.outcome == :unreachable
    assert result.verified_addresses == []

    # Previously verified addresses must be preserved.
    assert {:ok, %{addresses: ["10.0.0.1"]}} = Registry.get("node-h")
  end

  test "failed change preservation: previous addresses kept when all candidates timeout" do
    entry = setup_node_with_candidates("node-i", ["192.0.2.1", "192.0.2.2"])
    :ok = Registry.update("node-i", %{addresses: ["10.0.0.5"]})

    result =
      NodeProber.probe(entry, probe_fn: error_probe_fn(:timeout))

    assert result.outcome == :timeout
    assert result.verified_addresses == []

    assert {:ok, %{addresses: ["10.0.0.5"]}} = Registry.get("node-i")
  end

  test "failed change preservation: previous addresses kept when all candidates unreachable" do
    entry = setup_node_with_candidates("node-j", ["192.0.2.1"])
    :ok = Registry.update("node-j", %{addresses: ["10.0.0.6"]})

    result =
      NodeProber.probe(entry, probe_fn: error_probe_fn(:unreachable))

    assert result.outcome == :unreachable
    assert result.verified_addresses == []

    assert {:ok, %{addresses: ["10.0.0.6"]}} = Registry.get("node-j")
  end

  test "failed change preservation: previous addresses kept on identity mismatch" do
    entry = setup_node_with_candidates("node-k", ["192.0.2.1"])
    :ok = Registry.update("node-k", %{addresses: ["10.0.0.7"]})

    result =
      NodeProber.probe(entry,
        probe_fn: identity_mismatch_probe_fn("spiffe://node/node-k", "spiffe://intruder")
      )

    assert result.outcome == :identity_mismatch

    assert {:ok, %{addresses: ["10.0.0.7"]}} = Registry.get("node-k")
  end

  # ---------------------------------------------------------------------------
  # Degraded health response
  # ---------------------------------------------------------------------------

  test "degraded outcome when health status is not ok" do
    entry = setup_node_with_candidates("node-l", ["192.0.2.1"])

    probe_fn = fn _addr, _port, _host, _id, _timeout ->
      {:ok,
       %{agent_card: %{"name" => "node-l"}, health: %{"status" => "degraded", "reason" => "oom"}}}
    end

    result = NodeProber.probe(entry, probe_fn: probe_fn)

    assert result.outcome == :degraded
    assert result.verified_addresses == ["192.0.2.1"]
    assert result.health["status"] == "degraded"

    # Registry reachability updated to :degraded; addresses still adopted.
    assert {:ok, %{reachability: :degraded, addresses: ["192.0.2.1"]}} = Registry.get("node-l")
  end

  test "degraded outcome when health map has no status field" do
    entry = setup_node_with_candidates("node-m", ["192.0.2.1"])

    probe_fn = fn _addr, _port, _host, _id, _timeout ->
      {:ok, %{agent_card: %{"name" => "node-m"}, health: %{}}}
    end

    result = NodeProber.probe(entry, probe_fn: probe_fn)

    assert result.outcome == :degraded
    assert result.verified_addresses == ["192.0.2.1"]
  end

  # ---------------------------------------------------------------------------
  # Malformed / failed Agent Card or health response
  # ---------------------------------------------------------------------------

  test "malformed response treated as failure for that address — tries remaining candidates" do
    {:ok, call_count} = Agent.start_link(fn -> 0 end)

    probe_fn = fn address, _port, _host, _id, _timeout ->
      Agent.update(call_count, &(&1 + 1))

      case address do
        "192.0.2.1" ->
          {:error, :malformed_response, "unexpected HTTP 400"}

        "192.0.2.2" ->
          {:ok, %{agent_card: %{"name" => "node-n"}, health: %{"status" => "ok"}}}
      end
    end

    entry = setup_node_with_candidates("node-n", ["192.0.2.1", "192.0.2.2"])
    result = NodeProber.probe(entry, probe_fn: probe_fn)

    # Both addresses were tried.
    assert Agent.get(call_count, & &1) == 2

    # Second address succeeded.
    assert result.outcome == :healthy
    assert result.verified_addresses == ["192.0.2.2"]
  end

  test "all addresses return malformed response — unreachable outcome, addresses not updated" do
    entry = setup_node_with_candidates("node-o", ["192.0.2.1"])
    :ok = Registry.update("node-o", %{addresses: ["10.0.0.8"]})

    probe_fn = fn _addr, _port, _host, _id, _timeout ->
      {:error, :malformed_response, "empty body"}
    end

    result = NodeProber.probe(entry, probe_fn: probe_fn)

    assert result.outcome == :unreachable
    assert result.verified_addresses == []

    # Previous addresses preserved.
    assert {:ok, %{addresses: ["10.0.0.8"]}} = Registry.get("node-o")
  end

  # ---------------------------------------------------------------------------
  # Timeout outcome
  # ---------------------------------------------------------------------------

  test "timeout outcome when all candidates time out" do
    entry = setup_node_with_candidates("node-p", ["192.0.2.1", "192.0.2.2"])

    result = NodeProber.probe(entry, probe_fn: error_probe_fn(:timeout))

    assert result.outcome == :timeout
    assert result.verified_addresses == []
    assert result.error_details.reason == :timeout
  end

  # ---------------------------------------------------------------------------
  # Unreachable outcome
  # ---------------------------------------------------------------------------

  test "unreachable outcome when all candidates are unreachable" do
    entry = setup_node_with_candidates("node-q", ["192.0.2.1"])

    result = NodeProber.probe(entry, probe_fn: error_probe_fn(:unreachable))

    assert result.outcome == :unreachable
    assert result.verified_addresses == []
  end

  test "unreachable outcome when no candidate addresses are available" do
    entry = setup_node_with_candidates("node-r", [])

    result = NodeProber.probe(entry, probe_fn: healthy_probe_fn())

    assert result.outcome == :unreachable
    assert result.verified_addresses == []
  end

  # ---------------------------------------------------------------------------
  # Audit events
  # ---------------------------------------------------------------------------

  @tag :tmp_dir
  test "emits a node_probe_completed audit event on healthy probe", %{tmp_dir: tmp_dir} do
    {_pid, audit_name, read_events} = start_audit(tmp_dir)
    entry = setup_node_with_candidates("node-s", ["192.0.2.1"])

    NodeProber.probe(entry,
      probe_fn: healthy_probe_fn(),
      audit_server: audit_name
    )

    events = read_events.()
    assert length(events) == 1
    [event] = events
    assert event["event_type"] == "node_probe_completed"
    assert event["attributes"]["node_id"] == "node-s"
    assert event["attributes"]["outcome"] == "healthy"
    assert event["attributes"]["verified_address_count"] == 1
    assert String.starts_with?(event["correlation_id"], "corr_")
  end

  @tag :tmp_dir
  test "emits audit event with identity_mismatch outcome", %{tmp_dir: tmp_dir} do
    {_pid, audit_name, read_events} = start_audit(tmp_dir)
    entry = setup_node_with_candidates("node-t", ["192.0.2.1"])

    NodeProber.probe(entry,
      probe_fn: identity_mismatch_probe_fn("spiffe://node/node-t", "spiffe://imposter"),
      audit_server: audit_name
    )

    [event] = read_events.()
    assert event["event_type"] == "node_probe_completed"
    assert event["attributes"]["outcome"] == "identity_mismatch"
    assert event["attributes"]["verified_address_count"] == 0
  end

  @tag :tmp_dir
  test "emits audit event with timeout outcome", %{tmp_dir: tmp_dir} do
    {_pid, audit_name, read_events} = start_audit(tmp_dir)
    entry = setup_node_with_candidates("node-u", ["192.0.2.1"])

    NodeProber.probe(entry,
      probe_fn: error_probe_fn(:timeout),
      audit_server: audit_name
    )

    [event] = read_events.()
    assert event["attributes"]["outcome"] == "timeout"
    assert event["attributes"]["verified_address_count"] == 0
  end

  @tag :tmp_dir
  test "emits audit event with degraded outcome", %{tmp_dir: tmp_dir} do
    {_pid, audit_name, read_events} = start_audit(tmp_dir)
    entry = setup_node_with_candidates("node-v", ["192.0.2.1"])

    probe_fn = fn _addr, _port, _host, _id, _timeout ->
      {:ok, %{agent_card: %{"name" => "node-v"}, health: %{"status" => "degraded"}}}
    end

    NodeProber.probe(entry,
      probe_fn: probe_fn,
      audit_server: audit_name
    )

    [event] = read_events.()
    assert event["attributes"]["outcome"] == "degraded"
  end

  @tag :tmp_dir
  test "audit event includes hostname for redaction context (not IP address)", %{tmp_dir: tmp_dir} do
    {_pid, audit_name, read_events} = start_audit(tmp_dir)
    entry = setup_node_with_candidates("node-w", ["192.0.2.1"])

    NodeProber.probe(entry,
      probe_fn: healthy_probe_fn(),
      audit_server: audit_name
    )

    [event] = read_events.()
    assert event["attributes"]["hostname"] == "node-w.example.test"
  end

  @tag :tmp_dir
  test "audit event is emitted even when Audit server is unavailable (no crash)", %{
    tmp_dir: _tmp_dir
  } do
    entry = setup_node_with_candidates("node-x", ["192.0.2.1"])

    # Non-existent audit server name — should not raise.
    result =
      NodeProber.probe(entry,
        probe_fn: healthy_probe_fn(),
        audit_server: :nonexistent_audit_server
      )

    # Probe still returns a result despite audit failure.
    assert result.outcome == :healthy
  end

  # ---------------------------------------------------------------------------
  # Mixed error patterns across candidates
  # ---------------------------------------------------------------------------

  test "mixed candidates: timeout then success adopts the successful address" do
    entry = setup_node_with_candidates("node-y", ["192.0.2.1", "192.0.2.2"])

    probe_fn =
      per_address_probe_fn(%{
        "192.0.2.1" => {:error, :timeout},
        "192.0.2.2" => {:ok, %{agent_card: %{"name" => "node-y"}, health: %{"status" => "ok"}}}
      })

    result = NodeProber.probe(entry, probe_fn: probe_fn)

    assert result.outcome == :healthy
    assert result.verified_addresses == ["192.0.2.2"]

    assert {:ok, %{addresses: ["192.0.2.2"]}} = Registry.get("node-y")
  end

  test "mixed candidates: unreachable then timeout yields timeout outcome" do
    entry = setup_node_with_candidates("node-z", ["192.0.2.1", "192.0.2.2"])

    probe_fn =
      per_address_probe_fn(%{
        "192.0.2.1" => {:error, :unreachable},
        "192.0.2.2" => {:error, :timeout}
      })

    result = NodeProber.probe(entry, probe_fn: probe_fn)

    # Last error was :timeout.
    assert result.outcome == :timeout
    assert result.verified_addresses == []
  end

  test "mixed candidates: timeout then unreachable yields unreachable outcome" do
    entry = setup_node_with_candidates("node-aa", ["192.0.2.1", "192.0.2.2"])

    probe_fn =
      per_address_probe_fn(%{
        "192.0.2.1" => {:error, :timeout},
        "192.0.2.2" => {:error, :unreachable}
      })

    result = NodeProber.probe(entry, probe_fn: probe_fn)

    assert result.outcome == :unreachable
  end

  # ---------------------------------------------------------------------------
  # Registry isolation between nodes
  # ---------------------------------------------------------------------------

  test "probing one node does not affect another node's addresses" do
    :ok =
      Inventory.replace_json(
        inventory_json([
          inventory_node("node-ab"),
          inventory_node("node-ac")
        ])
      )

    :ok = Registry.put_candidates("node-ab", ["192.0.2.1"])
    :ok = Registry.put_candidates("node-ac", [])
    :ok = Registry.update("node-ac", %{addresses: ["10.0.10.1"]})
    {:ok, node_a_entry} = Registry.get("node-ab")

    NodeProber.probe(node_a_entry, probe_fn: healthy_probe_fn())

    # node-ac's addresses must remain untouched.
    assert {:ok, %{addresses: ["10.0.10.1"]}} = Registry.get("node-ac")
  end

  test "attempt token atomically records a successful probe observation" do
    entry = setup_node_with_candidates("node-token-success", ["192.0.2.20"])
    :ok = make_poll_eligible(entry.id)
    assert {:ok, token} = Registry.begin_poll(entry.id)

    assert %{outcome: :healthy} =
             NodeProber.probe(entry,
               probe_fn: healthy_probe_fn(),
               attempt_token: token
             )

    assert {:ok,
            %{
              reachability: :healthy,
              addresses: ["192.0.2.20"],
              last_attempted_contact: %DateTime{},
              last_successful_contact: %DateTime{},
              consecutive_failures: 0
            }} = Registry.get(entry.id)
  end

  test "attempt token records a failed probe and schedules backoff" do
    entry = setup_node_with_candidates("node-token-failure", ["192.0.2.21"])
    :ok = make_poll_eligible(entry.id)
    assert {:ok, token} = Registry.begin_poll(entry.id)

    assert %{outcome: :timeout} =
             NodeProber.probe(entry,
               probe_fn: error_probe_fn(:timeout),
               attempt_token: token
             )

    assert {:ok,
            %{
              reachability: :unreachable,
              consecutive_failures: 1,
              next_eligible_poll_at: %DateTime{}
            }} = Registry.get(entry.id)
  end

  # ---------------------------------------------------------------------------
  # Result structure completeness
  # ---------------------------------------------------------------------------

  test "all probe_result fields are present on healthy outcome" do
    entry = setup_node_with_candidates("node-ad", ["192.0.2.1"])
    result = NodeProber.probe(entry, probe_fn: healthy_probe_fn())

    assert Map.has_key?(result, :outcome)
    assert Map.has_key?(result, :node_id)
    assert Map.has_key?(result, :verified_addresses)
    assert Map.has_key?(result, :agent_card)
    assert Map.has_key?(result, :health)
    assert Map.has_key?(result, :error_details)
  end

  test "all probe_result fields are present on identity_mismatch outcome" do
    entry = setup_node_with_candidates("node-ae", ["192.0.2.1"])

    result =
      NodeProber.probe(entry,
        probe_fn: identity_mismatch_probe_fn("spiffe://node/node-ae", "spiffe://evil")
      )

    assert Map.has_key?(result, :outcome)
    assert Map.has_key?(result, :node_id)
    assert Map.has_key?(result, :verified_addresses)
    assert Map.has_key?(result, :agent_card)
    assert Map.has_key?(result, :health)
    assert Map.has_key?(result, :error_details)

    assert result.node_id == "node-ae"
    assert result.agent_card == nil
    assert result.health == nil
  end

  test "all probe_result fields are present on timeout outcome" do
    entry = setup_node_with_candidates("node-af", ["192.0.2.1"])
    result = NodeProber.probe(entry, probe_fn: error_probe_fn(:timeout))

    assert Map.has_key?(result, :outcome)
    assert Map.has_key?(result, :node_id)
    assert result.verified_addresses == []
    assert result.agent_card == nil
    assert result.health == nil
  end

  defp make_poll_eligible(node_id) do
    Registry.update(node_id, %{next_eligible_poll_at: DateTime.add(DateTime.utc_now(), -1)})
  end
end

defmodule Exocomp.Coordinator.RegistryTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.{Audit, Inventory, Registry}
  alias Exocomp.Coordinator.Inventory.Node

  defmodule MessageSink do
    @behaviour Exocomp.Coordinator.Audit.Sink

    @impl true
    def init(opts), do: {:ok, Keyword.fetch!(opts, :owner)}

    @impl true
    def write(owner, event) do
      send(owner, {:audit_event, event})
      {:ok, owner}
    end

    @impl true
    def close(_owner), do: :ok
  end

  setup do
    json =
      :json.encode(%{
        "version" => 1,
        "nodes" => [
          %{
            "id" => "node-a",
            "hostname" => "node-a.example.test",
            "port" => 8443,
            "certificate_identity" => "spiffe://node/node-a",
            "capabilities" => [],
            "labels" => %{}
          }
        ]
      })

    :ok = Inventory.replace_json(IO.iodata_to_binary(json))
    :ok
  end

  test "gets and updates bounded live node state" do
    assert {:ok,
            %{
              id: "node-a",
              reachability: :unknown,
              last_attempted_contact: nil,
              last_successful_contact: nil,
              consecutive_failures: 0,
              next_eligible_poll_at: %DateTime{}
            }} = Registry.get("node-a")

    assert :ok = Registry.update("node-a", %{reachability: :healthy, consecutive_failures: 0})
    assert {:ok, %{reachability: :healthy}} = Registry.get("node-a")
    assert {:error, :invalid_state} = Registry.update("node-a", %{reachability: :missing})
    assert {:error, :not_found} = Registry.update("missing", %{reachability: :healthy})
    assert :error = Registry.get("missing")
  end

  test "initial scheduling uses the 30-second default and bounded configurable jitter" do
    initial = ~U[2026-07-24 00:00:00.000Z]

    cases = [
      {:minimum, fn minimum, _maximum -> minimum end, 27_000},
      {:middle, fn _minimum, _maximum -> 0 end, 30_000},
      {:maximum, fn _minimum, maximum -> maximum end, 33_000}
    ]

    for {label, random, expected_ms} <- cases do
      {server, _clock} = start_registry(initial, random: random)
      :ok = Registry.rebuild([inventory_node("#{label}")], server)

      assert {:ok, entry} = Registry.get("#{label}", server)
      assert DateTime.diff(entry.next_eligible_poll_at, initial, :millisecond) == expected_ms
      assert Registry.due_nodes(server) == []
    end
  end

  test "due nodes are deterministic and begin_poll records the attempt timestamp" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {server, clock} = start_registry(initial, jitter_ms: 0)
    :ok = Registry.rebuild([inventory_node("node-b"), inventory_node("node-a")], server)

    set_clock(clock, DateTime.add(initial, 30_000, :millisecond))
    assert Enum.map(Registry.due_nodes(server), & &1.id) == ["node-a", "node-b"]

    assert {:ok, 1} = Registry.begin_poll("node-a", server)
    attempted_at = DateTime.add(initial, 30_000, :millisecond)
    assert {:ok, %{last_attempted_contact: ^attempted_at}} = Registry.get("node-a", server)
    assert Enum.map(Registry.due_nodes(server), & &1.id) == ["node-b"]
    assert {:error, :not_eligible} = Registry.begin_poll("node-a", server)
    assert {:error, :not_found} = Registry.begin_poll("missing", server)
  end

  test "success and degraded observations update timestamps and reset failures" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {server, clock} = start_registry(initial, jitter_ms: 0)
    :ok = Registry.rebuild([inventory_node("node-a")], server)

    set_clock(clock, DateTime.add(initial, 30_000, :millisecond))
    assert {:ok, token} = Registry.begin_poll("node-a", server)

    assert {:ok, healthy} =
             Registry.record_observation(
               "node-a",
               token,
               %{outcome: :healthy, verified_addresses: ["192.0.2.1"]},
               server
             )

    assert healthy.reachability == :healthy
    assert healthy.last_attempted_contact == DateTime.add(initial, 30_000, :millisecond)
    assert healthy.last_successful_contact == healthy.last_attempted_contact
    assert healthy.addresses == ["192.0.2.1"]
    assert healthy.consecutive_failures == 0

    assert DateTime.diff(
             healthy.next_eligible_poll_at,
             healthy.last_successful_contact,
             :millisecond
           ) ==
             30_000

    set_clock(clock, healthy.next_eligible_poll_at)
    assert {:ok, token} = Registry.begin_poll("node-a", server)
    assert {:ok, degraded} = Registry.record_observation("node-a", token, :degraded, server)
    assert degraded.reachability == :degraded
    assert degraded.last_successful_contact == degraded.last_attempted_contact
    assert degraded.consecutive_failures == 0
  end

  test "freshness thresholds map failures to degraded, stale, and unreachable" do
    now = ~U[2026-07-24 00:10:00.000Z]

    cases = [
      {:timeout, 59_999, :degraded},
      {:unreachable, 60_000, :stale},
      {:identity_mismatch, 299_999, :stale},
      {:authentication_failure, 300_000, :unreachable}
    ]

    for {outcome, success_age_ms, expected} <- cases do
      {server, _clock} = start_registry(now, jitter_ms: 0)
      node_id = Atom.to_string(outcome) <> Integer.to_string(success_age_ms)
      :ok = Registry.rebuild([inventory_node(node_id)], server)

      :ok =
        Registry.update(
          node_id,
          %{
            last_successful_contact: DateTime.add(now, -success_age_ms, :millisecond),
            next_eligible_poll_at: now,
            reachability: :healthy
          },
          server
        )

      assert {:ok, token} = Registry.begin_poll(node_id, server)
      assert {:ok, entry} = Registry.record_observation(node_id, token, outcome, server)
      assert entry.reachability == expected
      assert entry.consecutive_failures == 1
      assert entry.last_successful_contact == DateTime.add(now, -success_age_ms, :millisecond)
    end

    {server, _clock} = start_registry(now, jitter_ms: 0)
    :ok = Registry.rebuild([inventory_node("never-seen")], server)
    :ok = Registry.update("never-seen", %{next_eligible_poll_at: now}, server)
    assert {:ok, token} = Registry.begin_poll("never-seen", server)

    assert {:ok, %{reachability: :unreachable}} =
             Registry.record_observation("never-seen", token, :timeout, server)
  end

  test "state transition table covers recovery and every reachability state" do
    now = ~U[2026-07-24 00:10:00.000Z]

    cases = [
      {:unknown, nil, :healthy, :healthy},
      {:healthy, now, :degraded, :degraded},
      {:degraded, DateTime.add(now, -60_000, :millisecond), :timeout, :stale},
      {:stale, DateTime.add(now, -300_000, :millisecond), :unreachable, :unreachable},
      {:unreachable, nil, :healthy, :healthy}
    ]

    for {from, last_success, outcome, expected} <- cases do
      node_id = "#{from}-#{outcome}"
      {server, _clock} = start_registry(now, jitter_ms: 0)
      :ok = Registry.rebuild([inventory_node(node_id)], server)

      :ok =
        Registry.update(
          node_id,
          %{
            reachability: from,
            last_successful_contact: last_success,
            next_eligible_poll_at: now
          },
          server
        )

      assert {:ok, token} = Registry.begin_poll(node_id, server)

      assert {:ok, %{reachability: ^expected}} =
               Registry.record_observation(node_id, token, outcome, server)
    end
  end

  test "bounded exponential backoff grows, caps, and resets on recovery" do
    initial = ~U[2026-07-24 00:00:00.000Z]

    {server, clock} =
      start_registry(initial,
        poll_interval_ms: 1_000,
        jitter_ms: 0,
        backoff_cap_ms: 4_000
      )

    :ok = Registry.rebuild([inventory_node("node-a")], server)

    for {failure, expected_delay} <- [{1, 1_000}, {2, 2_000}, {3, 4_000}, {4, 4_000}] do
      {:ok, entry} = Registry.get("node-a", server)
      set_clock(clock, entry.next_eligible_poll_at)
      assert {:ok, token} = Registry.begin_poll("node-a", server)
      attempted_at = Agent.get(clock, & &1)
      assert {:ok, failed} = Registry.record_observation("node-a", token, :timeout, server)
      assert failed.consecutive_failures == failure

      assert DateTime.diff(failed.next_eligible_poll_at, attempted_at, :millisecond) ==
               expected_delay
    end

    {:ok, entry} = Registry.get("node-a", server)
    set_clock(clock, entry.next_eligible_poll_at)
    assert {:ok, token} = Registry.begin_poll("node-a", server)
    assert {:ok, recovered} = Registry.record_observation("node-a", token, :healthy, server)
    assert recovered.reachability == :healthy
    assert recovered.consecutive_failures == 0

    set_clock(clock, recovered.next_eligible_poll_at)
    assert {:ok, token} = Registry.begin_poll("node-a", server)
    attempted_at = Agent.get(clock, & &1)
    assert {:ok, failed_again} = Registry.record_observation("node-a", token, :timeout, server)
    assert failed_again.consecutive_failures == 1
    assert DateTime.diff(failed_again.next_eligible_poll_at, attempted_at, :millisecond) == 1_000
  end

  test "late results cannot overwrite a newer observation" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {server, clock} = start_registry(initial, jitter_ms: 0)
    :ok = Registry.rebuild([inventory_node("node-a")], server)

    set_clock(clock, DateTime.add(initial, 30_000, :millisecond))
    assert {:ok, first_token} = Registry.begin_poll("node-a", server)
    assert {:ok, first} = Registry.record_observation("node-a", first_token, :timeout, server)

    set_clock(clock, first.next_eligible_poll_at)
    assert {:ok, second_token} = Registry.begin_poll("node-a", server)
    assert second_token > first_token
    assert {:ok, newer} = Registry.record_observation("node-a", second_token, :healthy, server)

    assert {:ignored, :stale} =
             Registry.record_observation(
               "node-a",
               first_token,
               %{outcome: :degraded, verified_addresses: ["203.0.113.99"]},
               server
             )

    assert Registry.get("node-a", server) == {:ok, newer}
  end

  test "emits redacted transition-only audit events" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    audit_name = unique_name(:registry_audit)

    start_supervised!(
      {Audit, name: audit_name, sink: {MessageSink, owner: self()}},
      id: audit_name
    )

    {server, clock} = start_registry(initial, jitter_ms: 0, audit_server: audit_name)
    :ok = Registry.rebuild([inventory_node("node-a")], server)
    set_clock(clock, DateTime.add(initial, 30_000, :millisecond))
    assert {:ok, token} = Registry.begin_poll("node-a", server)

    result = %{
      outcome: :healthy,
      verified_addresses: ["192.0.2.1"],
      error_details: %{authorization: "Bearer secret", token: "plain-token"}
    }

    assert {:ok, _entry} = Registry.record_observation("node-a", token, result, server)

    assert_receive {:audit_event,
                    %{
                      "event_type" => "node_poll_transition",
                      "attributes" => attributes
                    }}

    assert attributes["node_id"] == "node-a"
    assert attributes["from"] == "unknown"
    assert attributes["to"] == "healthy"
    refute inspect(attributes) =~ "secret"
    refute inspect(attributes) =~ "plain-token"

    {:ok, entry} = Registry.get("node-a", server)
    set_clock(clock, entry.next_eligible_poll_at)
    assert {:ok, token} = Registry.begin_poll("node-a", server)
    assert {:ok, _entry} = Registry.record_observation("node-a", token, :healthy, server)
    refute_receive {:audit_event, %{"event_type" => "node_poll_transition"}}
  end

  test "rejects invalid outcomes" do
    now = ~U[2026-07-24 00:00:00.000Z]
    {server, clock} = start_registry(now, jitter_ms: 0)
    :ok = Registry.rebuild([inventory_node("node-a")], server)
    set_clock(clock, DateTime.add(now, 30_000, :millisecond))
    assert {:ok, token} = Registry.begin_poll("node-a", server)

    assert {:error, :invalid_outcome} =
             Registry.record_observation("node-a", token, :bogus, server)

    assert {:error, :not_found} = Registry.record_observation("missing", token, :healthy, server)
  end

  test "reconstructs configured nodes after registry restart" do
    previous = Process.whereis(Registry)
    reference = Process.monitor(previous)
    Process.exit(previous, :kill)
    assert_receive {:DOWN, ^reference, :process, ^previous, :killed}

    restarted = wait_for_restart(previous)
    assert is_pid(restarted)
    assert {:ok, %{id: "node-a", reachability: :unknown}} = wait_for_node()
  end

  defp start_registry(initial, opts) do
    clock_name = unique_name(:clock)
    {:ok, clock} = Agent.start_link(fn -> initial end, name: clock_name)
    registry_name = unique_name(:registry)

    registry =
      start_supervised!(
        {Registry,
         Keyword.merge(
           [
             name: registry_name,
             clock: fn -> Agent.get(clock, & &1) end,
             random: fn _minimum, _maximum -> 0 end,
             audit_server: unique_name(:missing_audit)
           ],
           opts
         )},
        id: registry_name
      )

    {registry, clock}
  end

  defp inventory_node(id) do
    %Node{
      id: id,
      hostname: "#{id}.example.test",
      port: 8443,
      certificate_identity: "spiffe://node/#{id}",
      capabilities: [],
      labels: %{}
    }
  end

  defp set_clock(clock, value), do: Agent.update(clock, fn _previous -> value end)

  defp unique_name(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"

  defp wait_for_restart(previous, attempts \\ 50)

  defp wait_for_restart(_previous, 0), do: nil

  defp wait_for_restart(previous, attempts) do
    case Process.whereis(Registry) do
      pid when is_pid(pid) and pid != previous ->
        pid

      _other ->
        Process.sleep(10)
        wait_for_restart(previous, attempts - 1)
    end
  end

  defp wait_for_node(attempts \\ 50)
  defp wait_for_node(0), do: Registry.get("node-a")

  defp wait_for_node(attempts) do
    case Registry.get("node-a") do
      {:ok, _entry} = found ->
        found

      :error ->
        Process.sleep(10)
        wait_for_node(attempts - 1)
    end
  end
end

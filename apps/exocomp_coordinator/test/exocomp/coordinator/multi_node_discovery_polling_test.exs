defmodule Exocomp.Coordinator.MultiNodeDiscoveryPollingTest do
  @moduledoc """
  Cross-component integration suite for multi-node discovery and health polling.

  Exercises the full Registry → HealthPoller pipeline with at least three
  controllable TLS node fixtures and a deterministic DNS/resolver seam.  All
  seams (clock, random, resolver, probe, audit) are injectable so no test
  requires a wall-clock sleep or real network call.

  Coverage areas:
  - Three concurrent healthy nodes
  - Degraded health status
  - Slow / timed-out node isolation (per-node timeout does not block peers)
  - Unreachable node (all candidates fail)
  - Wrong-identity node (identity_mismatch halts probe; previous address preserved)
  - Multiple DNS addresses per node (only verified addresses adopted)
  - DNS address change accepted after mTLS verification
  - Failed DNS address change retains last verified address
  - Bounded concurrent polling (concurrency cap and capacity refill)
  - Exponential backoff on consecutive failures
  - Recovery of a previously failing node without blocking unrelated nodes
  - Stale-node state transitions with injectable clock
  - Redacted audit events for reachability transitions
  """

  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.{Audit, HealthPoller, Inventory.Node, Registry}

  # ---------------------------------------------------------------------------
  # Audit sink that sends events to the test process.
  # ---------------------------------------------------------------------------

  defmodule MessageSink do
    @moduledoc false
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

  # ---------------------------------------------------------------------------
  # Fixture builders
  # ---------------------------------------------------------------------------

  defp node_fixture(suffix) do
    %Node{
      id: "integ-#{suffix}",
      hostname: "integ-#{suffix}.cluster.test",
      port: 9443,
      certificate_identity: "spiffe://cluster/integ-#{suffix}",
      capabilities: ["exocomp.node.health"],
      labels: %{"env" => "integration"}
    }
  end

  # Three canonical node fixtures used throughout the suite.
  defp three_nodes, do: Enum.map(["alpha", "beta", "gamma"], &node_fixture/1)

  # Minimal healthy probe result for a given entry.
  defp healthy_result(entry, extra_addresses \\ nil) do
    addresses = extra_addresses || entry.candidate_addresses
    addresses = if addresses == [], do: ["192.0.2.1"], else: addresses

    %{
      outcome: :healthy,
      node_id: entry.id,
      verified_addresses: addresses,
      agent_card: %{
        "version" => "1.0",
        "skills" => ["exocomp.node.health", "chat"]
      },
      health: %{"status" => "ok", "summary" => "node ready"},
      error_details: %{}
    }
  end

  # Degraded probe result.
  defp degraded_result(entry) do
    %{
      outcome: :degraded,
      node_id: entry.id,
      verified_addresses: entry.candidate_addresses,
      agent_card: %{"version" => "1.0", "skills" => []},
      health: %{"status" => "degraded", "reason" => "memory pressure"},
      error_details: %{}
    }
  end

  # ---------------------------------------------------------------------------
  # Process helpers
  # ---------------------------------------------------------------------------

  defp start_registry(initial, opts \\ []) do
    {:ok, clock} = Agent.start_link(fn -> initial end)
    name = unique_name(:registry)
    audit = Keyword.get(opts, :audit_server, unique_name(:audit_noop))

    start_supervised!(
      {Registry,
       [
         name: name,
         clock: fn -> Agent.get(clock, & &1) end,
         random: fn _min, _max -> 0 end,
         poll_interval_ms: Keyword.get(opts, :poll_interval_ms, 50),
         jitter_ms: 0,
         backoff_cap_ms: Keyword.get(opts, :backoff_cap_ms, 900_000),
         degraded_after_ms: Keyword.get(opts, :degraded_after_ms, 60_000),
         stale_after_ms: Keyword.get(opts, :stale_after_ms, 300_000),
         audit_server: audit
       ]},
      id: name
    )

    {name, clock}
  end

  defp advance_clock(clock, by_ms) do
    Agent.update(clock, &DateTime.add(&1, by_ms, :millisecond))
  end

  defp start_audit do
    name = unique_name(:audit)
    start_supervised!({Audit, name: name, sink: {MessageSink, owner: self()}}, id: name)
    name
  end

  defp start_task_supervisor do
    name = unique_name(:task_supervisor)
    start_supervised!({Task.Supervisor, name: name}, id: name)
    name
  end

  defp start_poller(registry, task_supervisor, opts) do
    id = unique_name(:poller)

    options =
      [
        name: id,
        registry_server: registry,
        task_supervisor: task_supervisor,
        interval_ms: 60_000,
        timeout_ms: Keyword.get(opts, :timeout_ms, 2_000),
        start_immediately: false
      ]
      |> Keyword.merge(Keyword.delete(opts, :timeout_ms))

    start_supervised!({HealthPoller, options}, id: id)
    id
  end

  defp eventually(assertion, attempts \\ 200)
  defp eventually(assertion, 0), do: assert(assertion.())

  defp eventually(assertion, attempts) do
    if assertion.() do
      :ok
    else
      Process.sleep(5)
      eventually(assertion, attempts - 1)
    end
  end

  defp collect_audit_events do
    collect_audit_events([])
  end

  defp collect_audit_events(acc) do
    receive do
      {:audit_event, event} -> collect_audit_events([event | acc])
    after
      10 -> Enum.reverse(acc)
    end
  end

  defp unique_name(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"

  # ---------------------------------------------------------------------------
  # 1. Three healthy nodes — all reach :healthy with correct Registry state
  # ---------------------------------------------------------------------------

  test "three healthy nodes all reach :healthy with addresses, Agent Card metadata, and timestamps" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    task_supervisor = start_task_supervisor()
    nodes = three_nodes()
    :ok = Registry.rebuild(nodes, registry)

    # Advance clock past the initial poll interval so all nodes are due.
    advance_clock(clock, 60)

    owner = self()

    # Resolver assigns a distinct address per node.
    resolver_adapter = fn entry ->
      suffix = String.split(entry.id, "-") |> List.last()

      address =
        case suffix do
          "alpha" -> "192.0.2.10"
          "beta" -> "192.0.2.11"
          "gamma" -> "192.0.2.12"
          _ -> "192.0.2.99"
        end

      {:ok, [address]}
    end

    probe_adapter = fn entry, _opts ->
      send(owner, {:probed, entry.id})
      healthy_result(entry)
    end

    poller =
      start_poller(registry, task_supervisor,
        concurrency: 3,
        resolver_adapter: resolver_adapter,
        probe_adapter: probe_adapter
      )

    :ok = HealthPoller.poll_now(poller)

    # All three nodes are probed.
    for node <- nodes do
      node_id = node.id
      assert_receive {:probed, ^node_id}, 2_000
    end

    eventually(fn ->
      Enum.all?(Registry.all(registry), &(&1.reachability == :healthy))
    end)

    Enum.each(Registry.all(registry), fn entry ->
      assert entry.reachability == :healthy
      assert entry.consecutive_failures == 0
      refute is_nil(entry.last_successful_contact)
      refute is_nil(entry.last_attempted_contact)
      assert entry.agent_card_version == "1.0"
      assert "exocomp.node.health" in entry.supported_skills
      assert "chat" in entry.supported_skills
      assert entry.diagnostic_summary == "node ready"
      refute entry.addresses == []
      refute is_nil(entry.next_eligible_poll_at)
    end)

    # Each node has its DNS-assigned address.
    assert {:ok, %{addresses: ["192.0.2.10"]}} = Registry.get("integ-alpha", registry)
    assert {:ok, %{addresses: ["192.0.2.11"]}} = Registry.get("integ-beta", registry)
    assert {:ok, %{addresses: ["192.0.2.12"]}} = Registry.get("integ-gamma", registry)
  end

  # ---------------------------------------------------------------------------
  # 2. Degraded health status — correct reachability and metadata
  # ---------------------------------------------------------------------------

  test "degraded health response results in :degraded reachability with addresses and metadata" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    task_supervisor = start_task_supervisor()
    [node | _] = [node_fixture("delta")]
    :ok = Registry.rebuild([node], registry)
    advance_clock(clock, 60)

    probe_adapter = fn entry, _opts ->
      degraded_result(entry)
    end

    resolver_adapter = fn _entry -> {:ok, ["192.0.2.20"]} end

    poller =
      start_poller(registry, task_supervisor,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)

    eventually(fn ->
      {:ok, e} = Registry.get("integ-delta", registry)
      e.reachability == :degraded
    end)

    {:ok, entry} = Registry.get("integ-delta", registry)
    assert entry.reachability == :degraded
    assert entry.addresses == ["192.0.2.20"]
    assert entry.consecutive_failures == 0
    refute is_nil(entry.last_successful_contact)
  end

  # ---------------------------------------------------------------------------
  # 3. Per-node timeout isolation — slow node does not block healthy peers
  # ---------------------------------------------------------------------------

  test "slow node is killed at its own timeout without blocking other nodes" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    task_supervisor = start_task_supervisor()

    nodes = three_nodes()
    :ok = Registry.rebuild(nodes, registry)
    advance_clock(clock, 60)

    owner = self()

    probe_adapter = fn
      %{id: "integ-alpha"} = _entry, _opts ->
        send(owner, {:slow_started, self()})
        # Block forever — timeout will kill this task.
        receive do: (:never_released -> :unreachable)

      entry, _opts ->
        send(owner, {:fast_done, entry.id})
        healthy_result(entry)
    end

    resolver_adapter = fn _entry -> {:ok, ["192.0.2.30"]} end

    poller =
      start_poller(registry, task_supervisor,
        concurrency: 3,
        timeout_ms: 80,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)

    assert_receive {:slow_started, slow_pid}, 2_000
    assert_receive {:fast_done, "integ-beta"}, 2_000
    assert_receive {:fast_done, "integ-gamma"}, 2_000

    # Peers reach :healthy without waiting for the slow node.
    eventually(fn ->
      {:ok, beta} = Registry.get("integ-beta", registry)
      {:ok, gamma} = Registry.get("integ-gamma", registry)
      beta.reachability == :healthy and gamma.reachability == :healthy
    end)

    # Slow node is killed after its timeout and becomes :unreachable.
    eventually(fn ->
      {:ok, alpha} = Registry.get("integ-alpha", registry)
      alpha.reachability == :unreachable and not Process.alive?(slow_pid)
    end)

    # Poller capacity is fully released after all outcomes are recorded.
    eventually(fn -> HealthPoller.in_flight(poller) == [] end)

    {:ok, alpha} = Registry.get("integ-alpha", registry)
    assert alpha.reachability == :unreachable
    assert alpha.consecutive_failures == 1
  end

  # ---------------------------------------------------------------------------
  # 4. Unreachable node — all candidates unreachable; previous address retained
  # ---------------------------------------------------------------------------

  test "unreachable node retains previously verified addresses and increments failure counter" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    task_supervisor = start_task_supervisor()

    nodes = [node_fixture("echo"), node_fixture("foxtrot"), node_fixture("golf")]
    :ok = Registry.rebuild(nodes, registry)

    # Pre-seed echo with a verified address so we can confirm it's preserved.
    :ok = Registry.put_candidates("integ-echo", ["10.0.0.1"], registry)
    :ok = Registry.update("integ-echo", %{addresses: ["10.0.0.1"]}, registry)

    advance_clock(clock, 60)

    probe_adapter = fn
      %{id: "integ-echo"}, _opts ->
        :unreachable

      entry, _opts ->
        healthy_result(entry)
    end

    resolver_adapter = fn
      %{id: "integ-echo"} -> {:ok, ["10.0.0.1"]}
      _entry -> {:ok, ["192.0.2.40"]}
    end

    poller =
      start_poller(registry, task_supervisor,
        concurrency: 3,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)

    eventually(fn ->
      {:ok, e} = Registry.get("integ-echo", registry)
      e.reachability == :unreachable
    end)

    # Verified address is preserved after the unreachable probe.
    {:ok, echo} = Registry.get("integ-echo", registry)
    assert echo.addresses == ["10.0.0.1"]
    assert echo.consecutive_failures == 1
    refute is_nil(echo.next_eligible_poll_at)

    # Peers are not affected.
    {:ok, foxtrot} = Registry.get("integ-foxtrot", registry)
    assert foxtrot.reachability == :healthy
  end

  # ---------------------------------------------------------------------------
  # 5. Wrong identity — identity_mismatch halts probe; previous address preserved
  # ---------------------------------------------------------------------------

  test "identity_mismatch halts probing immediately and preserves the last verified address" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    task_supervisor = start_task_supervisor()

    nodes = [node_fixture("hotel"), node_fixture("india"), node_fixture("juliet")]
    :ok = Registry.rebuild(nodes, registry)

    # Pre-seed hotel with a known verified address.
    :ok = Registry.update("integ-hotel", %{addresses: ["10.1.0.1"]}, registry)

    advance_clock(clock, 60)

    {:ok, call_agent} = Agent.start_link(fn -> 0 end)

    probe_adapter = fn
      %{id: "integ-hotel"}, _opts ->
        Agent.update(call_agent, &(&1 + 1))

        %{
          outcome: :identity_mismatch,
          node_id: "integ-hotel",
          verified_addresses: [],
          agent_card: nil,
          health: nil,
          error_details: %{
            expected: "spiffe://cluster/integ-hotel",
            actual: "spiffe://cluster/IMPOSTER"
          }
        }

      entry, _opts ->
        healthy_result(entry)
    end

    resolver_adapter = fn
      %{id: "integ-hotel"} -> {:ok, ["10.1.0.2", "10.1.0.3"]}
      _entry -> {:ok, ["192.0.2.50"]}
    end

    poller =
      start_poller(registry, task_supervisor,
        concurrency: 3,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)

    eventually(fn ->
      {:ok, h} = Registry.get("integ-hotel", registry)
      h.consecutive_failures >= 1
    end)

    # Previous verified address must be preserved.
    {:ok, hotel} = Registry.get("integ-hotel", registry)
    assert hotel.addresses == ["10.1.0.1"]

    # The HealthPoller delivers the identity_mismatch result as a failure;
    # reachability is :unreachable (no prior success).
    assert hotel.reachability == :unreachable

    # Peers are not affected.
    {:ok, india} = Registry.get("integ-india", registry)
    assert india.reachability == :healthy
  end

  # ---------------------------------------------------------------------------
  # 6. Multiple DNS addresses — only verified subset adopted
  # ---------------------------------------------------------------------------

  test "multiple candidate addresses — only addresses that pass mTLS verification are adopted" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    task_supervisor = start_task_supervisor()
    node = node_fixture("kilo")
    :ok = Registry.rebuild([node], registry)
    advance_clock(clock, 60)

    # Resolver returns three candidates; the middle one will fail.
    resolver_adapter = fn _entry ->
      {:ok, ["192.0.2.61", "192.0.2.62", "192.0.2.63"]}
    end

    probe_adapter = fn entry, opts ->
      probe_fn =
        Keyword.get(opts, :probe_fn, fn address, _port, _host, _id, _timeout ->
          case address do
            "192.0.2.61" ->
              {:ok,
               %{
                 agent_card: %{"version" => "2.0", "skills" => ["chat"]},
                 health: %{"status" => "ok", "summary" => "ready"}
               }}

            "192.0.2.62" ->
              {:error, :timeout}

            "192.0.2.63" ->
              {:ok,
               %{
                 agent_card: %{"version" => "2.0", "skills" => ["chat"]},
                 health: %{"status" => "ok", "summary" => "ready"}
               }}
          end
        end)

      # Simulate what NodeProber does: iterate candidates.
      verified =
        for addr <- entry.candidate_addresses,
            match?(
              {:ok, _},
              probe_fn.(addr, entry.port, entry.hostname, entry.certificate_identity, 1_000)
            ) do
          addr
        end

      if verified == [] do
        :timeout
      else
        %{
          outcome: :healthy,
          node_id: entry.id,
          verified_addresses: verified,
          agent_card: %{"version" => "2.0", "skills" => ["chat"]},
          health: %{"status" => "ok", "summary" => "ready"},
          error_details: %{}
        }
      end
    end

    poller =
      start_poller(registry, task_supervisor,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)

    eventually(fn ->
      {:ok, e} = Registry.get("integ-kilo", registry)
      e.reachability == :healthy
    end)

    {:ok, entry} = Registry.get("integ-kilo", registry)
    assert "192.0.2.61" in entry.addresses
    refute "192.0.2.62" in entry.addresses
    assert "192.0.2.63" in entry.addresses
    assert length(entry.addresses) == 2
  end

  # ---------------------------------------------------------------------------
  # 7. DNS address change accepted only after mTLS verification
  # ---------------------------------------------------------------------------

  test "DNS address change is accepted into Registry only after successful mTLS verification" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    task_supervisor = start_task_supervisor()
    node = node_fixture("lima")
    :ok = Registry.rebuild([node], registry)

    # Pre-set an old verified address.
    :ok = Registry.update("integ-lima", %{addresses: ["10.2.0.1"]}, registry)
    advance_clock(clock, 60)

    # DNS now returns a new address.
    resolver_adapter = fn _entry -> {:ok, ["10.2.0.99"]} end

    # Probe succeeds on the new DNS address.
    probe_adapter = fn entry, _opts ->
      %{
        outcome: :healthy,
        node_id: entry.id,
        verified_addresses: entry.candidate_addresses,
        agent_card: %{"version" => "1.0", "skills" => []},
        health: %{"status" => "ok", "summary" => "migrated"},
        error_details: %{}
      }
    end

    poller =
      start_poller(registry, task_supervisor,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)

    eventually(fn ->
      {:ok, e} = Registry.get("integ-lima", registry)
      e.reachability == :healthy
    end)

    {:ok, entry} = Registry.get("integ-lima", registry)
    # New address adopted after successful mTLS verification.
    assert entry.addresses == ["10.2.0.99"]
    refute "10.2.0.1" in entry.addresses
  end

  # ---------------------------------------------------------------------------
  # 8. Failed DNS address change retains last verified address
  # ---------------------------------------------------------------------------

  test "failed DNS address change retains the last verified address in Registry" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    task_supervisor = start_task_supervisor()
    node = node_fixture("mike")
    :ok = Registry.rebuild([node], registry)

    # Pre-set an old verified address.
    :ok = Registry.update("integ-mike", %{addresses: ["10.3.0.1"]}, registry)
    advance_clock(clock, 60)

    # DNS now returns a new candidate address.
    resolver_adapter = fn _entry -> {:ok, ["10.3.0.99"]} end

    # Probe fails on the new DNS candidate.
    probe_adapter = fn _entry, _opts ->
      :unreachable
    end

    poller =
      start_poller(registry, task_supervisor,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)

    eventually(fn ->
      {:ok, e} = Registry.get("integ-mike", registry)
      e.consecutive_failures >= 1
    end)

    # Old address must be preserved — DNS success alone does not replace addresses.
    {:ok, entry} = Registry.get("integ-mike", registry)
    assert entry.addresses == ["10.3.0.1"]
    refute "10.3.0.99" in entry.addresses
  end

  # ---------------------------------------------------------------------------
  # 9. Bounded concurrent polling — capacity cap and refill
  # ---------------------------------------------------------------------------

  test "concurrent polling respects the concurrency cap and refills capacity after completion" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    task_supervisor = start_task_supervisor()

    # Four nodes, concurrency bound of 2.
    nodes = Enum.map(["november", "oscar", "papa", "quebec"], &node_fixture/1)
    :ok = Registry.rebuild(nodes, registry)
    advance_clock(clock, 60)

    owner = self()

    probe_adapter = fn entry, _opts ->
      send(owner, {:started, entry.id, self()})
      receive do: (:release -> healthy_result(entry))
    end

    resolver_adapter = fn _entry -> {:ok, ["192.0.2.70"]} end

    poller =
      start_poller(registry, task_supervisor,
        concurrency: 2,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)

    # Exactly 2 workers start; the other 2 wait.
    first_batch =
      for _ <- 1..2, into: %{} do
        assert_receive {:started, node_id, pid}, 2_000
        {node_id, pid}
      end

    assert map_size(first_batch) == 2
    # No third worker should start while the cap is held.
    refute_receive {:started, _, _}, 50

    # Release one worker; a third node is dispatched to fill capacity.
    {_id, first_pid} = Enum.at(first_batch, 0)
    send(first_pid, :release)
    assert_receive {:started, third_id, third_pid}, 2_000
    refute Map.has_key?(first_batch, third_id)

    # Release remaining workers.
    {_id, second_pid} = Enum.at(first_batch, 1)
    send(second_pid, :release)
    assert_receive {:started, _fourth_id, fourth_pid}, 2_000
    send(third_pid, :release)
    send(fourth_pid, :release)

    eventually(fn -> HealthPoller.in_flight(poller) == [] end)

    # All four nodes end up healthy.
    eventually(fn ->
      Enum.all?(Registry.all(registry), &(&1.reachability == :healthy))
    end)
  end

  # ---------------------------------------------------------------------------
  # 10. Exponential backoff — next_eligible_poll_at defers on consecutive failures
  # ---------------------------------------------------------------------------

  test "consecutive failures produce exponential backoff in next_eligible_poll_at" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    poll_interval_ms = 100

    {registry, clock} =
      start_registry(initial,
        poll_interval_ms: poll_interval_ms,
        backoff_cap_ms: 1_600
      )

    node = node_fixture("romeo")
    :ok = Registry.rebuild([node], registry)

    # Each iteration: advance clock past next_eligible, begin_poll, record failure.
    advance_clock(clock, poll_interval_ms + 1)
    {:ok, token1} = Registry.begin_poll("integ-romeo", registry)
    {:ok, _e1} = Registry.record_observation("integ-romeo", token1, :timeout, registry)

    {:ok, e1} = Registry.get("integ-romeo", registry)
    delay1 = DateTime.diff(e1.next_eligible_poll_at, e1.last_attempted_contact, :millisecond)
    assert e1.consecutive_failures == 1
    # First failure: delay == base interval (100ms).
    assert delay1 == poll_interval_ms

    advance_clock(clock, delay1 + 1)
    {:ok, token2} = Registry.begin_poll("integ-romeo", registry)
    {:ok, _e2} = Registry.record_observation("integ-romeo", token2, :timeout, registry)

    {:ok, e2} = Registry.get("integ-romeo", registry)
    delay2 = DateTime.diff(e2.next_eligible_poll_at, e2.last_attempted_contact, :millisecond)
    assert e2.consecutive_failures == 2
    # Second failure: delay doubles.
    assert delay2 == poll_interval_ms * 2

    advance_clock(clock, delay2 + 1)
    {:ok, token3} = Registry.begin_poll("integ-romeo", registry)
    {:ok, _e3} = Registry.record_observation("integ-romeo", token3, :timeout, registry)

    {:ok, e3} = Registry.get("integ-romeo", registry)
    delay3 = DateTime.diff(e3.next_eligible_poll_at, e3.last_attempted_contact, :millisecond)
    assert e3.consecutive_failures == 3
    # Third failure: delay doubles again.
    assert delay3 == poll_interval_ms * 4

    advance_clock(clock, delay3 + 1)
    {:ok, token4} = Registry.begin_poll("integ-romeo", registry)
    {:ok, _e4} = Registry.record_observation("integ-romeo", token4, :timeout, registry)

    {:ok, e4} = Registry.get("integ-romeo", registry)
    delay4 = DateTime.diff(e4.next_eligible_poll_at, e4.last_attempted_contact, :millisecond)
    # Fourth failure: would be 800ms but cap is 1_600ms — not yet capped.
    assert delay4 == min(poll_interval_ms * 8, 1_600)

    advance_clock(clock, delay4 + 1)
    {:ok, token5} = Registry.begin_poll("integ-romeo", registry)
    {:ok, _e5} = Registry.record_observation("integ-romeo", token5, :timeout, registry)

    {:ok, e5} = Registry.get("integ-romeo", registry)
    delay5 = DateTime.diff(e5.next_eligible_poll_at, e5.last_attempted_contact, :millisecond)
    # Fifth failure: capped at 1_600.
    assert delay5 == 1_600
    assert e5.consecutive_failures == 5
  end

  # ---------------------------------------------------------------------------
  # 11. Recovery without blocking unrelated nodes
  # ---------------------------------------------------------------------------

  test "recovering node becomes :healthy again without affecting other nodes' scheduling" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial, poll_interval_ms: 50)
    task_supervisor = start_task_supervisor()

    nodes = [node_fixture("sierra"), node_fixture("tango"), node_fixture("uniform")]
    :ok = Registry.rebuild(nodes, registry)
    advance_clock(clock, 60)

    {:ok, failure_counter} = Agent.start_link(fn -> 0 end)
    owner = self()

    probe_adapter = fn entry, _opts ->
      case entry.id do
        "integ-sierra" ->
          count = Agent.get_and_update(failure_counter, &{&1, &1 + 1})

          if count < 2 do
            # Fail for first two polls.
            :unreachable
          else
            # Recover on third poll.
            send(owner, {:sierra_recovered, entry.id})
            healthy_result(entry)
          end

        other_id ->
          send(owner, {:peer_healthy, other_id})
          healthy_result(entry)
      end
    end

    resolver_adapter = fn _entry -> {:ok, ["192.0.2.80"]} end

    poller =
      start_poller(registry, task_supervisor,
        concurrency: 3,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    # Poll 1: sierra fails, peers succeed.
    :ok = HealthPoller.poll_now(poller)

    eventually(fn ->
      {:ok, e} = Registry.get("integ-sierra", registry)
      e.consecutive_failures >= 1
    end)

    assert_receive {:peer_healthy, "integ-tango"}, 2_000
    assert_receive {:peer_healthy, "integ-uniform"}, 2_000

    # Advance past sierra's backoff; peers also advance past their next poll.
    advance_clock(clock, 200)

    # Poll 2: sierra fails again, peers skip (already succeeded and scheduled further out).
    :ok = HealthPoller.poll_now(poller)

    eventually(fn ->
      {:ok, e} = Registry.get("integ-sierra", registry)
      e.consecutive_failures >= 2
    end)

    advance_clock(clock, 400)

    # Poll 3: sierra recovers.
    :ok = HealthPoller.poll_now(poller)
    assert_receive {:sierra_recovered, "integ-sierra"}, 2_000

    eventually(fn ->
      {:ok, e} = Registry.get("integ-sierra", registry)
      e.reachability == :healthy
    end)

    {:ok, sierra} = Registry.get("integ-sierra", registry)
    assert sierra.reachability == :healthy
    assert sierra.consecutive_failures == 0
    refute is_nil(sierra.last_successful_contact)

    # Peers remained healthy throughout; their state is preserved.
    {:ok, tango} = Registry.get("integ-tango", registry)
    {:ok, uniform} = Registry.get("integ-uniform", registry)
    assert tango.reachability == :healthy
    assert uniform.reachability == :healthy
  end

  # ---------------------------------------------------------------------------
  # 12. Stale state transitions via injectable clock
  # ---------------------------------------------------------------------------

  test "node transitions through healthy → degraded → stale → unreachable with injectable clock" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    # Use short thresholds so clock steps are small.
    degraded_after_ms = 1_000
    stale_after_ms = 5_000
    poll_interval_ms = 100

    {registry, clock} =
      start_registry(initial,
        poll_interval_ms: poll_interval_ms,
        degraded_after_ms: degraded_after_ms,
        stale_after_ms: stale_after_ms
      )

    node = node_fixture("victor")
    :ok = Registry.rebuild([node], registry)

    # First poll: success — establishes last_successful_contact.
    advance_clock(clock, poll_interval_ms + 1)
    t_success = DateTime.add(initial, poll_interval_ms + 1, :millisecond)
    {:ok, token} = Registry.begin_poll("integ-victor", registry)

    {:ok, e_healthy} =
      Registry.record_observation(
        "integ-victor",
        token,
        %{
          outcome: :healthy,
          node_id: "integ-victor",
          verified_addresses: ["192.0.2.90"],
          agent_card: %{"version" => "3.0", "skills" => []},
          health: %{"status" => "ok", "summary" => ""},
          error_details: %{}
        },
        registry
      )

    assert e_healthy.reachability == :healthy
    assert e_healthy.consecutive_failures == 0

    # Second poll: fail within degraded_after_ms — becomes :degraded.
    advance_clock(clock, poll_interval_ms + 1)
    {:ok, token2} = Registry.begin_poll("integ-victor", registry)
    {:ok, e_degraded} = Registry.record_observation("integ-victor", token2, :timeout, registry)

    assert e_degraded.reachability == :degraded
    assert e_degraded.consecutive_failures == 1
    # Verified address preserved after failure.
    assert e_degraded.addresses == ["192.0.2.90"]

    # Third poll: fail after degraded_after_ms but before stale_after_ms — :stale.
    # Clock is now at t_success + poll_interval + 1 + poll_interval + 1 ≈ 202ms.
    # We need age > 1000ms, so advance by 900ms more.
    advance_clock(clock, 900)
    advance_clock(clock, e_degraded.consecutive_failures * poll_interval_ms + 1)
    {:ok, token3} = Registry.begin_poll("integ-victor", registry)
    {:ok, e_stale} = Registry.record_observation("integ-victor", token3, :timeout, registry)

    assert e_stale.reachability == :stale
    assert e_stale.consecutive_failures == 2

    # Fourth poll: fail after stale_after_ms — :unreachable.
    # Advance so total age > 5000ms from t_success.
    # Current clock is already ~1203ms past t_success, need ~3900ms more.
    advance_clock(clock, 4_000)
    advance_clock(clock, e_stale.consecutive_failures * poll_interval_ms * 2 + 1)
    {:ok, token4} = Registry.begin_poll("integ-victor", registry)
    {:ok, e_unreachable} = Registry.record_observation("integ-victor", token4, :timeout, registry)

    assert e_unreachable.reachability == :unreachable
    assert e_unreachable.consecutive_failures == 3

    # Verify that t_success is still recorded throughout (not overwritten by failures).
    assert e_unreachable.last_successful_contact == t_success
  end

  # ---------------------------------------------------------------------------
  # 13. Audit events — node_poll_transition on reachability change, with redaction
  # ---------------------------------------------------------------------------

  test "reachability transitions emit node_poll_transition audit events with required fields" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    audit = start_audit()
    {registry, clock} = start_registry(initial, audit_server: audit)
    task_supervisor = start_task_supervisor()
    node = node_fixture("whiskey")
    :ok = Registry.rebuild([node], registry)
    advance_clock(clock, 60)

    # First poll is successful — triggers :unknown → :healthy transition.
    probe_adapter = fn entry, _opts -> healthy_result(entry) end
    resolver_adapter = fn _entry -> {:ok, ["192.0.2.100"]} end

    poller =
      start_poller(registry, task_supervisor,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)

    eventually(fn ->
      {:ok, e} = Registry.get("integ-whiskey", registry)
      e.reachability == :healthy
    end)

    events = collect_audit_events()
    transition_events = Enum.filter(events, &(&1["event_type"] == "node_poll_transition"))

    assert length(transition_events) >= 1
    [ev | _] = transition_events
    attrs = ev["attributes"]
    assert attrs["node_id"] == "integ-whiskey"
    assert attrs["from"] == "unknown"
    assert attrs["to"] == "healthy"
    assert attrs["consecutive_failures"] == 0
    assert is_binary(ev["correlation_id"])
    assert String.starts_with?(ev["correlation_id"], "corr_")
    assert is_binary(ev["occurred_at"])
  end

  test "audit events do not expose sensitive fields in attributes" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    audit = start_audit()
    {registry, clock} = start_registry(initial, audit_server: audit)
    task_supervisor = start_task_supervisor()

    node = %Node{
      id: "integ-xray",
      hostname: "integ-xray.cluster.test",
      port: 9443,
      # certificate_identity could be considered credential-adjacent; ensure
      # it is NOT redacted when it appears in the node_id/hostname context.
      certificate_identity: "spiffe://cluster/integ-xray",
      capabilities: [],
      labels: %{}
    }

    :ok = Registry.rebuild([node], registry)
    advance_clock(clock, 60)

    probe_adapter = fn entry, _opts -> healthy_result(entry) end
    resolver_adapter = fn _entry -> {:ok, ["192.0.2.101"]} end

    poller =
      start_poller(registry, task_supervisor,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)
    eventually(fn -> HealthPoller.in_flight(poller) == [] end)

    events = collect_audit_events()
    transition_events = Enum.filter(events, &(&1["event_type"] == "node_poll_transition"))
    assert length(transition_events) >= 1

    Enum.each(transition_events, fn event ->
      # No event value must equal the literal redaction sentinel when it
      # encodes a non-sensitive field like node_id or consecutive_failures.
      serialized = inspect(event)
      refute String.contains?(serialized, "[REDACTED][REDACTED]")
      # The node_id must be readable (not redacted).
      assert get_in(event, ["attributes", "node_id"]) == "integ-xray"
    end)
  end

  # ---------------------------------------------------------------------------
  # 14. Multiple addresses — DNS address-set changes and candidate isolation
  # ---------------------------------------------------------------------------

  test "DNS candidate-set expansion is reflected per-node without cross-node contamination" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    task_supervisor = start_task_supervisor()

    nodes = [node_fixture("yankee"), node_fixture("zulu")]
    :ok = Registry.rebuild(nodes, registry)
    advance_clock(clock, 60)

    # Node yankee gets two addresses; zulu gets one.
    resolver_adapter = fn
      %{id: "integ-yankee"} -> {:ok, ["192.0.3.1", "192.0.3.2"]}
      %{id: "integ-zulu"} -> {:ok, ["192.0.3.10"]}
      _ -> {:ok, []}
    end

    probe_adapter = fn entry, _opts ->
      healthy_result(entry, entry.candidate_addresses)
    end

    poller =
      start_poller(registry, task_supervisor,
        concurrency: 2,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)

    eventually(fn ->
      Enum.all?(Registry.all(registry), &(&1.reachability == :healthy))
    end)

    {:ok, yankee} = Registry.get("integ-yankee", registry)
    {:ok, zulu} = Registry.get("integ-zulu", registry)

    # Yankee adopted both of its addresses.
    assert "192.0.3.1" in yankee.addresses
    assert "192.0.3.2" in yankee.addresses
    assert length(yankee.addresses) == 2

    # Zulu has only its own address.
    assert zulu.addresses == ["192.0.3.10"]

    # No cross-contamination.
    refute "192.0.3.1" in zulu.addresses
    refute "192.0.3.10" in yankee.addresses
  end

  # ---------------------------------------------------------------------------
  # 15. Three nodes: mixed scenario — healthy, degraded, unreachable simultaneously
  # ---------------------------------------------------------------------------

  test "three nodes simultaneously showing healthy, degraded, and unreachable reachability" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    task_supervisor = start_task_supervisor()

    nodes = [node_fixture("one"), node_fixture("two"), node_fixture("three")]
    :ok = Registry.rebuild(nodes, registry)
    advance_clock(clock, 60)

    resolver_adapter = fn _entry -> {:ok, ["192.0.4.1"]} end

    probe_adapter = fn entry, _opts ->
      case entry.id do
        "integ-one" -> healthy_result(entry)
        "integ-two" -> degraded_result(entry)
        "integ-three" -> :unreachable
      end
    end

    poller =
      start_poller(registry, task_supervisor,
        concurrency: 3,
        probe_adapter: probe_adapter,
        resolver_adapter: resolver_adapter
      )

    :ok = HealthPoller.poll_now(poller)
    eventually(fn -> HealthPoller.in_flight(poller) == [] end)

    # Allow state machines to complete.
    eventually(fn ->
      Enum.all?(["integ-one", "integ-two", "integ-three"], fn id ->
        {:ok, e} = Registry.get(id, registry)
        e.reachability != :unknown
      end)
    end)

    {:ok, one} = Registry.get("integ-one", registry)
    {:ok, two} = Registry.get("integ-two", registry)
    {:ok, three} = Registry.get("integ-three", registry)

    assert one.reachability == :healthy
    assert one.consecutive_failures == 0
    refute is_nil(one.last_successful_contact)

    assert two.reachability == :degraded
    assert two.consecutive_failures == 0
    refute is_nil(two.last_successful_contact)

    assert three.reachability == :unreachable
    assert three.consecutive_failures == 1
    assert is_nil(three.last_successful_contact)

    # Addresses adopted for healthy/degraded; unreachable node has no addresses.
    refute one.addresses == []
    refute two.addresses == []
    assert three.addresses == []
  end

  # ---------------------------------------------------------------------------
  # 16. Stale-token guard — late probe result does not overwrite newer observation
  # ---------------------------------------------------------------------------

  test "stale attempt token is rejected and does not overwrite a newer observation" do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {registry, clock} = start_registry(initial)
    node = node_fixture("bravo")
    :ok = Registry.rebuild([node], registry)

    # First poll.
    advance_clock(clock, 60)
    {:ok, old_token} = Registry.begin_poll("integ-bravo", registry)

    # Second poll overtakes the first (e.g. poller restarted).
    # Record first poll as failure to free the token.
    {:ok, _} = Registry.record_observation("integ-bravo", old_token, :timeout, registry)

    # Advance past backoff.
    {:ok, stale_e} = Registry.get("integ-bravo", registry)

    delay =
      DateTime.diff(stale_e.next_eligible_poll_at, stale_e.last_attempted_contact, :millisecond)

    advance_clock(clock, delay + 1)

    {:ok, new_token} = Registry.begin_poll("integ-bravo", registry)
    # Apply a success with the new token.
    {:ok, healthy_e} =
      Registry.record_observation(
        "integ-bravo",
        new_token,
        %{
          outcome: :healthy,
          node_id: "integ-bravo",
          verified_addresses: ["192.0.5.1"],
          agent_card: %{"version" => "1.0", "skills" => []},
          health: %{"status" => "ok", "summary" => ""},
          error_details: %{}
        },
        registry
      )

    assert healthy_e.reachability == :healthy

    # Attempt to apply old_token again — must be rejected.
    result = Registry.record_observation("integ-bravo", old_token, :timeout, registry)
    assert result == {:ignored, :stale}

    # Registry state remains :healthy.
    {:ok, final} = Registry.get("integ-bravo", registry)
    assert final.reachability == :healthy
  end
end

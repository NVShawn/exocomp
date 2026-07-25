defmodule Exocomp.Coordinator.HealthPollerTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.{HealthPoller, Inventory.Node, Registry}

  test "runs three polls concurrently, enforces the bound, and refills capacity" do
    owner = self()
    {registry, clock} = start_registry(4)
    task_supervisor = start_task_supervisor()

    probe = fn entry, _opts ->
      send(owner, {:started, entry.id, self()})
      receive do: (:release -> healthy(entry.id))
    end

    poller =
      start_poller(registry, task_supervisor,
        concurrency: 3,
        probe_adapter: probe
      )

    :ok = HealthPoller.poll_now(poller)

    workers =
      for _ <- 1..3, into: %{} do
        assert_receive {:started, node_id, pid}
        {node_id, pid}
      end

    assert map_size(workers) == 3
    assert length(HealthPoller.in_flight(poller)) == 3
    refute_receive {:started, _, _}, 30

    {_node_id, pid} = Enum.at(workers, 0)
    send(pid, :release)
    assert_receive {:started, fourth_id, fourth_pid}
    refute Map.has_key?(workers, fourth_id)

    Enum.each(workers, fn {_id, worker} -> send(worker, :release) end)
    send(fourth_pid, :release)
    eventually(fn -> HealthPoller.in_flight(poller) == [] end)

    Enum.each(Registry.all(registry), fn entry ->
      assert entry.reachability == :healthy
      assert entry.agent_card_version == "1.0"
      assert entry.supported_skills == ["chat"]
      assert entry.diagnostic_summary == "ready"
      assert entry.last_successful_contact == Agent.get(clock, & &1)
    end)
  end

  test "a slow node cannot delay a peer and is killed at its own timeout" do
    owner = self()
    {registry, _clock} = start_registry(2)
    task_supervisor = start_task_supervisor()

    probe = fn
      %{id: "node-1"}, _opts ->
        send(owner, {:slow_started, self()})
        receive do: (:never -> healthy("node-1"))

      %{id: "node-2"}, _opts ->
        send(owner, :fast_finished)
        healthy("node-2")
    end

    poller =
      start_poller(registry, task_supervisor,
        concurrency: 2,
        timeout_ms: 60,
        probe_adapter: probe
      )

    :ok = HealthPoller.poll_now(poller)
    assert_receive {:slow_started, slow_pid}
    assert_receive :fast_finished

    eventually(fn ->
      {:ok, fast} = Registry.get("node-2", registry)
      fast.reachability == :healthy
    end)

    assert Process.alive?(slow_pid)

    eventually(fn ->
      {:ok, slow} = Registry.get("node-1", registry)
      slow.reachability == :unreachable and not Process.alive?(slow_pid)
    end)

    assert HealthPoller.in_flight(poller) == []
  end

  test "repeated scheduling passes never duplicate a node in flight" do
    owner = self()
    {registry, _clock} = start_registry(1)
    task_supervisor = start_task_supervisor()

    probe = fn entry, _opts ->
      send(owner, {:started_once, self()})
      receive do: (:release -> healthy(entry.id))
    end

    poller = start_poller(registry, task_supervisor, probe_adapter: probe)
    :ok = HealthPoller.poll_now(poller)
    :ok = HealthPoller.poll_now(poller)
    :ok = HealthPoller.poll_now(poller)

    assert_receive {:started_once, pid}
    refute_receive {:started_once, _}, 30
    assert HealthPoller.in_flight(poller) == ["node-1"]

    send(pid, :release)
    eventually(fn -> HealthPoller.in_flight(poller) == [] end)
  end

  test "restart kills orphan workers, recovers claims, and resumes scheduling" do
    owner = self()
    {registry, clock} = start_registry(1, poll_interval_ms: 1)
    task_supervisor = start_task_supervisor()

    blocking_probe = fn entry, _opts ->
      send(owner, {:orphan_started, self()})
      receive do: (:release -> healthy(entry.id))
    end

    poller =
      start_poller(registry, task_supervisor,
        probe_adapter: blocking_probe,
        id: unique_name(:first_poller)
      )

    :ok = HealthPoller.poll_now(poller)
    assert_receive {:orphan_started, orphan}
    GenServer.stop(poller)

    resumed_probe = fn entry, _opts ->
      send(owner, :resumed)
      healthy(entry.id)
    end

    resumed =
      start_poller(registry, task_supervisor,
        probe_adapter: resumed_probe,
        id: unique_name(:resumed_poller)
      )

    eventually(fn -> not Process.alive?(orphan) end)
    Agent.update(clock, &DateTime.add(&1, 2, :millisecond))
    :ok = HealthPoller.poll_now(resumed)
    assert_receive :resumed

    eventually(fn ->
      {:ok, entry} = Registry.get("node-1", registry)
      entry.reachability == :healthy
    end)
  end

  test "resolver and probe crashes are isolated and release capacity" do
    owner = self()
    {registry, _clock} = start_registry(2)
    task_supervisor = start_task_supervisor()

    resolver = fn
      %{id: "node-1"} -> raise "resolver crashed"
      _entry -> {:ok, ["192.0.2.2"]}
    end

    probe = fn entry, _opts ->
      send(owner, {:probed, entry.id, entry.candidate_addresses})
      healthy(entry.id)
    end

    poller =
      start_poller(registry, task_supervisor,
        concurrency: 1,
        resolver_adapter: resolver,
        probe_adapter: probe
      )

    :ok = HealthPoller.poll_now(poller)
    assert_receive {:probed, "node-2", ["192.0.2.2"]}

    eventually(fn ->
      {:ok, failed} = Registry.get("node-1", registry)
      {:ok, healthy} = Registry.get("node-2", registry)
      failed.reachability == :unreachable and healthy.reachability == :healthy
    end)
  end

  defp start_registry(count, opts \\ []) do
    initial = ~U[2026-07-24 00:00:00.000Z]
    {:ok, clock} = Agent.start_link(fn -> initial end)
    name = unique_name(:registry)

    start_supervised!(
      {Registry,
       [
         name: name,
         clock: fn -> Agent.get(clock, & &1) end,
         random: fn _min, _max -> 0 end,
         poll_interval_ms: Keyword.get(opts, :poll_interval_ms, 10),
         jitter_ms: 0
       ]},
      id: name
    )

    nodes = for number <- 1..count, do: inventory_node(number)
    :ok = Registry.rebuild(nodes, name)
    Agent.update(clock, &DateTime.add(&1, 10, :millisecond))
    {name, clock}
  end

  defp start_task_supervisor do
    name = unique_name(:task_supervisor)
    start_supervised!({Task.Supervisor, name: name}, id: name)
    name
  end

  defp start_poller(registry, task_supervisor, opts) do
    id = Keyword.get(opts, :id, unique_name(:poller))

    options =
      opts
      |> Keyword.delete(:id)
      |> Keyword.merge(
        name: id,
        registry_server: registry,
        task_supervisor: task_supervisor,
        interval_ms: 60_000,
        timeout_ms: Keyword.get(opts, :timeout_ms, 1_000),
        start_immediately: false
      )

    start_supervised!({HealthPoller, options}, id: id)
    id
  end

  defp inventory_node(number) do
    %Node{
      id: "node-#{number}",
      hostname: "node-#{number}.example.test",
      port: 8443,
      certificate_identity: "spiffe://node/node-#{number}",
      capabilities: [],
      labels: %{}
    }
  end

  defp healthy(id) do
    %{
      outcome: :healthy,
      node_id: id,
      verified_addresses: ["192.0.2.1"],
      agent_card: %{"version" => "1.0", "skills" => ["chat"]},
      health: %{"status" => "ok", "summary" => "ready"},
      error_details: %{}
    }
  end

  defp eventually(assertion, attempts \\ 100)
  defp eventually(assertion, 0), do: assert(assertion.())

  defp eventually(assertion, attempts) do
    if assertion.() do
      :ok
    else
      Process.sleep(5)
      eventually(assertion, attempts - 1)
    end
  end

  defp unique_name(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ServiceSchedulerTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.{HealthPoller, Inventory.Node, Registry, ServiceScheduler}

  @initial ~U[2026-08-01 00:00:00.000Z]

  test "discovers automatic services at startup and on a jittered periodic cadence" do
    owner = self()
    {inventory, reader} = inventory([automatic_node("node-a")])
    task_supervisor = task_supervisor()
    {:ok, clock} = Agent.start_link(fn -> @initial end)

    discovery = fn node, _opts ->
      send(owner, {:discovered, node.id})
      {:ok, ["api.service"]}
    end

    scheduler =
      start_scheduler(inventory, reader, task_supervisor,
        clock: fn -> Agent.get(clock, & &1) end,
        discovery_adapter: discovery,
        discovery_interval_ms: 25,
        discovery_jitter_ms: 5,
        random: fn _min, _max -> 3 end
      )

    assert_receive {:discovered, "node-a"}, 1_000
    assert %{next_discovery_at: next_at} = ServiceScheduler.status(scheduler)
    assert DateTime.diff(next_at, @initial, :millisecond) == 28

    assert_receive {:discovered, "node-a"}, 1_000

    assert %{services: [%{name: "api.service"}]} =
             ServiceScheduler.discovery_cache(scheduler)["node-a"]
  end

  test "a failed refresh preserves the newest successful discovery" do
    owner = self()
    {inventory, reader} = inventory([automatic_node("node-a")])
    task_supervisor = task_supervisor()
    {:ok, attempts} = Agent.start_link(fn -> 0 end)

    discovery = fn node, _opts ->
      attempt = Agent.get_and_update(attempts, fn n -> {n + 1, n + 1} end)
      send(owner, {:discovery_attempt, node.id, attempt})

      if attempt == 1 do
        {:ok, ["first.service"]}
      else
        {:error, :unreachable}
      end
    end

    scheduler =
      start_scheduler(inventory, reader, task_supervisor,
        discovery_adapter: discovery,
        start_immediately: false
      )

    :ok = ServiceScheduler.discover_now(scheduler)
    assert_receive {:discovery_attempt, "node-a", 1}, 1_000
    expected = ServiceScheduler.discovery_cache(scheduler)["node-a"]

    :ok = ServiceScheduler.discover_now(scheduler)
    assert_receive {:discovery_attempt, "node-a", 2}, 1_000
    assert ServiceScheduler.discovery_cache(scheduler)["node-a"] == expected
  end

  test "observations receive the effective union of manual and cached automatic services" do
    owner = self()

    node =
      automatic_node("node-a", [
        %{name: "manual.service", health_check_url: "http://127.0.0.1:8080/health"}
      ])

    {inventory, reader} = inventory([node])
    task_supervisor = task_supervisor()

    observation = fn observed_node, services, _opts ->
      send(owner, {:observed, observed_node.id, Enum.map(services, & &1.name)})
      {:ok, :observation}
    end

    scheduler =
      start_scheduler(inventory, reader, task_supervisor,
        discovery_adapter: fn _node, _opts -> {:ok, ["automatic.service"]} end,
        observation_adapter: observation,
        start_immediately: false
      )

    :ok = ServiceScheduler.discover_now(scheduler)
    :ok = ServiceScheduler.observe_now(scheduler, ["node-a"])
    assert_receive {:observed, "node-a", ["automatic.service", "manual.service"]}, 1_000

    assert %{observations: %{"node-a" => %{result: :observation}}} =
             ServiceScheduler.status(scheduler)
  end

  test "inventory replacement promptly reconciles the replacement node" do
    owner = self()
    {inventory, reader} = inventory([automatic_node("old-node")])
    task_supervisor = task_supervisor()

    discovery = fn node, _opts ->
      send(owner, {:discovered, node.id})
      {:ok, ["service.service"]}
    end

    scheduler =
      start_scheduler(inventory, reader, task_supervisor,
        discovery_adapter: discovery,
        start_immediately: false
      )

    Agent.update(inventory, fn _ -> %{nodes: [automatic_node("new-node")]} end)
    :ok = ServiceScheduler.inventory_replaced(scheduler)
    assert_receive {:discovered, "new-node"}, 1_000
    refute_receive {:discovered, "old-node"}, 50
  end

  test "normalizes the node service-inventory artifact into service names" do
    {inventory, reader} = inventory([automatic_node("node-a")])
    task_supervisor = task_supervisor()

    response = %{
      artifacts: [
        %{
          parts: [
            %{
              data: %{
                "observations" => %{
                  "enabled_services" => %{
                    "measurements" => %{
                      "api_service_type" => %{"value" => "simple"}
                    }
                  }
                }
              }
            }
          ]
        }
      ]
    }

    scheduler =
      start_scheduler(inventory, reader, task_supervisor,
        discovery_adapter: fn _node, _opts -> {:ok, response} end,
        start_immediately: false
      )

    :ok = ServiceScheduler.discover_now(scheduler)

    assert %{services: [%{name: "api.service"}]} =
             ServiceScheduler.discovery_cache(scheduler)["node-a"]
  end

  test "a timed-out node does not block a peer" do
    owner = self()
    {inventory, reader} = inventory([automatic_node("slow"), automatic_node("fast")])
    task_supervisor = task_supervisor()

    discovery = fn
      %{id: "slow"}, _opts ->
        send(owner, {:slow_started, self()})
        receive do: (:never -> {:ok, ["slow.service"]})

      %{id: "fast"}, _opts ->
        send(owner, :fast_finished)
        {:ok, ["fast.service"]}
    end

    scheduler =
      start_scheduler(inventory, reader, task_supervisor,
        discovery_adapter: discovery,
        concurrency: 2,
        timeout_ms: 40,
        start_immediately: false
      )

    :ok = ServiceScheduler.discover_now(scheduler)
    assert_receive {:slow_started, slow_pid}, 1_000
    assert_receive :fast_finished, 1_000
    eventually(fn -> not Process.alive?(slow_pid) end)

    assert %{services: [%{name: "fast.service"}]} =
             ServiceScheduler.discovery_cache(scheduler)["fast"]
  end

  test "cancellation kills active work and prevents a late cache write" do
    owner = self()
    {inventory, reader} = inventory([automatic_node("node-a")])
    task_supervisor = task_supervisor()

    discovery = fn _node, _opts ->
      send(owner, {:started, self()})
      receive do: (:never -> {:ok, ["late.service"]})
    end

    scheduler =
      start_scheduler(inventory, reader, task_supervisor,
        discovery_adapter: discovery,
        timeout_ms: 500,
        start_immediately: false
      )

    :ok = ServiceScheduler.discover_now(scheduler)
    assert_receive {:started, worker}, 1_000
    assert :ok = ServiceScheduler.cancel(scheduler)
    eventually(fn -> not Process.alive?(worker) end)
    assert %{in_flight: [], discovery_cache: %{}} = ServiceScheduler.status(scheduler)
  end

  test "successful health polls enqueue observations on the existing cadence" do
    owner = self()
    node = automatic_node("node-a", [%{name: "manual.service"}])
    {inventory, reader} = inventory([node])
    service_tasks = task_supervisor()

    scheduler =
      start_scheduler(inventory, reader, service_tasks,
        observation_adapter: fn observed_node, services, _opts ->
          send(owner, {:observed_from_health, observed_node.id, Enum.map(services, & &1.name)})
          {:ok, :observation}
        end,
        start_immediately: false
      )

    {:ok, clock} = Agent.start_link(fn -> @initial end)
    registry = unique_name(:registry)

    start_supervised!(
      {Registry,
       [
         name: registry,
         clock: fn -> Agent.get(clock, & &1) end,
         random: fn _min, _max -> 0 end,
         poll_interval_ms: 1,
         jitter_ms: 0
       ]},
      id: registry
    )

    :ok = Registry.rebuild([node], registry)
    Agent.update(clock, &DateTime.add(&1, 1, :millisecond))
    health_tasks = task_supervisor()

    poller =
      start_supervised!(
        {HealthPoller,
         [
           name: unique_name(:health_poller),
           registry_server: registry,
           task_supervisor: health_tasks,
           interval_ms: 60_000,
           timeout_ms: 500,
           start_immediately: false,
           resolver_adapter: fn _entry -> :ok end,
           probe_adapter: fn entry, _opts ->
             %{
               outcome: :healthy,
               node_id: entry.id,
               verified_addresses: [],
               agent_card: %{},
               health: %{}
             }
           end,
           service_scheduler: scheduler
         ]},
        id: unique_name(:health_poller_supervision)
      )

    :ok = HealthPoller.poll_now(poller)
    assert_receive {:observed_from_health, "node-a", ["manual.service"]}, 1_000
  end

  test "effective expectations use manual, automatic, and profile sources" do
    node = automatic_node("node-a", [%{name: "shared.service"}])
    {inventory, reader} = inventory([node])
    Agent.update(inventory, &Map.put(&1, :cluster_profile, "production"))
    task_supervisor = task_supervisor()

    scheduler =
      start_scheduler(inventory, reader, task_supervisor,
        discovery_adapter: fn _node, _opts ->
          {:ok, [%{name: "shared.service"}, %{name: "auto.service"}]}
        end,
        profile_resolver: fn "production", _node ->
          [%{name: "profile.service"}, %{name: "shared.service"}]
        end,
        start_immediately: false
      )

    :ok = ServiceScheduler.discover_now(scheduler)
    eventually(fn -> length(ServiceScheduler.expectations("node-a", scheduler)) == 3 end)

    expectations = ServiceScheduler.expectations("node-a", scheduler)
    shared = Enum.find(expectations, &(&1.unit == "shared.service"))

    assert shared.sources == [:automatic, :cluster_profile, :manual]
    assert shared.profile_context == "production"

    assert Enum.map(expectations, & &1.unit) == [
             "auto.service",
             "profile.service",
             "shared.service"
           ]
  end

  test "profile source maps configure profile expectations" do
    node = automatic_node("node-a")
    {inventory, reader} = inventory([node])
    Agent.update(inventory, &Map.put(&1, :cluster_profile, "production"))

    scheduler =
      start_scheduler(inventory, reader, task_supervisor(),
        discovery_adapter: fn _node, _opts -> {:ok, []} end,
        profile_sources: %{"production" => [%{name: "profile.service"}]},
        start_immediately: false
      )

    :ok = ServiceScheduler.discover_now(scheduler)
    eventually(fn -> length(ServiceScheduler.expectations("node-a", scheduler)) == 1 end)

    assert [%{unit: "profile.service", profile_context: "production"}] =
             ServiceScheduler.expectations("node-a", scheduler)
  end

  test "removing an expectation retires it and emits a desired-state event" do
    node = automatic_node("node-a", [%{name: "manual.service"}])
    {inventory, reader} = inventory([node])
    task_supervisor = task_supervisor()

    scheduler = start_scheduler(inventory, reader, task_supervisor, start_immediately: false)
    assert [%{unit: "manual.service"}] = ServiceScheduler.expectations("node-a", scheduler)

    Agent.update(inventory, fn value -> %{value | nodes: [automatic_node("node-a")]} end)
    :ok = ServiceScheduler.inventory_replaced(scheduler)

    eventually(fn -> ServiceScheduler.expectations("node-a", scheduler) == [] end)
    desired = ServiceScheduler.desired_state(scheduler)["node-a"]
    assert desired.retired["manual.service"].expectation.unit == "manual.service"

    assert Enum.any?(ServiceScheduler.transitions(scheduler), fn transition ->
             transition.event_type == :desired_state_removed and
               transition.attributes.unit == "manual.service" and
               is_binary(transition.correlation_id)
           end)
  end

  test "probe failure is unhealthy only after two observations and recovery has hysteresis" do
    node =
      automatic_node("node-a", [
        %{name: "api.service", health_check_url: "http://127.0.0.1:8080/health"}
      ])

    {inventory, reader} = inventory([node])
    task_supervisor = task_supervisor()
    owner = self()

    {:ok, sequence} =
      Agent.start_link(fn -> [:healthy, :unhealthy, :unhealthy, :healthy, :healthy] end)

    observation = fn _node, _services, _opts ->
      outcome = Agent.get_and_update(sequence, fn [head | tail] -> {head, tail} end)
      send(owner, {:observation_outcome, outcome})

      {:ok,
       %{
         service_states: %{"api.service" => outcome},
         probes: [{:ok, if(outcome == :healthy, do: 200, else: 503), 1, 1}]
       }}
    end

    scheduler =
      start_scheduler(inventory, reader, task_supervisor,
        observation_adapter: observation,
        start_immediately: false
      )

    observe = fn ->
      :ok = ServiceScheduler.observe_now(scheduler, ["node-a"])
      assert_receive {:observation_outcome, _}, 1_000
      eventually(fn -> map_size(ServiceScheduler.health(scheduler)) == 1 end)
    end

    observe.()
    assert ServiceScheduler.health(scheduler)[{"node-a", "api.service"}].state == :healthy
    observe.()
    assert ServiceScheduler.health(scheduler)[{"node-a", "api.service"}].state == :healthy
    observe.()
    assert ServiceScheduler.health(scheduler)[{"node-a", "api.service"}].state == :unhealthy
    observe.()
    assert ServiceScheduler.health(scheduler)[{"node-a", "api.service"}].state == :unhealthy
    observe.()
    assert ServiceScheduler.health(scheduler)[{"node-a", "api.service"}].state == :healthy
  end

  test "failed observations preserve explicit unreachable state" do
    node = automatic_node("node-a", [%{name: "api.service"}])
    {inventory, reader} = inventory([node])
    task_supervisor = task_supervisor()

    scheduler =
      start_scheduler(inventory, reader, task_supervisor,
        observation_adapter: fn _node, _services, _opts -> {:error, :unreachable} end,
        start_immediately: false
      )

    :ok = ServiceScheduler.observe_now(scheduler, ["node-a"])

    eventually(fn ->
      get_in(ServiceScheduler.observations(scheduler), ["node-a", :status]) == :unreachable
    end)

    assert ServiceScheduler.health(scheduler)[{"node-a", "api.service"}].state == :unreachable
  end

  defp start_scheduler(inventory, reader, task_supervisor, opts) do
    name = unique_name(:service_scheduler)

    options =
      [
        name: name,
        inventory_server: inventory,
        inventory_reader: reader,
        task_supervisor: task_supervisor,
        random: fn _min, _max -> 0 end,
        discovery_interval_ms: 50,
        discovery_jitter_ms: 0
      ]
      |> Keyword.merge(opts)

    start_supervised!({ServiceScheduler, options}, id: name)
    name
  end

  defp inventory(nodes) do
    {:ok, agent} = Agent.start_link(fn -> %{nodes: nodes} end)
    {agent, fn server -> Agent.get(server, & &1) end}
  end

  defp task_supervisor do
    name = unique_name(:service_task_supervisor)
    start_supervised!({Task.Supervisor, name: name}, id: name)
    name
  end

  defp automatic_node(id, services \\ []) do
    %Node{
      id: id,
      hostname: "#{id}.example.test",
      port: 8443,
      certificate_identity: "spiffe://node/#{id}",
      capabilities: [],
      labels: %{},
      monitoring: %{automatic: true, services: services}
    }
  end

  defp unique_name(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"

  defp eventually(assertion, timeout_ms \\ 1_000) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    eventually_until(assertion, deadline)
  end

  defp eventually_until(assertion, deadline) do
    if assertion.() do
      :ok
    else
      remaining = deadline - System.monotonic_time(:millisecond)

      if remaining > 0 do
        Process.sleep(min(5, remaining))
        eventually_until(assertion, deadline)
      else
        assert assertion.()
      end
    end
  end
end

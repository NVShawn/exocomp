# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ServiceScheduler do
  @moduledoc """
  Schedules automatic service discovery and effective-service observations.

  Discovery runs once at startup and on a jittered five-minute cadence.  Node
  health polling remains owned by `HealthPoller`; successful health polls enqueue
  an observation for the services currently effective for that node.

  Workers are supervised, bounded by one coordinator-wide concurrency limit,
  and independently timed out.  A failed discovery never replaces the newest
  successful discovery in `discovery_cache`.  Inventory replacement increments
  a generation for every node, cancels stale work, and immediately reconciles
  the replacement.

  The clock and random function are injectable.  Adapters are injectable too,
  which keeps scheduling tests deterministic and leaves the A2A client at the
  process boundary in production.
  """

  use GenServer

  alias Exocomp.Coordinator.{A2A.DiagnosticClient, Inventory, Registry}

  @default_discovery_interval_ms 300_000
  @default_discovery_jitter_ms 30_000
  @default_timeout_ms 15_000
  @default_concurrency 4
  @default_backoff_cap_ms 900_000
  @default_task_poll_interval_ms 100
  @inventory_property_suffixes ~w[
    type
    remainafterexit
    condition
    conditionresult
    unitfilestate
    loadstate
    activestate
    substate
  ]

  defstruct [
    :inventory,
    :inventory_reader,
    :registry,
    :task_supervisor,
    :discovery_adapter,
    :observation_adapter,
    :adapter_options,
    :clock,
    :random,
    :discovery_interval_ms,
    :discovery_jitter_ms,
    :timeout_ms,
    :concurrency,
    :backoff_cap_ms,
    :task_poll_interval_ms,
    :discovery_timer_ref,
    :next_discovery_at,
    tasks: %{},
    pending_discovery: MapSet.new(),
    pending_observation: MapSet.new(),
    discovery_cache: %{},
    observations: %{},
    failures: %{},
    generations: %{}
  ]

  @type service :: %{required(:name) => String.t(), optional(:health_check_url) => String.t()}

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Requests discovery for every inventory node configured for automatic discovery."
  @spec discover_now(GenServer.server()) :: :ok
  def discover_now(server \\ __MODULE__), do: GenServer.call(server, :discover_now)

  @doc "Requests observations for all nodes, or for the supplied node IDs."
  @spec observe_now(GenServer.server(), :all | [String.t()]) :: :ok
  def observe_now(server \\ __MODULE__, node_ids \\ :all),
    do: GenServer.call(server, {:observe_now, node_ids})

  @doc "Queues an observation from the health poller's successful node cadence."
  @spec observe_node(String.t(), GenServer.server()) :: :ok
  def observe_node(node_id, server \\ __MODULE__) when is_binary(node_id) do
    GenServer.cast(server, {:observe_node, node_id})
  end

  @doc "Signals that the inventory was atomically replaced."
  @spec inventory_replaced(GenServer.server()) :: :ok
  def inventory_replaced(server \\ __MODULE__), do: GenServer.cast(server, :inventory_replaced)

  @doc "Returns the newest successful discovery for each node."
  @spec discovery_cache(GenServer.server()) :: map()
  def discovery_cache(server \\ __MODULE__), do: GenServer.call(server, :discovery_cache)

  @doc "Returns the newest successful observation for each node."
  @spec observations(GenServer.server()) :: map()
  def observations(server \\ __MODULE__), do: GenServer.call(server, :observations)

  @doc "Returns the effective service records for a node."
  @spec effective_services(String.t(), GenServer.server()) :: [service()]
  def effective_services(node_id, server \\ __MODULE__) when is_binary(node_id) do
    GenServer.call(server, {:effective_services, node_id})
  end

  @doc "Returns a compact scheduler status useful to health and tests."
  @spec status(GenServer.server()) :: map()
  def status(server \\ __MODULE__), do: GenServer.call(server, :status)

  @doc "Cancels all pending and active discovery/observation work."
  @spec cancel(GenServer.server()) :: :ok
  def cancel(server \\ __MODULE__), do: GenServer.call(server, :cancel)

  @impl true
  def init(opts) do
    state = %__MODULE__{
      inventory: Keyword.get(opts, :inventory_server, Inventory),
      inventory_reader: Keyword.get(opts, :inventory_reader, &Inventory.current/1),
      registry: Keyword.get(opts, :registry_server, Registry),
      task_supervisor:
        Keyword.get(opts, :task_supervisor, Exocomp.Coordinator.ServiceTaskSupervisor),
      discovery_adapter: Keyword.get(opts, :discovery_adapter, &default_discovery/2),
      observation_adapter: Keyword.get(opts, :observation_adapter, &default_observation/3),
      adapter_options: Keyword.get(opts, :adapter_options, []),
      clock: Keyword.get(opts, :clock, &DateTime.utc_now/0),
      random: Keyword.get(opts, :random, &random_between/2),
      discovery_interval_ms:
        positive_option(opts, :discovery_interval_ms, @default_discovery_interval_ms),
      discovery_jitter_ms:
        nonnegative_option(opts, :discovery_jitter_ms, @default_discovery_jitter_ms),
      timeout_ms: positive_option(opts, :timeout_ms, @default_timeout_ms),
      concurrency: positive_option(opts, :concurrency, @default_concurrency),
      backoff_cap_ms: positive_option(opts, :backoff_cap_ms, @default_backoff_cap_ms),
      task_poll_interval_ms:
        positive_option(opts, :task_poll_interval_ms, @default_task_poll_interval_ms)
    }

    if Keyword.get(opts, :start_immediately, true), do: send(self(), :discover)
    {:ok, state}
  end

  @impl true
  def handle_call(:discover_now, _from, state) do
    state = request_discovery(state, automatic_nodes(state), true)
    {:reply, :ok, dispatch_pending(state)}
  end

  def handle_call({:observe_now, node_ids}, _from, state) do
    nodes = nodes_for_observation(state, node_ids)
    state = request_observation(state, nodes)
    {:reply, :ok, dispatch_pending(state)}
  end

  def handle_call(:discovery_cache, _from, state), do: {:reply, state.discovery_cache, state}
  def handle_call(:observations, _from, state), do: {:reply, state.observations, state}

  def handle_call({:effective_services, node_id}, _from, state) do
    {:reply, effective_services_for(node_id, state), state}
  end

  def handle_call(:status, _from, state) do
    {:reply,
     %{
       in_flight: Enum.map(state.tasks, fn {_ref, meta} -> {meta.kind, meta.node_id} end),
       pending_discovery: state.pending_discovery |> MapSet.to_list() |> Enum.sort(),
       pending_observation: state.pending_observation |> MapSet.to_list() |> Enum.sort(),
       discovery_cache: state.discovery_cache,
       observations: state.observations,
       failures: state.failures,
       next_discovery_at: state.next_discovery_at
     }, state}
  end

  def handle_call(:cancel, _from, state) do
    if state.discovery_timer_ref, do: Process.cancel_timer(state.discovery_timer_ref)
    {:reply, :ok, %{cancel_all(state) | discovery_timer_ref: nil, next_discovery_at: nil}}
  end

  @impl true
  def handle_cast({:observe_node, node_id}, state) do
    state = request_observation(state, nodes_for_observation(state, [node_id]))
    {:noreply, dispatch_pending(state)}
  end

  def handle_cast(:inventory_replaced, state) do
    current_ids = state |> inventory_nodes() |> Enum.map(& &1.id) |> MapSet.new()
    generations = bump_generations(state.generations, current_ids)

    state =
      state
      |> cancel_all()
      |> Map.put(:generations, generations)
      |> prune_removed_nodes(current_ids)
      |> request_discovery(automatic_nodes(state), true)
      |> request_observation(nodes_for_observation(state, :all))

    {:noreply, dispatch_pending(state)}
  end

  @impl true
  def handle_info(:discover, state) do
    state = schedule_next_discovery(state)
    state = request_discovery(state, automatic_nodes(state), false)
    {:noreply, dispatch_pending(state)}
  end

  def handle_info({ref, result}, state) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    case Map.pop(state.tasks, ref) do
      {nil, _tasks} ->
        {:noreply, state}

      {meta, tasks} ->
        Process.cancel_timer(meta.timeout_ref)
        state = handle_result(meta, result, %{state | tasks: tasks})
        {:noreply, dispatch_pending(state)}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    case Map.pop(state.tasks, ref) do
      {nil, _tasks} ->
        {:noreply, state}

      {meta, tasks} ->
        Process.demonitor(ref, [:flush])
        Process.cancel_timer(meta.timeout_ref)
        state = handle_result(meta, {:error, :worker_down}, %{state | tasks: tasks})
        {:noreply, dispatch_pending(state)}
    end
  end

  def handle_info({:task_timeout, ref}, state) do
    case Map.pop(state.tasks, ref) do
      {nil, _tasks} ->
        {:noreply, state}

      {%{task: task} = meta, tasks} ->
        Task.shutdown(task, :brutal_kill)
        Process.demonitor(ref, [:flush])
        state = handle_result(meta, {:error, :timeout}, %{state | tasks: tasks})
        {:noreply, dispatch_pending(state)}
    end
  end

  @impl true
  def terminate(_reason, state) do
    if state.discovery_timer_ref, do: Process.cancel_timer(state.discovery_timer_ref)
    cancel_all(state)
    :ok
  end

  defp request_discovery(state, nodes, force?) do
    pending =
      Enum.reduce(nodes, state.pending_discovery, fn node, pending ->
        if force? or retry_due?(state, :discovery, node.id) do
          MapSet.put(pending, node.id)
        else
          pending
        end
      end)

    %{state | pending_discovery: pending}
  end

  defp request_observation(state, nodes) do
    pending =
      Enum.reduce(nodes, state.pending_observation, fn node, pending ->
        if effective_services_for(node.id, state) == [] do
          MapSet.delete(pending, node.id)
        else
          MapSet.put(pending, node.id)
        end
      end)

    %{state | pending_observation: pending}
  end

  defp dispatch_pending(state) do
    state
    |> dispatch_kind(:discovery)
    |> dispatch_kind(:observation)
  end

  defp dispatch_kind(state, kind) do
    available = max(state.concurrency - map_size(state.tasks), 0)

    ids =
      case kind do
        :discovery -> state.pending_discovery |> MapSet.to_list() |> Enum.sort()
        :observation -> state.pending_observation |> MapSet.to_list() |> Enum.sort()
      end

    {state, _started} =
      Enum.reduce_while(ids, {state, 0}, fn node_id, {state, started} ->
        if started >= available do
          {:halt, {state, started}}
        else
          before = map_size(state.tasks)

          state =
            case find_node(node_id, state) do
              nil -> remove_pending(state, kind, node_id)
              node -> start_task_if_possible(node, kind, state)
            end

          started = if map_size(state.tasks) > before, do: started + 1, else: started
          {:cont, {state, started}}
        end
      end)

    state
  end

  defp start_task_if_possible(node, kind, state) do
    already_running? =
      Enum.any?(state.tasks, fn {_ref, meta} ->
        meta.node_id == node.id
      end)

    eligible? = kind == :observation or retry_due?(state, kind, node.id)

    cond do
      already_running? or not eligible? ->
        state

      kind == :observation and effective_services_for(node.id, state) == [] ->
        remove_pending(state, kind, node.id)

      true ->
        generation = Map.get(state.generations, node.id, 0)

        task =
          Task.Supervisor.async_nolink(state.task_supervisor, fn ->
            run_task(kind, node, state)
          end)

        timeout_ref = Process.send_after(self(), {:task_timeout, task.ref}, state.timeout_ms)

        meta = %{
          task: task,
          kind: kind,
          node_id: node.id,
          generation: generation,
          timeout_ref: timeout_ref,
          services: effective_services_for(node.id, state)
        }

        state
        |> put_task(task.ref, meta)
        |> remove_pending(kind, node.id)
    end
  end

  defp run_task(:discovery, node, state) do
    invoke_adapter(state.discovery_adapter, [node, adapter_opts(state)])
  end

  defp run_task(:observation, node, state) do
    services = effective_services_for(node.id, state)
    invoke_adapter(state.observation_adapter, [node, services, adapter_opts(state)])
  end

  defp adapter_opts(state) do
    Keyword.merge(state.adapter_options,
      timeout_ms: state.timeout_ms,
      registry: state.registry,
      task_poll_interval_ms: state.task_poll_interval_ms
    )
  end

  defp invoke_adapter(adapter, [node, opts]) when is_function(adapter, 2),
    do: adapter.(node, opts)

  defp invoke_adapter(adapter, [node, _opts]) when is_function(adapter, 1), do: adapter.(node)

  defp invoke_adapter(adapter, [node, services, opts]) when is_function(adapter, 3),
    do: adapter.(node, services, opts)

  defp invoke_adapter(adapter, [node, services, _opts]) when is_function(adapter, 2),
    do: adapter.(node, services)

  defp invoke_adapter(adapter, [node, _services, _opts]) when is_function(adapter, 1),
    do: adapter.(node)

  defp handle_result(%{kind: :discovery, node_id: node_id, generation: generation}, result, state) do
    if generation == Map.get(state.generations, node_id, 0) do
      case normalize_discovery(result) do
        {:ok, services} ->
          cache =
            Map.put(state.discovery_cache, node_id, %{
              services: services,
              discovered_at: now(state)
            })

          state = clear_failure(state, :discovery, node_id)
          state = %{state | discovery_cache: cache}
          state

        {:error, _reason} ->
          record_failure(state, :discovery, node_id)
      end
    else
      state
    end
  end

  defp handle_result(
         %{kind: :observation, node_id: node_id, generation: generation, services: services},
         result,
         state
       ) do
    if generation == Map.get(state.generations, node_id, 0) do
      case result do
        {:ok, observation} ->
          observations =
            Map.put(state.observations, node_id, %{
              services: services,
              result: observation,
              observed_at: now(state)
            })

          %{state | observations: observations} |> clear_failure(:observation, node_id)

        _failure ->
          record_failure(state, :observation, node_id)
      end
    else
      state
    end
  end

  defp normalize_discovery({:ok, value}), do: normalize_service_value(value)
  defp normalize_discovery({:error, reason}), do: {:error, reason}
  defp normalize_discovery(value), do: normalize_service_value(value)

  defp normalize_service_value(%{services: services}), do: normalize_service_value(services)
  defp normalize_service_value(%{"services" => services}), do: normalize_service_value(services)

  defp normalize_service_value(%{artifacts: [], status: %{message: message}}),
    do: normalize_service_value(message)

  defp normalize_service_value(%{artifacts: artifacts}),
    do: artifacts |> artifact_services() |> normalize_service_names()

  defp normalize_service_value(%{status: %{message: message}}),
    do: normalize_service_value(message)

  defp normalize_service_value(%{"observations" => observations}),
    do: normalize_service_value(observations)

  defp normalize_service_value(%{"enabled_services" => services}),
    do: normalize_service_value(services)

  defp normalize_service_value(%{"measurements" => measurements}),
    do: normalize_service_value(measurements)

  defp normalize_service_value(%{measurements: measurements}),
    do: normalize_service_value(measurements)

  defp normalize_service_value(services) when is_list(services),
    do: normalize_service_names(services)

  defp normalize_service_value(services) when is_map(services) do
    names =
      services
      |> Map.keys()
      |> Enum.map(&to_string/1)
      |> Enum.map(&service_name_from_inventory_key/1)
      |> Enum.reject(&is_nil/1)

    if names == [], do: {:error, :malformed_discovery}, else: normalize_service_names(names)
  end

  defp normalize_service_value(_other), do: {:error, :malformed_discovery}

  defp service_name_from_inventory_key(key) do
    cond do
      String.ends_with?(key, ".service") ->
        key

      true ->
        Enum.find_value(@inventory_property_suffixes, fn suffix ->
          marker = "_#{suffix}"

          if String.ends_with?(key, marker) do
            key
            |> String.trim_trailing(marker)
            |> String.trim_trailing("_")
            |> String.replace_suffix("_service", ".service")
          end
        end)
    end
  end

  defp artifact_services(artifacts) when is_list(artifacts) do
    Enum.flat_map(artifacts, fn artifact ->
      cond do
        is_map(artifact) and Map.has_key?(artifact, :parts) ->
          artifact_services(artifact.parts)

        is_map(artifact) and Map.has_key?(artifact, "parts") ->
          artifact_services(artifact["parts"])

        is_map(artifact) and Map.has_key?(artifact, :data) ->
          artifact_services(artifact.data)

        is_map(artifact) and Map.has_key?(artifact, "data") ->
          artifact_services(artifact["data"])

        true ->
          case normalize_service_value(artifact) do
            {:ok, services} -> services
            _ -> []
          end
      end
    end)
  end

  defp artifact_services(other) when is_map(other), do: artifact_services([other])
  defp artifact_services(_other), do: []

  defp normalize_service_names(services) do
    names =
      Enum.flat_map(services, fn
        name when is_binary(name) -> [%{name: name}]
        %{name: name} when is_binary(name) -> [%{name: name}]
        %{"name" => name} when is_binary(name) -> [%{name: name}]
        %{unit: name} when is_binary(name) -> [%{name: name}]
        %{"unit" => name} when is_binary(name) -> [%{name: name}]
        _other -> []
      end)

    names =
      names
      |> Enum.filter(&String.ends_with?(&1.name, ".service"))
      |> Enum.uniq_by(& &1.name)
      |> Enum.sort_by(& &1.name)

    {:ok, names}
  end

  defp effective_services_for(node_id, state) do
    case find_node(node_id, state) do
      nil ->
        []

      node ->
        manual =
          case node.monitoring do
            %{services: services} when is_list(services) ->
              Enum.map(services, &Map.put(&1, :source, :manual))

            _ ->
              []
          end

        automatic =
          case node.monitoring do
            %{automatic: true} ->
              state.discovery_cache
              |> Map.get(node.id, %{services: []})
              |> Map.get(:services, [])
              |> Enum.map(&Map.put(&1, :source, :automatic))

            _ ->
              []
          end

        (manual ++ automatic)
        |> Enum.reduce(%{}, fn service, acc ->
          Map.put_new(acc, service.name, service)
        end)
        |> Map.values()
        |> Enum.sort_by(& &1.name)
    end
  end

  defp automatic_nodes(state), do: Enum.filter(inventory_nodes(state), &automatic_node?/1)

  defp automatic_node?(%{monitoring: %{automatic: true}}), do: true
  defp automatic_node?(_node), do: false

  defp nodes_for_observation(state, :all), do: inventory_nodes(state)

  defp nodes_for_observation(state, node_ids) when is_list(node_ids) do
    node_ids
    |> Enum.uniq()
    |> Enum.map(&find_node(&1, state))
    |> Enum.reject(&is_nil/1)
  end

  defp inventory_nodes(state) do
    state.inventory_reader.(state.inventory).nodes
  catch
    :exit, _reason -> []
  end

  defp find_node(node_id, state), do: Enum.find(inventory_nodes(state), &(&1.id == node_id))

  defp schedule_next_discovery(state) do
    if state.discovery_timer_ref, do: Process.cancel_timer(state.discovery_timer_ref)

    jitter_bound = min(state.discovery_jitter_ms, state.discovery_interval_ms)
    jitter = state.random.(-jitter_bound, jitter_bound)
    delay = max(state.discovery_interval_ms + jitter, 0)
    timer_ref = Process.send_after(self(), :discover, delay)

    %{
      state
      | discovery_timer_ref: timer_ref,
        next_discovery_at: DateTime.add(now(state), delay, :millisecond)
    }
  end

  defp retry_due?(state, kind, node_id) do
    case Map.get(state.failures, {kind, node_id}) do
      nil -> true
      %{next_at: next_at} -> DateTime.compare(next_at, now(state)) in [:lt, :eq]
    end
  end

  defp record_failure(state, kind, node_id) do
    key = {kind, node_id}
    failures = Map.get(state.failures, key, %{count: 0})
    count = failures.count + 1
    base = state.discovery_interval_ms
    delay = min(base * Integer.pow(2, count - 1), state.backoff_cap_ms)
    failure = %{count: count, next_at: DateTime.add(now(state), delay, :millisecond)}
    %{state | failures: Map.put(state.failures, key, failure)}
  end

  defp clear_failure(state, kind, node_id),
    do: %{state | failures: Map.delete(state.failures, {kind, node_id})}

  defp cancel_all(state) do
    Enum.each(state.tasks, fn {_ref, %{task: task, timeout_ref: timeout_ref}} ->
      Process.cancel_timer(timeout_ref)
      Task.shutdown(task, :brutal_kill)
    end)

    %{state | tasks: %{}, pending_discovery: MapSet.new(), pending_observation: MapSet.new()}
  end

  defp prune_removed_nodes(state, current_ids) do
    keep = fn {node_id, _value} -> MapSet.member?(current_ids, node_id) end

    %{
      state
      | discovery_cache: Map.filter(state.discovery_cache, keep),
        observations: Map.filter(state.observations, keep),
        failures:
          Map.filter(state.failures, fn {{_kind, node_id}, _value} ->
            MapSet.member?(current_ids, node_id)
          end)
    }
  end

  defp bump_generations(generations, current_ids) do
    Enum.reduce(current_ids, %{}, fn node_id, acc ->
      Map.put(acc, node_id, Map.get(generations, node_id, 0) + 1)
    end)
  end

  defp put_task(state, ref, meta), do: %{state | tasks: Map.put(state.tasks, ref, meta)}

  defp remove_pending(state, :discovery, node_id),
    do: %{state | pending_discovery: MapSet.delete(state.pending_discovery, node_id)}

  defp remove_pending(state, :observation, node_id),
    do: %{state | pending_observation: MapSet.delete(state.pending_observation, node_id)}

  defp now(state) do
    case state.clock.() do
      %DateTime{} = current ->
        current

      other ->
        raise ArgumentError,
              "service scheduler clock must return DateTime, got: #{inspect(other)}"
    end
  end

  defp default_discovery(node, opts) do
    request_task(node, "exocomp.service.inventory", %{}, opts)
  end

  defp default_observation(node, services, opts) do
    params = %{
      "services" => Enum.map(services, & &1.name),
      "probes" =>
        services
        |> Enum.filter(&Map.has_key?(&1, :health_check_url))
        |> Enum.map(fn service -> %{"url" => service.health_check_url} end)
    }

    request_task(node, "exocomp.service.observe", params, opts)
  end

  defp request_task(node, skill, params, opts) do
    client = Keyword.get(opts, :client, DiagnosticClient)
    client_opts = Keyword.get(opts, :client_opts, [])
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)

    request_opts =
      Keyword.merge(client_opts,
        registry: Keyword.get(opts, :registry),
        timeout_ms: timeout_ms
      )

    with {:ok, task} <-
           client.send(node.id, skill, params, request_opts) do
      await_task(
        client,
        node.id,
        task,
        Keyword.put(opts, :client_opts, request_opts),
        System.monotonic_time(:millisecond) + timeout_ms
      )
    end
  end

  defp await_task(_client, _node_id, %{status: %{state: :completed}} = task, _opts, _deadline),
    do: {:ok, task}

  defp await_task(_client, _node_id, %{status: %{state: state}}, _opts, _deadline)
       when state in [:failed, :canceled, :rejected],
       do: {:error, state}

  defp await_task(client, node_id, %{id: task_id}, opts, deadline) do
    remaining = deadline - System.monotonic_time(:millisecond)

    if remaining <= 0 do
      {:error, :timeout}
    else
      Process.sleep(
        min(Keyword.get(opts, :task_poll_interval_ms, @default_task_poll_interval_ms), remaining)
      )

      case client.get_task(node_id, task_id, Keyword.get(opts, :client_opts, [])) do
        {:ok, task} -> await_task(client, node_id, task, opts, deadline)
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp await_task(_client, _node_id, _task, _opts, _deadline), do: {:error, :malformed_task}

  defp random_between(minimum, maximum), do: minimum + :rand.uniform(maximum - minimum + 1) - 1

  defp positive_option(opts, key, default) do
    case Keyword.get(opts, key, default) do
      value when is_integer(value) and value > 0 -> value
      value -> raise ArgumentError, "#{key} must be a positive integer, got: #{inspect(value)}"
    end
  end

  defp nonnegative_option(opts, key, default) do
    case Keyword.get(opts, key, default) do
      value when is_integer(value) and value >= 0 ->
        value

      value ->
        raise ArgumentError, "#{key} must be a non-negative integer, got: #{inspect(value)}"
    end
  end
end

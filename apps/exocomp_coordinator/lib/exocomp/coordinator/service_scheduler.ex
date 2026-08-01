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

  alias Exocomp.DesiredService
  alias Exocomp.Coordinator.{A2A.DiagnosticClient, Audit, Inventory, Registry}

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
    :audit_server,
    :profile_resolver,
    :profile_sources,
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
    generations: %{},
    expectations: %{},
    health: %{},
    retired: %{},
    transitions: []
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

  @doc "Returns resolver-backed effective expectations for a node."
  @spec expectations(String.t(), GenServer.server()) :: [DesiredService.t()]
  def expectations(node_id, server \\ __MODULE__) when is_binary(node_id) do
    GenServer.call(server, {:expectations, node_id})
  end

  @doc "Returns the current expectation and health view for every node."
  @spec desired_state(GenServer.server()) :: map()
  def desired_state(server \\ __MODULE__), do: GenServer.call(server, :desired_state)

  @doc "Returns the latest per-service health records, including pending hysteresis."
  @spec health(GenServer.server()) :: map()
  def health(server \\ __MODULE__), do: GenServer.call(server, :health)

  @doc "Returns correlated desired-state and health transition records."
  @spec transitions(GenServer.server()) :: [map()]
  def transitions(server \\ __MODULE__), do: GenServer.call(server, :transitions)

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
      audit_server: Keyword.get(opts, :audit_server, Audit),
      profile_resolver:
        Keyword.get(opts, :profile_resolver) ||
          profile_resolver_from_sources(Keyword.get(opts, :profile_sources, %{})),
      profile_sources: Keyword.get(opts, :profile_sources, %{}),
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
    state = reconcile_desired_state(state)
    nodes = nodes_for_observation(state, node_ids)
    state = request_observation(state, nodes)
    {:reply, :ok, dispatch_pending(state)}
  end

  def handle_call(:discovery_cache, _from, state), do: {:reply, state.discovery_cache, state}
  def handle_call(:observations, _from, state), do: {:reply, state.observations, state}

  def handle_call({:effective_services, node_id}, _from, state) do
    {:reply, effective_services_for(node_id, state), state}
  end

  def handle_call({:expectations, node_id}, _from, state) do
    {:reply, effective_expectations_for(node_id, state), state}
  end

  def handle_call(:desired_state, _from, state) do
    state = reconcile_desired_state(state)
    {:reply, desired_state_view(state), state}
  end

  def handle_call(:health, _from, state), do: {:reply, state.health, state}

  def handle_call(:transitions, _from, state),
    do: {:reply, Enum.reverse(state.transitions), state}

  def handle_call(:status, _from, state) do
    state = reconcile_desired_state(state)

    {:reply,
     %{
       in_flight: Enum.map(state.tasks, fn {_ref, meta} -> {meta.kind, meta.node_id} end),
       pending_discovery: state.pending_discovery |> MapSet.to_list() |> Enum.sort(),
       pending_observation: state.pending_observation |> MapSet.to_list() |> Enum.sort(),
       discovery_cache: state.discovery_cache,
       observations: state.observations,
       failures: state.failures,
       desired_state: desired_state_view(state),
       health: state.health,
       transitions: Enum.reverse(state.transitions),
       next_discovery_at: state.next_discovery_at
     }, state}
  end

  def handle_call(:cancel, _from, state) do
    if state.discovery_timer_ref, do: Process.cancel_timer(state.discovery_timer_ref)
    {:reply, :ok, %{cancel_all(state) | discovery_timer_ref: nil, next_discovery_at: nil}}
  end

  @impl true
  def handle_cast({:observe_node, node_id}, state) do
    state = reconcile_desired_state(state)
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
      |> reconcile_desired_state()
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
          |> reconcile_desired_state()
          |> request_observation(nodes_for_observation(state, [node_id]))

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
          correlation_id = observation_correlation(observation)

          case normalize_observation(observation, services) do
            {:ok, summary} ->
              state =
                state
                |> put_observation(node_id, services, observation, summary, correlation_id)
                |> update_health(node_id, services, summary, correlation_id)
                |> clear_failure(:observation, node_id)

              state

            {:error, reason, summary} ->
              state
              |> put_observation(node_id, services, observation, summary, correlation_id)
              |> update_failed_observation_health(
                node_id,
                services,
                reason,
                correlation_id
              )
              |> record_failure(:observation, node_id)
          end

        {:error, reason} ->
          correlation_id = Audit.correlation_id()

          state
          |> put_failed_observation(node_id, services, reason, correlation_id)
          |> update_failed_observation_health(node_id, services, reason, correlation_id)
          |> record_failure(:observation, node_id)

        _failure ->
          correlation_id = Audit.correlation_id()

          state
          |> put_failed_observation(node_id, services, :observation_failed, correlation_id)
          |> update_failed_observation_health(
            node_id,
            services,
            :observation_failed,
            correlation_id
          )
          |> record_failure(:observation, node_id)
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

  defp put_observation(state, node_id, services, result, summary, correlation_id) do
    observations =
      Map.put(state.observations, node_id, %{
        services: services,
        result: result,
        summary: summary,
        status: summary.status,
        observed_at: now(state),
        correlation_id: correlation_id,
        last_successful_observed_at: now(state)
      })

    %{state | observations: observations}
  end

  defp put_failed_observation(state, node_id, services, reason, correlation_id) do
    previous = Map.get(state.observations, node_id, %{})
    failure_state = observation_failure_state(reason)

    observation = %{
      services: services,
      result: {:error, reason},
      summary: %{status: failure_state, reason: reason},
      status: failure_state,
      observed_at: now(state),
      correlation_id: correlation_id,
      last_successful_observed_at: Map.get(previous, :last_successful_observed_at)
    }

    %{state | observations: Map.put(state.observations, node_id, observation)}
  end

  defp update_health(state, node_id, services, summary, correlation_id) do
    Enum.reduce(services, state, fn service, acc ->
      unit = service_name(service)

      observation =
        summary.service_states
        |> Map.get(unit, %{state: :healthy})
        |> Map.put_new(:observed_at, now(acc))

      apply_health_observation(acc, {node_id, unit}, observation, correlation_id)
    end)
  end

  defp update_failed_observation_health(state, node_id, services, reason, correlation_id) do
    observed_state = observation_failure_state(reason)

    Enum.reduce(services, state, fn service, acc ->
      apply_health_observation(
        acc,
        {node_id, service_name(service)},
        %{state: observed_state, reason: reason, observed_at: now(acc)},
        correlation_id
      )
    end)
  end

  defp observation_failure_state(reason) when reason in [:unreachable, :worker_down],
    do: :unreachable

  defp observation_failure_state(:timeout), do: :stale
  defp observation_failure_state(:stale), do: :stale
  defp observation_failure_state(:probe_or_service_failed), do: :unhealthy
  defp observation_failure_state(_reason), do: :stale

  defp apply_health_observation(state, key, observation, correlation_id) do
    candidate = Map.get(observation, :state, :unhealthy)
    previous = Map.get(state.health, key, initial_health())
    {updated, transition} = next_health(previous, candidate, observation, correlation_id)
    state = %{state | health: Map.put(state.health, key, updated)}

    case transition do
      nil ->
        state

      %{from: from, to: to, attributes: attributes} ->
        emit_transition(
          state,
          :service_health_transition,
          Map.merge(attributes, %{node_id: elem(key, 0), unit: elem(key, 1), from: from, to: to}),
          correlation_id
        )
    end
  end

  defp next_health(previous, candidate, observation, correlation_id)
       when candidate in [:stale, :unreachable] do
    updated = %{
      previous
      | state: candidate,
        candidate_state: nil,
        candidate_count: 0,
        consecutive_observations: 1,
        last_observed_at: observation_time(observation),
        last_correlation_id: correlation_id,
        reason: Map.get(observation, :reason),
        lifecycle: :active
    }

    transition =
      if previous.state == candidate,
        do: nil,
        else: %{from: previous.state, to: candidate, attributes: %{observed_state: candidate}}

    {updated, transition}
  end

  defp next_health(previous, :healthy, observation, correlation_id) do
    confirmation_count =
      if previous.candidate_state == :healthy, do: previous.candidate_count + 1, else: 1

    confirmed? = previous.state in [:unknown, :healthy] or confirmation_count >= 2
    state = if confirmed?, do: :healthy, else: previous.state

    updated = %{
      previous
      | state: state,
        candidate_state: if(state == :healthy, do: nil, else: :healthy),
        candidate_count: if(state == :healthy, do: 0, else: confirmation_count),
        consecutive_observations: confirmation_count,
        last_observed_at: observation_time(observation),
        last_correlation_id: correlation_id,
        reason: Map.get(observation, :reason),
        lifecycle: :active
    }

    transition =
      if state != previous.state,
        do: %{from: previous.state, to: state, attributes: %{observed_state: :healthy}},
        else: nil

    {updated, transition}
  end

  defp next_health(previous, :unhealthy, observation, correlation_id) do
    confirmation_count =
      if previous.candidate_state == :unhealthy, do: previous.candidate_count + 1, else: 1

    state = if confirmation_count >= 2, do: :unhealthy, else: previous.state

    updated = %{
      previous
      | state: state,
        candidate_state: if(state == :unhealthy, do: nil, else: :unhealthy),
        candidate_count: if(state == :unhealthy, do: 0, else: confirmation_count),
        consecutive_observations: confirmation_count,
        last_observed_at: observation_time(observation),
        last_correlation_id: correlation_id,
        reason: Map.get(observation, :reason),
        lifecycle: :active
    }

    transition =
      if state != previous.state,
        do: %{from: previous.state, to: state, attributes: %{observed_state: :unhealthy}},
        else: nil

    {updated, transition}
  end

  defp next_health(previous, _candidate, observation, correlation_id),
    do: next_health(previous, :unhealthy, observation, correlation_id)

  defp observation_time(observation), do: Map.get(observation, :observed_at)

  defp emit_transition(state, event_type, attributes, correlation_id) do
    event = %{
      event_type: event_type,
      correlation_id: correlation_id,
      occurred_at: now(state),
      attributes: attributes
    }

    _ = safe_audit_emit(state.audit_server, event_type, attributes, correlation_id)
    %{state | transitions: [event | Enum.take(state.transitions, 999)]}
  end

  defp safe_audit_emit(server, event_type, attributes, correlation_id) do
    Audit.emit(event_type, attributes, server: server, correlation_id: correlation_id)
  catch
    :exit, _reason -> :ok
  end

  defp observation_correlation(observation) when is_map(observation) do
    Map.get(observation, :correlation_id) ||
      Map.get(observation, "correlation_id") ||
      Audit.correlation_id()
  end

  defp observation_correlation(_observation), do: Audit.correlation_id()

  defp normalize_observation({:ok, value}, services), do: normalize_observation(value, services)

  defp normalize_observation(value, services) do
    payload = observation_payload(value)
    recognized? = observation_payload_recognized?(payload)
    probes = observation_probes(payload)
    probe_map = probe_results_map(all_probe_keys(services), probes)

    service_states =
      Map.new(services, fn service ->
        unit = service_name(service)
        systemd = observed_systemd_state(payload, unit)
        systemd = expected_systemd_state(service, systemd)
        explicit = observed_service_state(payload, unit)
        probe_state = service_probe_state(service, probe_map)

        state =
          cond do
            probe_state == :unhealthy -> :unhealthy
            systemd == :unhealthy -> :unhealthy
            explicit == :unhealthy -> :unhealthy
            explicit == :healthy -> :healthy
            systemd == :healthy and probe_state == :healthy -> :healthy
            not recognized? -> :healthy
            true -> :unhealthy
          end

        {unit, %{state: state, systemd: systemd, probes: probe_state}}
      end)

    summary = %{
      status:
        if(Enum.all?(service_states, fn {_unit, value} -> value.state == :healthy end),
          do: :healthy,
          else: :unhealthy
        ),
      service_states: service_states,
      probes: probes
    }

    if summary.status == :healthy,
      do: {:ok, summary},
      else: {:error, :probe_or_service_failed, summary}
  end

  defp observation_payload(value) when is_map(value) do
    cond do
      Map.has_key?(value, :artifacts) -> artifact_payload(Map.get(value, :artifacts))
      Map.has_key?(value, "artifacts") -> artifact_payload(Map.get(value, "artifacts"))
      true -> value
    end
  end

  defp observation_payload(_value), do: %{}

  defp artifact_payload(artifacts) when is_list(artifacts),
    do: Enum.find_value(artifacts, %{}, &artifact_payload/1)

  defp artifact_payload(value) when is_map(value) do
    cond do
      Map.has_key?(value, :data) -> artifact_payload(Map.get(value, :data))
      Map.has_key?(value, "data") -> artifact_payload(Map.get(value, "data"))
      Map.has_key?(value, :parts) -> artifact_payload(Map.get(value, :parts))
      Map.has_key?(value, "parts") -> artifact_payload(Map.get(value, "parts"))
      Map.has_key?(value, :skill) or Map.has_key?(value, "skill") -> value
      true -> value
    end
  end

  defp artifact_payload(_value), do: %{}

  defp observation_payload_recognized?(payload) when is_map(payload) do
    Enum.any?(
      [
        :service_states,
        "service_states",
        :services,
        "services",
        :systemd,
        "systemd",
        :probes,
        "probes"
      ],
      &Map.has_key?(payload, &1)
    )
  end

  defp observation_payload_recognized?(_payload), do: false

  defp observation_probes(payload) when is_map(payload),
    do: Map.get(payload, :probes, Map.get(payload, "probes", [])) || []

  defp observation_probes(_payload), do: []

  defp all_probe_keys(services),
    do: services |> Enum.flat_map(&service_probes/1) |> Enum.uniq()

  defp probe_results_map(keys, results) do
    keyed =
      Enum.flat_map(results, fn result ->
        case result do
          %{url: key} -> [{key, result}]
          %{"url" => key} -> [{key, result}]
          %{probe: key} -> [{key, result}]
          %{"probe" => key} -> [{key, result}]
          %{name: key} -> [{key, result}]
          %{"name" => key} -> [{key, result}]
          %{id: key} -> [{key, result}]
          %{"id" => key} -> [{key, result}]
          _other -> []
        end
      end)

    zipped = Enum.zip(keys, results)
    Map.new(zipped ++ keyed)
  end

  defp service_probe_state(service, probe_map) do
    probes = service_probes(service)

    cond do
      probes == [] -> :healthy
      Enum.any?(probes, &(not Map.has_key?(probe_map, &1))) -> :unhealthy
      Enum.all?(probes, &probe_pass?(Map.get(probe_map, &1))) -> :healthy
      true -> :unhealthy
    end
  end

  defp probe_pass?({:ok, status, _time, _size}) when is_integer(status), do: status in 200..299
  defp probe_pass?(%{status: status}) when is_integer(status), do: status in 200..299
  defp probe_pass?(%{"status" => status}) when is_integer(status), do: status in 200..299
  defp probe_pass?(_value), do: false

  defp observed_service_state(payload, unit) when is_map(payload) do
    states = Map.get(payload, :service_states, Map.get(payload, "service_states", %{})) || %{}

    case Map.get(states, unit, Map.get(states, to_string(unit))) do
      value when is_map(value) -> service_state_value(value)
      value -> normalize_health_state(value)
    end
  end

  defp observed_service_state(_payload, _unit), do: nil

  defp service_state_value(value) do
    normalize_health_state(
      Map.get(
        value,
        :state,
        Map.get(value, "state", Map.get(value, :health, Map.get(value, "health")))
      )
    )
  end

  defp normalize_health_state(value) when value in [:healthy, :ok, :running, :active],
    do: :healthy

  defp normalize_health_state(value) when value in [:unhealthy, :failed, :degraded, :inactive],
    do: :unhealthy

  defp normalize_health_state(value) when value in ["healthy", "ok", "running", "active"],
    do: :healthy

  defp normalize_health_state(value)
       when value in ["unhealthy", "failed", "degraded", "inactive"],
       do: :unhealthy

  defp normalize_health_state(_value), do: nil

  defp observed_systemd_state(payload, unit) when is_map(payload) do
    systemd = Map.get(payload, :systemd, Map.get(payload, "systemd"))

    measurements =
      case systemd do
        %{measurements: values} -> values
        %{"measurements" => values} -> values
        _ -> Map.get(payload, :measurements, Map.get(payload, "measurements", %{}))
      end || %{}

    prefix = unit |> String.replace(".", "_") |> String.replace("-", "_")
    key = String.downcase(prefix <> "_activestate")

    measurements
    |> measurement_for_key(key)
    |> measurement_value()
    |> case do
      value when value in ["active", "running", :active, :running] -> :healthy
      value when value in ["inactive", "failed", "dead", :inactive, :failed, :dead] -> :unhealthy
      _ -> nil
    end
  end

  defp observed_systemd_state(_payload, _unit), do: nil

  defp expected_systemd_state(_service, nil), do: nil

  defp expected_systemd_state(service, observed) do
    expected = service_field(service, :expected_state, :running)

    case expected do
      state when state in [:running, :active, "running", "active"] ->
        observed

      state when state in [:stopped, :inactive, "stopped", "inactive"] ->
        if observed == :healthy, do: :unhealthy, else: :healthy

      _other ->
        observed
    end
  end

  defp measurement_value(%{value: value}), do: value
  defp measurement_value(%{"value" => value}), do: value
  defp measurement_value(value), do: value

  defp measurement_for_key(measurements, key) do
    Map.get(measurements, key) ||
      Enum.find_value(measurements, fn
        {candidate, value} when is_atom(candidate) ->
          if Atom.to_string(candidate) == key, do: value

        _other ->
          nil
      end)
  end

  defp normalize_service_names(services) do
    names =
      Enum.flat_map(services, fn
        name when is_binary(name) -> [%{name: name}]
        %{name: name} = service when is_binary(name) -> [normalize_service_record(service)]
        %{"name" => name} = service when is_binary(name) -> [normalize_service_record(service)]
        %{unit: name} = service when is_binary(name) -> [normalize_service_record(service)]
        %{"unit" => name} = service when is_binary(name) -> [normalize_service_record(service)]
        _other -> []
      end)

    names =
      names
      |> Enum.filter(&String.ends_with?(&1.name, ".service"))
      |> Enum.uniq_by(& &1.name)
      |> Enum.sort_by(& &1.name)

    {:ok, names}
  end

  defp normalize_service_record(service) do
    name = service_name(service)

    service
    |> Map.put(:name, name)
    |> Map.delete("name")
    |> Map.delete(:unit)
    |> Map.delete("unit")
  end

  defp effective_services_for(node_id, state) do
    node_id
    |> effective_expectations_for(state)
    |> Enum.map(&expectation_to_service/1)
  end

  defp effective_expectations_for(node_id, state) do
    case find_node(node_id, state) do
      nil -> []
      node -> DesiredService.resolve(source_contributions(node, state))
    end
  end

  defp source_contributions(node, state) do
    manual =
      node
      |> manual_services()
      |> Enum.map(&contribution(:manual, node.id, &1))

    automatic =
      if automatic_node?(node) do
        state.discovery_cache
        |> Map.get(node.id, %{services: []})
        |> Map.get(:services, [])
        |> Enum.map(&contribution(:automatic, node.id, &1))
      else
        []
      end

    profile =
      node
      |> profile_services(state)
      |> Enum.map(&contribution(:cluster_profile, node.id, &1))

    manual ++ automatic ++ profile
  end

  defp manual_services(%{monitoring: %{services: services}}) when is_list(services), do: services
  defp manual_services(_node), do: []

  defp contribution(source, node_id, service) do
    DesiredService.SourceExpectation.new(source, node_id, service_name(service),
      required_probes: service_probes(service),
      expected_state: service_field(service, :expected_state, :running),
      profile_context: service_field(service, :profile_context)
    )
  end

  defp expectation_to_service(expectation) do
    probes = Enum.filter(expectation.required_probes, &probe_url?/1)

    %{
      name: expectation.unit,
      source: List.first(expectation.sources),
      sources: expectation.sources,
      required_probes: expectation.required_probes,
      probes: probes,
      health_check_url: List.first(probes),
      expected_state: expectation.expected_state,
      profile_context: expectation.profile_context,
      recovery_authority_source: expectation.recovery_authority_source
    }
    |> Map.reject(fn {_key, value} -> is_nil(value) end)
  end

  defp service_name(%{name: name}) when is_binary(name), do: name
  defp service_name(%{"name" => name}) when is_binary(name), do: name
  defp service_name(%{unit: name}) when is_binary(name), do: name
  defp service_name(%{"unit" => name}) when is_binary(name), do: name
  defp service_name(name) when is_binary(name), do: name

  defp service_probes(service) do
    values =
      [
        service_field(service, :health_check_url),
        service_field(service, :health_check_urls, []),
        service_field(service, :required_probes, []),
        service_field(service, :probes, [])
      ]
      |> List.flatten()

    values
    |> Enum.map(fn
      %{url: url} -> url
      %{"url" => url} -> url
      probe -> probe
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp service_field(service, field, default \\ nil)

  defp service_field(service, field, default) when is_map(service) do
    Map.get(service, field, Map.get(service, Atom.to_string(field), default))
  end

  defp service_field(_service, _field, default), do: default

  defp probe_url?(probe) when is_binary(probe), do: String.starts_with?(probe, "http")
  defp probe_url?(_probe), do: false

  defp automatic_nodes(state), do: Enum.filter(inventory_nodes(state), &automatic_node?/1)

  defp automatic_node?(%{monitoring: %{automatic: true}}), do: true
  defp automatic_node?(_node), do: false

  defp profile_services(node, state) do
    profile = inventory_profile(state)

    if is_nil(profile) do
      []
    else
      result = invoke_profile_resolver(state.profile_resolver, profile, node)

      case result do
        {:ok, value} -> add_profile_context(normalize_profile_services(value, node.id), profile)
        value -> add_profile_context(normalize_profile_services(value, node.id), profile)
      end
    end
  end

  defp inventory_profile(state) do
    inventory = inventory_reader_result(state)
    Map.get(inventory, :cluster_profile, Map.get(inventory, "cluster_profile"))
  end

  defp inventory_reader_result(state) do
    state.inventory_reader.(state.inventory)
  catch
    :exit, _reason -> %{}
  end

  defp invoke_profile_resolver(resolver, profile, node) when is_function(resolver, 2),
    do: resolver.(profile, node)

  defp invoke_profile_resolver(resolver, profile, _node) when is_function(resolver, 1),
    do: resolver.(profile)

  defp invoke_profile_resolver(_resolver, _profile, _node), do: []

  defp normalize_profile_services(value, node_id) when is_map(value) do
    cond do
      Map.has_key?(value, :services) ->
        normalize_profile_services(Map.get(value, :services), node_id)

      Map.has_key?(value, "services") ->
        normalize_profile_services(Map.get(value, "services"), node_id)

      Map.has_key?(value, node_id) ->
        normalize_profile_services(Map.get(value, node_id), node_id)

      Map.has_key?(value, to_string(node_id)) ->
        normalize_profile_services(Map.get(value, to_string(node_id)), node_id)

      true ->
        []
    end
  end

  defp normalize_profile_services(value, _node_id) when is_list(value), do: value
  defp normalize_profile_services(_value, _node_id), do: []

  defp add_profile_context(services, profile) do
    Enum.map(services, fn
      service when is_map(service) -> Map.put_new(service, :profile_context, profile)
      service when is_binary(service) -> %{name: service, profile_context: profile}
      service -> service
    end)
  end

  defp default_profile_resolver(profile, _node) do
    sources = Application.get_env(:exocomp_coordinator, :cluster_profiles, %{})
    Map.get(sources, profile, Map.get(sources, to_string(profile), []))
  end

  defp profile_resolver_from_sources(%{}), do: &default_profile_resolver/2

  defp profile_resolver_from_sources(sources) when is_map(sources) do
    fn profile, _node -> Map.get(sources, profile, Map.get(sources, to_string(profile), [])) end
  end

  defp profile_resolver_from_sources(_sources), do: &default_profile_resolver/2

  defp reconcile_desired_state(state) do
    current_ids = state |> inventory_nodes() |> Enum.map(& &1.id) |> MapSet.new()

    Enum.reduce(MapSet.to_list(current_ids), state, fn node_id, acc ->
      reconcile_node(node_id, acc)
    end)
  end

  defp reconcile_node(node_id, state) do
    previous = Map.get(state.expectations, node_id, %{})

    current =
      effective_expectations_for(node_id, state)
      |> Map.new(fn expectation -> {expectation.unit, expectation} end)

    removed = Map.keys(previous) -- Map.keys(current)
    added = Map.keys(current) -- Map.keys(previous)

    changed =
      Map.keys(current)
      |> Enum.filter(fn unit ->
        Map.has_key?(previous, unit) and previous[unit] != current[unit]
      end)

    state =
      Enum.reduce(removed, state, fn unit, acc ->
        expectation = previous[unit]
        correlation_id = Audit.correlation_id()
        key = {node_id, unit}

        acc
        |> put_retired(key, expectation, correlation_id)
        |> emit_transition(
          :desired_state_removed,
          %{node_id: node_id, unit: unit, sources: expectation.sources},
          correlation_id
        )
      end)

    state =
      Enum.reduce(added, state, fn unit, acc ->
        correlation_id = Audit.correlation_id()
        key = {node_id, unit}

        acc
        |> clear_retired(key)
        |> reset_health(key)
        |> emit_transition(
          :desired_state_added,
          %{node_id: node_id, unit: unit, sources: current[unit].sources},
          correlation_id
        )
      end)

    state =
      Enum.reduce(changed, state, fn unit, acc ->
        correlation_id = Audit.correlation_id()
        key = {node_id, unit}

        acc
        |> reset_health_if_expectation_changed(key)
        |> emit_transition(
          :desired_state_changed,
          %{
            node_id: node_id,
            unit: unit,
            from_sources: previous[unit].sources,
            to_sources: current[unit].sources,
            from_probes: previous[unit].required_probes,
            to_probes: current[unit].required_probes
          },
          correlation_id
        )
      end)

    %{state | expectations: Map.put(state.expectations, node_id, current)}
  end

  defp put_retired(state, key, expectation, correlation_id) do
    health =
      state.health
      |> Map.get(key, %{state: :unknown})
      |> Map.merge(%{state: :retired, lifecycle: :retired, retired_at: now(state)})

    %{
      state
      | retired:
          Map.put(state.retired, key, %{
            expectation: expectation,
            retired_at: now(state),
            correlation_id: correlation_id
          }),
        health: Map.put(state.health, key, health)
    }
  end

  defp clear_retired(state, key), do: %{state | retired: Map.delete(state.retired, key)}

  defp reset_health(state, key),
    do: %{state | health: Map.put(state.health, key, initial_health())}

  defp reset_health_if_expectation_changed(state, key), do: reset_health(state, key)

  defp initial_health do
    %{
      state: :unknown,
      candidate_state: nil,
      candidate_count: 0,
      consecutive_observations: 0,
      last_observed_at: nil,
      last_correlation_id: nil,
      reason: nil,
      lifecycle: :active
    }
  end

  defp desired_state_view(state) do
    node_ids =
      state.expectations
      |> Map.keys()
      |> Kernel.++(Enum.map(state.retired, fn {{node_id, _unit}, _value} -> node_id end))
      |> Enum.uniq()
      |> Enum.sort()

    Map.new(node_ids, fn node_id ->
      expectations =
        Map.get(state.expectations, node_id, %{}) |> Map.values() |> Enum.sort_by(& &1.unit)

      retired =
        state.retired
        |> Enum.filter(fn {{id, _unit}, _value} -> id == node_id end)
        |> Map.new(fn {{_id, unit}, value} -> {unit, value} end)

      health =
        state.health
        |> Enum.filter(fn {{id, _unit}, _value} -> id == node_id end)
        |> Map.new(fn {{_id, unit}, value} -> {unit, value} end)

      {node_id, %{expectations: expectations, health: health, retired: retired}}
    end)
  end

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

    removed_node_ids = Map.keys(state.expectations) -- MapSet.to_list(current_ids)

    state =
      Enum.reduce(removed_node_ids, state, fn node_id, acc ->
        acc.expectations
        |> Map.get(node_id, %{})
        |> Map.keys()
        |> Enum.reduce(acc, fn unit, inner ->
          expectation = inner.expectations[node_id][unit]
          correlation_id = Audit.correlation_id()

          inner
          |> put_retired({node_id, unit}, expectation, correlation_id)
          |> emit_transition(
            :desired_state_removed,
            %{node_id: node_id, unit: unit, sources: expectation.sources},
            correlation_id
          )
        end)
      end)

    %{
      state
      | discovery_cache: Map.filter(state.discovery_cache, keep),
        observations: Map.filter(state.observations, keep),
        expectations: Map.filter(state.expectations, keep),
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
        |> Enum.flat_map(&Map.get(&1, :probes, []))
        |> Enum.filter(&probe_url?/1)
        |> Enum.uniq()
        |> Enum.map(&%{"url" => &1})
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

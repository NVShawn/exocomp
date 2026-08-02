# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Incidents.HealthReducer do
  @moduledoc """
  Deterministically reduces health observations into incident transitions.

  Health observations are deliberately reduced before they reach the incident
  store.  A degraded observation is only actionable after two consecutive
  observations for the same incident fingerprint.  Stale, unreachable,
  security/control-plane failures, critical Ceph health, explicit alerts, and
  coverage failures are immediate.  Healthy observations use the same
  hysteresis in reverse and resolve a health-derived incident after two
  consecutive healthy observations.

  The reducer has no model or inference dependency.  `reduce/3` is pure and
  returns actions; `process/4` is the optional persistence boundary that sends
  those actions to `Exocomp.MissionControl.Incidents`.
  """

  alias Exocomp.MissionControl.Incidents
  alias Exocomp.MissionControl.Incidents.Fingerprint

  @degraded_threshold 2
  @healthy_threshold 2
  @failure_categories ~w(identity authentication audit policy remediation)a
  @health_states [:healthy, :degraded, :unhealthy, :stale, :unreachable, :unknown]
  @actions [:open, :update, :resolve]

  defstruct targets: %{},
            processed_observations: %{},
            transitions: [],
            last_observation: nil,
            now_fn: &DateTime.utc_now/0

  @type target_key :: {
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        }

  @type t :: %__MODULE__{
          targets: %{optional(target_key()) => map()},
          processed_observations: %{optional(String.t()) => String.t()},
          transitions: [map()],
          last_observation: map() | nil,
          now_fn: (-> DateTime.t())
        }

  @type result :: :duplicate | [map()]

  @doc "Creates an empty reducer state. `:now_fn` is injectable for tests."
  @spec new(keyword()) :: t()
  def new(opts \\ []) when is_list(opts) do
    %__MODULE__{now_fn: Keyword.get(opts, :now_fn, &DateTime.utc_now/0)}
  end

  @doc "Compatibility alias for callers that name the state a store."
  @spec new_store(keyword()) :: t()
  def new_store(opts \\ []), do: new(opts)

  @doc "Returns the deterministic severity mapping used by incident actions."
  @spec severity(term()) :: :critical | :warning | :info
  def severity(value) do
    case token(value) do
      value when value in ["critical", "crit", "error", "err", "fatal", "health_err"] ->
        :critical

      value when value in ["warning", "warn", "degraded", "unhealthy", "health_warn"] ->
        :warning

      value when value in ["info", "notice", "healthy", "ok", "health_ok"] ->
        :info

      _ ->
        :warning
    end
  end

  @doc "Returns the reducer's supported health states."
  @spec health_states() :: [atom()]
  def health_states, do: @health_states

  @doc "Returns the reducer's two-observation thresholds."
  @spec thresholds() :: %{degraded: pos_integer(), healthy: pos_integer()}
  def thresholds, do: %{degraded: @degraded_threshold, healthy: @healthy_threshold}

  @doc """
  Applies one observation without performing I/O.

  The third return value is `:duplicate` for an idempotent duplicate, or a
  list of deterministic actions.  An empty list means that an observation is
  being retained as hysteresis evidence but has not crossed a transition.
  """
  @spec reduce(t(), map(), keyword()) :: {:ok, t(), result()} | {:error, term()}
  def reduce(state, observation, opts \\ [])

  def reduce(%__MODULE__{} = state, observation, opts)
      when is_map(observation) and is_list(opts) do
    with {:ok, normalized} <- normalize(observation, state),
         :ok <- check_duplicate(state, normalized) do
      digest = digest(normalized)

      case Map.fetch(state.processed_observations, normalized.observation_id) do
        {:ok, ^digest} ->
          {:ok, state, :duplicate}

        :error ->
          state =
            state
            |> put_processed(normalized.observation_id, digest)
            |> Map.put(:last_observation, normalized)

          {state, actions} = transition(state, normalized, opts)
          {:ok, state, actions}
      end
    end
  end

  @spec reduce(map(), t(), keyword()) :: {:ok, t(), result()} | {:error, term()}
  def reduce(observation, %__MODULE__{} = state, opts) when is_map(observation) do
    reduce(state, observation, opts)
  end

  @doc "Applies one observation using the common `apply_event` name."
  @spec apply_event(t(), map(), keyword()) :: {:ok, t(), result()} | {:error, term()}
  def apply_event(state, observation, opts \\ []), do: reduce(state, observation, opts)

  @doc """
  Applies actions to an incident store after reducing them.

  Persistence is intentionally kept at this boundary.  The reducer itself
  remains deterministic and can be used by replay and table-driven tests.
  """
  @spec process(t(), map(), GenServer.server(), keyword()) ::
          {:ok, t(), result()} | {:error, term()}
  def process(state, observation, server, opts \\ [])

  def process(%__MODULE__{} = state, observation, server, opts)
      when is_map(observation) and is_list(opts) do
    with {:ok, candidate, result} <- reduce(state, observation, opts),
         {:ok, candidate, result} <-
           promote_existing_incident(candidate, result, server),
         {:ok, persisted, candidate} <- persist(result, candidate, server) do
      {:ok, candidate, persisted}
    end
  end

  @spec process(map(), t(), GenServer.server(), keyword()) ::
          {:ok, t(), result()} | {:error, term()}
  def process(observation, %__MODULE__{} = state, server, opts)
      when is_map(observation) do
    process(state, observation, server, opts)
  end

  @doc "Returns transitions in occurrence order."
  @spec transitions(t()) :: [map()]
  def transitions(%__MODULE__{transitions: transitions}), do: Enum.reverse(transitions)

  @doc "Returns the per-fingerprint hysteresis state."
  @spec target_state(t(), target_key()) :: map() | nil
  def target_state(%__MODULE__{targets: targets}, key), do: Map.get(targets, key)

  defp transition(state, %{event_kind: kind} = observation, opts)
       when kind in [:desired_state_removed, :resolved, :alert_resolved] do
    keys = matching_keys(state, observation)

    {state, actions} =
      Enum.reduce(keys, {state, []}, fn key, {state, actions} ->
        target = state.targets[key]

        if target.incident_state == :open do
          action = action(:resolve, key, observation, target, "explicit resolution", opts)

          {put_target(state, key, %{target | incident_state: :resolved, healthy_count: 0}),
           [action | actions]}
        else
          {state, actions}
        end
      end)

    {record_transitions(state, Enum.reverse(actions)), Enum.reverse(actions)}
  end

  defp transition(state, %{explicit?: true} = observation, opts) do
    transition_immediate(state, observation, opts)
  end

  defp transition(state, %{immediate?: true} = observation, opts) do
    transition_immediate(state, observation, opts)
  end

  defp transition(state, %{health: :unhealthy} = observation, opts) do
    key = observation.key
    target = Map.get(state.targets, key, initial_target(observation))
    consecutive = next_count(target, :unhealthy)

    target = %{
      target
      | unhealthy_count: consecutive,
        healthy_count: 0,
        last_observed_state: :unhealthy,
        last_observed_at: observation.occurred_at,
        last_observation_id: observation.observation_id,
        severity: observation.severity,
        health_derived?: observation.health_derived?
    }

    {target, action} =
      cond do
        target.incident_state == :resolved ->
          {%{target | incident_state: :open},
           action(:update, key, observation, target, "recurrence", opts)}

        target.incident_state == :open ->
          {target, action(:update, key, observation, target, "continued unhealthy health", opts)}

        consecutive >= @degraded_threshold ->
          {%{target | incident_state: :open},
           action(:open, key, observation, target, "health threshold", opts)}

        true ->
          {target, nil}
      end

    state = put_target(state, key, target)
    finish_transition(state, action)
  end

  defp transition(state, %{health: :healthy} = observation, opts) do
    key = observation.key
    target = Map.get(state.targets, key, initial_target(observation))
    consecutive = next_count(target, :healthy)

    target = %{
      target
      | unhealthy_count: 0,
        healthy_count: consecutive,
        last_observed_state: :healthy,
        last_observed_at: observation.occurred_at,
        last_observation_id: observation.observation_id
    }

    {target, action} =
      if target.incident_state == :open and target.health_derived? and
           consecutive >= @healthy_threshold do
        {%{target | incident_state: :resolved},
         action(:resolve, key, observation, target, "healthy threshold", opts)}
      else
        {target, nil}
      end

    state = put_target(state, key, target)
    finish_transition(state, action)
  end

  defp transition(state, _observation, _opts), do: {state, []}

  defp transition_immediate(state, observation, opts) do
    key = observation.key
    target = Map.get(state.targets, key, initial_target(observation))
    event = if target.incident_state == :open, do: :update, else: :open

    target = %{
      target
      | incident_state: :open,
        unhealthy_count: 0,
        healthy_count: 0,
        last_observed_state: observation.health,
        last_observed_at: observation.occurred_at,
        last_observation_id: observation.observation_id,
        severity: observation.severity,
        health_derived?: observation.health_derived?
    }

    state = put_target(state, key, target)
    finish_transition(state, action(event, key, observation, target, "immediate evidence", opts))
  end

  defp finish_transition(state, nil), do: {record_transitions(state, []), []}
  defp finish_transition(state, action), do: {record_transitions(state, [action]), [action]}

  defp action(type, key, observation, target, trigger, _opts) when type in @actions do
    evidence = evidence(observation, type, trigger)

    %{
      action: type,
      event_type: event_type(type),
      fingerprint: Fingerprint.build(evidence),
      key: key,
      severity: observation.severity,
      trigger: trigger,
      health_derived?: target.health_derived?,
      evidence: evidence
    }
  end

  defp event_type(:open), do: :opened
  defp event_type(:update), do: :updated
  defp event_type(:resolve), do: :resolved

  defp evidence(observation, action, trigger) do
    payload =
      observation.payload
      |> Map.merge(%{
        "observation_id" => observation.observation_id,
        "health_state" => Atom.to_string(observation.health),
        "severity" => Atom.to_string(observation.severity),
        "transition" => Atom.to_string(action),
        "trigger" => trigger
      })

    %{
      organization_id: observation.organization_id,
      cluster_id: observation.cluster_id,
      alert_type: observation.alert_type,
      source: observation.source,
      target_type: observation.target_type,
      target_identity: observation.target_identity,
      occurred_at: observation.occurred_at,
      correlation_id: observation.correlation_id,
      severity: observation.severity,
      health_derived?: observation.health_derived?,
      payload: payload
    }
  end

  defp persist(:duplicate, state, _server), do: {:ok, [], state}

  defp persist(actions, state, server) when is_list(actions) do
    Enum.reduce_while(actions, {:ok, [], state}, fn action, {:ok, persisted, state} ->
      evidence = Map.put(action.evidence, :event_type, action.event_type)

      case Incidents.record(evidence, server) do
        {:ok, incident} ->
          target = state.targets[action.key]
          target = Map.merge(target, %{incident_id: incident.id, incident_state: incident.state})
          state = put_target(state, action.key, target)
          action = Map.put(action, :incident, incident)
          {:cont, {:ok, [action | persisted], state}}

        {:error, reason} ->
          {:halt, {:error, {:incident_store, reason}}}
      end
    end)
    |> case do
      {:ok, persisted, state} -> {:ok, Enum.reverse(persisted), state}
      error -> error
    end
  end

  defp promote_existing_incident(state, :duplicate, _server), do: {:ok, state, :duplicate}

  defp promote_existing_incident(state, actions, _server) when actions != [],
    do: {:ok, state, actions}

  defp promote_existing_incident(%{last_observation: nil} = state, [], _server),
    do: {:ok, state, []}

  defp promote_existing_incident(state, [], server) do
    observation = state.last_observation

    if observation.health == :unhealthy do
      evidence = evidence(observation, :update, "recurrence")

      case Incidents.get_by_fingerprint(
             observation.organization_id,
             Fingerprint.build(evidence),
             server
           ) do
        {:ok, %{state: incident_state}}
        when incident_state in [:open, :acknowledged, :resolved] ->
          key = observation.key
          target = Map.get(state.targets, key, initial_target(observation))
          target = %{target | incident_state: :open, health_derived?: true}
          action = action(:update, key, observation, target, "recurrence", [])
          state = put_target(state, key, target)
          {:ok, record_transitions(state, [action]), [action]}

        _ ->
          {:ok, state, []}
      end
    else
      {:ok, state, []}
    end
  end

  defp matching_keys(state, observation) do
    exact = observation.key

    keys =
      state.targets
      |> Map.keys()
      |> Enum.filter(fn {org, cluster, alert_type, source, target_type, target_identity} ->
        org == observation.organization_id and cluster == observation.cluster_id and
          target_type == observation.target_type and
          target_identity == observation.target_identity and
          optional_match?(observation.alert_type, alert_type) and
          optional_match?(observation.source, source)
      end)

    case keys do
      [] -> if Map.has_key?(state.targets, exact), do: [exact], else: []
      keys -> Enum.sort(keys)
    end
  end

  defp optional_match?(nil, _value), do: true
  defp optional_match?(value, value), do: true
  defp optional_match?(_left, _right), do: false

  defp initial_target(observation) do
    %{
      incident_state: :none,
      incident_id: nil,
      unhealthy_count: 0,
      healthy_count: 0,
      last_observed_state: nil,
      last_observed_at: nil,
      last_observation_id: nil,
      severity: observation.severity,
      health_derived?: observation.health_derived?
    }
  end

  defp next_count(target, :unhealthy),
    do: if(target.last_observed_state == :unhealthy, do: target.unhealthy_count + 1, else: 1)

  defp next_count(target, :healthy),
    do: if(target.last_observed_state == :healthy, do: target.healthy_count + 1, else: 1)

  defp put_target(state, key, target), do: %{state | targets: Map.put(state.targets, key, target)}

  defp record_transitions(state, []), do: state

  defp record_transitions(state, actions),
    do: %{state | transitions: Enum.reverse(actions) ++ state.transitions}

  defp put_processed(state, observation_id, digest),
    do: %{
      state
      | processed_observations: Map.put(state.processed_observations, observation_id, digest)
    }

  defp check_duplicate(state, observation) do
    case Map.fetch(state.processed_observations, observation.observation_id) do
      :error ->
        :ok

      {:ok, digest} ->
        if digest == digest(observation), do: :ok, else: {:error, :observation_id_conflict}
    end
  end

  defp normalize(observation, state) do
    input = merge_payload(observation)

    with {:ok, organization_id} <- required_string(input, :organization_id),
         {:ok, cluster_id} <- required_string(input, :cluster_id),
         {:ok, occurred_at} <- timestamp(fetch(input, :occurred_at, state.now_fn.())) do
      kind = normalize_kind(fetch(input, :kind, fetch(input, :event_type, nil)))
      target_type = target_type(input, kind)
      target_identity = target_identity(input, target_type, cluster_id)
      source = source(input, kind)
      alert_type = alert_type(input, kind, source, target_type)
      health = health_state(input)
      explicit? = explicit_alert?(kind, input)
      resolved? = kind in [:desired_state_removed, :resolved, :alert_resolved]
      immediate? = immediate?(input, kind, health, explicit?)
      severity = severity_for(input, health, immediate?)
      observation_id = observation_id(input)

      normalized = %{
        organization_id: organization_id,
        cluster_id: cluster_id,
        target_type: target_type,
        target_identity: target_identity,
        source: source,
        alert_type: alert_type,
        occurred_at: occurred_at,
        correlation_id: string_or_default(fetch(input, :correlation_id), observation_id),
        observation_id: observation_id,
        event_kind: if(resolved?, do: kind, else: kind),
        health: health,
        severity: severity,
        explicit?: explicit?,
        immediate?: immediate?,
        health_derived?: not explicit? and not resolved?,
        payload: payload(observation)
      }

      {:ok, Map.put(normalized, :key, target_key(normalized))}
    end
  end

  defp required_string(map, key) do
    case fetch(map, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, {:invalid_observation, key}}
    end
  end

  defp timestamp(%DateTime{} = value), do: {:ok, value}

  defp timestamp(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, parsed, _offset} -> {:ok, parsed}
      _ -> {:error, {:invalid_observation, :occurred_at}}
    end
  end

  defp timestamp(_value), do: {:error, {:invalid_observation, :occurred_at}}

  defp observation_id(observation) do
    case fetch(observation, :observation_id, fetch(observation, :event_id, nil)) do
      value when is_binary(value) and byte_size(value) > 0 -> value
      _ -> "obs_" <> digest(observation)
    end
  end

  defp target_type(observation, kind) do
    case fetch(observation, :target_type) do
      value when is_atom(value) ->
        Atom.to_string(value)

      value when is_binary(value) and byte_size(value) > 0 ->
        value

      _ ->
        cond do
          fetch(observation, :unit) || fetch(observation, :service) -> "service"
          fetch(observation, :node_id) -> "node"
          kind in [:alert_opened, :alert_updated, :alert_resolved] -> "cluster"
          true -> "cluster"
        end
    end
  end

  defp target_identity(observation, "service", _cluster_id),
    do:
      string_or_default(
        fetch(
          observation,
          :target_identity,
          fetch(observation, :unit, fetch(observation, :service))
        ),
        "service"
      )

  defp target_identity(observation, "node", cluster_id),
    do:
      string_or_default(
        fetch(observation, :target_identity, fetch(observation, :node_id)),
        cluster_id
      )

  defp target_identity(observation, _target_type, cluster_id),
    do: string_or_default(fetch(observation, :target_identity), cluster_id)

  defp source(observation, kind) do
    value = fetch(observation, :source)

    string_or_default(
      value,
      cond do
        kind in [:alert_opened, :alert_updated, :alert_resolved] ->
          "cluster"

        fetch(observation, :unit) || fetch(observation, :service) ->
          "systemd"

        fetch(observation, :profile) || fetch(observation, :coverage) ->
          "cluster_profile"

        String.starts_with?(token(fetch(observation, :status)), "health_") or
            String.starts_with?(token(health_status(fetch(observation, :health))), "health_") ->
          "ceph"

        true ->
          "health"
      end
    )
  end

  defp alert_type(observation, kind, source, target_type) do
    case fetch(observation, :alert_type, fetch(observation, :alert_name, nil)) do
      value when is_binary(value) and byte_size(value) > 0 ->
        value

      value when is_atom(value) ->
        Atom.to_string(value)

      _ ->
        cond do
          coverage_failure?(observation) -> "profile.coverage"
          kind in [:alert_opened, :alert_updated, :alert_resolved] -> "cluster.alert"
          failure_category(observation) != nil -> "#{failure_category(observation)}.failure"
          health_state(observation) == :stale -> "health.stale"
          health_state(observation) == :unreachable -> "health.unreachable"
          target_type == "service" -> "service.health"
          source == "ceph" -> "ceph.health"
          true -> "health.degraded"
        end
    end
  end

  defp normalize_kind(value) do
    case token(value) do
      "alert.opened" -> :alert_opened
      "alert_opened" -> :alert_opened
      "alert.updated" -> :alert_updated
      "alert_updated" -> :alert_updated
      "alert.resolved" -> :alert_resolved
      "alert_resolved" -> :alert_resolved
      "desired_state.removed" -> :desired_state_removed
      "desired_state_removed" -> :desired_state_removed
      "resolved" -> :resolved
      "resolve" -> :resolved
      _ -> :observation
    end
  end

  defp explicit_alert?(kind, observation),
    do:
      kind in [:alert_opened, :alert_updated] or
        fetch(observation, :explicit_alert, false) == true or
        fetch(observation, :explicit, false) == true

  defp immediate?(observation, kind, health, explicit?) do
    explicit? or kind in [:alert_opened, :alert_updated] or health in [:stale, :unreachable] or
      failure_category(observation) in @failure_categories or
      critical_health?(observation) or coverage_failure?(observation)
  end

  defp critical_health?(observation) do
    values = [
      fetch(observation, :severity),
      fetch(observation, :status),
      health_status(fetch(observation, :health))
    ]

    Enum.any?(values, &(token(&1) in ["critical", "crit", "error", "err", "fatal", "health_err"]))
  end

  defp coverage_failure?(observation) do
    coverage = fetch(observation, :coverage_status, fetch(observation, :coverage, nil))

    token(coverage) in ["degraded", "incomplete", "unsupported", "missing", "failed"] or
      (is_map(coverage) and
         token(fetch(coverage, :status)) in [
           "degraded",
           "incomplete",
           "unsupported",
           "missing",
           "failed"
         ])
  end

  defp severity_for(observation, health, immediate?) do
    value = fetch(observation, :severity, fetch(observation, :status, nil))

    cond do
      critical_health?(observation) -> :critical
      token(value) in ["health_warn", "warning", "warn"] -> :warning
      health == :unreachable -> :critical
      failure_category(observation) in @failure_categories -> :critical
      immediate? and health == :stale -> :warning
      health in [:healthy, :unknown] -> :info
      true -> severity(value)
    end
  end

  defp health_state(observation) do
    value =
      fetch(
        observation,
        :health_state,
        fetch(observation, :health, fetch(observation, :state, fetch(observation, :status, nil)))
      )

    value = if is_map(value), do: health_status(value), else: value
    value = if is_nil(value), do: fetch(observation, :severity), else: value

    case token(value) do
      value when value in ["healthy", "ok", "running", "active", "health_ok"] ->
        :healthy

      value
      when value in [
             "degraded",
             "unhealthy",
             "failed",
             "inactive",
             "warning",
             "warn",
             "health_warn",
             "health_err"
           ] ->
        :unhealthy

      value when value in ["stale", "expired", "timeout"] ->
        :stale

      value when value in ["unreachable", "offline", "disconnected"] ->
        :unreachable

      _ ->
        :unknown
    end
  end

  defp failure_category(observation) do
    values =
      [
        fetch(observation, :failure_type),
        fetch(observation, :failure_category),
        fetch(observation, :failure),
        fetch(observation, :category),
        fetch(observation, :error_category),
        fetch(observation, :reason),
        fetch(observation, :health_reason),
        fetch(observation, :kind),
        fetch(observation, :event_type),
        fetch(observation, :source)
      ]
      |> Enum.flat_map(fn
        value when is_list(value) -> value
        value -> [value]
      end)

    Enum.find_value(values, fn value -> failure_category_token(token(value)) end)
  end

  defp failure_category_token(value) do
    cond do
      value in [
        "identity",
        "identity_failure",
        "identity.failed",
        "identity_mismatch",
        "identity_failed"
      ] or
          String.starts_with?(value, "identity.") ->
        :identity

      value in [
        "authentication",
        "authentication_failure",
        "auth",
        "auth_failed",
        "authentication_failed"
      ] or String.starts_with?(value, "authentication.") or String.starts_with?(value, "auth.") ->
        :authentication

      value in ["audit", "audit_failure", "audit_failed", "audit_unavailable"] or
          String.starts_with?(value, "audit.") ->
        :audit

      value in ["policy", "policy_failure", "policy_failed", "policy_denied"] or
          String.starts_with?(value, "policy.") ->
        :policy

      value in ["remediation", "remediation_failure", "remediation_failed"] or
          String.starts_with?(value, "remediation.") ->
        :remediation

      true ->
        nil
    end
  end

  defp payload(observation) do
    case fetch(observation, :payload, fetch(observation, :evidence, %{})) do
      value when is_map(value) -> value
      _ -> %{}
    end
  end

  defp merge_payload(observation) do
    Map.merge(payload(observation), observation)
  end

  defp health_status(value) when is_map(value) do
    case fetch(value, :status) do
      nil -> health_status(fetch(value, :overall))
      status -> status
    end
  end

  defp health_status(value), do: value

  defp target_key(observation),
    do:
      {observation.organization_id, observation.cluster_id, observation.alert_type,
       observation.source, observation.target_type, observation.target_identity}

  defp fetch(map, key, default \\ nil) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key), default)
    end
  end

  defp token(value) when is_atom(value), do: value |> Atom.to_string() |> String.downcase()
  defp token(value) when is_binary(value), do: String.downcase(value)
  defp token(_value), do: ""

  defp string_or_default(value, _default) when is_binary(value) and byte_size(value) > 0,
    do: value

  defp string_or_default(value, _default) when is_atom(value), do: Atom.to_string(value)
  defp string_or_default(_value, default), do: default

  defp digest(value),
    do: :crypto.hash(:sha256, :erlang.term_to_binary(value)) |> Base.encode16(case: :lower)
end

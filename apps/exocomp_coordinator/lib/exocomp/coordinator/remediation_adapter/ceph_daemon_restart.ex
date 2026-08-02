# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.RemediationAdapter.CephDaemonRestart do
  @moduledoc """
  Policy adapter for one already-failed, expected Ceph daemon.

  The coordinator decides whether a restart is safe and sends a typed A2A
  profile action to the node. It never receives or executes a command, helper
  path, or shell callback. The node's installed profile-action catalog owns
  those details.
  """

  @behaviour Exocomp.Coordinator.RemediationAdapter

  alias Exocomp.ClusterProfile.Registry, as: ProfileRegistry
  alias Exocomp.Coordinator.{Collectors, ProfileCoverage, Registry}
  alias Exocomp.Coordinator.A2A.{ProfileActionClient, ProfileInspectionClient}
  alias Exocomp.Coordinator.RemediationAdapter.CephCooldown

  @action_id "restart_failed_daemon"
  @profile_id "ceph"
  @profile_version 1
  @max_evidence_age_ms 5 * 60 * 1000
  @daemon_types ~w[mon mgr osd mds radosgw]
  @default_cooldown_ms 30 * 60 * 1000
  @default_stability_window_ms 30_000
  @default_stability_poll_interval_ms 1_000

  @doc "The only action ID handled by this adapter."
  def action_id, do: @action_id

  @doc "Derives the canonical systemd target from the typed daemon identity."
  @spec target_unit(String.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def target_unit(daemon_type, daemon_id)
      when daemon_type in @daemon_types and is_binary(daemon_id) do
    instance =
      case String.split(daemon_id, ".", parts: 2) do
        [^daemon_type, value] -> value
        [value] -> value
        _ -> ""
      end

    if valid_instance?(daemon_type, instance) do
      {:ok, "ceph-#{daemon_type}@#{instance}.service"}
    else
      {:error, :invalid_daemon_identity}
    end
  end

  def target_unit(_daemon_type, _daemon_id), do: {:error, :invalid_daemon_identity}

  @impl true
  def validate_proposal(%{"action_id" => @action_id, "parameters" => params} = proposal)
      when is_map(params) do
    with {:ok, node_id} <- fetch_string(params, "node_id"),
         {:ok, daemon_id} <- fetch_string(params, "daemon_id"),
         {:ok, daemon_type} <- fetch_string(params, "daemon_type"),
         {:ok, profile_name} <- fetch_string(params, "profile_name"),
         {:ok, target_unit} <- target_unit(daemon_type, daemon_id),
         {:ok, profile_version} <- profile_version(params),
         {:ok, node} <- node_from_inventory(node_id),
         :ok <- node_supports_action(node),
         :ok <- profile_is_shipped(profile_name, profile_version) do
      if Map.get(proposal, "target_id") == daemon_id do
        validated = %{
          action_id: @action_id,
          node_id: node_id,
          daemon_id: daemon_id,
          daemon_type: daemon_type,
          profile_name: profile_name,
          profile_version: profile_version,
          target_unit: target_unit,
          evidence_refs: Map.get(proposal, "evidence_refs", [])
        }

        {:ok, copy_internal_context(validated, proposal)}
      else
        {:error, :target_mapping_mismatch}
      end
    end
  end

  def validate_proposal(%{"action_id" => @action_id}), do: {:error, :invalid_parameters}

  def validate_proposal(%{"action_id" => action_id}),
    do: {:error, {:unsupported_action, action_id}}

  def validate_proposal(_proposal), do: {:error, :malformed_proposal}

  @impl true
  def collect_evidence(
        %{
          node_id: node_id,
          daemon_id: daemon_id,
          daemon_type: daemon_type,
          target_unit: target_unit
        } = proposal
      )
      when is_binary(node_id) and is_binary(daemon_id) and is_binary(daemon_type) and
             is_binary(target_unit) do
    with {:ok, ceph} <- fresh_ceph_evidence(),
         {:ok, node_state} <- fresh_node_state(proposal.node_id),
         {:ok, evidence} <- normalize_evidence(ceph, node_state, proposal) do
      {:ok, evidence}
    else
      {:error, reason} -> {:error, {:evidence_collection_failed, reason}}
    end
  end

  def collect_evidence(_proposal), do: {:error, {:evidence_collection_failed, :invalid_proposal}}

  @impl true
  def decide(
        %{
          node_id: node_id,
          daemon_id: daemon_id,
          daemon_type: daemon_type,
          profile_name: profile_name,
          profile_version: profile_version,
          target_unit: target_unit
        } = proposal,
        evidence
      )
      when is_binary(node_id) and is_binary(daemon_id) and is_binary(daemon_type) and
             is_binary(profile_name) and is_integer(profile_version) and is_binary(target_unit) and
             is_map(evidence) do
    with :ok <- check_not_in_cooldown(proposal),
         :ok <- check_node_in_inventory(proposal.node_id),
         {:ok, node} <- node_from_inventory(proposal.node_id),
         :ok <- node_supports_action(node),
         :ok <- check_profile_supported(proposal.profile_name, proposal.profile_version),
         :ok <- check_evidence_fresh(evidence),
         :ok <- check_exact_mapping(proposal, evidence),
         :ok <- check_daemon_failed(evidence),
         :ok <- check_no_active_workload(evidence) do
      {:allow,
       %{
         action_id: @action_id,
         node_id: proposal.node_id,
         daemon_id: proposal.daemon_id,
         daemon_type: proposal.daemon_type,
         profile_name: proposal.profile_name,
         profile_version: proposal.profile_version,
         target_unit: proposal.target_unit
       }}
    else
      {:error, reason} -> {:deny, reason}
    end
  end

  def decide(_proposal, _evidence), do: {:deny, :invalid_policy_input}

  @impl true
  def execute(
        %{
          action_id: @action_id,
          node_id: node_id,
          daemon_id: _daemon_id,
          daemon_type: _daemon_type,
          profile_name: _profile_name,
          profile_version: _profile_version,
          target_unit: _target_unit
        } = action,
        _evidence,
        _approval
      )
      when is_binary(node_id) do
    client =
      Application.get_env(:exocomp_coordinator, :profile_action_client, ProfileActionClient)

    case invoke_action_client(client, action) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, {:action_dispatch_failed, reason}}
      other -> {:error, {:invalid_action_client_result, other}}
    end
  end

  def execute(_action, _evidence, _approval), do: {:error, :invalid_action}

  @impl true
  def verify(
        %{
          action_id: @action_id,
          node_id: node_id,
          daemon_id: daemon_id,
          daemon_type: _daemon_type,
          profile_name: _profile_name,
          profile_version: _profile_version,
          target_unit: target_unit
        } = action,
        pre_execution_evidence,
        result
      )
      when is_binary(node_id) do
    with {:ok, post_evidence, sample_count} <-
           verify_stability_window(action, pre_execution_evidence),
         :ok <- clear_cooldown(action) do
      {:ok,
       %{
         status: "healthy",
         daemon_id: daemon_id,
         target_unit: target_unit,
         execution: result,
         collected_at: post_evidence.collected_at,
         verification_type: "stability_window_passed",
         stability_window_ms: stability_window_ms(),
         samples: sample_count
       }}
    else
      {:error, reason} ->
        reason_atom = extract_reason_atom(reason)

        case record_cooldown(action, reason_atom) do
          {:ok, _event} ->
            {:error, {:verification_failed, reason}}

          {:error, audit_reason} ->
            {:error, {:verification_failed, {:cooldown_record_failed, audit_reason, reason}}}
        end
    end
  end

  def verify(_action, _evidence, _result), do: {:error, :invalid_action}

  # ---------------------------------------------------------------------------
  # Trusted policy gates
  # ---------------------------------------------------------------------------

  defp check_not_in_cooldown(proposal) do
    cooldown_ms =
      Application.get_env(:exocomp_coordinator, :ceph_cooldown_ms, @default_cooldown_ms)

    opts = cooldown_opts(proposal, cooldown_ms)

    case CephCooldown.cooldown_status(proposal.daemon_id, proposal.node_id, opts) do
      {:ok, true} -> {:error, :in_cooldown}
      {:ok, false} -> :ok
      {:error, _reason} -> {:error, :in_cooldown}
    end
  end

  defp verify_stability_window(action, pre_execution_evidence) do
    poll_interval_ms = stability_poll_interval_ms()

    with {:ok, evidence} <- collect_evidence(action),
         :ok <- verify_sample(action, pre_execution_evidence, evidence) do
      deadline = System.monotonic_time(:millisecond) + stability_window_ms()

      poll_stability(
        action,
        pre_execution_evidence,
        evidence,
        deadline,
        poll_interval_ms,
        1
      )
    end
  end

  defp poll_stability(action, pre, evidence, deadline, poll_interval, samples) do
    if System.monotonic_time(:millisecond) >= deadline do
      {:ok, evidence, samples}
    else
      remaining = max(deadline - System.monotonic_time(:millisecond), 0)
      Process.sleep(min(poll_interval, remaining))

      with {:ok, next_evidence} <- collect_evidence(action),
           :ok <- verify_sample(action, pre, next_evidence) do
        poll_stability(action, pre, next_evidence, deadline, poll_interval, samples + 1)
      end
    end
  end

  defp verify_sample(action, pre_execution_evidence, post_evidence) do
    with :ok <- check_exact_mapping(action, post_evidence),
         :ok <- check_topology_identity(pre_execution_evidence, post_evidence),
         :ok <- check_healthy(post_evidence),
         :ok <- check_cluster_health_not_regressed(pre_execution_evidence, post_evidence) do
      :ok
    end
  end

  defp check_topology_identity(pre_evidence, post_evidence) do
    pre_identity = topology_identity(pre_evidence)
    post_identity = topology_identity(post_evidence)

    cond do
      is_nil(pre_identity) ->
        :ok

      pre_identity == post_identity ->
        :ok

      true ->
        {:error, :topology_identity_changed}
    end
  end

  defp topology_identity(evidence) do
    topology = Map.get(evidence, :topology, Map.get(evidence, "topology", %{}))

    if is_map(topology) do
      value(topology, :fsid, "fsid") ||
        value(topology, :cluster_id, "cluster_id") ||
        value(topology, :cluster_fsid, "cluster_fsid") ||
        value(topology, :identity, "identity")
    end
  end

  defp stability_window_ms do
    configured =
      Application.get_env(
        :exocomp_coordinator,
        :ceph_stability_window_ms,
        @default_stability_window_ms
      )

    if is_integer(configured) and configured >= 0,
      do: configured,
      else: @default_stability_window_ms
  end

  defp stability_poll_interval_ms do
    configured =
      Application.get_env(
        :exocomp_coordinator,
        :ceph_stability_poll_interval_ms,
        @default_stability_poll_interval_ms
      )

    if is_integer(configured) and configured > 0,
      do: configured,
      else: @default_stability_poll_interval_ms
  end

  defp clear_cooldown(action) do
    case CephCooldown.clear_cooldown(action.daemon_id, cooldown_opts(action)) do
      :ok -> :ok
      {:error, reason} -> {:error, {:cooldown_clear_failed, reason}}
    end
  end

  defp record_cooldown(action, reason) do
    CephCooldown.record_cooldown(
      action.daemon_id,
      action.node_id,
      action.target_unit,
      reason,
      cooldown_opts(action)
    )
  end

  defp cooldown_opts(value, cooldown_ms \\ nil) do
    opts = if is_integer(cooldown_ms), do: [cooldown_ms: cooldown_ms], else: []

    case Map.get(value, :audit_server) do
      nil -> opts
      audit_server -> Keyword.put(opts, :audit_server, audit_server)
    end
    |> maybe_put_correlation_id(Map.get(value, :correlation_id))
  end

  defp maybe_put_correlation_id(opts, correlation_id)
       when is_binary(correlation_id) and byte_size(correlation_id) > 0,
       do: Keyword.put(opts, :correlation_id, correlation_id)

  defp maybe_put_correlation_id(opts, _correlation_id), do: opts

  defp copy_internal_context(validated, proposal) do
    validated
    |> maybe_copy(proposal, "_audit_server", :audit_server)
    |> maybe_copy(proposal, "_correlation_id", :correlation_id)
  end

  defp maybe_copy(map, source, source_key, target_key) do
    case Map.get(source, source_key) do
      value when not is_nil(value) -> Map.put(map, target_key, value)
      _ -> map
    end
  end

  defp check_cluster_health_not_regressed(pre_evidence, post_evidence) do
    with {:ok, pre_health} <- extract_cluster_health(pre_evidence),
         {:ok, post_health} <- extract_cluster_health(post_evidence) do
      if health_status(pre_health) == "HEALTH_UNKNOWN" or
           health_status(post_health) == "HEALTH_UNKNOWN" do
        {:error, :cluster_health_unknown}
      else
        if is_degradation?(pre_health, post_health) do
          {:error, {:cluster_health_regressed, pre_health, post_health}}
        else
          :ok
        end
      end
    else
      {:error, _} = error -> error
    end
  end

  defp extract_cluster_health(evidence) do
    health = Map.get(evidence, :ceph_health, Map.get(evidence, "ceph_health", %{}))

    if is_map(health) do
      {:ok, health}
    else
      {:error, :missing_cluster_health}
    end
  end

  defp is_degradation?(pre_health, post_health) do
    pre_status = health_status(pre_health)
    post_status = health_status(post_health)

    case {pre_status, post_status} do
      {"HEALTH_OK", "HEALTH_OK"} -> false
      {"HEALTH_OK", "HEALTH_WARN"} -> true
      {"HEALTH_OK", "HEALTH_ERR"} -> true
      {"HEALTH_WARN", "HEALTH_ERR"} -> true
      {"HEALTH_WARN", "HEALTH_OK"} -> false
      {"HEALTH_WARN", "HEALTH_WARN"} -> false
      # If it was already critical, restart failed
      {"HEALTH_ERR", _} -> true
      {_, "HEALTH_OK"} -> false
      {_, "HEALTH_WARN"} -> false
      # Unknown health statuses are not considered degradation
      _ -> false
    end
  end

  defp health_status(health) do
    case health do
      %{"overall" => %{"status" => status}} when is_binary(status) -> status
      %{"status" => status} when is_binary(status) -> status
      %{overall: %{status: status}} when is_binary(status) -> status
      %{status: status} when is_binary(status) -> status
      _ -> "HEALTH_UNKNOWN"
    end
  end

  defp check_node_in_inventory(node_id) do
    case node_from_inventory(node_id) do
      {:ok, _node} -> :ok
      {:error, _} = error -> error
    end
  end

  defp node_from_inventory(node_id) do
    registry = Application.get_env(:exocomp_coordinator, :registry, Registry)

    case Registry.get(node_id, registry) do
      {:ok, node} -> {:ok, node}
      :error -> {:error, {:node_not_found, node_id}}
    end
  end

  defp node_supports_action(node) do
    capabilities = Map.get(node, :capabilities, Map.get(node, "capabilities", []))

    if "exocomp.profile.action" in capabilities do
      :ok
    else
      {:error, :node_profile_action_unsupported}
    end
  end

  defp profile_is_shipped(profile_id, version) do
    case {profile_id, ProfileRegistry.lookup(profile_id, version)} do
      {@profile_id, {:ok, profile}} ->
        if @action_id in profile.supported_typed_actions(),
          do: :ok,
          else: {:error, {:unsupported_profile, profile_id}}

      {_other, {:ok, _profile}} ->
        {:error, {:unsupported_profile, profile_id}}

      {_profile_id, {:error, _}} ->
        {:error, {:unsupported_profile, profile_id}}
    end
  end

  defp check_profile_supported(profile_id, version) do
    coverage = Application.get_env(:exocomp_coordinator, :profile_coverage, ProfileCoverage)

    with :ok <- profile_is_shipped(profile_id, version),
         true <- ProfileCoverage.available?(profile_id, coverage) do
      :ok
    else
      false -> {:error, {:unsupported_profile, profile_id}}
      {:error, _} = error -> error
    end
  end

  defp check_evidence_fresh(evidence) do
    with {:ok, ceph_at} <- evidence_timestamp(evidence, :collected_at),
         {:ok, node_at} <- evidence_timestamp(evidence, :node_collected_at),
         :ok <- fresh_timestamp(ceph_at),
         :ok <- fresh_timestamp(node_at) do
      :ok
    else
      {:error, _} = error -> error
    end
  end

  defp fresh_timestamp(timestamp) do
    age_ms = DateTime.diff(DateTime.utc_now(), timestamp, :millisecond)

    cond do
      age_ms < 0 -> {:error, :future_evidence}
      age_ms > @max_evidence_age_ms -> {:error, {:stale_evidence, age_ms}}
      true -> :ok
    end
  end

  defp check_exact_mapping(action, evidence) do
    mapping = Map.get(evidence, :mapping, Map.get(evidence, "mapping", %{}))

    if is_map(mapping) and value(evidence, :node_id, "node_id") == action.node_id and
         value(mapping, :node_id, "node_id") == action.node_id and
         value(mapping, :daemon_id, "daemon_id") == action.daemon_id and
         value(mapping, :target_unit, "target_unit") == action.target_unit do
      :ok
    else
      {:error, :target_mapping_changed}
    end
  end

  defp check_daemon_failed(evidence) do
    case Map.get(evidence, :daemon_state, Map.get(evidence, "daemon_state")) do
      state when state in ["failed", "inactive"] -> :ok
      state when is_binary(state) -> {:error, {:daemon_not_failed, state}}
      _ -> {:error, :daemon_state_unknown}
    end
  end

  defp check_no_active_workload(evidence) do
    case Map.get(evidence, :active_pgs, Map.get(evidence, "active_pgs")) do
      0 -> :ok
      count when is_integer(count) -> {:error, {:daemon_has_active_pgs, count}}
      _ -> {:error, :active_workload_unknown}
    end
  end

  defp check_healthy(evidence) do
    case Map.get(evidence, :daemon_state, Map.get(evidence, "daemon_state")) do
      state when state in ["active", "healthy", "running"] -> :ok
      state when is_binary(state) -> {:error, {:daemon_not_healthy, state}}
      _ -> {:error, :daemon_state_unknown}
    end
  end

  # ---------------------------------------------------------------------------
  # Fresh typed evidence
  # ---------------------------------------------------------------------------

  defp fresh_ceph_evidence do
    collector =
      Application.get_env(:exocomp_coordinator, :ceph_collector, {Collectors.Ceph, :collect, []})

    result = invoke_collector(collector)

    case result do
      %{status: :ok, topology: topology, health: health, collected_at: collected_at}
      when is_map(topology) and is_map(health) and is_binary(collected_at) ->
        {:ok, result}

      %{status: status} ->
        {:error, {:ceph_evidence_unavailable, status}}

      _ ->
        {:error, :malformed_ceph_evidence}
    end
  end

  defp fresh_node_state(node_id) do
    client =
      Application.get_env(:exocomp_coordinator, :node_state_client, ProfileInspectionClient)

    result =
      case client do
        module when is_atom(module) -> module.collect(node_id, [])
        fun when is_function(fun, 1) -> fun.(node_id)
        fun when is_function(fun, 2) -> fun.(node_id, [])
        _ -> {:error, :invalid_node_state_client}
      end

    case result do
      {:ok, state} when is_map(state) -> {:ok, state}
      state when is_map(state) -> {:ok, state}
      {:error, reason} -> {:error, {:node_state_unavailable, reason}}
      _ -> {:error, :malformed_node_state}
    end
  rescue
    error -> {:error, {:node_state_client_failed, Exception.message(error)}}
  end

  defp normalize_evidence(ceph, node_state, proposal) do
    node_state = unwrap_profile_observation(node_state)
    node_collected_at = node_timestamp(node_state)

    with {:ok, _node_datetime} <- parse_timestamp(node_collected_at),
         {:ok, _} <- evidence_timestamp(%{collected_at: ceph.collected_at}, :collected_at),
         {:ok, daemon_state, active_pgs} <- daemon_observation(node_state, ceph, proposal),
         {:ok, target_unit} <- target_unit(proposal.daemon_type, proposal.daemon_id) do
      {:ok,
       %{
         collected_at: ceph.collected_at,
         node_collected_at: node_collected_at,
         source: :ceph_and_node,
         node_id: proposal.node_id,
         ceph_health: ceph.health,
         topology: ceph.topology,
         daemon_id: proposal.daemon_id,
         daemon_state: daemon_state,
         active_pgs: active_pgs,
         mapping: %{
           node_id: proposal.node_id,
           daemon_id: proposal.daemon_id,
           target_unit: target_unit
         }
       }}
    else
      {:error, _} = error -> error
    end
  end

  defp unwrap_profile_observation(%{"observations" => %{"ceph" => observation}}),
    do: observation

  defp unwrap_profile_observation(%{observations: %{ceph: observation}}), do: observation
  defp unwrap_profile_observation(state), do: state

  defp daemon_observation(node_state, ceph, proposal) do
    target = proposal.target_unit
    daemon = node_daemon(node_state, target, proposal.daemon_id)

    if is_nil(daemon) do
      {:error, :target_mapping_changed}
    else
      state =
        daemon_state_from(daemon) ||
          daemon_state_from_ceph(ceph, proposal.daemon_type, proposal.daemon_id)

      pgs = daemon_workload_from(daemon) || 0

      if is_binary(state), do: {:ok, state, pgs}, else: {:error, :daemon_state_unknown}
    end
  end

  defp node_daemon(node_state, target_unit, daemon_id) do
    node_state
    |> daemon_list()
    |> Enum.find(fn daemon ->
      value(daemon, :unit, "unit") == target_unit or
        value(daemon, :id, "id") in [daemon_id, String.replace_prefix(daemon_id, "osd.", "")]
    end)
  end

  defp daemon_list(state) do
    measurements = value(state, :measurements, "measurements") || %{}
    daemons = value(measurements, :daemons, "daemons") || value(state, :daemons, "daemons")

    case value(daemons, :value, "value") do
      list when is_list(list) -> list
      list when is_map(list) -> Map.values(list)
      _ -> []
    end
  end

  defp daemon_state_from(nil), do: nil

  defp daemon_state_from(daemon) do
    value(daemon, :active_state, "active_state") || value(daemon, :state, "state")
  end

  defp daemon_workload_from(nil), do: nil

  defp daemon_workload_from(daemon) do
    value(daemon, :active_pgs, "active_pgs") || value(daemon, :pg_count, "pg_count")
  end

  defp daemon_state_from_ceph(ceph, daemon_type, daemon_id) do
    section =
      case daemon_type do
        "osd" -> "osds"
        "mon" -> "monitors"
        "mgr" -> "managers"
        "mds" -> "mdss"
        _ -> "gateways"
      end

    data =
      get_in(ceph.topology, [section, daemon_id]) ||
        get_in(ceph.topology, [section, String.replace_prefix(daemon_id, "#{daemon_type}.", "")])

    case value(data, :state, "state") do
      "up" -> "active"
      "down" -> "failed"
      state when is_binary(state) -> String.downcase(state)
      _ -> nil
    end
  end

  defp node_timestamp(state),
    do: value(state, :observed_at, "observed_at") || value(state, :collected_at, "collected_at")

  defp evidence_timestamp(evidence, key) do
    case value(evidence, key, Atom.to_string(key)) do
      timestamp when is_binary(timestamp) -> parse_timestamp(timestamp)
      _ -> {:error, {:missing_evidence_timestamp, key}}
    end
  end

  defp parse_timestamp(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, datetime, _} -> {:ok, datetime}
      _ -> {:error, :invalid_evidence_timestamp}
    end
  end

  defp parse_timestamp(_timestamp), do: {:error, :invalid_evidence_timestamp}

  defp invoke_collector({module, function, args}) when is_atom(module),
    do: apply(module, function, args)

  defp invoke_collector(fun) when is_function(fun, 0), do: fun.()
  defp invoke_collector(_), do: %{status: :degraded}

  defp invoke_action_client(module, action) when is_atom(module),
    do: module.execute(action.node_id, action, [])

  defp invoke_action_client(fun, action) when is_function(fun, 2),
    do: fun.(action.node_id, action)

  defp invoke_action_client(fun, action) when is_function(fun, 3),
    do: fun.(action.node_id, action, [])

  defp invoke_action_client(_client, _action), do: {:error, :invalid_action_client}

  defp profile_version(params) do
    case Map.get(params, "profile_version", @profile_version) do
      version when is_integer(version) and version > 0 ->
        {:ok, version}

      version when is_binary(version) ->
        case Integer.parse(version) do
          {parsed, ""} when parsed > 0 -> {:ok, parsed}
          _ -> {:error, {:invalid_parameter, "profile_version"}}
        end

      _ ->
        {:error, {:invalid_parameter, "profile_version"}}
    end
  end

  defp fetch_string(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, {:invalid_parameter, key}}
    end
  end

  defp valid_instance?("osd", instance), do: Regex.match?(~r/\A[0-9]{1,10}\z/, instance)

  defp valid_instance?(_type, instance),
    do: Regex.match?(~r/\A[A-Za-z0-9][A-Za-z0-9_.-]{0,127}\z/, instance)

  defp value(map, atom_key, string_key) when is_map(map),
    do: Map.get(map, atom_key) || Map.get(map, string_key)

  defp value(_map, _atom_key, _string_key), do: nil

  defp extract_reason_atom({reason, _detail}), do: reason
  defp extract_reason_atom(reason) when is_atom(reason), do: reason
  defp extract_reason_atom(_other), do: :verification_failed
end

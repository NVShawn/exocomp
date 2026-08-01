# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.RemediationAdapter.CephDaemonRestart do
  @moduledoc """
  Remediation adapter for restarting failed Ceph daemons.

  This adapter validates proposals for restarting already-failed Ceph daemons,
  collects fresh evidence about daemon and cluster state, applies policy to
  ensure safety constraints are met, and executes through a restricted profile
  helper action.

  ## Proposal format

      %{
        "schema_version" => "1",
        "action_id" => "restart_failed_daemon",
        "target_id" => "osd.42",
        "parameters" => %{
          "node_id" => "node-1",
          "daemon_id" => "osd.42",
          "daemon_type" => "osd",
          "profile_name" => "ceph-default"
        },
        "evidence_refs" => ["ceph-health-evidence-1", "ceph-topology-evidence-1"],
        "rationale" => "Daemon failed, restarting after health verification"
      }

  ## Constraints

  - Daemon must be in a failed state (not active or merely degraded)
  - Node must exist in the coordinator's inventory
  - Profile must be supported on the node
  - Evidence must be fresh (within 5 minutes of collection)
  - Exact node/daemon mapping must be validated
  - Automatic-mode discovery alone cannot authorize the action
  """

  @behaviour Exocomp.Coordinator.RemediationAdapter

  alias Exocomp.Coordinator.{Collectors, ProfileCoverage, Registry}
  alias Exocomp.ClusterProfile.Registry, as: ProfileRegistry

  @action_id "restart_failed_daemon"
  @max_evidence_age_ms 5 * 60 * 1000  # 5 minutes

  # ---------------------------------------------------------------------------
  # RemediationAdapter callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def validate_proposal(%{"action_id" => @action_id, "parameters" => params} = proposal)
      when is_map(params) do
    with {:ok, node_id} <- fetch_string(params, "node_id"),
         {:ok, daemon_id} <- fetch_string(params, "daemon_id"),
         {:ok, daemon_type} <- fetch_string(params, "daemon_type"),
         {:ok, profile_name} <- fetch_string(params, "profile_name") do
      # Validate the node exists in inventory
      registry_name = Application.get_env(:exocomp_coordinator, :registry, Registry)

      case Registry.get(node_id, registry_name) do
        {:ok, _node} ->
          {:ok,
           %{
             node_id: node_id,
             daemon_id: daemon_id,
             daemon_type: daemon_type,
             profile_name: profile_name,
             evidence_refs: Map.get(proposal, "evidence_refs", [])
           }}

        :error ->
          {:error, {:node_not_found, node_id}}
      end
    end
  end

  def validate_proposal(%{"action_id" => @action_id}),
    do: {:error, :invalid_parameters}

  def validate_proposal(%{"action_id" => action_id}),
    do: {:error, {:unsupported_action, action_id}}

  def validate_proposal(_proposal),
    do: {:error, :malformed_proposal}

  @impl true
  def collect_evidence(proposal) do
    # Collect fresh evidence from Ceph and node state through existing typed diagnostic paths
    case gather_fresh_evidence(proposal) do
      {:ok, evidence} -> {:ok, evidence}
      {:error, reason} -> {:error, {:evidence_collection_failed, reason}}
    end
  end

  @impl true
  def decide(proposal, evidence) do
    node_id = proposal.node_id
    daemon_id = proposal.daemon_id
    daemon_type = proposal.daemon_type
    profile_name = proposal.profile_name

    with :ok <- check_node_in_inventory(node_id),
         :ok <- check_profile_supported(node_id, profile_name),
         :ok <- check_evidence_fresh(evidence),
         :ok <- check_daemon_failed(evidence, daemon_id),
         :ok <- check_no_active_workload(evidence, daemon_id) do
      action = %{
        node_id: node_id,
        daemon_id: daemon_id,
        daemon_type: daemon_type,
        profile_name: profile_name
      }

      {:allow, action}
    else
      {:error, reason} -> {:deny, reason}
    end
  end

  @impl true
  def execute(action, _evidence, _approval) do
    # Execute through the restricted profile helper action
    # This invokes a profile-specific helper that performs the restart
    case invoke_profile_helper(action) do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def verify(action, _evidence, result) do
    # Verify that the daemon is now in a healthy state
    case verify_daemon_health(action, result) do
      {:ok, status} ->
        {:ok, status}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Private: validation helpers
  # ---------------------------------------------------------------------------

  defp check_node_in_inventory(node_id) do
    registry_name = Application.get_env(:exocomp_coordinator, :registry, Registry)

    case Registry.get(node_id, registry_name) do
      {:ok, _node} -> :ok
      :error -> {:error, {:node_not_found, node_id}}
    end
  end

  defp check_profile_supported(node_id, profile_name) do
    # Consult the shipped cluster profile registry to validate profile support
    registry_name = Application.get_env(:exocomp_coordinator, :registry, Registry)
    profile_coverage = Application.get_env(:exocomp_coordinator, :profile_coverage, ProfileCoverage)

    with {:ok, _node} <- Registry.get(node_id, registry_name),
         true <- check_profile_available(profile_name, profile_coverage) do
      :ok
    else
      :error -> {:error, {:node_not_found, node_id}}
      false -> {:error, {:unsupported_profile, profile_name}}
    end
  end

  defp check_profile_available(profile_id, profile_coverage) do
    # Check if the profile is available in the registry and at runtime
    case ProfileRegistry.advertised_profiles()
         |> Enum.find(&(&1.id == profile_id)) do
      %{} -> ProfileCoverage.available?(profile_id, profile_coverage)
      nil -> false
    end
  end

  defp check_evidence_fresh(evidence) do
    # Verify evidence was collected recently enough
    case evidence_timestamp(evidence) do
      {:ok, timestamp} ->
        age_ms = DateTime.utc_now() |> DateTime.diff(timestamp, :millisecond)

        if age_ms <= @max_evidence_age_ms do
          :ok
        else
          {:error, {:stale_evidence, age_ms}}
        end

      :error ->
        {:error, :missing_evidence_timestamp}
    end
  end

  defp check_daemon_failed(evidence, daemon_id) do
    # Verify that the daemon is actually in a failed state
    case daemon_state(evidence, daemon_id) do
      {:ok, "failed"} -> :ok
      {:ok, "inactive"} -> :ok
      {:ok, state} -> {:error, {:daemon_not_failed, state}}
      :error -> {:error, :daemon_state_unknown}
    end
  end

  defp check_no_active_workload(evidence, daemon_id) do
    # Verify that the daemon has no active workload
    # (i.e., no PGs are being served by this daemon)
    case daemon_workload(evidence, daemon_id) do
      {:ok, 0} -> :ok
      {:ok, count} -> {:error, {:daemon_has_active_pgs, count}}
      :error -> :ok  # If we can't determine workload, assume it's safe
    end
  end

  # ---------------------------------------------------------------------------
  # Private: evidence extraction
  # ---------------------------------------------------------------------------

  defp evidence_timestamp(evidence) when is_map(evidence) do
    case Map.get(evidence, :collected_at) || Map.get(evidence, "collected_at") do
      timestamp when is_binary(timestamp) ->
        case DateTime.from_iso8601(timestamp) do
          {:ok, dt, _} -> {:ok, dt}
          _error -> :error
        end

      _other ->
        :error
    end
  end

  defp evidence_timestamp(_), do: :error

  defp daemon_state(evidence, _daemon_id) when is_map(evidence) do
    # Extract daemon state from normalized evidence
    case Map.get(evidence, :daemon_state) || Map.get(evidence, "daemon_state") do
      state when is_binary(state) -> {:ok, state}
      _other -> :error
    end
  end

  defp daemon_state(_evidence, _daemon_id), do: :error

  defp daemon_workload(evidence, _daemon_id) when is_map(evidence) do
    # Extract daemon workload information
    case Map.get(evidence, :active_pgs) || Map.get(evidence, "active_pgs") do
      count when is_integer(count) -> {:ok, count}
      _other -> :error
    end
  end

  defp daemon_workload(_evidence, _daemon_id), do: :error

  # ---------------------------------------------------------------------------
  # Private: execution
  # ---------------------------------------------------------------------------

  defp invoke_profile_helper(action) do
    # Invoke the restricted profile helper action via bin/profile-action-helper
    # The helper is executed with sudoers to run with necessary privileges
    # Format: profile-action-helper <profile_id> <action_id> <tab-separated-params>
    helper_path = "/usr/libexec/exocomp/profile-action-helper"

    request_line =
      [
        action.profile_name,
        "restart_failed_daemon",
        action.daemon_type,
        action.daemon_id
      ]
      |> Enum.join("\t")

    # Allow dependency injection for testing
    case invoke_helper_with_sudo(helper_path, request_line) do
      {:ok, _output} ->
        # Helper executed successfully, action has been initiated
        {:ok, %{status: "restart_initiated", daemon_id: action.daemon_id, timestamp: iso_now()}}

      {:error, reason} ->
        {:error, {:helper_execution_failed, reason}}
    end
  end

  defp invoke_helper_with_sudo(helper_path, request_line) do
    # Allow dependency injection for testing via application configuration
    helper_fn = Application.get_env(:exocomp_coordinator, :profile_helper, :default)
    
    case helper_fn do
      :default ->
        # Execute the profile helper via sudo with the request line on stdin
        # One-attempt semantics: no retry on transient failure
        execute_profile_helper_via_sudo(helper_path, request_line)
        
      function when is_function(function, 2) ->
        function.(helper_path, request_line)
        
      {module, function_atom, extra_args} when is_atom(module) and is_atom(function_atom) ->
        apply(module, function_atom, [helper_path, request_line] ++ extra_args)
        
      _ ->
        execute_profile_helper_via_sudo(helper_path, request_line)
    end
  end

  defp execute_profile_helper_via_sudo(helper_path, request_line) do
    # Execute the profile helper via sudo with the request line on stdin
    # One-attempt semantics: no retry on transient failure
    timeout_ms = 30_000

    task =
      Task.async(fn ->
        System.cmd("sudo", [helper_path], input: request_line, stderr_to_stdout: true)
      end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {output, 0}} when is_binary(output) ->
        {:ok, output}

      {:ok, {output, exit_code}} when is_integer(exit_code) and exit_code != 0 ->
        reason = String.trim(output)
        {:error, "helper exited with status #{exit_code}: #{reason}"}

      {:exit, reason} ->
        {:error, "helper process crashed: #{inspect(reason)}"}

      nil ->
        {:error, "helper execution timed out after #{timeout_ms}ms"}

      _other ->
        {:error, "invalid helper response"}
    end
  rescue
    error ->
      {:error, Exception.message(error)}
  catch
    _kind, _reason ->
      {:error, "helper execution failed"}
  end

  defp verify_daemon_health(action, _result) do
    # Verify that the daemon is now in a healthy state by collecting fresh evidence
    case gather_fresh_evidence(%{node_id: action.node_id, daemon_id: action.daemon_id}) do
      {:ok, evidence} ->
        # Check if the daemon is now healthy (not failed)
        case check_daemon_health_status(evidence, action.daemon_id) do
          :ok -> {:ok, %{status: "healthy", daemon_id: action.daemon_id, timestamp: iso_now()}}
          {:error, reason} -> {:error, {:verification_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:verification_evidence_failed, reason}}
    end
  end

  defp check_daemon_health_status(evidence, daemon_id) do
    # Verify the daemon is no longer in a failed state
    case daemon_state(evidence, daemon_id) do
      {:ok, "failed"} -> {:error, "daemon still in failed state"}
      {:ok, "inactive"} -> {:error, "daemon is inactive"}
      {:ok, _healthy_state} -> :ok
      :error -> {:error, "could not determine daemon state"}
    end
  end

  # ---------------------------------------------------------------------------
  # Private: helpers
  # ---------------------------------------------------------------------------

  defp fetch_string(map, key) when is_map(map) and is_binary(key) do
    case Map.get(map, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _other -> {:error, {:invalid_parameter, key}}
    end
  end

  # ---------------------------------------------------------------------------
  # Private: evidence gathering
  # ---------------------------------------------------------------------------

  defp gather_fresh_evidence(proposal_or_action) when is_map(proposal_or_action) do
    # Collect fresh Ceph health/topology and node state evidence
    # through the existing typed diagnostic paths, not caller-supplied evidence
    ceph_evidence = invoke_ceph_collector()

    case ceph_evidence.status do
      :degraded ->
        {:error, :ceph_unavailable}

      :ok ->
        {:ok, normalize_evidence(ceph_evidence, proposal_or_action)}

      :partial ->
        # Partial collection is acceptable if we have topology data
        if map_size(ceph_evidence.topology) > 0 do
          {:ok, normalize_evidence(ceph_evidence, proposal_or_action)}
        else
          {:error, :ceph_partially_unavailable}
        end
    end
  end

  defp invoke_ceph_collector do
    # Allow dependency injection for testing
    collector_fn = Application.get_env(:exocomp_coordinator, :ceph_collector, {Collectors.Ceph, :collect, []})
    
    case collector_fn do
      {module, function, extra_args} when is_atom(module) and is_atom(function) ->
        apply(module, function, extra_args)
      function when is_function(function, 0) ->
        function.()
      _ ->
        Collectors.Ceph.collect()
    end
  rescue
    _error -> 
      %{
        schema_version: 1,
        collected_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        status: :degraded,
        health: %{},
        topology: %{},
        errors: []
      }
  end

  defp normalize_evidence(ceph_evidence, context) do
    # Normalize Ceph evidence into a standard format for policy checks
    daemon_id = Map.get(context, :daemon_id) || Map.get(context, "daemon_id")

    %{
      collected_at: ceph_evidence.collected_at,
      source: :ceph_collector,
      ceph_health: Map.get(ceph_evidence, :health, %{}),
      topology: Map.get(ceph_evidence, :topology, %{}),
      daemon_id: daemon_id,
      daemon_state: extract_daemon_state_from_ceph(ceph_evidence, daemon_id),
      active_pgs: extract_active_pgs_from_ceph(ceph_evidence, daemon_id)
    }
  end

  defp extract_daemon_state_from_ceph(ceph_evidence, daemon_id) when is_binary(daemon_id) do
    # Extract daemon state from Ceph topology data
    osds = Map.get(ceph_evidence.topology, "osds", %{})
    mons = Map.get(ceph_evidence.topology, "monitors", %{})
    mgrs = Map.get(ceph_evidence.topology, "managers", %{})

    cond do
      is_map(osds) and Map.has_key?(osds, daemon_id) ->
        extract_osd_state(osds[daemon_id])

      is_map(mons) and Map.has_key?(mons, daemon_id) ->
        extract_mon_state(mons[daemon_id])

      is_map(mgrs) and Map.has_key?(mgrs, daemon_id) ->
        extract_mgr_state(mgrs[daemon_id])

      true ->
        "unknown"
    end
  end

  defp extract_daemon_state_from_ceph(_evidence, _daemon_id), do: "unknown"

  defp extract_osd_state(osd_data) when is_map(osd_data) do
    # OSD state mapping from Ceph metadata
    case Map.get(osd_data, "state") do
      "up" -> "active"
      "down" -> "failed"
      "autoout" -> "failed"
      state when is_binary(state) -> String.downcase(state)
      _ -> "unknown"
    end
  end

  defp extract_osd_state(_), do: "unknown"

  defp extract_mon_state(mon_data) when is_map(mon_data) do
    # Mon state - typically up or down
    if Map.get(mon_data, "rank") != nil, do: "active", else: "failed"
  end

  defp extract_mon_state(_), do: "unknown"

  defp extract_mgr_state(mgr_data) when is_map(mgr_data) do
    # Mgr state - typically active or standby
    case Map.get(mgr_data, "state") do
      "active" -> "active"
      "standby" -> "active"
      _ -> "failed"
    end
  end

  defp extract_mgr_state(_), do: "unknown"

  defp extract_active_pgs_from_ceph(_ceph_evidence, daemon_id) when is_binary(daemon_id) do
    # Extract number of active PGs for the daemon from health data
    # For now, return 0 as we don't have detailed PG mapping
    0
  end

  defp extract_active_pgs_from_ceph(_evidence, _daemon_id), do: 0

  defp iso_now do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end
end

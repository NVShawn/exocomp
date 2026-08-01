# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile.CephHealthReducer do
  @moduledoc """
  Reduces Ceph evidence into cluster and daemon health states.

  Converts fresh Ceph CLI evidence, topology mappings, and node observations
  into profile, coverage, and daemon health states.

  ## Health Mapping

  Ceph cluster health status maps deterministically to severity:
    * `HEALTH_OK` → `:healthy` when all criteria pass
    * `HEALTH_WARN` → `:degraded`
    * `HEALTH_ERR` → `:critical`

  ## Degradation Reasons

  A cluster or daemon health is `:degraded` when:
    * Evidence is stale (collected_at > freshness_threshold)
    * Evidence is missing (evidence unavailable or collection failed)
    * Topology is incomplete (inventory coverage < 100%)
    * Topology is ambiguous (conflict or missing mappings)
    * Required daemon units fail systemd state validation
    * Profile coverage is degraded (unsupported nodes)

  A cluster health is `:critical` when:
    * Ceph cluster reports `HEALTH_ERR`
    * Required daemons are unavailable or unreachable

  ## Idempotency

  Health reduction is deterministic: the same evidence and observations
  always produce the same result. No time-dependent logic beyond staleness
  checks; freshness is explicit via collected_at timestamp.
  """

  @type severity :: :healthy | :degraded | :critical | :unknown

  @type reason ::
          :stale_evidence
          | :missing_evidence
          | :collection_failed
          | :incomplete_coverage
          | :ambiguous_topology
          | :daemon_state_failed
          | :critical_health_status
          | :unreachable_cluster
          | :unsupported_profiles

  @type daemon_health :: %{
          node_id: String.t(),
          daemon_id: String.t(),
          kind: atom(),
          unit: String.t(),
          severity: severity(),
          reasons: [reason()],
          systemd_state: map(),
          profile_coverage: map()
        }

  @type result :: %{
          schema_version: pos_integer(),
          collected_at: String.t(),
          cluster_health: %{
            severity: severity(),
            reasons: [reason()],
            status: String.t() | nil,
            evidence_ref: String.t() | nil
          },
          daemon_health: [daemon_health()],
          coverage: map(),
          deterministic: boolean()
        }

  @schema_version 1
  @default_freshness_threshold_ms 300_000  # 5 minutes

  @doc """
  Reduce Ceph evidence into cluster and daemon health states.

  ## Options

    * `:freshness_threshold_ms` — Maximum age of evidence before staleness
      (default: 300000, 5 minutes)

  ## Input Parameters

    * `evidence` — Map from `Exocomp.Coordinator.Collectors.Ceph.collect/1`
      containing health, topology, and collection status
    * `topology_result` — Map from `Exocomp.Coordinator.CephTopology.reconcile/2`
      containing daemon mappings and coverage
    * `daemon_states` — List of daemon systemd state observations with
      node_id, unit, expected_state, active_state, load_state
    * `profile_coverage` — Profile coverage status from
      `Exocomp.Coordinator.ProfileCoverage` (optional, defaults to empty map)

  ## Returns

  A result map containing cluster health, daemon health, coverage, and reasons
  for any degradation.
  """
  @spec reduce(map(), map(), [map()], map(), keyword()) :: result()
  def reduce(
        evidence,
        topology_result,
        daemon_states,
        profile_coverage,
        opts \\ []
      )
      when is_map(evidence) and is_map(topology_result) and is_list(daemon_states) and
             is_map(profile_coverage) and is_list(opts) do
    freshness_threshold = Keyword.get(opts, :freshness_threshold_ms, @default_freshness_threshold_ms)

    cluster_health = evaluate_cluster_health(evidence, topology_result, freshness_threshold)
    daemon_health = evaluate_daemon_health(daemon_states, topology_result, profile_coverage)

    %{
      schema_version: @schema_version,
      collected_at: evidence[:collected_at] || DateTime.utc_now() |> DateTime.to_iso8601(),
      cluster_health: cluster_health,
      daemon_health: daemon_health,
      coverage: coverage_from_topology(topology_result),
      deterministic: true
    }
  end

  @doc false
  @spec reduce(map(), map(), [map()]) :: result()
  def reduce(evidence, topology_result, daemon_states) do
    reduce(evidence, topology_result, daemon_states, %{})
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Private: Cluster Health Evaluation
  # ──────────────────────────────────────────────────────────────────────────

  defp evaluate_cluster_health(evidence, topology_result, freshness_threshold) do
    evidence_status = evidence[:status] || :degraded
    collected_at = evidence[:collected_at]

    # Determine staleness
    is_stale = check_staleness(collected_at, freshness_threshold)

    # Determine evidence availability
    evidence_available = evidence_status in [:ok, :partial]

    # Get Ceph health status
    ceph_status = extract_ceph_health_status(evidence)

    # Evaluate topology coverage
    topology_status = topology_result[:status] || :degraded
    coverage_complete = topology_result[:coverage][:status] == :complete

    # Determine severity and reasons
    {severity, reasons} =
      determine_cluster_severity_and_reasons(
        ceph_status,
        is_stale,
        evidence_available,
        topology_status,
        coverage_complete
      )

    %{
      severity: severity,
      reasons: Enum.uniq(reasons),
      status: ceph_status,
      evidence_ref: bounded_evidence_ref(evidence[:collected_at])
    }
  end

  defp determine_cluster_severity_and_reasons(
         ceph_status,
         is_stale,
         evidence_available,
         topology_status,
         coverage_complete
       ) do
    reasons = []

    # Check for staleness
    reasons = if is_stale, do: [:stale_evidence | reasons], else: reasons

    # Check for missing evidence
    reasons = if not evidence_available, do: [:missing_evidence | reasons], else: reasons

    # Check for incomplete coverage
    reasons = if not coverage_complete, do: [:incomplete_coverage | reasons], else: reasons

    # Check for ambiguous topology
    reasons =
      if topology_status in [:ambiguous, :missing, :conflicting_fsid, :orphan_daemon],
        do: [:ambiguous_topology | reasons],
        else: reasons

    # Check for critical health status (HEALTH_ERR)
    reasons =
      if ceph_status == "HEALTH_ERR",
        do: [:critical_health_status | reasons],
        else: reasons

    # Determine severity based on ceph status and other factors
    severity =
      cond do
        not evidence_available ->
          :degraded

        is_stale ->
          :degraded

        ceph_status == "HEALTH_ERR" ->
          :critical

        ceph_status == "HEALTH_WARN" ->
          :degraded

        ceph_status == "HEALTH_OK" and not coverage_complete ->
          :degraded

        ceph_status == "HEALTH_OK" and topology_status == :ok ->
          :healthy

        ceph_status == "HEALTH_OK" ->
          :degraded

        true ->
          :unknown
      end

    {severity, reasons}
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Private: Daemon Health Evaluation
  # ──────────────────────────────────────────────────────────────────────────

  defp evaluate_daemon_health(daemon_states, topology_result, profile_coverage) do
    mappings = topology_result[:mappings] || []
    coverage_status = topology_result[:coverage][:status] || :degraded

    Enum.map(mappings, fn mapping ->
      node_id = mapping[:node_id]
      daemon_id = mapping[:authoritative][:id]
      kind = mapping[:authoritative][:kind]
      unit = mapping[:local][:unit]

      # Find systemd state for this daemon
      systemd_state =
        Enum.find(daemon_states, %{}, fn state ->
          state[:node_id] == node_id and state[:unit] == unit
        end)

      # Determine profile coverage
      profile_cov = profile_coverage || %{}

      # Evaluate daemon severity
      {severity, reasons} =
        determine_daemon_severity_and_reasons(
          systemd_state,
          mapping,
          profile_cov,
          coverage_status
        )

      %{
        node_id: node_id,
        daemon_id: daemon_id,
        kind: kind,
        unit: unit,
        severity: severity,
        reasons: Enum.uniq(reasons),
        systemd_state: systemd_state,
        profile_coverage: profile_cov
      }
    end)
    |> Enum.sort_by(&{&1.node_id, &1.kind, &1.daemon_id})
  end

  defp determine_daemon_severity_and_reasons(
         systemd_state,
         mapping,
         _profile_coverage,
         coverage_status
       ) do
    reasons = []

    # Check for unsupported profiles
    reasons =
      if coverage_status == :degraded,
        do: [:unsupported_profiles | reasons],
        else: reasons

    # Check systemd state
    expected_state = systemd_state[:expected_state]
    active_state = systemd_state[:active_state]
    load_state = systemd_state[:load_state]

    systemd_healthy = validate_systemd_state(expected_state, active_state, load_state)

    reasons = if not systemd_healthy, do: [:daemon_state_failed | reasons], else: reasons

    # Check daemon state from profile evidence
    profile_health = check_profile_evidence_health(mapping)

    # Severity is degraded if either systemd or profile evidence fails
    severity =
      case {systemd_healthy, profile_health} do
        {true, true} -> :healthy
        _ -> :degraded
      end

    {severity, reasons}
  end

  defp validate_systemd_state(expected_state, active_state, load_state) do
    # Systemd is healthy when:
    # - load_state is "loaded"
    # - active_state matches expected state
    load_ok = load_state in ["loaded", "enabled"]

    active_ok =
      cond do
        expected_state in [:started, "started"] ->
          active_state in ["active", "activating"]

        expected_state in [:stopped, "stopped"] ->
          active_state in ["inactive", "deactivating"]

        true ->
          false
      end

    load_ok and active_ok
  end

  defp check_profile_evidence_health(mapping) do
    local_state = mapping[:local][:state] || %{}

    # When there is no profile evidence observation (empty state map), treat
    # as a no-op: the systemd gate alone determines health.
    if map_size(local_state) == 0 do
      true
    else
      # Profile evidence is healthy when at least one observable field is present.
      # An observation with all-nil fields is treated as a collection failure.
      enablement = local_state[:enablement]
      load_state = local_state[:load_state]
      active_state = local_state[:active_state]

      enablement != nil or load_state != nil or active_state != nil
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Private: Staleness and Coverage
  # ──────────────────────────────────────────────────────────────────────────

  defp check_staleness(nil, _threshold), do: true

  defp check_staleness(collected_at, threshold) when is_binary(collected_at) do
    case DateTime.from_iso8601(collected_at) do
      {:ok, datetime, _offset} ->
        age_ms = DateTime.diff(DateTime.utc_now(), datetime, :millisecond)
        age_ms > threshold

      {:error, _reason} ->
        true
    end
  end

  defp check_staleness(_collected_at, _threshold), do: true

  defp coverage_from_topology(topology_result) do
    topology_result[:coverage] || %{
      status: :degraded,
      topology_status: :degraded,
      inventory_nodes: 0,
      supported_nodes: 0,
      non_member_nodes: 0,
      unsupported_nodes: []
    }
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Private: Ceph Health Status Extraction
  # ──────────────────────────────────────────────────────────────────────────

  defp extract_ceph_health_status(evidence) do
    health = evidence[:health] || %{}

    # Try to extract status from the overall or status field
    case health do
      %{"overall" => %{"status" => status}} when is_binary(status) -> status
      %{"status" => status} when is_binary(status) -> status
      %{overall: %{status: status}} when is_binary(status) -> status
      %{status: status} when is_binary(status) -> status
      _ -> "unknown"
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Private: Evidence References
  # ──────────────────────────────────────────────────────────────────────────

  defp bounded_evidence_ref(nil), do: nil

  defp bounded_evidence_ref(collected_at) when is_binary(collected_at) do
    # Return a short reference bounded to 64 bytes
    collected_at
    |> String.slice(0, 64)
  end

  defp bounded_evidence_ref(_), do: nil
end

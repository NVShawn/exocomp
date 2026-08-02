# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile.Ceph do
  @moduledoc """
  Ceph cluster profile shipped with every Exocomp release.

  This profile enables Exocomp coordinators to discover, query, and manage
  health state in Ceph storage clusters.  It is **read-only**: no Ceph user
  credentials are created, no Ceph commands are executed, and no cluster
  state is modified by this profile.

  ## Required Cephx capabilities

  Create a `client.exocomp` user in Ceph with the minimum read-only
  capabilities required for health monitoring:

      ceph auth get-or-create client.exocomp \\
        mon 'allow r' \\
        mgr 'allow r' \\
        osd 'allow r' \\
        mds 'allow r'

  ## Configuration

  The coordinator config must include a `cluster_profiles.ceph` section with
  absolute paths to the Ceph binary, ceph.conf, and keyring.  See
  `docs/ceph-profile-configuration.md` for the full operator guide.

  ## Runtime validation

  All configuration paths and files are validated at coordinator startup via
  `Exocomp.ClusterProfile.Ceph.Validator`.  Failures degrade profile coverage
  and emit actionable audit events — they do **not** crash the coordinator.
  """

  @behaviour Exocomp.ClusterProfile

  @id "ceph"
  @version 1

  @impl true
  def id, do: @id

  @impl true
  def version, do: @version

  @impl true
  def node_discovery_capability do
    %{
      enabled: true,
      mode: :static_inventory,
      sources: [:configured_inventory],
      dynamic_membership: false
    }
  end

  @impl true
  def expected_services(_context), do: {:ok, ["ceph-mon", "ceph-osd", "ceph-mgr"]}

  @impl true
  def health_reduction(observations) when is_list(observations) do
    statuses = Enum.map(observations, &observation_status/1)

    status =
      cond do
        :unreachable in statuses -> :unreachable
        :stale in statuses -> :stale
        :degraded in statuses -> :degraded
        statuses != [] and Enum.all?(statuses, &(&1 == :healthy)) -> :healthy
        true -> :unknown
      end

    %{status: status, observation_count: length(observations)}
  end

  def health_reduction(_observations), do: %{status: :unknown, observation_count: 0}

  @impl true
  # The typed action is exposed only through the coordinator's policy and
  # audit gates; the profile itself does not authorize a restart.
  def supported_typed_actions, do: ["diagnose_service", "restart_failed_daemon"]

  @impl true
  def redaction_metadata do
    %{
      sensitive_fields: [
        "token",
        "secret",
        "password",
        "private_key",
        "key",
        "keyring",
        "cephx_key",
        "auth_key"
      ],
      redact_nested_maps: true,
      max_value_bytes: 4_096
    }
  end

  # ── Private helpers ──────────────────────────────────────────────────────────

  defp observation_status(%{status: status})
       when status in [:healthy, :degraded, :stale, :unreachable],
       do: status

  defp observation_status(%{"status" => status})
       when status in ["healthy", "degraded", "stale", "unreachable"],
       do: String.to_existing_atom(status)

  defp observation_status(_observation), do: :unknown
end

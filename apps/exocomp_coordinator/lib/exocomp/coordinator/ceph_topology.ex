# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.CephTopology do
  @moduledoc """
  Deterministically correlates Ceph topology with inventory node discoveries.

  Ceph's coordinator-side metadata is authoritative for daemon identity and
  hostname.  A node is selected from the validated inventory by exact
  hostname first and case-normalized hostname second.  No address, certificate
  identity, or reverse-DNS result is used as a substitute for that stable
  identity.

  The reconciler is deliberately pure.  It accepts the topology returned by
  `Exocomp.Coordinator.Collectors.Ceph` and profile-inspection results from
  nodes in either their internal observation form or their serialized A2A
  artifact form.  Each result is retained, including non-members and nodes
  whose release cannot inspect the requested profile.

  A successful daemon mapping contributes a `cluster_profile` expectation to
  `Exocomp.DesiredService` with profile context `cluster:ceph`.  Local daemon
  observations never authorize recovery by themselves.
  """

  alias Exocomp.DesiredService

  @schema_version 1
  @section_kinds %{
    "monitors" => :mon,
    "mons" => :mon,
    "mon" => :mon,
    "managers" => :mgr,
    "mgrs" => :mgr,
    "mgr" => :mgr,
    "osds" => :osd,
    "osd" => :osd,
    "mdss" => :mds,
    "mds" => :mds,
    "gateways" => :gateway,
    "rgws" => :gateway,
    "radosgws" => :gateway,
    "rgw" => :gateway
  }

  @type result :: %{
          schema_version: pos_integer(),
          status: :ok | :degraded | :missing | :ambiguous | :conflicting_fsid | :orphan_daemon,
          mappings: [map()],
          nodes: [map()],
          missing: [map()],
          ambiguous: [map()],
          conflicting_fsid: [map()],
          orphan_daemons: [map()],
          desired_services: [DesiredService.t()],
          coverage: map()
        }

  @doc """
  Correlate a topology with combined inventory/discovery records.

  Each record may be an inventory node with a `discovery`, `observation`, or
  `artifact` field, or a discovery record with `node_id` and `observation`.
  Plain inventory nodes are treated as unsupported because they supplied no
  profile-inspection result.
  """
  @spec reconcile(map(), [term()]) :: result()
  def reconcile(topology, records) when is_list(records) do
    {inventory, discoveries} = split_combined_records(records)
    do_reconcile(topology, inventory, discoveries)
  end

  @doc """
  Correlate a topology with separate inventory and node discovery inputs.

  Discovery inputs may be a list keyed by `node_id`, a map keyed by node ID,
  or a list of combined records.  The optional keyword argument is reserved
  for future bounded policy settings and is accepted for API stability.
  """
  @spec reconcile(map(), [term()], term(), keyword()) :: result()
  def reconcile(topology, inventory_nodes, discoveries, opts)
      when is_list(inventory_nodes) and is_list(opts) do
    _ = opts
    do_reconcile(topology, inventory_nodes, discoveries)
  end

  @spec reconcile(map(), [term()], term()) :: result()
  def reconcile(topology, inventory_nodes, discoveries)
      when is_list(inventory_nodes) do
    do_reconcile(topology, inventory_nodes, discoveries)
  end

  @doc "Compatibility alias for callers that use correlation terminology."
  def correlate(topology, records) when is_list(records), do: reconcile(topology, records)

  def correlate(topology, inventory_nodes, discoveries) when is_list(inventory_nodes),
    do: reconcile(topology, inventory_nodes, discoveries)

  def correlate(topology, inventory_nodes, discoveries, opts) when is_list(inventory_nodes),
    do: reconcile(topology, inventory_nodes, discoveries, opts)

  @doc "Returns the profile-inspection skill selector used by this reconciler."
  def profile_selector, do: %{"profile" => "ceph", "version" => 1}

  defp do_reconcile(topology_input, inventory_input, discoveries_input) do
    topology = topology_map(topology_input)
    inventory = inventory_input |> normalize_inventory() |> sort_by_node()
    discoveries = normalize_discoveries(discoveries_input, inventory)
    authoritative = authoritative_daemons(topology)

    {topology_issues, topology_assignments} = assign_authoritative(authoritative, inventory)

    {node_results, mappings, missing, ambiguous, conflicting_fsid, orphan_daemons} =
      reconcile_nodes(
        inventory,
        discoveries,
        topology_assignments,
        topology_issues,
        topology_cluster_fsid(topology)
      )

    mappings = sort_mappings(mappings)
    desired_services = desired_services(mappings)
    missing = sort_issue_results(missing)
    ambiguous = sort_issue_results(ambiguous)
    conflicting_fsid = sort_issue_results(conflicting_fsid)
    orphan_daemons = sort_issue_results(orphan_daemons)
    unsupported_nodes = Enum.filter(node_results, &(&1.status == :unsupported))
    topology_status = topology_status(topology_input)

    %{
      schema_version: @schema_version,
      status:
        overall_status(
          missing,
          ambiguous,
          conflicting_fsid,
          orphan_daemons,
          unsupported_nodes,
          topology_status
        ),
      mappings: mappings,
      nodes: node_results,
      missing: missing,
      ambiguous: ambiguous,
      conflicting_fsid: conflicting_fsid,
      orphan_daemons: orphan_daemons,
      desired_services: desired_services,
      # `services` is kept as a convenient resolver-facing alias.  The
      # canonical field is `desired_services`.
      services: desired_services,
      coverage: %{
        status: coverage_status(unsupported_nodes, topology_status),
        topology_status: topology_status,
        inventory_nodes: length(inventory),
        supported_nodes: Enum.count(node_results, &(&1.status in [:member, :non_member])),
        non_member_nodes: Enum.count(node_results, &(&1.status == :non_member)),
        unsupported_nodes: Enum.map(unsupported_nodes, & &1.node_id)
      }
    }
  end

  defp split_combined_records(records) do
    Enum.reduce(records, {[], []}, fn record, {inventory, discoveries} ->
      normalized = normalize_node(record)

      if has_inventory_identity?(normalized) do
        {[record | inventory], [record | discoveries]}
      else
        {inventory, [record | discoveries]}
      end
    end)
    |> then(fn {inventory, discoveries} ->
      # A combined record with an inspection result is also an inventory
      # record; plain inventory records have no discovery and are preserved.
      {Enum.reverse(inventory), Enum.reverse(discoveries)}
    end)
  end

  defp normalize_inventory(nodes) when is_list(nodes) do
    nodes
    |> Enum.map(&normalize_node/1)
    |> Enum.filter(&has_inventory_identity?/1)
    |> Enum.uniq_by(fn node -> node.node_id end)
  end

  defp normalize_inventory(_nodes), do: []

  defp normalize_node(%{id: id, hostname: hostname} = node)
       when is_binary(id) and is_binary(hostname) do
    %{node_id: id, hostname: hostname, raw: node}
  end

  defp normalize_node(node) when is_map(node) do
    nested = value(node, :node, "node")
    nested = if is_map(nested), do: nested, else: %{}

    %{
      node_id:
        string_value(
          value(node, :node_id, "node_id") || value(node, :id, "id") ||
            value(nested, :id, "id")
        ),
      hostname:
        string_value(value(node, :hostname, "hostname") || value(nested, :hostname, "hostname")),
      raw: node
    }
  end

  defp normalize_node(_node), do: %{node_id: nil, hostname: nil, raw: nil}

  defp has_inventory_identity?(%{node_id: node_id, hostname: hostname}),
    do: is_binary(node_id) and is_binary(hostname) and node_id != "" and hostname != ""

  defp sort_by_node(nodes), do: Enum.sort_by(nodes, &{&1.node_id, &1.hostname})

  defp normalize_discoveries(input, inventory) when is_map(input) do
    input
    |> Enum.map(fn {node_id, discovery} ->
      normalize_discovery_record(discovery, node_id, inventory)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(&{&1.node_id || "", &1.hostname || ""})
    |> index_discoveries()
  end

  defp normalize_discoveries(input, inventory) when is_list(input) do
    input
    |> Enum.map(fn record ->
      normalized = normalize_node(record)
      node_id = normalized.node_id
      normalize_discovery_record(record, node_id, inventory)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(&{&1.node_id || "", &1.hostname || ""})
    |> index_discoveries()
  end

  defp normalize_discoveries(_input, _inventory), do: %{}

  defp index_discoveries(records) do
    Enum.reduce(records, %{}, fn record, acc ->
      if is_binary(record.node_id), do: Map.put_new(acc, record.node_id, record), else: acc
    end)
  end

  defp normalize_discovery_record(record, node_id, inventory) do
    record_map = if is_map(record), do: record, else: %{}
    node_id = node_id || string_value(value(record_map, :id, "id"))
    hostname = string_value(value(record_map, :hostname, "hostname"))
    node_id = node_id || inventory_node_id_for_hostname(hostname, inventory)
    source = discovery_source(record_map)

    case extract_discovery(source) do
      nil -> nil
      discovery -> %{node_id: node_id, hostname: hostname, discovery: discovery, raw: record}
    end
  end

  defp discovery_source(record) when is_map(record) do
    value(record, :discovery, "discovery") ||
      value(record, :observation, "observation") ||
      value(record, :artifact, "artifact") ||
      value(record, :result, "result") || record
  end

  defp discovery_source(_record), do: nil

  defp extract_discovery(nil), do: nil

  defp extract_discovery(value) when is_map(value) do
    value = unwrap_artifact(value)

    cond do
      value(value, :error, "error") != nil ->
        %{status: :unsupported, reason: value(value, :error, "error"), daemons: []}

      profile_observation = value(value, :observations, "observations") ->
        extract_discovery(value(profile_observation, :ceph, "ceph"))

      measurements = value(value, :measurements, "measurements") ->
        extract_measurements(measurements, value)

      has_discovery_fields?(value) ->
        extract_measurements(value, value)

      true ->
        nil
    end
  end

  defp extract_discovery(_value), do: nil

  defp unwrap_artifact(%{parts: parts}) when is_list(parts), do: unwrap_parts(parts)
  defp unwrap_artifact(%{"parts" => parts}) when is_list(parts), do: unwrap_parts(parts)
  defp unwrap_artifact(value), do: value

  defp unwrap_parts([part | _]) when is_map(part) do
    value(part, :data, "data") || part
  end

  defp unwrap_parts(_parts), do: %{}

  defp extract_measurements(measurements, envelope) when is_map(measurements) do
    membership = measurement_value(value(measurements, :membership, "membership"))
    daemons = measurement_value(value(measurements, :daemons, "daemons"))
    errors = measurement_value(value(measurements, :errors, "errors")) || []
    envelope_error = value(envelope, :error, "error")

    cond do
      envelope_error != nil ->
        %{status: :unsupported, reason: envelope_error, daemons: []}

      measurement_error(value(measurements, :membership, "membership")) != nil ->
        %{
          status: :unsupported,
          reason: measurement_error(value(measurements, :membership, "membership")),
          daemons: []
        }

      measurement_error(value(measurements, :daemons, "daemons")) != nil ->
        %{
          status: :unsupported,
          reason: measurement_error(value(measurements, :daemons, "daemons")),
          daemons: []
        }

      is_list(daemons) ->
        %{
          status: discovery_status(membership, daemons, errors),
          reason: nil,
          daemons: daemons,
          errors: errors
        }

      true ->
        %{status: :unsupported, reason: :malformed_discovery, daemons: []}
    end
  end

  defp extract_measurements(_measurements, _envelope),
    do: %{status: :unsupported, reason: :malformed_discovery, daemons: []}

  defp has_discovery_fields?(value),
    do:
      map_has?(value, :membership, "membership") or map_has?(value, :daemons, "daemons") or
        map_has?(value, :supported, "supported")

  defp discovery_status(membership, daemons, errors) do
    cond do
      membership in [:not_member, "not_member"] and daemons == [] and errors == [] -> :non_member
      membership in [:member, "member"] -> :member
      daemons != [] -> :member
      errors != [] -> :unsupported
      true -> :non_member
    end
  end

  defp measurement_value(%{value: value}), do: value
  defp measurement_value(%{"value" => value}), do: value
  defp measurement_value(value), do: value

  defp measurement_error(%{error: error}), do: error
  defp measurement_error(%{"error" => error}), do: error
  defp measurement_error(_value), do: nil

  defp authoritative_daemons(topology) do
    topology
    |> Enum.flat_map(fn {section, entries} ->
      case Map.get(@section_kinds, to_string(section)) do
        nil -> []
        kind -> section_daemons(kind, entries)
      end
    end)
    |> Enum.sort_by(&authoritative_sort_key/1)
  end

  defp section_daemons(kind, entries) when is_map(entries) do
    entries
    |> Enum.map(fn {key, value} -> authoritative_daemon(kind, key, value) end)
    |> Enum.reject(&is_nil/1)
  end

  defp section_daemons(kind, entries) when is_list(entries) do
    entries
    |> Enum.with_index()
    |> Enum.map(fn {value, index} -> authoritative_daemon(kind, index, value) end)
    |> Enum.reject(&is_nil/1)
  end

  defp section_daemons(_kind, _entries), do: []

  defp authoritative_daemon(kind, key, data) when is_map(data) do
    key = to_string(key)

    reported_id =
      value(data, :name, "name") || value(data, :daemon_id, "daemon_id") ||
        value(data, :id, "id") || key

    ids =
      [
        reported_id,
        value(data, :name, "name"),
        value(data, :daemon_id, "daemon_id"),
        value(data, :id, "id"),
        key
      ]
      |> Enum.map(&daemon_identity(kind, &1))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    if ids == [] do
      nil
    else
      %{
        kind: kind,
        id: hd(ids),
        ids: ids,
        hostname: string_value(value(data, :hostname, "hostname") || value(data, :host, "host")),
        fsid:
          string_value(value(data, :fsid, "fsid") || value(data, :cluster_fsid, "cluster_fsid")),
        raw: data
      }
    end
  end

  defp authoritative_daemon(_kind, _key, _data), do: nil

  defp daemon_identity(_kind, nil), do: nil

  defp daemon_identity(kind, id) do
    id = to_string(id) |> String.trim()
    prefix = Atom.to_string(kind) <> "."

    id =
      cond do
        String.starts_with?(id, prefix) ->
          String.replace_prefix(id, prefix, "")

        String.starts_with?(id, Atom.to_string(kind) <> "_") ->
          String.replace_prefix(id, Atom.to_string(kind) <> "_", "")

        true ->
          id
      end

    if id == "", do: nil, else: String.downcase(id)
  end

  defp authoritative_sort_key(daemon), do: {daemon.hostname || "", daemon.kind, daemon.id}

  defp assign_authoritative(authoritative, inventory) do
    Enum.reduce(authoritative, {[], %{}}, fn daemon, {issues, assignments} ->
      case inventory_matches(daemon.hostname, inventory) do
        {:ok, node, match_type} ->
          assignment = Map.put(daemon, :node, node) |> Map.put(:match, match_type)
          {issues, Map.update(assignments, node.node_id, [assignment], &[assignment | &1])}

        {:error, :missing, details} ->
          {[
             issue(
               :missing,
               Map.merge(details, %{
                 kind: daemon.kind,
                 daemon_id: daemon.id,
                 hostname: daemon.hostname
               })
             )
             | issues
           ], assignments}

        {:error, :ambiguous, details} ->
          {[
             issue(
               :ambiguous,
               Map.merge(details, %{
                 kind: daemon.kind,
                 daemon_id: daemon.id,
                 hostname: daemon.hostname
               })
             )
             | issues
           ], assignments}
      end
    end)
    |> then(fn {issues, assignments} ->
      {issues,
       Map.new(assignments, fn {node_id, daemons} ->
         {node_id, Enum.sort_by(daemons, &authoritative_sort_key/1)}
       end)}
    end)
  end

  defp inventory_matches(nil, _inventory), do: {:error, :missing, %{reason: :missing_hostname}}

  defp inventory_matches(hostname, inventory) do
    exact = Enum.filter(inventory, &(&1.hostname == hostname))

    cond do
      length(exact) == 1 ->
        {:ok, hd(exact), :exact}

      length(exact) > 1 ->
        {:error, :ambiguous, %{reason: :duplicate_exact_hostname}}

      true ->
        normalized = normalize_hostname(hostname)
        matches = Enum.filter(inventory, &(normalize_hostname(&1.hostname) == normalized))

        case matches do
          [node] -> {:ok, node, :case_normalized}
          [] -> {:error, :missing, %{reason: :inventory_host}}
          _ -> {:error, :ambiguous, %{reason: :duplicate_normalized_hostname}}
        end
    end
  end

  defp reconcile_nodes(inventory, discoveries, assignments, topology_issues, cluster_fsid) do
    {nodes, mappings, missing, ambiguous, conflicts, orphans, consumed} =
      Enum.reduce(inventory, {[], [], [], [], [], [], MapSet.new()}, fn node,
                                                                        {nodes, mappings, missing,
                                                                         ambiguous, conflicts,
                                                                         orphans, consumed} ->
        discovery = Map.get(discoveries, node.node_id)
        assigned = Map.get(assignments, node.node_id, [])

        case discovery && discovery.discovery do
          %{status: :unsupported} = unsupported ->
            result = %{
              node_id: node.node_id,
              hostname: node.hostname,
              status: :unsupported,
              coverage: :degraded,
              reason: unsupported.reason
            }

            {[result | nodes], mappings, missing, ambiguous, conflicts, orphans, consumed}

          %{status: :non_member} ->
            result = %{
              node_id: node.node_id,
              hostname: node.hostname,
              status: :non_member,
              coverage: :supported,
              mapping_count: 0
            }

            {[result | nodes], mappings, missing, ambiguous, conflicts, orphans, consumed}

          %{status: :member, daemons: daemons} = discovery_data ->
            {node_mappings, node_missing, node_ambiguous, node_conflicts, node_orphans,
             node_consumed} =
              reconcile_node_daemons(node, daemons, assigned, cluster_fsid)

            result = %{
              node_id: node.node_id,
              hostname: node.hostname,
              status: :member,
              coverage:
                if(Map.get(discovery_data, :errors, []) == [], do: :supported, else: :partial),
              mapping_count: length(node_mappings),
              daemon_count: length(daemons)
            }

            {[result | nodes], node_mappings ++ mappings, node_missing ++ missing,
             node_ambiguous ++ ambiguous, node_conflicts ++ conflicts, node_orphans ++ orphans,
             MapSet.union(consumed, node_consumed)}

          _ ->
            result = %{
              node_id: node.node_id,
              hostname: node.hostname,
              status: :unsupported,
              coverage: :degraded,
              reason: :profile_inspection_unavailable
            }

            {[result | nodes], mappings, missing, ambiguous, conflicts, orphans, consumed}
        end
      end)

    # An authoritative daemon that was assigned to a supported node but did
    # not appear in a local result is a missing mapping. Unsupported nodes are
    # intentionally excluded: their coverage is already explicit and we must
    # not turn an old node into a false membership failure.
    assigned_missing =
      assignments
      |> Map.values()
      |> List.flatten()
      |> Enum.reject(fn daemon ->
        MapSet.member?(consumed, daemon_key(daemon)) or
          not supported_discovery?(Map.get(discoveries, daemon.node.node_id))
      end)
      |> Enum.map(fn daemon ->
        issue(:missing, %{
          reason: :local_daemon,
          node_id: daemon.node.node_id,
          hostname: daemon.node.hostname,
          kind: daemon.kind,
          daemon_id: daemon.id
        })
      end)

    topology_missing = Enum.filter(topology_issues, &(&1.status == :missing))
    topology_ambiguous = Enum.filter(topology_issues, &(&1.status == :ambiguous))

    {Enum.sort_by(nodes, &{&1.node_id, &1.hostname}), mappings,
     missing ++ assigned_missing ++ topology_missing, topology_ambiguous ++ ambiguous, conflicts,
     orphans}
  end

  defp reconcile_node_daemons(node, local_daemons, assigned, cluster_fsid) do
    local_daemons = Enum.map(local_daemons, &normalize_local_daemon/1)
    duplicate_identities = duplicate_local_identities(local_daemons)

    Enum.reduce(local_daemons, {[], [], [], [], [], MapSet.new()}, fn local,
                                                                      {mappings, missing,
                                                                       ambiguous, conflicts,
                                                                       orphans, consumed} ->
      candidates = Enum.filter(assigned, &local_matches?(&1, local))

      cond do
        not is_binary(local.unit) ->
          {mappings, missing, ambiguous, conflicts,
           [
             issue(:orphan_daemon, %{
               node_id: node.node_id,
               hostname: node.hostname,
               reason: :invalid_unit,
               daemon: local
             })
             | orphans
           ], consumed}

        local_identity_key(local) in duplicate_identities and candidates != [] ->
          {mappings, missing,
           [
             issue(:ambiguous, %{
               node_id: node.node_id,
               hostname: node.hostname,
               reason: :duplicate_local_daemon,
               daemon: local
             })
             | ambiguous
           ], conflicts, orphans, consumed}

        candidates == [] ->
          {mappings, missing, ambiguous, conflicts,
           [
             issue(:orphan_daemon, %{
               node_id: node.node_id,
               hostname: node.hostname,
               daemon: local
             })
             | orphans
           ], consumed}

        length(candidates) > 1 ->
          {mappings, missing,
           [
             issue(:ambiguous, %{
               node_id: node.node_id,
               hostname: node.hostname,
               reason: :duplicate_daemon_match,
               daemon: local
             })
             | ambiguous
           ], conflicts, orphans, consumed}

        length(candidates) == 1 ->
          [authoritative] = candidates
          key = daemon_key(authoritative)

          case fsid_status(authoritative, local, cluster_fsid) do
            :ok ->
              mapping = %{
                node_id: node.node_id,
                hostname: node.hostname,
                match: authoritative.match,
                authoritative: authoritative,
                local: local,
                desired_service: desired_service(node, local)
              }

              {[mapping | mappings], missing, ambiguous, conflicts, orphans,
               MapSet.put(consumed, key)}

            {:conflicting, expected, actual} ->
              {mappings, missing, ambiguous,
               [
                 issue(:conflicting_fsid, %{
                   node_id: node.node_id,
                   hostname: node.hostname,
                   kind: local.kind,
                   daemon_id: local.id,
                   expected_fsid: expected,
                   actual_fsid: actual,
                   unit: local.unit
                 })
                 | conflicts
               ], orphans, MapSet.put(consumed, key)}
          end
      end
    end)
  end

  defp normalize_local_daemon(daemon) when is_map(daemon) do
    kind = value(daemon, :kind, "kind") |> normalize_kind()
    id = string_value(value(daemon, :id, "id"))

    %{
      kind: kind,
      id: id,
      identity: daemon_identity(kind, id),
      unit: string_value(value(daemon, :unit, "unit")),
      fsid: string_value(value(daemon, :fsid, "fsid")),
      state: %{
        enablement: value(daemon, :enablement, "enablement"),
        load_state: value(daemon, :load_state, "load_state"),
        active_state: value(daemon, :active_state, "active_state"),
        substate: value(daemon, :substate, "substate")
      },
      raw: daemon
    }
  end

  defp normalize_local_daemon(daemon),
    do: %{kind: nil, id: nil, identity: nil, unit: nil, fsid: nil, state: %{}, raw: daemon}

  defp local_matches?(authoritative, local),
    do:
      authoritative.kind == local.kind and local.identity != nil and
        local.identity in authoritative.ids

  defp fsid_status(authoritative, local, cluster_fsid) do
    expected = authoritative.fsid || cluster_fsid

    cond do
      authoritative.fsid != nil and cluster_fsid != nil and
          normalize_fsid(authoritative.fsid) != normalize_fsid(cluster_fsid) ->
        {:conflicting, cluster_fsid, authoritative.fsid}

      expected == nil or local.fsid == nil ->
        :ok

      normalize_fsid(expected) == normalize_fsid(local.fsid) ->
        :ok

      true ->
        {:conflicting, expected, local.fsid}
    end
  end

  defp desired_service(node, local) do
    DesiredService.cluster_profile(node.node_id, local.unit,
      required_probes: ["systemd"],
      profile_context: "cluster:ceph"
    )
  end

  defp desired_services(mappings) do
    mappings
    |> Enum.map(& &1.desired_service)
    |> DesiredService.resolve()
  end

  defp daemon_key(daemon), do: {daemon.node.node_id, daemon.kind, daemon.id}

  defp supported_discovery?(%{discovery: %{status: status}})
       when status in [:member, :non_member],
       do: true

  defp supported_discovery?(_discovery), do: false

  defp local_identity_key(%{kind: kind, identity: identity}), do: {kind, identity}

  defp duplicate_local_identities(daemons) do
    daemons
    |> Enum.group_by(&local_identity_key/1)
    |> Enum.filter(fn {{kind, identity}, values} ->
      kind != nil and identity != nil and length(values) > 1
    end)
    |> Enum.map(fn {key, _values} -> key end)
    |> MapSet.new()
  end

  defp topology_cluster_fsid(topology) do
    string_value(value(topology, :fsid, "fsid") || value(topology, :cluster_fsid, "cluster_fsid"))
  end

  defp topology_map(%{topology: topology} = input) when is_map(topology) do
    put_wrapper_fsid(topology, input)
  end

  defp topology_map(%{"topology" => topology} = input) when is_map(topology) do
    put_wrapper_fsid(topology, input)
  end

  defp topology_map(topology) when is_map(topology), do: topology
  defp topology_map(_topology), do: %{}

  defp put_wrapper_fsid(topology, input) do
    fsid = value(input, :fsid, "fsid") || value(input, :cluster_fsid, "cluster_fsid")
    if is_binary(fsid) and fsid != "", do: Map.put_new(topology, "fsid", fsid), else: topology
  end

  defp topology_status(%{status: status}) when status in [:ok, :partial, :degraded], do: status

  defp topology_status(%{"status" => status}) when status in ["ok", "partial", "degraded"],
    do: String.to_existing_atom(status)

  defp topology_status(_topology), do: :ok

  defp coverage_status(unsupported_nodes, topology_status) do
    if unsupported_nodes != [] or topology_status != :ok, do: :degraded, else: :complete
  end

  defp overall_status([], [], [], [], [], :ok), do: :ok

  defp overall_status([], [], [], [], _unsupported, topology_status) when topology_status != :ok,
    do: :degraded

  defp overall_status([], [], [], [], unsupported, :ok) when unsupported != [], do: :degraded

  defp overall_status(_missing, ambiguous, _conflicts, _orphans, _unsupported, _topology)
       when ambiguous != [],
       do: :ambiguous

  defp overall_status(_missing, _ambiguous, conflicts, _orphans, _unsupported, _topology)
       when conflicts != [],
       do: :conflicting_fsid

  defp overall_status(_missing, _ambiguous, _conflicts, orphans, _unsupported, _topology)
       when orphans != [],
       do: :orphan_daemon

  defp overall_status(missing, _ambiguous, _conflicts, _orphans, _unsupported, _topology)
       when missing != [],
       do: :missing

  defp overall_status(_missing, _ambiguous, _conflicts, _orphans, _unsupported, _topology),
    do: :degraded

  defp sort_mappings(mappings),
    do:
      Enum.sort_by(
        mappings,
        &{&1.node_id, &1.authoritative.kind, &1.authoritative.id, &1.local.unit || ""}
      )

  defp sort_issue_results(issues), do: Enum.sort_by(issues, &issue_sort_key/1)

  defp issue_sort_key(issue),
    do:
      {Map.get(issue, :node_id, ""), Map.get(issue, :hostname, ""),
       Map.get(issue, :kind, :unknown), Map.get(issue, :daemon_id, ""),
       inspect(Map.get(issue, :reason, ""))}

  defp issue(status, details), do: Map.put(details, :status, status)

  defp inventory_node_id_for_hostname(nil, _inventory), do: nil

  defp inventory_node_id_for_hostname(hostname, inventory) do
    case Enum.find(inventory, &(normalize_hostname(&1.hostname) == normalize_hostname(hostname))) do
      nil -> nil
      node -> node.node_id
    end
  end

  defp normalize_hostname(hostname) when is_binary(hostname),
    do: hostname |> String.trim() |> String.trim_trailing(".") |> String.downcase()

  defp normalize_hostname(_hostname), do: ""

  defp normalize_kind(kind) when kind in [:mon, :mgr, :osd, :mds, :gateway], do: kind
  defp normalize_kind("mon"), do: :mon
  defp normalize_kind("mgr"), do: :mgr
  defp normalize_kind("osd"), do: :osd
  defp normalize_kind("mds"), do: :mds
  defp normalize_kind(kind) when kind in ["rgw", "gateway"], do: :gateway
  defp normalize_kind(_kind), do: nil

  defp normalize_fsid(fsid), do: fsid |> to_string() |> String.downcase()

  defp value(map, atom_key, string_key) when is_map(map) do
    Map.get(map, atom_key) || Map.get(map, string_key)
  end

  defp value(_map, _atom_key, _string_key), do: nil

  defp map_has?(map, atom_key, string_key),
    do: Map.has_key?(map, atom_key) or Map.has_key?(map, string_key)

  defp string_value(value) when is_binary(value) and value != "", do: value
  defp string_value(value) when is_integer(value), do: Integer.to_string(value)
  defp string_value(_value), do: nil
end

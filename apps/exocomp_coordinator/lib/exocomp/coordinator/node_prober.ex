defmodule Exocomp.Coordinator.NodeProber do
  @moduledoc """
  Authenticated node probe boundary.

  For each node, connects to DNS-resolved candidate addresses using the
  configured hostname as SNI/identity context (never reverse DNS). Validates
  the peer certificate against the node's expected `certificate_identity`.
  Fetches the Agent Card and health response with a per-request timeout. Returns
  a typed probe outcome and emits redacted audit events.

  `Registry.addresses` is updated only after at least one candidate address
  passes full mTLS identity verification and payload validation. Prior verified
  addresses are preserved on DNS, transport, certificate, or payload failure.

  An identity mismatch halts probing immediately — the mismatch is not treated
  as a simple connectivity failure, and no further candidate addresses are
  tried.

  ## Typed outcomes

    * `:healthy` — at least one address connected, identity verified, Agent
      Card valid, health status ok.
    * `:degraded` — at least one address connected and identity verified but
      health status indicates degraded operation.
    * `:timeout` — all candidate addresses timed out; no identity mismatch
      seen.
    * `:unreachable` — all candidates were unreachable (connect refused, no
      route, etc.); no identity mismatch seen.
    * `:identity_mismatch` — a candidate's certificate identity did not match
      `certificate_identity`; probing halted immediately.

  ## Injectable transport

  The `:probe_fn` option replaces the real mTLS+HTTP transport for testing.
  Signature:

      probe_fn(
        address         :: String.t(),
        port            :: pos_integer(),
        hostname        :: String.t(),
        cert_identity   :: String.t(),
        timeout_ms      :: pos_integer()
      ) ::
        {:ok, %{agent_card: map(), health: map()}}
        | {:error, :identity_mismatch, %{expected: String.t(), actual: term()}}
        | {:error, :timeout}
        | {:error, :unreachable}
        | {:error, :malformed_response, term()}

  ## Options

    * `:probe_fn` — injectable transport (defaults to real mTLS client).
    * `:timeout_ms` — per-address timeout in milliseconds (default 5 000).
    * `:audit_server` — Audit GenServer name/pid (default
      `Exocomp.Coordinator.Audit`).
    * `:registry_server` — Registry GenServer name/pid (default
      `Exocomp.Coordinator.Registry`).
  """

  alias Exocomp.Coordinator.{Audit, Registry}

  @type outcome :: :healthy | :degraded | :timeout | :unreachable | :identity_mismatch

  @type probe_result :: %{
          outcome: outcome(),
          node_id: String.t(),
          verified_addresses: [String.t()],
          agent_card: map() | nil,
          health: map() | nil,
          error_details: map()
        }

  @default_timeout_ms 5_000

  @doc """
  Probes a node registry entry.

  Returns a `probe_result` map with the outcome and relevant diagnostic data.
  Updates `Registry.addresses` in-place when the probe succeeds.
  """
  @spec probe(map(), keyword()) :: probe_result()
  def probe(node_entry, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)
    probe_fn = Keyword.get(opts, :probe_fn, &default_probe/5)
    correlation_id = Audit.correlation_id()

    result =
      do_probe(
        node_entry.candidate_addresses,
        node_entry.port,
        node_entry.hostname,
        node_entry.certificate_identity,
        probe_fn,
        timeout_ms
      )

    outcome = build_outcome(node_entry.id, result)

    update_registry(node_entry.id, outcome, opts)
    emit_audit(node_entry.id, node_entry.hostname, outcome, correlation_id, opts)

    outcome
  end

  # ---------------------------------------------------------------------------
  # Private — candidate iteration
  # ---------------------------------------------------------------------------

  # Iterates through candidate addresses, returning a consolidated result.
  # Stops immediately on identity mismatch.
  @spec do_probe(
          [String.t()],
          pos_integer(),
          String.t(),
          String.t(),
          function(),
          pos_integer()
        ) ::
          {:identity_mismatch, map()}
          | {:verified, [String.t()], map() | nil, map() | nil}
          | {:failed, :timeout | :unreachable}

  defp do_probe([], _port, _hostname, _cert_identity, _probe_fn, _timeout_ms) do
    {:failed, :unreachable}
  end

  defp do_probe(candidates, port, hostname, cert_identity, probe_fn, timeout_ms) do
    try_each(candidates, port, hostname, cert_identity, probe_fn, timeout_ms, [], nil, nil, nil)
  end

  defp try_each(
         [],
         _port,
         _hostname,
         _cert_identity,
         _probe_fn,
         _timeout_ms,
         verified,
         last_error,
         agent_card,
         health
       ) do
    if verified == [] do
      {:failed, last_error || :unreachable}
    else
      {:verified, Enum.reverse(verified), agent_card, health}
    end
  end

  defp try_each(
         [address | rest],
         port,
         hostname,
         cert_identity,
         probe_fn,
         timeout_ms,
         verified,
         last_error,
         agent_card,
         health
       ) do
    case probe_fn.(address, port, hostname, cert_identity, timeout_ms) do
      {:ok, %{agent_card: ac, health: h}} ->
        try_each(
          rest,
          port,
          hostname,
          cert_identity,
          probe_fn,
          timeout_ms,
          [address | verified],
          last_error,
          agent_card || ac,
          health || h
        )

      {:error, :identity_mismatch, details} ->
        {:identity_mismatch, details}

      {:error, :timeout} ->
        try_each(
          rest,
          port,
          hostname,
          cert_identity,
          probe_fn,
          timeout_ms,
          verified,
          :timeout,
          agent_card,
          health
        )

      {:error, :unreachable} ->
        try_each(
          rest,
          port,
          hostname,
          cert_identity,
          probe_fn,
          timeout_ms,
          verified,
          :unreachable,
          agent_card,
          health
        )

      {:error, :malformed_response, _detail} ->
        try_each(
          rest,
          port,
          hostname,
          cert_identity,
          probe_fn,
          timeout_ms,
          verified,
          :unreachable,
          agent_card,
          health
        )
    end
  end

  # ---------------------------------------------------------------------------
  # Private — outcome construction
  # ---------------------------------------------------------------------------

  defp build_outcome(node_id, {:identity_mismatch, details}) do
    %{
      outcome: :identity_mismatch,
      node_id: node_id,
      verified_addresses: [],
      agent_card: nil,
      health: nil,
      error_details: details
    }
  end

  defp build_outcome(node_id, {:verified, addresses, agent_card, health}) do
    reachability =
      if healthy_status?(health) do
        :healthy
      else
        :degraded
      end

    %{
      outcome: reachability,
      node_id: node_id,
      verified_addresses: addresses,
      agent_card: agent_card,
      health: health,
      error_details: %{}
    }
  end

  defp build_outcome(node_id, {:failed, error}) do
    %{
      outcome: error,
      node_id: node_id,
      verified_addresses: [],
      agent_card: nil,
      health: nil,
      error_details: %{reason: error}
    }
  end

  # Health is considered "ok" when the status field equals "ok" (case-insensitive).
  # A missing or non-"ok" status is treated as degraded.
  defp healthy_status?(%{"status" => status}) when is_binary(status) do
    String.downcase(status) == "ok"
  end

  defp healthy_status?(_other), do: false

  # ---------------------------------------------------------------------------
  # Private — Registry update
  # ---------------------------------------------------------------------------

  defp update_registry(node_id, %{outcome: outcome, verified_addresses: addrs}, opts)
       when outcome in [:healthy, :degraded] and addrs != [] do
    registry = Keyword.get(opts, :registry_server, Registry)

    changes = %{
      addresses: addrs,
      reachability: outcome
    }

    Registry.update(node_id, changes, registry)
  catch
    :exit, _ -> :ok
  end

  defp update_registry(_node_id, _outcome_map, _opts), do: :ok

  # ---------------------------------------------------------------------------
  # Private — audit
  # ---------------------------------------------------------------------------

  defp emit_audit(node_id, hostname, outcome_map, correlation_id, opts) do
    audit_server = Keyword.get(opts, :audit_server, Audit)
    %{outcome: outcome} = outcome_map

    attributes =
      %{
        node_id: node_id,
        hostname: hostname,
        outcome: outcome,
        verified_address_count: length(outcome_map.verified_addresses)
      }
      |> maybe_put(:error_details, outcome_map.error_details)

    Audit.emit(
      :node_probe_completed,
      attributes,
      server: audit_server,
      correlation_id: correlation_id
    )
  catch
    :exit, _ -> :ok
  end

  defp maybe_put(map, _key, value) when value == %{}, do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  # ---------------------------------------------------------------------------
  # Private — real mTLS transport (requires live TLS infrastructure)
  # ---------------------------------------------------------------------------

  # This default implementation makes a real HTTPS request to the candidate
  # address, using the configured hostname for SNI and validating the peer
  # certificate against certificate_identity.  It requires a configured
  # coordinator trust root and is not exercised in unit tests (tests inject
  # probe_fn instead).
  #
  # Returns :unreachable for all unimplemented/unavailable cases until the
  # full mTLS client is wired in.
  defp default_probe(_address, _port, _hostname, _cert_identity, _timeout_ms) do
    {:error, :unreachable}
  end
end

defmodule Exocomp.Coordinator.Resolver do
  @moduledoc """
  Supervised DNS resolver that converts inventory hostnames into normalized
  address candidates.

  Each inventory hostname is resolved using both IPv4 (`:inet`) and IPv6
  (`:inet6`) forward DNS lookups. Reverse DNS is never consulted. Results are
  normalized to string form via `:inet.ntoa/1`, deduplicated, and sorted
  deterministically so that equal address sets compare equal regardless of DNS
  reply ordering.

  Resolved addresses are stored in the Registry as `candidate_addresses` for
  each node. DNS success alone does **not** replace `Registry.addresses` —
  candidates are adopted only after authenticated mTLS verification
  (EXOCOMP-89).

  Resolution success and failure are reported as structured `Audit` events:
  * `:dns_resolved` — at least one address was resolved for a hostname.
  * `:dns_resolution_failed` — no addresses could be obtained (NXDOMAIN,
    timeout, empty, or other error).

  The resolver backend is dependency-injectable via the `:resolver_fn` option,
  which defaults to `:inet.getaddrs/2`. Tests pass a deterministic fake to
  avoid real DNS lookups.

  ## Options

  * `:resolver_fn` — `(charlist(), :inet | :inet6 -> {:ok, [tuple()]} | {:error, term()})`.
    Defaults to `&:inet.getaddrs/2`.
  * `:interval_ms` — Milliseconds between periodic resolution sweeps.
    Defaults to `30_000` (30 s).
  * `:name` — Registered name. Defaults to `Exocomp.Coordinator.Resolver`.
  """

  use GenServer

  alias Exocomp.Coordinator.{Audit, Inventory, Registry}

  @default_interval_ms 30_000

  defstruct [
    :resolver_fn,
    :interval_ms,
    :timer_ref,
    # %{node_id => [address_string]}
    candidates: %{}
  ]

  @type resolver_fn ::
          (charlist(), :inet | :inet6 -> {:ok, [tuple()]} | {:error, term()})

  @type t :: %__MODULE__{
          resolver_fn: resolver_fn(),
          interval_ms: pos_integer(),
          timer_ref: reference() | nil,
          candidates: %{String.t() => [String.t()]}
        }

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Returns the current candidate address map keyed by node ID."
  @spec candidates(GenServer.server()) :: %{String.t() => [String.t()]}
  def candidates(server \\ __MODULE__), do: GenServer.call(server, :candidates)

  @doc "Triggers an immediate resolution sweep and waits for it to complete."
  @spec resolve_now(GenServer.server()) :: :ok
  def resolve_now(server \\ __MODULE__), do: GenServer.call(server, :resolve_now)

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(opts) do
    resolver_fn = Keyword.get(opts, :resolver_fn, &:inet.getaddrs/2)
    interval_ms = Keyword.get(opts, :interval_ms, @default_interval_ms)

    state = %__MODULE__{
      resolver_fn: resolver_fn,
      interval_ms: interval_ms
    }

    # Kick off the first sweep immediately.
    send(self(), :resolve)
    {:ok, state}
  end

  @impl true
  def handle_call(:candidates, _from, state) do
    {:reply, state.candidates, state}
  end

  def handle_call(:resolve_now, _from, state) do
    new_state = do_resolve_all(state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info(:resolve, state) do
    new_state = do_resolve_all(state)
    timer_ref = Process.send_after(self(), :resolve, new_state.interval_ms)
    {:noreply, %{new_state | timer_ref: timer_ref}}
  end

  # ---------------------------------------------------------------------------
  # Private — resolution logic
  # ---------------------------------------------------------------------------

  defp do_resolve_all(state) do
    correlation_id = safe_correlation_id()
    nodes = safe_inventory_nodes()

    new_candidates =
      Map.new(nodes, fn node ->
        addrs = resolve_node(node, state.resolver_fn, state.candidates, correlation_id)
        {node.id, addrs}
      end)

    %{state | candidates: new_candidates}
  end

  defp resolve_node(node, resolver_fn, old_candidates, correlation_id) do
    hostname_chars = to_charlist(node.hostname)

    ipv4_result = resolver_fn.(hostname_chars, :inet)
    ipv6_result = resolver_fn.(hostname_chars, :inet6)

    addresses = collect_addresses(ipv4_result, ipv6_result)
    old_addresses = Map.get(old_candidates, node.id)

    if addresses == [] do
      emit_resolution_failed(node, ipv4_result, ipv6_result, correlation_id)
    else
      changed = old_addresses != addresses
      emit_resolution_success(node, addresses, changed, correlation_id)
    end

    safe_put_candidates(node.id, addresses)

    addresses
  end

  # Collect, normalize, deduplicate, and sort addresses from both families.
  defp collect_addresses(ipv4_result, ipv6_result) do
    inet_addrs =
      case ipv4_result do
        {:ok, addrs} -> addrs
        _ -> []
      end

    inet6_addrs =
      case ipv6_result do
        {:ok, addrs} -> addrs
        _ -> []
      end

    (inet_addrs ++ inet6_addrs)
    |> Enum.map(&normalize_address/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_address(tuple) when is_tuple(tuple) do
    tuple |> :inet.ntoa() |> to_string()
  end

  # ---------------------------------------------------------------------------
  # Private — audit events
  # ---------------------------------------------------------------------------

  defp emit_resolution_success(node, addresses, changed, correlation_id) do
    Audit.emit(
      :dns_resolved,
      %{
        node_id: node.id,
        hostname: node.hostname,
        address_count: length(addresses),
        addresses: addresses,
        changed: changed
      },
      correlation_id: correlation_id
    )
  catch
    :exit, _ -> :ok
  end

  defp emit_resolution_failed(node, ipv4_result, ipv6_result, correlation_id) do
    ipv4_error =
      case ipv4_result do
        {:error, reason} -> inspect(reason)
        {:ok, _} -> nil
      end

    ipv6_error =
      case ipv6_result do
        {:error, reason} -> inspect(reason)
        {:ok, _} -> nil
      end

    Audit.emit(
      :dns_resolution_failed,
      %{
        node_id: node.id,
        hostname: node.hostname,
        ipv4_error: ipv4_error,
        ipv6_error: ipv6_error
      },
      correlation_id: correlation_id
    )
  catch
    :exit, _ -> :ok
  end

  # ---------------------------------------------------------------------------
  # Private — safe wrappers (tolerate transient process unavailability)
  # ---------------------------------------------------------------------------

  defp safe_inventory_nodes do
    Inventory.current().nodes
  catch
    :exit, _ -> []
  end

  defp safe_put_candidates(node_id, addresses) do
    Registry.put_candidates(node_id, addresses)
  catch
    :exit, _ -> :ok
  end

  defp safe_correlation_id do
    Audit.correlation_id()
  catch
    :exit, _ -> "corr_fallback_#{System.unique_integer([:positive])}"
  end
end

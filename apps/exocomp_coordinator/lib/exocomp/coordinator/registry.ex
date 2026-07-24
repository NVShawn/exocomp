defmodule Exocomp.Coordinator.Registry do
  @moduledoc """
  ETS-backed live node registry and deterministic poll state machine.

  Poll attempts receive a monotonically increasing token. A result is applied
  only while its token is still current, preventing a slow callback from
  replacing a newer observation.

  The default schedule is 30 seconds with up to 3 seconds of jitter. Failed
  authentication, timeout, and unreachable probes use exponential backoff,
  capped at 15 minutes. After a prior success, failures remain `:degraded` for
  60 seconds, become `:stale` until 5 minutes, and are then `:unreachable`.
  Nodes without a successful observation become `:unreachable` on failure.

  `:clock` and `:random` functions may be injected when starting the registry,
  allowing schedule and transition tests to run without sleeping.
  """

  use GenServer

  alias Exocomp.Coordinator.{Audit, Inventory}
  alias Exocomp.Coordinator.Inventory.Node

  @states [:unknown, :healthy, :degraded, :stale, :unreachable]
  @success_outcomes [:healthy, :degraded]
  @failure_outcomes [:timeout, :unreachable, :identity_mismatch, :authentication_failure]

  @default_poll_interval_ms 30_000
  @default_jitter_ms 3_000
  @default_backoff_cap_ms 900_000
  @default_degraded_after_ms 60_000
  @default_stale_after_ms 300_000

  @type attempt_token :: pos_integer()
  @type outcome ::
          :healthy
          | :degraded
          | :timeout
          | :unreachable
          | :identity_mismatch
          | :authentication_failure

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @spec rebuild([Node.t()], GenServer.server()) :: :ok
  def rebuild(nodes, server \\ __MODULE__), do: GenServer.call(server, {:rebuild, nodes})

  @spec all(GenServer.server()) :: [map()]
  def all(server \\ __MODULE__), do: GenServer.call(server, :all)

  @spec get(String.t(), GenServer.server()) :: {:ok, map()} | :error
  def get(node_id, server \\ __MODULE__), do: GenServer.call(server, {:get, node_id})

  @spec update(String.t(), map(), GenServer.server()) ::
          :ok | {:error, :not_found | :invalid_state}
  def update(node_id, changes, server \\ __MODULE__) when is_map(changes) do
    GenServer.call(server, {:update, node_id, changes})
  end

  @doc """
  Returns entries whose next poll time has arrived, ordered by node ID.
  """
  @spec due_nodes(GenServer.server()) :: [map()]
  def due_nodes(server \\ __MODULE__), do: GenServer.call(server, :due_nodes)

  @doc """
  Starts an eligible poll and returns its ordering token.
  """
  @spec begin_poll(String.t(), GenServer.server()) ::
          {:ok, attempt_token()} | {:error, :not_found | :not_eligible}
  def begin_poll(node_id, server \\ __MODULE__) do
    GenServer.call(server, {:begin_poll, node_id})
  end

  @doc """
  Applies a typed probe result if `token` still identifies the latest attempt.

  The result may be an outcome atom or a NodeProber result map containing an
  `:outcome` key. Successful result maps may also atomically adopt their
  `:verified_addresses`.
  """
  @spec record_observation(String.t(), attempt_token(), outcome() | map(), GenServer.server()) ::
          {:ok, map()} | {:ignored, :stale} | {:error, :not_found | :invalid_outcome}
  def record_observation(node_id, token, result, server \\ __MODULE__) do
    GenServer.call(server, {:record_observation, node_id, token, result})
  end

  @doc """
  Converts polls orphaned by a poller restart into typed failures.

  Late worker results retain their old attempt tokens and are ignored.
  """
  @spec recover_in_flight(outcome(), GenServer.server()) :: non_neg_integer()
  def recover_in_flight(outcome \\ :timeout, server \\ __MODULE__) do
    GenServer.call(server, {:recover_in_flight, outcome})
  end

  @doc """
  Stores DNS-resolved address candidates for a node.

  Candidates are kept separate from `addresses`, which are only set after
  mTLS verification. DNS success alone does not replace the live addresses.
  """
  @spec put_candidates(String.t(), [String.t()], GenServer.server()) ::
          :ok | {:error, :not_found}
  def put_candidates(node_id, candidates, server \\ __MODULE__) when is_list(candidates) do
    GenServer.call(server, {:put_candidates, node_id, candidates})
  end

  @impl true
  def init(opts) do
    state = %{
      table: new_table(),
      clock: Keyword.get(opts, :clock, &DateTime.utc_now/0),
      random: Keyword.get(opts, :random, &random_between/2),
      poll_interval_ms: positive_option(opts, :poll_interval_ms, @default_poll_interval_ms),
      jitter_ms: nonnegative_option(opts, :jitter_ms, @default_jitter_ms),
      backoff_cap_ms: positive_option(opts, :backoff_cap_ms, @default_backoff_cap_ms),
      degraded_after_ms: positive_option(opts, :degraded_after_ms, @default_degraded_after_ms),
      stale_after_ms: positive_option(opts, :stale_after_ms, @default_stale_after_ms),
      audit_server: Keyword.get(opts, :audit_server, Audit)
    }

    validate_thresholds!(state)
    send(self(), :reconstruct)
    {:ok, state}
  end

  @impl true
  def handle_call({:rebuild, nodes}, _from, state) do
    new_table = new_table()
    now = now(state)
    Enum.each(nodes, &:ets.insert(new_table, {&1.id, initial_entry(&1, now, state)}))
    :ets.delete(state.table)
    {:reply, :ok, %{state | table: new_table}}
  end

  def handle_call(:all, _from, state) do
    entries =
      state.table
      |> :ets.tab2list()
      |> Enum.map(&elem(&1, 1))
      |> Enum.map(&public_entry/1)
      |> Enum.sort_by(& &1.id)

    {:reply, entries, state}
  end

  def handle_call(:due_nodes, _from, state) do
    current = now(state)

    entries =
      state.table
      |> :ets.tab2list()
      |> Enum.map(&elem(&1, 1))
      |> Enum.filter(&due?(&1, current))
      |> Enum.map(&public_entry/1)
      |> Enum.sort_by(& &1.id)

    {:reply, entries, state}
  end

  def handle_call({:get, node_id}, _from, state) do
    reply =
      case lookup(state.table, node_id) do
        {:ok, entry} -> {:ok, public_entry(entry)}
        :error -> :error
      end

    {:reply, reply, state}
  end

  def handle_call({:update, node_id, changes}, _from, state) do
    with {:ok, entry} <- lookup(state.table, node_id),
         :ok <- valid_state(changes) do
      :ets.insert(state.table, {node_id, Map.merge(entry, changes)})
      {:reply, :ok, state}
    else
      :error -> {:reply, {:error, :not_found}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:begin_poll, node_id}, _from, state) do
    current = now(state)

    case lookup(state.table, node_id) do
      {:ok, entry} ->
        if due?(entry, current) do
          token = entry.poll_generation + 1

          updated = %{
            entry
            | poll_generation: token,
              active_poll_token: token,
              last_attempted_contact: current
          }

          :ets.insert(state.table, {node_id, updated})
          {:reply, {:ok, token}, state}
        else
          {:reply, {:error, :not_eligible}, state}
        end

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:record_observation, node_id, token, result}, _from, state) do
    case lookup(state.table, node_id) do
      {:ok, %{active_poll_token: ^token} = entry} ->
        case outcome(result) do
          outcome when outcome in @success_outcomes ->
            updated = successful_observation(entry, outcome, result, now(state), state)
            store_and_audit(entry, updated, outcome, state)
            {:reply, {:ok, public_entry(updated)}, state}

          outcome when outcome in @failure_outcomes ->
            updated = failed_observation(entry, outcome, now(state), state)
            store_and_audit(entry, updated, outcome, state)
            {:reply, {:ok, public_entry(updated)}, state}

          _other ->
            {:reply, {:error, :invalid_outcome}, state}
        end

      {:ok, _entry} ->
        {:reply, {:ignored, :stale}, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:recover_in_flight, outcome}, _from, state)
      when outcome in @failure_outcomes do
    current = now(state)

    recovered =
      state.table
      |> :ets.tab2list()
      |> Enum.map(&elem(&1, 1))
      |> Enum.filter(&(not is_nil(&1.active_poll_token)))
      |> Enum.map(fn entry ->
        updated = failed_observation(entry, outcome, current, state)
        store_and_audit(entry, updated, outcome, state)
        entry.id
      end)

    {:reply, length(recovered), state}
  end

  def handle_call({:put_candidates, node_id, candidates}, _from, state) do
    case lookup(state.table, node_id) do
      {:ok, entry} ->
        :ets.insert(state.table, {node_id, %{entry | candidate_addresses: candidates}})
        {:reply, :ok, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_info(:reconstruct, state) do
    if Process.whereis(Inventory) do
      current = now(state)
      nodes = Inventory.current().nodes
      Enum.each(nodes, &:ets.insert(state.table, {&1.id, initial_entry(&1, current, state)}))
    end

    {:noreply, state}
  end

  defp new_table, do: :ets.new(__MODULE__, [:set, :private, read_concurrency: true])

  defp initial_entry(node, current, state) do
    %{
      id: node.id,
      hostname: node.hostname,
      port: node.port,
      certificate_identity: node.certificate_identity,
      capabilities: node.capabilities,
      labels: node.labels,
      addresses: [],
      candidate_addresses: [],
      last_successful_contact: nil,
      last_attempted_contact: nil,
      reachability: :unknown,
      agent_card_version: nil,
      supported_skills: [],
      diagnostic_summary: nil,
      consecutive_failures: 0,
      next_eligible_poll_at: schedule(current, state.poll_interval_ms, state),
      poll_generation: 0,
      active_poll_token: nil
    }
  end

  defp successful_observation(entry, outcome, result, current, state) do
    entry
    |> Map.put(:reachability, outcome)
    |> Map.put(:last_successful_contact, current)
    |> Map.put(:consecutive_failures, 0)
    |> Map.put(:next_eligible_poll_at, schedule(current, state.poll_interval_ms, state))
    |> Map.put(:active_poll_token, nil)
    |> maybe_adopt_addresses(result)
    |> maybe_adopt_agent_card(result)
    |> maybe_adopt_health(result)
  end

  defp failed_observation(entry, _outcome, current, state) do
    failures = entry.consecutive_failures + 1
    delay = exponential_backoff(failures, state.poll_interval_ms, state.backoff_cap_ms)

    %{
      entry
      | reachability: failed_reachability(entry.last_successful_contact, current, state),
        consecutive_failures: failures,
        next_eligible_poll_at: schedule(current, delay, state, state.backoff_cap_ms),
        active_poll_token: nil
    }
  end

  defp failed_reachability(nil, _current, _state), do: :unreachable

  defp failed_reachability(last_success, current, state) do
    age = DateTime.diff(current, last_success, :millisecond)

    cond do
      age < state.degraded_after_ms -> :degraded
      age < state.stale_after_ms -> :stale
      true -> :unreachable
    end
  end

  defp exponential_backoff(1, base, cap), do: min(base, cap)

  defp exponential_backoff(failures, base, cap) do
    Enum.reduce(2..failures//1, min(base, cap), fn _step, delay ->
      min(delay * 2, cap)
    end)
  end

  defp schedule(current, base_delay, state, cap \\ nil) do
    jitter_bound = min(state.jitter_ms, base_delay)
    jitter = state.random.(-jitter_bound, jitter_bound)
    delay = max(base_delay + jitter, 0)
    DateTime.add(current, if(cap, do: min(delay, cap), else: delay), :millisecond)
  end

  defp due?(%{active_poll_token: token}, _current) when not is_nil(token), do: false
  defp due?(%{next_eligible_poll_at: nil}, _current), do: true

  defp due?(entry, current) do
    DateTime.compare(entry.next_eligible_poll_at, current) in [:lt, :eq]
  end

  defp outcome(%{outcome: outcome}), do: outcome
  defp outcome(outcome) when is_atom(outcome), do: outcome
  defp outcome(_result), do: nil

  defp maybe_adopt_addresses(entry, %{verified_addresses: addresses})
       when is_list(addresses) and addresses != [] do
    %{entry | addresses: addresses}
  end

  defp maybe_adopt_addresses(entry, _result), do: entry

  defp maybe_adopt_agent_card(entry, %{agent_card: card}) when is_map(card) do
    entry
    |> Map.put(:agent_card_version, field(card, "version") || field(card, "protocolVersion"))
    |> Map.put(:supported_skills, field(card, "skills") || [])
  end

  defp maybe_adopt_agent_card(entry, _result), do: entry

  defp maybe_adopt_health(entry, %{health: health}) when is_map(health) do
    Map.put(entry, :diagnostic_summary, field(health, "summary") || field(health, "reason"))
  end

  defp maybe_adopt_health(entry, _result), do: entry

  defp field(map, "version"), do: Map.get(map, "version") || Map.get(map, :version)

  defp field(map, "protocolVersion"),
    do: Map.get(map, "protocolVersion") || Map.get(map, :protocolVersion)

  defp field(map, "skills"), do: Map.get(map, "skills") || Map.get(map, :skills)
  defp field(map, "summary"), do: Map.get(map, "summary") || Map.get(map, :summary)
  defp field(map, "reason"), do: Map.get(map, "reason") || Map.get(map, :reason)

  defp store_and_audit(previous, updated, outcome, state) do
    :ets.insert(state.table, {updated.id, updated})

    if previous.reachability != updated.reachability do
      emit_transition(previous, updated, outcome, state.audit_server)
    end
  end

  defp emit_transition(previous, updated, outcome, audit_server) do
    Audit.emit(
      :node_poll_transition,
      %{
        node_id: updated.id,
        from: previous.reachability,
        to: updated.reachability,
        outcome: outcome,
        consecutive_failures: updated.consecutive_failures,
        observed_at: DateTime.to_iso8601(updated.last_attempted_contact)
      },
      server: audit_server
    )
  catch
    :exit, _reason -> :ok
  end

  defp lookup(table, node_id) do
    case :ets.lookup(table, node_id) do
      [{^node_id, entry}] -> {:ok, entry}
      [] -> :error
    end
  end

  defp public_entry(entry), do: Map.drop(entry, [:active_poll_token, :poll_generation])

  defp valid_state(%{reachability: state}) when state not in @states, do: {:error, :invalid_state}
  defp valid_state(_changes), do: :ok

  defp now(state) do
    case state.clock.() do
      %DateTime{} = current -> current
      other -> raise ArgumentError, "registry clock must return DateTime, got: #{inspect(other)}"
    end
  end

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

  defp validate_thresholds!(state) do
    if state.degraded_after_ms >= state.stale_after_ms do
      raise ArgumentError, ":degraded_after_ms must be less than :stale_after_ms"
    end
  end
end

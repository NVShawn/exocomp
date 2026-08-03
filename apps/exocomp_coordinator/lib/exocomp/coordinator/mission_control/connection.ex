# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.Connection do
  @moduledoc """
  Keeps the coordinator's optional Mission Control session alive.

  The transport is deliberately injected. The WebSocket client owns TLS and
  framing, while this process owns heartbeat cadence, connection loss, and
  retry policy. Connection attempts run in an unlinked worker, so an offline
  control plane cannot block the coordinator's local work.

  A connection is considered stable only after it remains authenticated for
  `:stable_after_ms` (90 seconds by default). Failed connections before that
  point retain their backoff history; a stable connection resets it.
  """

  use GenServer

  import Bitwise

  @default_heartbeat_interval_ms 30_000
  @default_stable_after_ms 90_000
  @default_min_backoff_ms 1_000
  @default_max_backoff_ms 60_000

  @type session :: term()
  @type status :: :connecting | :connected | :disconnected

  @type option ::
          {:name, GenServer.name()}
          | {:connect_fn, (-> {:ok, session()} | {:error, term()})}
          | {:send_fn, (session(), map() -> :ok | {:ok, term()} | {:error, term()})}
          | {:heartbeat_fn, (-> map())}
          | {:random_fn, (integer(), integer() -> integer())}
          | {:schedule_fn, (term(), non_neg_integer() -> reference())}
          | {:cancel_timer_fn, (reference() -> term())}
          | {:now_fn, (-> integer())}
          | {:heartbeat_interval_ms, pos_integer()}
          | {:stable_after_ms, pos_integer()}
          | {:min_backoff_ms, pos_integer()}
          | {:max_backoff_ms, pos_integer()}
          | {:start_immediately, boolean()}

  @spec start_link([option()]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Returns the current connection state without exposing the session handle."
  @spec status(GenServer.server()) :: map()
  def status(server \\ __MODULE__), do: GenServer.call(server, :status)

  @doc "Starts an asynchronous connection attempt when no session is active."
  @spec connect_now(GenServer.server()) :: :ok
  def connect_now(server \\ __MODULE__), do: GenServer.call(server, :connect_now)

  @doc "Installs an authenticated transport session and begins heartbeat scheduling."
  @spec authenticated(session(), GenServer.server()) :: :ok
  def authenticated(session, server \\ __MODULE__),
    do: GenServer.call(server, {:authenticated, session})

  @doc "Reports a transport loss. Repeated reports do not create duplicate retries."
  @spec disconnected(term(), GenServer.server()) :: :ok
  def disconnected(reason \\ :transport_closed, server \\ __MODULE__) do
    GenServer.call(server, {:disconnected, reason})
  end

  @impl true
  def init(opts) do
    state = %{
      connect_fn: Keyword.get(opts, :connect_fn, fn -> {:error, :not_configured} end),
      send_fn: Keyword.get(opts, :send_fn, fn _session, _event -> {:error, :not_configured} end),
      heartbeat_fn: Keyword.get(opts, :heartbeat_fn, &default_heartbeat/0),
      random_fn: Keyword.get(opts, :random_fn, &random_between/2),
      schedule_fn: Keyword.get(opts, :schedule_fn, &schedule_timer/2),
      cancel_timer_fn: Keyword.get(opts, :cancel_timer_fn, &cancel_timer/1),
      now_fn: Keyword.get(opts, :now_fn, &monotonic_ms/0),
      heartbeat_interval_ms:
        positive_option(opts, :heartbeat_interval_ms, @default_heartbeat_interval_ms),
      stable_after_ms: positive_option(opts, :stable_after_ms, @default_stable_after_ms),
      min_backoff_ms: positive_option(opts, :min_backoff_ms, @default_min_backoff_ms),
      max_backoff_ms: positive_option(opts, :max_backoff_ms, @default_max_backoff_ms),
      status: :disconnected,
      session: nil,
      session_monitor_ref: nil,
      connect_pid: nil,
      connect_monitor_ref: nil,
      connect_token: nil,
      connect_generation: 0,
      heartbeat_timer_ref: nil,
      heartbeat_generation: 0,
      stable_timer_ref: nil,
      stable_generation: 0,
      reconnect_timer_ref: nil,
      reconnect_generation: 0,
      backoff_attempts: 0,
      reconnect_delay_ms: nil,
      connected_at_ms: nil,
      stable?: false,
      last_error: nil
    }

    if state.max_backoff_ms < state.min_backoff_ms do
      raise ArgumentError, ":max_backoff_ms must be greater than or equal to :min_backoff_ms"
    end

    if Keyword.get(opts, :start_immediately, true), do: send(self(), :connect)
    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, state), do: {:reply, public_status(state), state}

  def handle_call(:connect_now, _from, state) do
    {:reply, :ok, start_connect(state)}
  end

  def handle_call({:authenticated, session}, _from, state) do
    {:reply, :ok, install_session(session, state)}
  end

  def handle_call({:disconnected, reason}, _from, state) do
    {:reply, :ok, lose_connection(reason, state)}
  end

  @impl true
  def handle_info(:connect, state), do: {:noreply, start_connect(state)}

  def handle_info({:connect_result, token, result}, %{connect_token: token} = state) do
    state = clear_connect_worker(state)

    case result do
      {:ok, session} -> {:noreply, install_session(session, state)}
      {:error, reason} -> {:noreply, schedule_reconnect(reason, state)}
      other -> {:noreply, schedule_reconnect({:invalid_connect_result, other}, state)}
    end
  end

  def handle_info({:connect_result, _token, _result}, state), do: {:noreply, state}

  def handle_info({:heartbeat, generation}, %{heartbeat_generation: generation} = state) do
    {:noreply, send_heartbeat(state)}
  end

  def handle_info({:heartbeat, _generation}, state), do: {:noreply, state}

  def handle_info(
        {:stable, generation},
        %{stable_generation: generation, status: :connected, session: session} = state
      )
      when not is_nil(session) do
    {:noreply, %{state | stable_timer_ref: nil, stable?: true, backoff_attempts: 0}}
  end

  def handle_info({:stable, _generation}, state), do: {:noreply, state}

  def handle_info({:reconnect, generation}, %{reconnect_generation: generation} = state) do
    {:noreply, state |> clear_reconnect_timer() |> start_connect()}
  end

  def handle_info({:reconnect, _generation}, state), do: {:noreply, state}

  def handle_info({:DOWN, ref, :process, _pid, reason}, %{session_monitor_ref: ref} = state) do
    {:noreply, lose_connection({:session_down, reason}, state)}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %{connect_monitor_ref: ref} = state) do
    # Successful workers send their result before exiting. A worker that exits
    # without a result is treated as a failed attempt rather than a crash.
    {:noreply, schedule_reconnect({:connect_worker_down, reason}, clear_connect_worker(state))}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, state) do
    state
    |> clear_heartbeat_timer()
    |> clear_stable_timer()
    |> clear_reconnect_timer()
    |> clear_session_monitor()
    |> clear_connect_worker()

    :ok
  end

  defp start_connect(%{session: session} = state) when not is_nil(session), do: state
  defp start_connect(%{connect_monitor_ref: ref} = state) when not is_nil(ref), do: state

  defp start_connect(state) do
    state = clear_reconnect_timer(state)
    token = state.connect_generation + 1
    owner = self()
    connect_fn = state.connect_fn

    {pid, monitor_ref} =
      spawn_monitor(fn ->
        result = safely(fn -> connect_fn.() end)
        send(owner, {:connect_result, token, result})
      end)

    %{
      state
      | status: :connecting,
        connect_pid: pid,
        connect_monitor_ref: monitor_ref,
        connect_token: token,
        connect_generation: token,
        reconnect_delay_ms: nil,
        last_error: nil
    }
  end

  defp install_session(session, state) do
    state
    |> stop_connect_worker()
    |> clear_connect_worker()
    |> clear_reconnect_timer()
    |> clear_heartbeat_timer()
    |> clear_stable_timer()
    |> clear_session_monitor()
    |> Map.merge(%{
      status: :connected,
      session: session,
      session_monitor_ref: monitor_session(session),
      connected_at_ms: now(state),
      stable?: false,
      reconnect_delay_ms: nil,
      last_error: nil
    })
    |> schedule_heartbeat()
    |> schedule_stability()
  end

  defp send_heartbeat(%{status: :connected, session: session} = state) when not is_nil(session) do
    event = safely(state.heartbeat_fn)

    case event do
      {:error, reason} ->
        lose_connection({:heartbeat_build_failed, reason}, state)

      event ->
        case safely(fn -> state.send_fn.(session, event) end) do
          :ok -> schedule_heartbeat(state)
          {:ok, _value} -> schedule_heartbeat(state)
          {:error, reason} -> lose_connection({:heartbeat_failed, reason}, state)
          other -> lose_connection({:invalid_heartbeat_result, other}, state)
        end
    end
  end

  defp send_heartbeat(state), do: state

  defp lose_connection(_reason, %{session: nil, reconnect_timer_ref: ref} = state)
       when not is_nil(ref),
       do: state

  defp lose_connection(reason, state) do
    state =
      state
      |> clear_heartbeat_timer()
      |> clear_stable_timer()
      |> clear_session_monitor()
      |> Map.merge(%{status: :disconnected, session: nil, connected_at_ms: nil, stable?: false})

    schedule_reconnect(reason, state)
  end

  defp schedule_reconnect(reason, state) do
    state = clear_connect_worker(state)

    if state.reconnect_timer_ref do
      %{state | status: :disconnected, last_error: reason}
    else
      attempt = state.backoff_attempts
      bound = full_jitter_bound(attempt, state.min_backoff_ms, state.max_backoff_ms)
      delay = bounded_random(state.random_fn, bound)
      generation = state.reconnect_generation + 1
      timer_ref = state.schedule_fn.({:reconnect, generation}, delay)

      %{
        state
        | status: :disconnected,
          reconnect_timer_ref: timer_ref,
          reconnect_generation: generation,
          backoff_attempts: attempt + 1,
          reconnect_delay_ms: delay,
          last_error: reason
      }
    end
  end

  defp schedule_heartbeat(state) do
    state = clear_heartbeat_timer(state)
    generation = state.heartbeat_generation + 1
    timer_ref = state.schedule_fn.({:heartbeat, generation}, state.heartbeat_interval_ms)
    %{state | heartbeat_timer_ref: timer_ref, heartbeat_generation: generation}
  end

  defp schedule_stability(state) do
    state = clear_stable_timer(state)
    generation = state.stable_generation + 1
    timer_ref = state.schedule_fn.({:stable, generation}, state.stable_after_ms)
    %{state | stable_timer_ref: timer_ref, stable_generation: generation}
  end

  defp clear_heartbeat_timer(%{heartbeat_timer_ref: nil} = state), do: state

  defp clear_heartbeat_timer(state) do
    _ = state.cancel_timer_fn.(state.heartbeat_timer_ref)
    %{state | heartbeat_timer_ref: nil}
  end

  defp clear_stable_timer(%{stable_timer_ref: nil} = state), do: state

  defp clear_stable_timer(state) do
    _ = state.cancel_timer_fn.(state.stable_timer_ref)
    %{state | stable_timer_ref: nil}
  end

  defp clear_reconnect_timer(%{reconnect_timer_ref: nil} = state), do: state

  defp clear_reconnect_timer(state) do
    _ = state.cancel_timer_fn.(state.reconnect_timer_ref)
    %{state | reconnect_timer_ref: nil}
  end

  defp clear_session_monitor(%{session_monitor_ref: nil} = state), do: state

  defp clear_session_monitor(state) do
    Process.demonitor(state.session_monitor_ref, [:flush])
    %{state | session_monitor_ref: nil}
  end

  defp clear_connect_worker(%{connect_monitor_ref: nil} = state), do: state

  defp clear_connect_worker(state) do
    Process.demonitor(state.connect_monitor_ref, [:flush])
    %{state | connect_pid: nil, connect_monitor_ref: nil, connect_token: nil}
  end

  defp stop_connect_worker(%{connect_pid: nil} = state), do: state

  defp stop_connect_worker(state) do
    _ = Process.exit(state.connect_pid, :kill)
    state
  end

  defp monitor_session(session) when is_pid(session), do: Process.monitor(session)
  defp monitor_session(_session), do: nil

  defp public_status(state) do
    %{
      status: state.status,
      authenticated: not is_nil(state.session),
      stable: state.stable?,
      connected_at_ms: state.connected_at_ms,
      backoff_attempts: state.backoff_attempts,
      reconnect_delay_ms: state.reconnect_delay_ms,
      heartbeat_generation: state.heartbeat_generation,
      stable_generation: state.stable_generation,
      reconnect_generation: state.reconnect_generation,
      last_error: state.last_error
    }
  end

  defp full_jitter_bound(attempt, minimum, maximum) do
    multiplier = 1 <<< min(attempt, 62)
    min(minimum * multiplier, maximum)
  end

  defp bounded_random(random_fn, maximum) do
    case random_fn.(0, maximum) do
      value when is_integer(value) and value >= 0 and value <= maximum ->
        value

      value ->
        raise ArgumentError,
              "random_fn must return an integer in 0..#{maximum}, got: #{inspect(value)}"
    end
  end

  defp safely(function) do
    function.()
  rescue
    error -> {:error, {:exception, Exception.message(error)}}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp now(state) do
    case state.now_fn.() do
      value when is_integer(value) ->
        value

      value ->
        raise ArgumentError,
              "now_fn must return an integer millisecond timestamp, got: #{inspect(value)}"
    end
  end

  defp default_heartbeat, do: %{schema_version: 1, kind: "cluster.heartbeat"}
  defp monotonic_ms, do: System.monotonic_time(:millisecond)
  defp schedule_timer(message, delay), do: Process.send_after(self(), message, delay)
  defp cancel_timer(timer_ref), do: Process.cancel_timer(timer_ref)

  defp random_between(minimum, maximum) do
    minimum + :rand.uniform(maximum - minimum + 1) - 1
  end

  defp positive_option(opts, key, default) do
    case Keyword.get(opts, key, default) do
      value when is_integer(value) and value > 0 -> value
      value -> raise ArgumentError, "#{key} must be a positive integer, got: #{inspect(value)}"
    end
  end
end

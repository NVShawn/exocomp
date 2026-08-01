# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.SessionLiveness do
  @moduledoc """
  Tracks valid heartbeats for one authenticated Mission Control session.

  The gateway validates the transport and envelope before calling
  `heartbeat/2`. This process then commits connection transitions before it
  publishes them, which prevents a transient UI or broadcast state from
  claiming a connection change that was not stored.
  """

  use GenServer

  @default_disconnect_after_ms 90_000
  @default_commit_retry_ms 1_000

  @type option ::
          {:name, GenServer.name()}
          | {:now_fn, (-> integer())}
          | {:schedule_fn, (term(), non_neg_integer() -> reference())}
          | {:cancel_timer_fn, (reference() -> term())}
          | {:commit_state_fn, (term(), :connected | :disconnected -> :ok | {:error, term()})}
          | {:publish_state_fn, (term(), :connected | :disconnected -> term())}
          | {:disconnect_after_ms, pos_integer()}
          | {:commit_retry_ms, pos_integer()}

  @spec start_link([option()]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @spec status(GenServer.server()) :: map()
  def status(server \\ __MODULE__), do: GenServer.call(server, :status)

  @doc "Commits and publishes that a newly authenticated session is connected."
  @spec authenticated(term(), GenServer.server()) :: :ok | {:error, term()}
  def authenticated(session_id, server \\ __MODULE__) do
    GenServer.call(server, {:authenticated, session_id})
  end

  @doc "Records a validated heartbeat for the active session."
  @spec heartbeat(term(), GenServer.server()) :: :ok | {:error, :not_active | term()}
  def heartbeat(session_id, server \\ __MODULE__) do
    GenServer.call(server, {:heartbeat, session_id})
  end

  @impl true
  def init(opts) do
    {:ok,
     %{
       now_fn: Keyword.get(opts, :now_fn, &monotonic_ms/0),
       schedule_fn: Keyword.get(opts, :schedule_fn, &schedule_timer/2),
       cancel_timer_fn: Keyword.get(opts, :cancel_timer_fn, &cancel_timer/1),
       commit_state_fn: Keyword.get(opts, :commit_state_fn, fn _session_id, _state -> :ok end),
       publish_state_fn: Keyword.get(opts, :publish_state_fn, fn _session_id, _state -> :ok end),
       disconnect_after_ms:
         positive_option(opts, :disconnect_after_ms, @default_disconnect_after_ms),
       commit_retry_ms: positive_option(opts, :commit_retry_ms, @default_commit_retry_ms),
       session_id: nil,
       status: :disconnected,
       last_heartbeat_at_ms: nil,
       timer_ref: nil,
       timer_generation: 0,
       last_error: nil
     }}
  end

  @impl true
  def handle_call(:status, _from, state), do: {:reply, public_status(state), state}

  def handle_call({:authenticated, session_id}, _from, state) do
    now = now(state)
    candidate = %{state | session_id: session_id, last_heartbeat_at_ms: now, last_error: nil}

    case transition(candidate, :connected) do
      {:ok, state} ->
        {:reply, :ok, schedule_timeout(state)}

      {:error, reason, _candidate} ->
        {:reply, {:error, reason}, %{state | last_error: {:commit_failed, reason}}}
    end
  end

  def handle_call({:heartbeat, session_id}, _from, %{session_id: session_id} = state)
      when not is_nil(session_id) do
    state = %{state | last_heartbeat_at_ms: now(state), last_error: nil}

    case state.status do
      :connected ->
        {:reply, :ok, schedule_timeout(state)}

      :disconnected ->
        case transition(state, :connected) do
          {:ok, state} -> {:reply, :ok, schedule_timeout(state)}
          {:error, reason, state} -> {:reply, {:error, reason}, schedule_retry(state)}
        end
    end
  end

  def handle_call({:heartbeat, _session_id}, _from, state),
    do: {:reply, {:error, :not_active}, state}

  @impl true
  def handle_info({:liveness_check, generation}, %{timer_generation: generation} = state) do
    elapsed = now(state) - state.last_heartbeat_at_ms

    if elapsed < state.disconnect_after_ms do
      {:noreply, schedule_timeout(state)}
    else
      case transition(%{state | timer_ref: nil}, :disconnected) do
        {:ok, state} -> {:noreply, state}
        {:error, _reason, state} -> {:noreply, schedule_retry(state)}
      end
    end
  end

  def handle_info({:liveness_check, _generation}, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, state) do
    _ = clear_timer(state)
    :ok
  end

  defp transition(%{session_id: session_id} = state, desired_state) do
    case safely(fn -> state.commit_state_fn.(session_id, desired_state) end) do
      :ok ->
        transition_committed(state, desired_state)

      {:ok, _value} ->
        transition_committed(state, desired_state)

      {:error, reason} ->
        {:error, reason, %{state | last_error: {:commit_failed, reason}}}

      other ->
        {:error, {:invalid_commit_result, other}, %{state | last_error: {:commit_failed, other}}}
    end
  end

  defp transition_committed(state, desired_state) do
    # Publishing happens strictly after the durable transition succeeds.
    publish_result = safely(fn -> state.publish_state_fn.(state.session_id, desired_state) end)
    {:ok, %{state | status: desired_state, last_error: publish_error(publish_result)}}
  end

  defp publish_error(:ok), do: nil
  defp publish_error({:ok, _value}), do: nil
  defp publish_error({:error, reason}), do: {:publish_failed, reason}
  defp publish_error(_other), do: nil

  defp schedule_timeout(%{session_id: nil} = state), do: clear_timer(state)

  defp schedule_timeout(state) do
    state = clear_timer(state)
    generation = state.timer_generation + 1
    deadline = state.last_heartbeat_at_ms + state.disconnect_after_ms
    delay = max(deadline - now(state), 0)
    timer_ref = state.schedule_fn.({:liveness_check, generation}, delay)
    %{state | timer_ref: timer_ref, timer_generation: generation}
  end

  defp schedule_retry(state) do
    state = clear_timer(state)
    generation = state.timer_generation + 1
    timer_ref = state.schedule_fn.({:liveness_check, generation}, state.commit_retry_ms)
    %{state | timer_ref: timer_ref, timer_generation: generation}
  end

  defp clear_timer(%{timer_ref: nil} = state), do: state

  defp clear_timer(state) do
    _ = state.cancel_timer_fn.(state.timer_ref)
    %{state | timer_ref: nil}
  end

  defp public_status(state) do
    %{
      session_id: state.session_id,
      status: state.status,
      last_heartbeat_at_ms: state.last_heartbeat_at_ms,
      timer_generation: state.timer_generation,
      last_error: state.last_error
    }
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

  defp safely(function) do
    function.()
  rescue
    error -> {:error, {:exception, Exception.message(error)}}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp monotonic_ms, do: System.monotonic_time(:millisecond)
  defp schedule_timer(message, delay), do: Process.send_after(self(), message, delay)
  defp cancel_timer(timer_ref), do: Process.cancel_timer(timer_ref)

  defp positive_option(opts, key, default) do
    case Keyword.get(opts, key, default) do
      value when is_integer(value) and value > 0 -> value
      value -> raise ArgumentError, "#{key} must be a positive integer, got: #{inspect(value)}"
    end
  end
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.Connection do
  @moduledoc """
  Mission Control connection handler for outbound WebSocket connection.

  Manages:
  - Connection establishment via mTLS WebSocket
  - Heartbeat dispatch at configured interval (default 30 seconds)
  - Reconnection with full-jitter exponential backoff
  - Connection state tracking

  The connection is always outbound from the coordinator to Mission Control.
  Connection failure does not cause the coordinator to fail; it continues
  operating locally and replays events after reconnection.
  """

  use GenServer
  require Logger

  alias Exocomp.Coordinator.Config

  # ── API ────────────────────────────────────────────────────────────────────

  @doc """
  Starts the connection handler.

  Options:
    - `:config` (required) — Mission Control configuration
    - `:name` (optional) — registered process name
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Returns the current connection state.

  Returns one of: `:disconnected`, `:connecting`, `:connected`.
  """
  @spec connection_status(pid() | atom()) :: :disconnected | :connecting | :connected
  def connection_status(server \\ __MODULE__) do
    GenServer.call(server, :connection_status)
  end

  # ── GenServer callbacks ────────────────────────────────────────────────────

  @type state :: %{
          config: Config.MissionControl.t(),
          status: :disconnected | :connecting | :connected,
          connection_pid: pid() | nil,
          backoff_state: backoff_state(),
          heartbeat_timer: reference() | nil
        }

  @type backoff_state :: %{
          current_delay: pos_integer(),
          min_delay: pos_integer(),
          max_delay: pos_integer(),
          attempt: non_neg_integer()
        }

  @impl true
  def init(opts) do
    config = Keyword.fetch!(opts, :config)

    Logger.info(
      "[MissionControlConnection] Initializing connection to #{config.url} with #{config.heartbeat_interval_seconds}s heartbeat"
    )

    state = %{
      config: config,
      status: :disconnected,
      connection_pid: nil,
      backoff_state: init_backoff_state(config),
      heartbeat_timer: nil
    }

    # Start the first connection attempt immediately
    send(self(), :connect)

    {:ok, state}
  end

  @impl true
  def handle_info(:connect, state) do
    Logger.info("[MissionControlConnection] Attempting connection to #{state.config.url}")

    # For now, log the attempt but don't actually establish a connection.
    # Actual WebSocket connection will be implemented in a follow-up task.
    new_state = %{
      state
      | status: :disconnected,
        backoff_state: increment_backoff_attempt(state.backoff_state)
    }

    # Schedule next reconnection attempt
    delay = calculate_backoff_delay(new_state.backoff_state)

    send_after(self(), :connect, delay)

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:heartbeat, state) do
    case state.status do
      :connected ->
        Logger.debug("[MissionControlConnection] Sending heartbeat")

      # Heartbeat would be sent here once connection is established

      :disconnected ->
        Logger.debug("[MissionControlConnection] Skipping heartbeat: disconnected")

      :connecting ->
        Logger.debug("[MissionControlConnection] Skipping heartbeat: connecting")
    end

    # Reschedule the next heartbeat
    timer = schedule_heartbeat(state.config.heartbeat_interval_seconds)

    {:noreply, %{state | heartbeat_timer: timer}}
  end

  @impl true
  def handle_call(:connection_status, _from, state) do
    {:reply, state.status, state}
  end

  # ── Helper functions ───────────────────────────────────────────────────────

  defp init_backoff_state(config) do
    %{
      current_delay: config.reconnect_min_backoff_seconds,
      min_delay: config.reconnect_min_backoff_seconds,
      max_delay: config.reconnect_max_backoff_seconds,
      attempt: 0
    }
  end

  defp increment_backoff_attempt(backoff) do
    %{backoff | attempt: backoff.attempt + 1}
  end

  defp calculate_backoff_delay(backoff) do
    # Full-jitter exponential backoff:
    # delay = random(0, min(2^attempt * base, max))
    base = backoff.min_delay
    max_exponential = min(pow(2, backoff.attempt) * base, backoff.max_delay)
    random_delay = :rand.uniform(max_exponential)
    max(1000, min(random_delay, backoff.max_delay * 1000))
  end

  defp pow(base, exp) when exp >= 0 do
    pow_helper(base, exp, 1)
  end

  defp pow_helper(_base, 0, acc), do: acc
  defp pow_helper(base, exp, acc), do: pow_helper(base, exp - 1, acc * base)

  defp schedule_heartbeat(interval_seconds) do
    Process.send_after(self(), :heartbeat, interval_seconds * 1000)
  end

  defp send_after(pid, msg, delay_ms) do
    Process.send_after(pid, msg, max(1, delay_ms))
  end
end

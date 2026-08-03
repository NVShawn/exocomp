# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.Outbox do
  @moduledoc """
  Durable event and command outbox for Mission Control.

  The outbox persists events and commands to disk, ensuring they survive
  process restarts and coordinator restarts. Events are retained until
  acknowledged by Mission Control. Commands are retained until they expire
  or are acknowledged.

  The outbox directory is configured in the Mission Control config block
  as `outbox_path`.
  """

  use GenServer
  require Logger

  alias Exocomp.Coordinator.Config

  @type event :: map()
  @type command :: map()

  # ── API ────────────────────────────────────────────────────────────────────

  @doc """
  Starts the outbox server.

  Options:
    - `:config` (required) — Mission Control configuration
    - `:name` (optional) — registered process name
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Appends an event to the outbox.

  Returns `{:ok, event_id}` on success or `{:error, reason}` on failure.
  """
  @spec append_event(event(), pid() | atom()) :: {:ok, String.t()} | {:error, term()}
  def append_event(event, server \\ __MODULE__) do
    GenServer.call(server, {:append_event, event})
  end

  @doc """
  Appends a command to the outbox.

  Returns `{:ok, command_id}` on success or `{:error, reason}` on failure.
  """
  @spec append_command(command(), pid() | atom()) :: {:ok, String.t()} | {:error, term()}
  def append_command(command, server \\ __MODULE__) do
    GenServer.call(server, {:append_command, command})
  end

  @doc """
  Lists pending events (not yet acknowledged by Mission Control).

  Returns a list of events.
  """
  @spec list_pending_events(pid() | atom()) :: [event()]
  def list_pending_events(server \\ __MODULE__) do
    GenServer.call(server, :list_pending_events)
  end

  @doc """
  Acknowledges an event, removing it from the pending list.

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  @spec acknowledge_event(String.t(), pid() | atom()) :: :ok | {:error, term()}
  def acknowledge_event(event_id, server \\ __MODULE__) do
    GenServer.call(server, {:acknowledge_event, event_id})
  end

  # ── GenServer callbacks ────────────────────────────────────────────────────

  @type state :: %{
          config: Config.MissionControl.t(),
          outbox_path: String.t(),
          events_dir: String.t(),
          commands_dir: String.t()
        }

  @impl true
  def init(opts) do
    config = Keyword.fetch!(opts, :config)
    outbox_path = config.outbox_path

    # Ensure the outbox directory structure exists
    events_dir = Path.join(outbox_path, "events")
    commands_dir = Path.join(outbox_path, "commands")

    with :ok <- File.mkdir_p(events_dir),
         :ok <- File.mkdir_p(commands_dir) do
      Logger.info("[MissionControlOutbox] Initialized at #{outbox_path}")

      state = %{
        config: config,
        outbox_path: outbox_path,
        events_dir: events_dir,
        commands_dir: commands_dir
      }

      {:ok, state}
    else
      {:error, reason} ->
        Logger.error("[MissionControlOutbox] Failed to initialize: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:append_event, event}, _from, state) do
    event_id = generate_id()

    case write_event(state.events_dir, event_id, event) do
      :ok ->
        {:reply, {:ok, event_id}, state}

      {:error, reason} ->
        Logger.error("[MissionControlOutbox] Failed to write event: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:append_command, command}, _from, state) do
    command_id = generate_id()

    case write_command(state.commands_dir, command_id, command) do
      :ok ->
        {:reply, {:ok, command_id}, state}

      {:error, reason} ->
        Logger.error("[MissionControlOutbox] Failed to write command: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:list_pending_events, _from, state) do
    events = read_pending_events(state.events_dir)
    {:reply, events, state}
  end

  @impl true
  def handle_call({:acknowledge_event, event_id}, _from, state) do
    event_file = Path.join(state.events_dir, "#{event_id}.json")

    case File.rm(event_file) do
      :ok ->
        {:reply, :ok, state}

      {:error, :enoent} ->
        # Event already acknowledged or doesn't exist
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.error("[MissionControlOutbox] Failed to acknowledge event: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  # ── Helper functions ───────────────────────────────────────────────────────

  defp generate_id do
    # Generate a simple ID using timestamp and random suffix
    timestamp = System.os_time(:millisecond)
    random = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    "#{timestamp}-#{random}"
  end

  defp write_event(events_dir, event_id, event) do
    file_path = Path.join(events_dir, "#{event_id}.json")
    content = Jason.encode!(event)
    File.write(file_path, content)
  end

  defp write_command(commands_dir, command_id, command) do
    file_path = Path.join(commands_dir, "#{command_id}.json")
    content = Jason.encode!(command)
    File.write(file_path, content)
  end

  defp read_pending_events(events_dir) do
    case File.ls(events_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".json"))
        |> Enum.map(&read_event_file(events_dir, &1))
        |> Enum.filter(&(&1 != nil))

      {:error, _} ->
        []
    end
  end

  defp read_event_file(events_dir, filename) do
    file_path = Path.join(events_dir, filename)

    case File.read(file_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, event} -> event
          {:error, _} -> nil
        end

      {:error, _} ->
        nil
    end
  end
end

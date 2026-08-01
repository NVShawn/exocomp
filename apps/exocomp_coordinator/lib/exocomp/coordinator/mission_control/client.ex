# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.Client do
  @moduledoc """
  Optional coordinator-owned Mission Control connection process.

  This process owns an outbound socket only.  It is deliberately not part of
  the coordinator's inbound listener supervision tree; callers opt into it
  with `connect: true` or call `connect/1` explicitly.
  """

  use GenServer

  alias Exocomp.Coordinator.MissionControl.WebSocket

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    case Keyword.get(opts, :name) do
      nil -> GenServer.start_link(__MODULE__, opts)
      name -> GenServer.start_link(__MODULE__, opts, name: name)
    end
  end

  @doc "Opens the configured outbound mTLS WebSocket."
  @spec connect(pid()) :: :ok | {:error, term()}
  def connect(server), do: GenServer.call(server, :connect, 30_000)

  @doc "Sends a JSON text payload over the established connection."
  @spec send(pid(), map() | binary()) :: :ok | {:error, term()}
  def send(server, payload), do: GenServer.call(server, {:send, payload})

  @doc "Receives one WebSocket message from the established connection."
  @spec recv(pid(), timeout()) :: {:ok, WebSocket.message()} | {:error, term()}
  def recv(server, timeout \\ 15_000),
    do: GenServer.call(server, {:recv, timeout}, timeout + 1_000)

  @doc "Closes the established connection, if any."
  @spec disconnect(pid()) :: :ok
  def disconnect(server), do: GenServer.call(server, :disconnect)

  @impl GenServer
  def init(opts) do
    state = %{opts: opts, socket: nil}

    if Keyword.get(opts, :connect, false) do
      {:ok, state, {:continue, :connect}}
    else
      {:ok, state}
    end
  end

  @impl GenServer
  def handle_continue(:connect, %{opts: opts} = state) do
    case WebSocket.connect(opts) do
      {:ok, socket} -> {:noreply, %{state | socket: socket}}
      {:error, _reason} -> {:noreply, state}
    end
  end

  @impl GenServer
  def handle_call(:connect, _from, %{socket: %WebSocket{}} = state), do: {:reply, :ok, state}

  def handle_call(:connect, _from, %{opts: opts} = state) do
    case WebSocket.connect(opts) do
      {:ok, socket} -> {:reply, :ok, %{state | socket: socket}}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:send, _payload}, _from, %{socket: nil} = state),
    do: {:reply, {:error, :not_connected}, state}

  def handle_call({:send, payload}, _from, %{socket: socket} = state) do
    case WebSocket.send_text(socket, payload) do
      {:ok, socket} -> {:reply, :ok, %{state | socket: socket}}
      {:error, reason} -> {:reply, {:error, reason}, %{state | socket: nil}}
    end
  end

  def handle_call({:recv, _timeout}, _from, %{socket: nil} = state),
    do: {:reply, {:error, :not_connected}, state}

  def handle_call({:recv, timeout}, _from, %{socket: socket} = state) do
    case WebSocket.recv(socket, timeout) do
      {:ok, message, socket} -> {:reply, {:ok, message}, %{state | socket: socket}}
      {:error, reason} -> {:reply, {:error, reason}, %{state | socket: nil}}
    end
  end

  def handle_call(:disconnect, _from, %{socket: nil} = state), do: {:reply, :ok, state}

  def handle_call(:disconnect, _from, %{socket: socket} = state) do
    :ok = WebSocket.close(socket)
    {:reply, :ok, %{state | socket: nil}}
  end

  @impl GenServer
  def terminate(_reason, %{socket: nil}), do: :ok
  def terminate(_reason, %{socket: socket}), do: WebSocket.close(socket)
end

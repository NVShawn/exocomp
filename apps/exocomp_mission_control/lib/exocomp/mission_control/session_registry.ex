# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.SessionRegistry do
  @moduledoc """
  Local ownership index for active cluster sessions.

  Session ownership is intentionally process-local.  The durable outbox is
  shared by replicas; whichever replica successfully authenticates a cluster
  registers its live session and drains that cluster's pending commands.  A
  newer session replaces the old entry, so a reconnect can take ownership
  without moving command rows between replicas.
  """

  use GenServer

  @type session_id :: String.t()
  @type target :: pid() | (map() -> term())

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: Keyword.get(opts, :name, __MODULE__))
  end

  @spec register(String.t(), String.t(), session_id(), target(), GenServer.server()) ::
          {:ok, map() | nil}
  def register(organization_id, cluster_id, session_id, target, server \\ __MODULE__) do
    GenServer.call(server, {:register, organization_id, cluster_id, session_id, target})
  end

  @spec unregister(String.t(), String.t(), session_id(), GenServer.server()) ::
          :ok | {:error, atom()}
  def unregister(organization_id, cluster_id, session_id, server \\ __MODULE__) do
    GenServer.call(server, {:unregister, organization_id, cluster_id, session_id})
  end

  @spec owner(String.t(), String.t(), GenServer.server()) :: {:ok, map()} | {:error, :offline}
  def owner(organization_id, cluster_id, server \\ __MODULE__) do
    GenServer.call(server, {:owner, organization_id, cluster_id})
  end

  @impl GenServer
  def init(state), do: {:ok, state}

  @impl GenServer
  def handle_call({:register, organization_id, cluster_id, session_id, target}, _from, state) do
    key = {organization_id, cluster_id}
    previous = Map.get(state, key)
    owner = %{session_id: session_id, target: target}
    {:reply, {:ok, previous}, Map.put(state, key, owner)}
  end

  @impl GenServer
  def handle_call({:unregister, organization_id, cluster_id, session_id}, _from, state) do
    key = {organization_id, cluster_id}

    case Map.get(state, key) do
      %{session_id: ^session_id} -> {:reply, :ok, Map.delete(state, key)}
      nil -> {:reply, {:error, :offline}, state}
      _other -> {:reply, {:error, :not_owner}, state}
    end
  end

  @impl GenServer
  def handle_call({:owner, organization_id, cluster_id}, _from, state) do
    case Map.fetch(state, {organization_id, cluster_id}) do
      {:ok, owner} -> {:reply, {:ok, owner}, state}
      :error -> {:reply, {:error, :offline}, state}
    end
  end
end

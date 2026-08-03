# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OIDCConfigCache do
  @moduledoc "Small per-process TTL cache for OIDC discovery and JWKS documents."

  use GenServer

  @default_ttl 3_600

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Return a cached value or evaluate `loader` once for a cache key."
  def fetch(key, loader, ttl \\ @default_ttl) when is_function(loader, 0) do
    case Process.whereis(__MODULE__) do
      nil -> loader.()
      _pid -> GenServer.call(__MODULE__, {:fetch, key, loader, ttl})
    end
  end

  @doc "Clear all cached discovery and key-set documents."
  def clear do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, :clear)
    else
      :ok
    end
  end

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def handle_call({:fetch, key, loader, ttl}, _from, state) do
    now = System.monotonic_time(:second)

    case Map.get(state, key) do
      {expires_at, value} when expires_at > now ->
        {:reply, {:ok, value}, state}

      _ ->
        case loader.() do
          {:ok, value} = result ->
            {:reply, result, Map.put(state, key, {now + ttl, value})}

          error ->
            {:reply, error, Map.delete(state, key)}
        end
    end
  end

  @impl true
  def handle_call(:clear, _from, _state), do: {:reply, :ok, %{}}
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ClusterSessions do
  @moduledoc """
  Serializes authenticated Mission Control sessions by cluster identity.

  Registration and replacement occur in one GenServer call.  This makes the
  newest authenticated socket authoritative even when two reconnects arrive
  at nearly the same time, while the session ID prevents an old socket from
  unregistering its replacement during termination.
  """

  use GenServer

  @type identity :: Exocomp.MissionControl.CertificateIdentity.t()

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Registers a certificate identity and returns its new random session ID."
  @spec register(GenServer.server(), identity(), pid()) :: {:ok, String.t()} | {:error, term()}
  def register(identity), do: register(__MODULE__, identity, self())
  def register(server, identity), do: register(server, identity, self())

  def register(server, identity, pid) do
    safe_call(server, {:register, identity, pid})
  end

  @doc "Removes a session only if it is still the current session for the cluster."
  @spec unregister(GenServer.server(), identity() | String.t(), String.t(), pid()) :: :ok
  def unregister(identity, session_id), do: unregister(__MODULE__, identity, session_id, self())

  def unregister(server, identity, session_id),
    do: unregister(server, identity, session_id, self())

  def unregister(server, identity, session_id, pid) do
    safe_call(server, {:unregister, identity_key(identity), session_id, pid})
  end

  @doc "Returns the current session for a cluster identity, if one exists."
  @spec get(GenServer.server(), identity() | String.t()) :: {:ok, map()} | :error
  def get(identity), do: get(__MODULE__, identity)
  def get(server, identity), do: safe_call(server, {:get, identity_key(identity)})

  @doc "Marks an identity revoked and terminates its current session, if any."
  @spec revoke(GenServer.server(), identity() | String.t()) :: :ok | {:error, term()}
  def revoke(identity), do: revoke(__MODULE__, identity)

  def revoke(server, identity),
    do: safe_call(server, {:revoke, identity_key(identity)})

  @doc "Checks the configured revocation set and callback."
  @spec revoked?(GenServer.server(), identity() | String.t()) :: boolean()
  def revoked?(identity), do: revoked?(__MODULE__, identity)

  def revoked?(server, identity),
    do: safe_call(server, {:revoked?, identity_key(identity)})

  @impl GenServer
  def init(opts) do
    revoked =
      opts
      |> Keyword.get(:revoked_identities, [])
      |> Enum.map(&identity_key/1)
      |> MapSet.new()

    {:ok,
     %{
       sessions: %{},
       revoked: revoked,
       revoked_fun: Keyword.get(opts, :revoked?, fn _ -> false end)
     }}
  end

  @impl GenServer
  def handle_call({:register, identity, pid}, _from, state) do
    key = identity_key(identity)

    if revoked_in_state?(key, state) do
      {:reply, {:error, :revoked}, state}
    else
      session_id = new_session_id()

      if old = Map.get(state.sessions, key) do
        send(old.pid, {:mission_control_session_replaced, session_id})
      end

      session = %{session_id: session_id, identity: identity, pid: pid}
      {:reply, {:ok, session_id}, %{state | sessions: Map.put(state.sessions, key, session)}}
    end
  end

  def handle_call({:unregister, key, session_id, pid}, _from, state) do
    sessions =
      case Map.get(state.sessions, key) do
        %{session_id: ^session_id, pid: ^pid} -> Map.delete(state.sessions, key)
        _other -> state.sessions
      end

    {:reply, :ok, %{state | sessions: sessions}}
  end

  def handle_call({:get, key}, _from, state) do
    reply = if Map.has_key?(state.sessions, key), do: {:ok, state.sessions[key]}, else: :error
    {:reply, reply, state}
  end

  def handle_call({:revoke, key}, _from, state) do
    if session = Map.get(state.sessions, key) do
      send(session.pid, :mission_control_session_revoked)
    end

    {:reply, :ok, %{state | revoked: MapSet.put(state.revoked, key)}}
  end

  def handle_call({:revoked?, key}, _from, state),
    do: {:reply, revoked_in_state?(key, state), state}

  defp revoked_in_state?(key, state) do
    MapSet.member?(state.revoked, key) or
      try do
        state.revoked_fun.(key) == true
      rescue
        _exception -> true
      catch
        _kind, _reason -> true
      end
  end

  defp safe_call(server, request) do
    GenServer.call(server, request)
  catch
    :exit, _reason -> {:error, :unavailable}
  end

  defp identity_key(%{spiffe_id: spiffe_id}) when is_binary(spiffe_id), do: spiffe_id
  defp identity_key(%{"spiffe_id" => spiffe_id}) when is_binary(spiffe_id), do: spiffe_id
  defp identity_key(spiffe_id) when is_binary(spiffe_id), do: spiffe_id
  defp identity_key(other), do: inspect(other)

  defp new_session_id do
    "sess_" <> Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
  end
end

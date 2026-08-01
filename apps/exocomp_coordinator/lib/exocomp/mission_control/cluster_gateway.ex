# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ClusterGateway do
  @moduledoc """
  Plug endpoint for `GET /api/v1/clusters/connect`.

  TLS is configured by the Mission Control listener with peer verification
  and `fail_if_no_peer_cert`.  This Plug repeats the certificate-presence and
  identity checks at the application boundary, then upgrades only an
  authenticated request.  Incoming payloads are acknowledged but never used
  to determine organization or cluster identity.
  """

  @behaviour Plug

  alias Exocomp.MissionControl.{CertificateIdentity, ClusterSessions}

  @connect_path ["api", "v1", "clusters", "connect"]

  @doc "Returns strict TLS 1.3 server options for a Mission Control listener."
  @spec server_tls_options(keyword()) :: {:ok, keyword()} | {:error, term()}
  def server_tls_options(opts) do
    with {:ok, certfile} <- required_tls_option(opts, :certfile),
         {:ok, keyfile} <- required_tls_option(opts, :keyfile),
         {:ok, cacertfile} <- required_tls_option(opts, :cacertfile) do
      {:ok,
       [
         certfile: certfile,
         keyfile: keyfile,
         cacertfile: cacertfile,
         verify: :verify_peer,
         fail_if_no_peer_cert: true,
         versions: [:"tlsv1.3"]
       ]}
    end
  end

  @impl Plug
  def init(opts) do
    %{
      session_registry: Keyword.get(opts, :session_registry, ClusterSessions),
      identity_opts: Keyword.get(opts, :identity_opts, []),
      websocket_opts: Keyword.get(opts, :websocket_opts, [])
    }
  end

  @impl Plug
  def call(%Plug.Conn{method: "GET", path_info: @connect_path} = conn, opts) do
    with {:ok, identity} <- CertificateIdentity.from_conn(conn, opts.identity_opts),
         false <- ClusterSessions.revoked?(opts.session_registry, identity),
         :ok <- validate_upgrade_request(conn),
         {:ok, session_id} <- ClusterSessions.register(opts.session_registry, identity, self()),
         {:ok, upgraded} <- upgrade(conn, opts, identity, session_id) do
      upgraded
    else
      true -> unauthorized(conn, 403, "client certificate revoked")
      {:error, :revoked} -> unauthorized(conn, 403, "client certificate revoked")
      {:error, :unavailable} -> error(conn, 503, "cluster gateway unavailable")
      {:error, :invalid_websocket_upgrade} -> error(conn, 400, "WebSocket upgrade required")
      {:error, _reason} -> unauthorized(conn, 401, "valid client certificate required")
    end
  end

  def call(conn, _opts), do: error(conn, 404, "not found")

  defp upgrade(conn, opts, identity, session_id) do
    state = %{
      session_registry: opts.session_registry,
      identity: identity,
      session_id: session_id
    }

    try do
      {:ok, Plug.Conn.upgrade_adapter(conn, :websocket, {Socket, state, opts.websocket_opts})}
    rescue
      exception ->
        ClusterSessions.unregister(opts.session_registry, identity, session_id, self())
        {:error, {:upgrade_failed, exception}}
    end
  end

  defp unauthorized(conn, status, message), do: error(conn, status, message)

  defp validate_upgrade_request(conn) do
    with true <- header_token?(conn, "connection", "upgrade"),
         true <- header_token?(conn, "upgrade", "websocket"),
         true <- nonempty_header?(conn, "sec-websocket-key"),
         ["13"] <- Plug.Conn.get_req_header(conn, "sec-websocket-version") do
      :ok
    else
      _other -> {:error, :invalid_websocket_upgrade}
    end
  end

  defp header_token?(conn, name, expected) do
    conn
    |> Plug.Conn.get_req_header(name)
    |> Enum.any?(fn value ->
      value
      |> String.downcase()
      |> String.split(",")
      |> Enum.any?(&(String.trim(&1) == expected))
    end)
  end

  defp nonempty_header?(conn, name) do
    conn
    |> Plug.Conn.get_req_header(name)
    |> Enum.any?(&(String.trim(&1) != ""))
  end

  defp required_tls_option(opts, key) do
    case Keyword.get(opts, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      value when is_list(value) and value != [] -> {:ok, value}
      _other -> {:error, {:missing_tls_option, key}}
    end
  end

  defp error(conn, status, message) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, Jason.encode!(%{"error" => message}))
    |> Plug.Conn.halt()
  end

  defmodule Socket do
    @moduledoc false
    @behaviour WebSock

    alias Exocomp.MissionControl.ClusterSessions

    @impl WebSock
    def init(state) do
      {:push, {:text, Jason.encode!(connected_payload(state))}, state}
    end

    @impl WebSock
    def handle_in({_payload, opcode: opcode}, state) when opcode in [:text, :binary] do
      {:push,
       {:text,
        Jason.encode!(%{
          "type" => "ack",
          "session_id" => state.session_id,
          "organization_id" => state.identity.organization_id,
          "cluster_id" => state.identity.cluster_id
        })}, state}
    end

    @impl WebSock
    def handle_info({:mission_control_session_replaced, _new_session_id}, state),
      do: {:stop, :session_replaced, 4001, state}

    def handle_info(:mission_control_session_revoked, state),
      do: {:stop, :session_revoked, 4003, state}

    def handle_info(_message, state), do: {:ok, state}

    @impl WebSock
    def terminate(_reason, state) do
      ClusterSessions.unregister(
        state.session_registry,
        state.identity,
        state.session_id,
        self()
      )

      :ok
    end

    defp connected_payload(state) do
      %{
        "type" => "connected",
        "session_id" => state.session_id,
        "organization_id" => state.identity.organization_id,
        "cluster_id" => state.identity.cluster_id
      }
    end
  end
end

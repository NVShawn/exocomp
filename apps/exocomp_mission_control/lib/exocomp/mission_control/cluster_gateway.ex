# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ClusterGateway do
  @moduledoc """
  Plug endpoint for `GET /api/v1/clusters/connect`.

  TLS is configured by the Mission Control listener with peer verification
  and `fail_if_no_peer_cert`.  This Plug repeats the certificate-presence and
  identity checks at the application boundary, then upgrades only an
  authenticated request. Incoming payloads are committed and acknowledged only
  through the event ingestor; they never determine organization or cluster
  identity.
  """

  @behaviour Plug

  alias Exocomp.MissionControl.{
    CertificateIdentity,
    ClusterEventIngestor,
    ClusterSessions,
    CommandOutbox
  }

  @connect_path ["api", "v1", "clusters", "connect"]
  @connect_request_path "/api/v1/clusters/connect"

  @doc false
  def session_topic(%{spiffe_id: spiffe_id}) when is_binary(spiffe_id) do
    "mission-control:cluster-session:" <> Base.url_encode64(spiffe_id, padding: false)
  end

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
      event_ingestor: Keyword.get(opts, :event_ingestor, ClusterEventIngestor),
      command_outbox: Keyword.get(opts, :command_outbox, CommandOutbox),
      command_outbox_opts: Keyword.get(opts, :command_outbox_opts, []),
      pubsub: Keyword.get(opts, :pubsub, Exocomp.MissionControl.PubSub),
      identity_opts: Keyword.get(opts, :identity_opts, []),
      websocket_opts: Keyword.get(opts, :websocket_opts, [])
    }
  end

  @impl Plug
  def call(%Plug.Conn{method: "GET"} = conn, opts) do
    if connect_request?(conn) do
      connect(conn, opts)
    else
      error(conn, 404, "not found")
    end
  end

  def call(conn, _opts), do: error(conn, 404, "not found")

  defp connect(conn, opts) do
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

  defp connect_request?(%Plug.Conn{path_info: @connect_path}), do: true

  # Phoenix's `forward` routes the remaining path to the target Plug while
  # retaining `request_path`; accept both forms so direct Plug tests and the
  # mounted production route exercise the same authentication boundary.
  defp connect_request?(%Plug.Conn{request_path: @connect_request_path}), do: true
  defp connect_request?(_conn), do: false

  defp upgrade(conn, opts, identity, session_id) do
    state = %{
      session_registry: opts.session_registry,
      event_ingestor: opts.event_ingestor,
      command_outbox: opts.command_outbox,
      command_outbox_opts: opts.command_outbox_opts,
      pubsub: opts.pubsub,
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

    alias Exocomp.MissionControl.{
      ClusterEvent,
      ClusterEventIngestor,
      ClusterSessions,
      Command,
      CommandOutbox,
      EventIngestionError
    }

    @impl WebSock
    def init(state) do
      subscribe_to_session_owner(state)
      announce_session_owner(state)
      subscribe_to_commands(state)
      request_pending_delivery(state)
      {:push, {:text, Jason.encode!(connected_payload(state))}, state}
    end

    @impl WebSock
    def handle_in({payload, opcode: opcode}, state) when opcode in [:text, :binary] do
      case decode_payload(payload) do
        {:ok, %{"type" => "command_ack", "command_id" => command_id}} ->
          acknowledge_command(command_id, state)

        {:ok, envelope} ->
          case ingest(envelope, state) do
            {:ok, result} ->
              {:push, {:text, Jason.encode!(acknowledgement_payload(state, result))}, state}

            {:error, error} ->
              {:push, {:text, Jason.encode!(rejection_payload(state, error))}, state}
          end

        {:error, error} ->
          {:push, {:text, Jason.encode!(rejection_payload(state, error))}, state}
      end
    end

    @impl WebSock
    def handle_info({:command_outbox, :deliver}, state) do
      request_pending_delivery(state)
      {:ok, state}
    end

    def handle_info(
          {:mission_control_command_outbox_delivery, organization_id, cluster_id},
          state
        ) do
      if current_session?(state, organization_id, cluster_id) do
        socket = self()
        session = %{session_id: state.session_id}

        _ =
          state.command_outbox.deliver_pending(
            organization_id,
            cluster_id,
            session,
            fn command ->
              send(socket, {:mission_control_command, command})
              :ok
            end,
            state.command_outbox_opts
          )
      end

      {:ok, state}
    end

    def handle_info({:mission_control_command, %Command{} = command}, state) do
      {:push, {:text, Jason.encode!(Command.envelope(command))}, state}
    end

    def handle_info(
          {:mission_control_session_owner, spiffe_id, replacement_session_id},
          %{identity: %{spiffe_id: spiffe_id}, session_id: session_id} = state
        ) do
      if replacement_session_id == session_id do
        {:ok, state}
      else
        {:stop, :session_replaced, 4001, state}
      end
    end

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

    defp ingest(envelope, state) do
      with {:ok, result} <-
             ClusterEventIngestor.ingest(
               envelope,
               state.identity,
               Map.get(state, :event_ingestor, ClusterEventIngestor)
             ) do
        {:ok, result}
      end
    end

    defp decode_payload(payload) do
      case Jason.decode(payload) do
        {:ok, envelope} when is_map(envelope) -> {:ok, envelope}
        _other -> {:error, EventIngestionError.new(:invalid_event_schema, "event must be JSON")}
      end
    end

    defp acknowledge_command(command_id, state) when is_binary(command_id) do
      case state.command_outbox.acknowledge(
             state.identity.organization_id,
             state.identity.cluster_id,
             command_id,
             state.command_outbox_opts
           ) do
        {:ok, status} ->
          {:push,
           {:text, Jason.encode!(command_acknowledgement_payload(state, command_id, status))},
           state}

        {:error, reason} ->
          {:push, {:text, Jason.encode!(command_rejection_payload(state, command_id, reason))},
           state}
      end
    end

    defp acknowledge_command(_command_id, state) do
      {:push, {:text, Jason.encode!(command_rejection_payload(state, nil, :invalid_command_id))},
       state}
    end

    defp acknowledgement_payload(state, result) do
      %{
        "type" => "ack",
        "session_id" => state.session_id,
        "organization_id" => state.identity.organization_id,
        "cluster_id" => state.identity.cluster_id,
        "acknowledged_sequence" => result.acknowledgement
      }
    end

    defp rejection_payload(state, %EventIngestionError{} = error) do
      %{
        "type" => "error",
        "session_id" => state.session_id,
        "error" => Atom.to_string(error.code)
      }
    end

    defp rejection_payload(state, _error) do
      %{"type" => "error", "session_id" => state.session_id, "error" => "event_rejected"}
    end

    defp command_acknowledgement_payload(state, command_id, status) do
      %{
        "type" => "command_ack",
        "session_id" => state.session_id,
        "command_id" => command_id,
        "status" => Atom.to_string(status)
      }
    end

    defp command_rejection_payload(state, command_id, reason) do
      %{
        "type" => "command_ack",
        "session_id" => state.session_id,
        "command_id" => command_id,
        "error" => command_acknowledgement_error(reason)
      }
    end

    defp connected_payload(state) do
      %{
        "type" => "connected",
        "session_id" => state.session_id,
        "organization_id" => state.identity.organization_id,
        "cluster_id" => state.identity.cluster_id,
        "schema_version" => ClusterEvent.schema_version()
      }
    end

    defp subscribe_to_commands(%{pubsub: pubsub, identity: identity}) do
      _ =
        Phoenix.PubSub.subscribe(
          pubsub,
          CommandOutbox.topic(identity.organization_id, identity.cluster_id)
        )

      :ok
    rescue
      _exception -> :ok
    end

    defp subscribe_to_commands(_state), do: :ok

    defp subscribe_to_session_owner(%{pubsub: pubsub, identity: identity}) do
      _ = Phoenix.PubSub.subscribe(pubsub, ClusterGateway.session_topic(identity))
      :ok
    rescue
      _exception -> :ok
    end

    defp subscribe_to_session_owner(_state), do: :ok

    defp announce_session_owner(%{pubsub: pubsub, identity: identity, session_id: session_id}) do
      _ =
        Phoenix.PubSub.broadcast(
          pubsub,
          ClusterGateway.session_topic(identity),
          {:mission_control_session_owner, identity.spiffe_id, session_id}
        )

      :ok
    rescue
      _exception -> :ok
    end

    defp announce_session_owner(_state), do: :ok

    defp request_pending_delivery(%{command_outbox: _outbox, identity: identity}) do
      send(
        self(),
        {:mission_control_command_outbox_delivery, identity.organization_id, identity.cluster_id}
      )
    end

    defp request_pending_delivery(_state), do: :ok

    defp current_session?(state, organization_id, cluster_id) do
      with true <- state.identity.organization_id == organization_id,
           true <- state.identity.cluster_id == cluster_id,
           {:ok, %{session_id: session_id}} <-
             ClusterSessions.get(state.session_registry, state.identity) do
        session_id == state.session_id
      else
        _other -> false
      end
    end

    defp command_acknowledgement_error(:expired), do: "expired"
    defp command_acknowledgement_error(:not_found), do: "not_found"
    defp command_acknowledgement_error(_reason), do: "command_ack_rejected"
  end
end

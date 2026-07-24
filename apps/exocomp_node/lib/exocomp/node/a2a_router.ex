defmodule Exocomp.Node.A2ARouter do
  @moduledoc """
  HTTP entry point for the node's A2A 1.0 service.

  Client certificate authentication and protocol-version validation run before
  request parsing so unauthenticated requests cannot cause their bodies to be
  read.
  """

  use Plug.Router, copy_opts_to_assign: :router_opts

  require Logger

  alias Exocomp.A2A.InvalidRequestError
  alias Exocomp.A2A.MethodNotFoundError
  alias Exocomp.A2A.UnsupportedOperationError
  alias Exocomp.Node.Handlers.AgentCardHandler
  alias Exocomp.Node.Plug.JSONBodyParser

  @max_body_length 1_048_576

  plug(:authenticate_mtls)
  plug(:require_a2a_version)

  plug(JSONBodyParser,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason,
    length: @max_body_length,
    pass_assigns: true
  )

  plug(:match)
  plug(:dispatch)

  get "/.well-known/agent-card.json" do
    AgentCardHandler.call(conn, conn.assigns.router_opts)
  end

  post "/message:send" do
    json_response(conn, 202, %{status: "accepted"})
  end

  get "/tasks/:id" do
    json_response(conn, 200, %{id: id})
  end

  get "/tasks" do
    json_response(conn, 200, %{tasks: []})
  end

  post "/tasks/:id" do
    if String.ends_with?(id, ":cancel") do
      task_id = String.trim_trailing(id, ":cancel")
      json_response(conn, 200, %{id: task_id, status: "cancelled"})
    else
      error_response(conn, 404, %MethodNotFoundError{})
    end
  end

  post "/message/stream" do
    error_response(conn, 400, %UnsupportedOperationError{})
  end

  post "/tasks/:id/resubscribe" do
    error_response(conn, 400, %UnsupportedOperationError{})
  end

  match _ do
    error_response(conn, 404, %MethodNotFoundError{})
  end

  defp authenticate_mtls(conn, _opts) do
    case Plug.Conn.get_peer_data(conn) do
      %{ssl_cert: ssl_cert} when is_binary(ssl_cert) and byte_size(ssl_cert) > 0 ->
        Logger.info("[A2ARouter] mTLS client certificate accepted")
        conn

      _peer_data ->
        Logger.warning("[A2ARouter] mTLS client certificate missing")

        conn
        |> error_response(401, %InvalidRequestError{
          message: "Client certificate required"
        })
        |> halt()
    end
  end

  defp require_a2a_version(conn, _opts) do
    case get_req_header(conn, "a2a-version") do
      ["1.0"] ->
        conn

      _other ->
        conn
        |> error_response(400, %InvalidRequestError{
          message: "A2A-Version header must be 1.0"
        })
        |> halt()
    end
  end

  defp error_response(conn, status, error) do
    json_response(conn, status, %{
      jsonrpc: "2.0",
      id: nil,
      error: Map.from_struct(error)
    })
  end

  defp json_response(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end

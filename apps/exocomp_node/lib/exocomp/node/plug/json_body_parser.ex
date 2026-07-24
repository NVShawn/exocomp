defmodule Exocomp.Node.Plug.JSONBodyParser do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn

  @impl Plug
  def init(opts), do: Plug.Parsers.init(opts)

  @impl Plug
  def call(conn, opts) do
    Plug.Parsers.call(conn, opts)
  rescue
    Plug.Parsers.RequestTooLargeError ->
      body = %{
        jsonrpc: "2.0",
        id: nil,
        error: %{code: -32600, message: "Request body too large", data: nil}
      }

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(413, Jason.encode!(body))
      |> halt()
  end
end

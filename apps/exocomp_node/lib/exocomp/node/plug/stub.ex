defmodule Exocomp.Node.Plug.Stub do
  @moduledoc """
  Minimal Plug that returns `200 OK` for every request.

  Used as the Bandit handler during testing and as a health-check endpoint
  before real request routing is implemented.
  """

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    Plug.Conn.send_resp(conn, 200, "OK")
  end
end

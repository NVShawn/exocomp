defmodule Exocomp.Node.A2ARouterTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias Exocomp.Node.A2ARouter

  @opts A2ARouter.init(node_id: "node-7.example")

  defp authenticated_conn(method, path, body \\ nil) do
    method
    |> conn(path, body)
    |> put_peer_data(%{ssl_cert: <<1>>})
    |> put_req_header("a2a-version", "1.0")
  end

  test "agent card contains exactly the diagnostic skills and disables streaming" do
    response =
      :get
      |> authenticated_conn("/.well-known/agent-card.json")
      |> A2ARouter.call(@opts)

    assert response.status == 200
    card = Jason.decode!(response.resp_body)

    assert card["url"] == "https://node-7.example/"
    assert card["capabilities"]["streaming"] == false

    assert Enum.map(card["skills"], & &1["id"]) == [
             "exocomp.system.diagnose",
             "exocomp.service.diagnose",
             "exocomp.remediation.propose"
           ]
  end

  test "request without a client certificate returns 401 before reading the body" do
    conn =
      :post
      |> conn("/message:send", String.duplicate("x", 1_048_577))
      |> put_req_header("a2a-version", "1.0")
      |> A2ARouter.call(@opts)

    assert conn.status == 401
    assert %Plug.Conn.Unfetched{aspect: :body_params} = conn.body_params
  end

  test "missing A2A-Version header returns InvalidRequestError" do
    conn =
      :get
      |> conn("/tasks")
      |> put_peer_data(%{ssl_cert: <<1>>})
      |> A2ARouter.call(@opts)

    assert conn.status == 400
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32600
  end

  test "body over one MiB returns 413" do
    conn =
      :post
      |> authenticated_conn("/message:send", String.duplicate("x", 1_048_577))
      |> put_req_header("content-type", "application/json")
      |> A2ARouter.call(@opts)

    assert conn.status == 413
  end

  test "message streaming returns UnsupportedOperationError" do
    conn =
      :post
      |> authenticated_conn("/message/stream", Jason.encode!(%{}))
      |> put_req_header("content-type", "application/json")
      |> A2ARouter.call(@opts)

    assert conn.status == 400
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32004
  end

  test "unknown route returns MethodNotFoundError" do
    conn =
      :get
      |> authenticated_conn("/not-a-route")
      |> A2ARouter.call(@opts)

    assert conn.status == 404
    assert Jason.decode!(conn.resp_body)["error"]["code"] == -32601
  end
end

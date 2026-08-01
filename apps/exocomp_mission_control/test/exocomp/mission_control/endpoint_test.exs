# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.EndpointTest do
  use ExUnit.Case, async: true

  import Plug.Test

  test "GET /health returns a JSON 200 response" do
    conn =
      :get
      |> conn("/health")
      |> Exocomp.MissionControl.Endpoint.call([])

    assert conn.status == 200
    assert Plug.Conn.get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == ~s({"status":"ok"})
  end

  test "static assets are served by the endpoint" do
    conn =
      :get
      |> conn("/robots.txt")
      |> Exocomp.MissionControl.Endpoint.call([])

    assert conn.status == 200
    assert conn.resp_body == "User-agent: *\nDisallow:\n"
  end
end

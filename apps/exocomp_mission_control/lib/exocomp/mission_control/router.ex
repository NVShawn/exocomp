# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Router do
  @moduledoc false

  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  get "/health" do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, ~s({"status":"ok"}))
  end

  scope "/" do
    pipe_through(:browser)

    live("/incidents", Exocomp.MissionControlWeb.IncidentInboxLive, :index)
    live("/incidents/:id", Exocomp.MissionControlWeb.IncidentDetailLive, :show)
  end
end

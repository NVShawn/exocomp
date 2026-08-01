# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ErrorController do
  @moduledoc false

  use Phoenix.Controller

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_view(html: Exocomp.MissionControl.ErrorHTML)
    |> render("404.html")
  end

  def forbidden(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> put_view(html: Exocomp.MissionControl.ErrorHTML)
    |> render("403.html")
  end

  def health(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"status":"ok"}))
  end
end

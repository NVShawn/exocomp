# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Router do
  @moduledoc false

  use Phoenix.Router

  # credo:disable-for-this-file Credo.Check.Readability.AliasUsage

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {Exocomp.MissionControl.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :require_authenticated do
    plug(:fetch_session)
    plug(:redirect_unauthenticated)
  end

  scope "/", Exocomp.MissionControl do
    pipe_through(:browser)

    get "/health" do
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, ~s({"status":"ok"}))
    end
  end

  scope "/auth", Exocomp.MissionControl do
    pipe_through(:browser)

    get("/login", AuthController, :login)
    get("/callback", AuthController, :callback)
    get("/logout", AuthController, :logout)
  end

  scope "/" do
    pipe_through(:browser)

    live_session :authenticated,
      on_mount: {Exocomp.MissionControl.LiveView.RequireRole, :require_authenticated_or_redirect},
      session: {__MODULE__, :auth_session, []} do
      live("/", Exocomp.MissionControl.DashboardLive.Index, :index)
      live("/incidents", Exocomp.MissionControl.IncidentsLive.Index, :index)
      live("/conversations", Exocomp.MissionControl.ConversationsLive.Index, :index)
      live("/admin", Exocomp.MissionControl.AdminLive.Index, :index)
      live("/admin/invitations", Exocomp.MissionControl.AdminLive.Index, :invitations)
      live("/admin/clusters", Exocomp.MissionControl.AdminLive.Index, :clusters)
      live("/admin/certificates", Exocomp.MissionControl.AdminLive.Index, :clusters)
      live("/admin/role-mappings", Exocomp.MissionControl.AdminLive.Index, :role_mappings)
      live("/admin/oidc-role-mappings", Exocomp.MissionControl.AdminLive.Index, :role_mappings)
      live("/admin/retention", Exocomp.MissionControl.AdminLive.Index, :retention)
      live("/admin/webhooks", Exocomp.MissionControl.AdminLive.Index, :webhooks)
    end
  end

  scope "/forbidden" do
    pipe_through(:browser)

    get("/", Exocomp.MissionControl.ErrorController, :forbidden)
  end

  # Error handlers (must be last)
  match(:*, "/*path", Exocomp.MissionControl.ErrorController, :not_found)

  defp redirect_unauthenticated(conn, _opts) do
    case get_session(conn, :operator_id) do
      nil ->
        conn
        |> Phoenix.Controller.redirect(to: "/auth/login")
        |> Plug.Conn.halt()

      _ ->
        conn
    end
  end

  def auth_session(conn, _opts) do
    operator_id = get_session(conn, :operator_id)
    operator_role = get_session(conn, :operator_role)
    organization_id = get_session(conn, :organization_id)
    operator_name = get_session(conn, :operator_name)

    %{
      "operator_id" => operator_id,
      "operator_role" => operator_role,
      "organization_id" => organization_id,
      "operator_name" => operator_name
    }
  end
end

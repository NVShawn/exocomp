# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Router do
  @moduledoc false

  use Phoenix.Router
  import Phoenix.LiveView.Router

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

  scope "/", Exocomp.MissionControl do
    pipe_through(:browser)

    # OIDC Authentication routes
    get("/auth/login", AuthController, :login)
    get("/auth/callback", AuthController, :callback)
    get("/auth/logout", AuthController, :logout)
    post("/auth/logout", AuthController, :logout)

    # Error pages
    get("/forbidden", ErrorController, :forbidden)
  end

  scope "/", Exocomp.MissionControl do
    pipe_through(:api)

    get("/health", HealthController, :health)
  end

  # Protected LiveView routes — require authentication and at minimum viewer role
  scope "/", Exocomp.MissionControl do
    pipe_through(:browser)

    live_session :authenticated,
      on_mount: [
        {Exocomp.MissionControl.LiveView.RequireRole, :authenticate}
      ] do
      live("/", DashboardLive.Index, :index)
      live("/incidents", IncidentsLive.Index, :index)
    end

    live_session :operator,
      on_mount: [
        {Exocomp.MissionControl.LiveView.RequireRole, :authenticate},
        {Exocomp.MissionControl.LiveView.RequireRole, :operate}
      ] do
      live("/conversations", ConversationsLive.Index, :index)
    end

    live_session :admin,
      on_mount: [
        {Exocomp.MissionControl.LiveView.RequireRole, :authenticate},
        {Exocomp.MissionControl.LiveView.RequireRole, :administer}
      ] do
      live("/admin", AdminLive.Index, :index)
    end
  end

  # Catch-all: return 404 for unmatched routes
  scope "/", Exocomp.MissionControl do
    pipe_through(:browser)
    match(:*, "/*path", ErrorController, :not_found)
  end
end

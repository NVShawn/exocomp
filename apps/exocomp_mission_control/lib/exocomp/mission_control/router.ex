# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
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

    # Protected routes
    live("/", DashboardLive.Index)
  end

  # API routes (if needed in future)
  scope "/api/v1", Exocomp.MissionControl do
    pipe_through(:api)
  end
end

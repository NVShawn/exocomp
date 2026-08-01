# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule ExocompMissionControlWeb.Router do
  use Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_user_session)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", ExocompMissionControlWeb do
    pipe_through(:browser)

    live("/proposals/:proposal_id", ProposalLive, :show)
  end

  # Enable LiveDashboard in development
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: ExocompMissionControlWeb.Telemetry)
    end
  end

  # ── Private Helpers ──────────────────────────────────────────────────

  defp put_user_session(conn, _opts) do
    # In a real implementation, this would extract user info from OIDC session
    Plug.Conn.put_session(conn, :user_role, :viewer)
  end
end

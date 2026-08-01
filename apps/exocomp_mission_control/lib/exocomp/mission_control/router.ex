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

    get("/health", ErrorController, :health)
  end

  scope "/auth", Exocomp.MissionControl do
    pipe_through(:browser)

    get("/login", AuthController, :login)
    get("/callback", AuthController, :callback)
    get("/logout", AuthController, :logout)
  end

  scope "/forbidden", Exocomp.MissionControl do
    pipe_through(:browser)

    get("/", ErrorController, :forbidden)
  end

  scope "/" do
    pipe_through(:browser)

    # Placeholder for LiveView routes - will be configured with proper live_session in future
    get("/", Exocomp.MissionControl.ErrorController, :not_found)
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

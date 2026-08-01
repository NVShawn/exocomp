# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Plug.RequireRole do
  @moduledoc """
  Plug for enforcing role-based access control on routes.

  Redirects unauthenticated users to /auth/login.
  Returns 403 Forbidden for authenticated users lacking required role.
  """

  import Plug.Conn
  require Logger

  alias Phoenix.Controller

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    operator_id = get_session(conn, :operator_id)
    operator_role = get_session(conn, :operator_role)

    case {operator_id, operator_role} do
      {nil, _} ->
        conn
        |> put_session(:redirect_after_login, conn.request_path)
        |> redirect(to: "/auth/login")
        |> halt()

      {_, nil} ->
        Logger.warning("Operator #{operator_id} has nil role")
        forbidden(conn)

      {_, role} ->
        minimum_role = Keyword.get(opts, :role, :viewer)

        if has_required_role?(role, minimum_role) do
          conn
        else
          Logger.warning(
            "Operator #{operator_id} with role #{role} denied access to #{conn.request_path}"
          )

          forbidden(conn)
        end
    end
  end

  defp forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> Phoenix.Controller.put_view(Exocomp.MissionControl.ErrorHTML)
    |> Phoenix.Controller.render("403.html")
    |> halt()
  end

  defp has_required_role?(role, minimum) do
    role_index(role) >= role_index(minimum)
  end

  defp role_index(:viewer), do: 0
  defp role_index(:operator), do: 1
  defp role_index(:admin), do: 2
  defp role_index(_), do: -1
end

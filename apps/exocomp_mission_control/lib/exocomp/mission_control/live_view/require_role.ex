# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.LiveView.RequireRole do
  @moduledoc """
  LiveView hook for enforcing role-based access control.

  Use in LiveView mounts:

      def mount(_params, session, socket) do
        {:ok, socket}
        |> RequireRole.require_operator_or_redirect(session)
      end

  Or to require admin:

      def mount(_params, session, socket) do
        {:ok, socket}
        |> RequireRole.require_admin_or_redirect(session)
      end
  """

  alias Exocomp.MissionControl.Identity.Operator

  def require_authenticated_or_redirect({:ok, socket}, session) do
    case get_operator_from_session(session) do
      nil -> {:redirect, to: "/auth/login"}
      operator -> {:ok, Phoenix.Component.assign(socket, :operator, operator)}
    end
  end

  def require_authenticated_or_redirect({:error, _} = err, _session), do: err

  def require_viewer_or_redirect({:ok, socket}, session) do
    case get_operator_from_session(session) do
      nil ->
        {:redirect, to: "/auth/login"}

      %Operator{} = operator ->
        if Operator.has_role_at_least?(operator, :viewer) do
          {:ok, Phoenix.Component.assign(socket, :operator, operator)}
        else
          {:redirect, to: "/forbidden"}
        end
    end
  end

  def require_viewer_or_redirect({:error, _} = err, _session), do: err

  def require_operator_or_redirect({:ok, socket}, session) do
    case get_operator_from_session(session) do
      nil ->
        {:redirect, to: "/auth/login"}

      %Operator{} = operator ->
        if Operator.has_role_at_least?(operator, :operator) do
          {:ok, Phoenix.Component.assign(socket, :operator, operator)}
        else
          {:redirect, to: "/forbidden"}
        end
    end
  end

  def require_operator_or_redirect({:error, _} = err, _session), do: err

  def require_admin_or_redirect({:ok, socket}, session) do
    case get_operator_from_session(session) do
      nil ->
        {:redirect, to: "/auth/login"}

      %Operator{} = operator ->
        if Operator.has_role_at_least?(operator, :admin) do
          {:ok, Phoenix.Component.assign(socket, :operator, operator)}
        else
          {:redirect, to: "/forbidden"}
        end
    end
  end

  def require_admin_or_redirect({:error, _} = err, _session), do: err

  defp get_operator_from_session(session) do
    with operator_id when is_binary(operator_id) <- session["operator_id"],
         operator_role when is_atom(operator_role) <- session["operator_role"],
         organization_id when is_binary(organization_id) <- session["organization_id"] do
      %Operator{
        sub: operator_id,
        organization_id: organization_id,
        role: operator_role,
        display_name: session["operator_name"]
      }
    else
      _ -> nil
    end
  end
end

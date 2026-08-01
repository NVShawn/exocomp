# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControlWeb.IncidentLiveSupport do
  @moduledoc false

  @topic_prefix "incidents:"

  @spec user(map()) :: %{subject: String.t(), organization_id: String.t(), role: atom()} | nil
  def user(session) when is_map(session) do
    session
    |> Map.get("current_user", Map.get(session, :current_user, Map.get(session, "user")))
    |> normalize_user()
  end

  def user(_session), do: nil

  @spec topic(String.t()) :: String.t()
  def topic(organization_id), do: @topic_prefix <> organization_id

  @spec incidents_server() :: GenServer.server()
  def incidents_server do
    Application.get_env(
      :exocomp_mission_control,
      :incidents_server,
      Exocomp.MissionControl.Incidents
    )
  end

  @spec operator?(map()) :: boolean()
  def operator?(%{role: role}), do: role in [:operator, :admin]
  def operator?(_user), do: false

  @spec role_name(atom()) :: String.t()
  def role_name(role), do: Atom.to_string(role)

  @spec format_time(DateTime.t() | nil) :: String.t()
  def format_time(%DateTime{} = value), do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%S UTC")
  def format_time(_value), do: "—"

  defp normalize_user(user) when is_map(user) do
    organization_id = Map.get(user, :organization_id, Map.get(user, "organization_id"))

    subject =
      Map.get(
        user,
        :subject,
        Map.get(user, "subject", Map.get(user, :email, Map.get(user, "email")))
      )

    role = Map.get(user, :role, Map.get(user, "role", :viewer))

    with organization_id when is_binary(organization_id) and byte_size(organization_id) > 0 <-
           organization_id,
         subject when is_binary(subject) and byte_size(subject) > 0 <- subject,
         role when role in [:viewer, :operator, :admin, "viewer", "operator", "admin"] <- role do
      %{subject: subject, organization_id: organization_id, role: normalize_role(role)}
    else
      _ -> nil
    end
  end

  defp normalize_user(_user), do: nil

  defp normalize_role(role) when is_atom(role), do: role
  defp normalize_role(role), do: String.to_existing_atom(role)
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.IncidentsLive.Index do
  @moduledoc false

  use Phoenix.LiveView
  alias Exocomp.MissionControl.LiveView.RequireRole

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket}
    |> RequireRole.require_authenticated_or_redirect(session)
    |> case do
      {:ok, socket} ->
        {:ok, assign(socket, :page_title, "Incidents")}

      {:redirect, _} = redirect ->
        redirect
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900">Incidents</h2>
      <p class="text-gray-600">No incidents at this time</p>
    </div>
    """
  end
end

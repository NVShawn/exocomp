# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.IncidentsLive.Index do
  @moduledoc """
  Incidents LiveView — shows open incidents for authenticated viewers.

  Authorization is handled at the router level via live_session on_mount hooks.
  The `current_operator` assign is set by the RequireRole authenticate hook.
  """

  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Incidents")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Incidents</h2>
        <p class="text-gray-600 mt-1">Track and manage active incidents</p>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <p class="text-gray-600">No open incidents at this time</p>
      </div>
    </div>
    """
  end
end

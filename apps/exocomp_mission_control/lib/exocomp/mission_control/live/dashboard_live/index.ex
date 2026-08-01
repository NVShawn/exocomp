# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.DashboardLive.Index do
  @moduledoc """
  Dashboard LiveView showing fleet overview for authenticated operators.
  """

  use Phoenix.LiveView
  alias Exocomp.MissionControl.LiveView.RequireRole

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket}
    |> RequireRole.require_authenticated_or_redirect(session)
    |> case do
      {:ok, socket} ->
        {:ok,
         socket
         |> assign(:page_title, "Fleet Overview")
         |> put_flash(:info, "Welcome to Mission Control")}

      {:redirect, _} = redirect ->
        redirect
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Fleet Overview</h2>
        <p class="text-gray-600 mt-1">Monitor your Exocomp clusters and nodes</p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-gray-600 text-sm font-medium">Clusters</h3>
          <p class="text-3xl font-bold text-gray-900 mt-2">0</p>
          <p class="text-gray-500 text-sm mt-1">Connected</p>
        </div>

        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-gray-600 text-sm font-medium">Nodes</h3>
          <p class="text-3xl font-bold text-gray-900 mt-2">0</p>
          <p class="text-gray-500 text-sm mt-1">Total</p>
        </div>

        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-gray-600 text-sm font-medium">Incidents</h3>
          <p class="text-3xl font-bold text-gray-900 mt-2">0</p>
          <p class="text-gray-500 text-sm mt-1">Open</p>
        </div>

        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-gray-600 text-sm font-medium">Health</h3>
          <p class="text-3xl font-bold text-green-600 mt-2">OK</p>
          <p class="text-gray-500 text-sm mt-1">Overall</p>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-gray-900">Cluster List</h3>
        <p class="text-gray-600 mt-2">No clusters connected yet</p>
      </div>
    </div>
    """
  end
end

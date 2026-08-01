# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AdminLive.Index do
  @moduledoc """
  Administration LiveView — admin-only configuration and management.

  Authorization is handled at the router level via live_session on_mount hooks.
  The `current_operator` assign is set by the RequireRole authenticate hook
  and the admin role is enforced by the RequireRole :administer hook.
  """

  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Administration")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Administration</h2>
        <p class="text-gray-600 mt-1">Configure clusters, webhooks, and OIDC role mappings</p>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <p class="text-gray-600">Admin features coming soon</p>
      </div>
    </div>
    """
  end
end

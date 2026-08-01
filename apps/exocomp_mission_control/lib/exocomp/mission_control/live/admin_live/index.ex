# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AdminLive.Index do
  @moduledoc false

  use Phoenix.LiveView
  alias Exocomp.MissionControl.LiveView.RequireRole

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket}
    |> RequireRole.require_admin_or_redirect(session)
    |> case do
      {:ok, socket} ->
        {:ok, assign(socket, :page_title, "Administration")}

      {:redirect, _} = redirect ->
        redirect
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900">Administration</h2>
      <p class="text-gray-600">Admin features coming soon</p>
    </div>
    """
  end
end

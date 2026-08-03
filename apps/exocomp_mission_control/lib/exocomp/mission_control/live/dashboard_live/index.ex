# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.DashboardLive.Index do
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Mission Control Dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container">
      <h1>Mission Control</h1>
      <p>Welcome to Exocomp Mission Control</p>
    </div>
    """
  end
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Components do
  @moduledoc """
  Reusable components for Mission Control UI.

  Includes navigation, badges, status indicators, and common UI patterns.
  """

  use Phoenix.Component

  alias Exocomp.MissionControl.Identity.Operator

  @doc """
  Renders the main navigation bar based on operator role.

  Shows different menu items depending on the operator's role:
  - Viewer: Fleet, Incidents
  - Operator: Fleet, Incidents, Conversations
  - Admin: Fleet, Incidents, Conversations, Admin
  """
  attr(:operator, Operator, required: true)

  def navigation(assigns) do
    ~H"""
    <nav class="flex items-center gap-6">
      <a href="/" class="text-gray-700 hover:text-gray-900 font-medium">Fleet</a>
      <a href="/incidents" class="text-gray-700 hover:text-gray-900 font-medium">Incidents</a>

      <%= if Operator.has_role_at_least?(@operator, :operator) do %>
        <a href="/conversations" class="text-gray-700 hover:text-gray-900 font-medium">Conversations</a>
      <% end %>

      <%= if Operator.has_role_at_least?(@operator, :admin) do %>
        <a href="/admin" class="text-gray-700 hover:text-gray-900 font-medium">Admin</a>
      <% end %>
    </nav>
    """
  end

  @doc """
  Renders a role badge with role-specific styling.

  Displays the operator's role with appropriate visual styling:
  - Viewer: Blue background
  - Operator: Orange background
  - Admin: Red background
  """
  attr(:role, Operator.role(), required: true)

  def role_badge(%{role: role} = assigns) do
    {bg_class, text} =
      case role do
        :viewer -> {"bg-blue-100 text-blue-800", "Viewer"}
        :operator -> {"bg-orange-100 text-orange-800", "Operator"}
        :admin -> {"bg-red-100 text-red-800", "Admin"}
        _ -> {"bg-gray-100 text-gray-800", "Unknown"}
      end

    assigns =
      assigns
      |> assign(:bg_class, bg_class)
      |> assign(:text, text)

    ~H"""
    <span class={["inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium", @bg_class]} title="User role">
      <%= @text %>
    </span>
    """
  end

  @doc """
  Renders flash messages with appropriate styling.

  Displays success, error, and info messages from the flash map.
  """
  attr(:flash, :map, required: true)

  def flash_messages(%{flash: flash} = assigns) do
    ~H"""
    <div id="flash-messages" class="space-y-4" role="region" aria-live="polite" aria-atomic="true">
      <%= if flash["info"] do %>
        <div class="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-3 rounded" role="alert">
          <p class="font-medium">ℹ <%= flash["info"] %></p>
        </div>
      <% end %>

      <%= if flash["success"] do %>
        <div class="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded" role="alert">
          <p class="font-medium">✓ <%= flash["success"] %></p>
        </div>
      <% end %>

      <%= if flash["error"] do %>
        <div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded" role="alert">
          <p class="font-medium">✕ <%= flash["error"] %></p>
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a connectivity indicator showing cluster connection status.

  Displays the connection state with visual styling:
  - Connected: Green
  - Disconnected: Gray
  - Reconnecting: Yellow
  """
  attr(:status, :atom, required: true, values: [:connected, :disconnected, :reconnecting])
  attr(:last_seen_at, :any, default: nil)

  def connectivity_indicator(%{status: status} = assigns) do
    {color, icon} =
      case status do
        :connected -> {"text-green-600", "●"}
        :disconnected -> {"text-gray-400", "●"}
        :reconnecting -> {"text-yellow-600", "◐"}
      end

    assigns =
      assigns
      |> assign(:color, color)
      |> assign(:icon, icon)

    ~H"""
    <span class={["flex items-center gap-2", @color]} title={"Cluster is #{@status}"}>
      <span class="text-lg"><%= @icon %></span>
      <span class="text-sm font-medium capitalize"><%= @status %></span>
    </span>
    """
  end

  @doc """
  Renders a health status indicator.

  Shows the health state of a cluster or node with appropriate styling:
  - Healthy: Green
  - Degraded: Orange
  - Unhealthy: Red
  """
  attr(:status, :atom, required: true, values: [:healthy, :degraded, :unhealthy, :unknown])

  def health_indicator(%{status: status} = assigns) do
    {bg_class, text} =
      case status do
        :healthy -> {"bg-green-100 text-green-800", "Healthy"}
        :degraded -> {"bg-yellow-100 text-yellow-800", "Degraded"}
        :unhealthy -> {"bg-red-100 text-red-800", "Unhealthy"}
        :unknown -> {"bg-gray-100 text-gray-800", "Unknown"}
      end

    assigns =
      assigns
      |> assign(:bg_class, bg_class)
      |> assign(:text, text)

    ~H"""
    <span class={["inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium", @bg_class]}>
      <%= @text %>
    </span>
    """
  end

  @doc """
  Renders a formatted timestamp with human-readable relative time.
  """
  attr(:datetime, :any, required: true)

  def timestamp(%{datetime: datetime} = assigns) do
    formatted =
      case datetime do
        %DateTime{} -> DateTime.to_iso8601(datetime)
        %NaiveDateTime{} -> NaiveDateTime.to_iso8601(datetime)
        nil -> "Never"
        _ -> to_string(datetime)
      end

    assigns = assign(assigns, :formatted, formatted)

    ~H"""
    <time datetime={@formatted} class="text-sm text-gray-600" title={@formatted}>
      <%= @formatted %>
    </time>
    """
  end

  @doc """
  Renders an empty state message.

  Shows a message when there is no data to display.
  """
  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:icon, :string, default: "○")

  def empty_state(%{title: title, description: description} = assigns) do
    ~H"""
    <div class="text-center py-12">
      <p class="text-4xl mb-4"><%= @icon %></p>
      <h3 class="text-lg font-medium text-gray-900"><%= @title %></h3>
      <p class="text-gray-500 mt-1"><%= @description %></p>
    </div>
    """
  end

  @doc """
  Renders a loading state skeleton.

  Shows a loading placeholder while content is being fetched.
  """
  attr(:count, :integer, default: 3)
  attr(:type, :atom, default: :list, values: [:list, :card, :text])

  def loading_skeleton(%{type: :list} = assigns) do
    ~H"""
    <div class="space-y-4">
      <%= for _ <- 1..@count do %>
        <div class="bg-gray-200 h-12 rounded animate-pulse"></div>
      <% end %>
    </div>
    """
  end

  def loading_skeleton(%{type: :card} = assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <%= for _ <- 1..@count do %>
        <div class="bg-gray-200 rounded-lg p-6 h-40 animate-pulse"></div>
      <% end %>
    </div>
    """
  end

  def loading_skeleton(%{type: :text} = assigns) do
    ~H"""
    <div class="space-y-2">
      <div class="bg-gray-200 h-4 rounded w-3/4 animate-pulse"></div>
      <div class="bg-gray-200 h-4 rounded w-1/2 animate-pulse"></div>
    </div>
    """
  end
end

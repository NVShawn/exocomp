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
    <nav class="flex items-center gap-6" role="navigation" aria-label="Primary navigation">
      <a href="/" 
         class="text-gray-700 hover:text-gray-900 hover:bg-gray-100 font-medium py-2 px-3 rounded transition-colors"
         aria-label="Fleet overview">
        Fleet
      </a>
      <a href="/incidents" 
         class="text-gray-700 hover:text-gray-900 hover:bg-gray-100 font-medium py-2 px-3 rounded transition-colors"
         aria-label="Incidents">
        Incidents
      </a>

      <%= if Operator.has_role_at_least?(@operator, :operator) do %>
        <a href="/conversations" 
           class="text-gray-700 hover:text-gray-900 hover:bg-gray-100 font-medium py-2 px-3 rounded transition-colors"
           aria-label="Conversations">
          Conversations
        </a>
      <% end %>

      <%= if Operator.has_role_at_least?(@operator, :admin) do %>
        <a href="/admin" 
           class="text-gray-700 hover:text-gray-900 hover:bg-gray-100 font-medium py-2 px-3 rounded transition-colors"
           aria-label="Administration panel">
          Admin
        </a>
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
    {bg_class, text, aria_label} =
      case role do
        :viewer ->
          {"bg-blue-100 text-blue-800", "Viewer", "Your role: Viewer (read-only access)"}

        :operator ->
          {"bg-orange-100 text-orange-800", "Operator",
           "Your role: Operator (operational permissions)"}

        :admin ->
          {"bg-red-100 text-red-800", "Admin", "Your role: Administrator (full permissions)"}

        _ ->
          {"bg-gray-100 text-gray-800", "Unknown", "Role: Unknown"}
      end

    assigns =
      assigns
      |> assign(:bg_class, bg_class)
      |> assign(:text, text)
      |> assign(:aria_label, aria_label)

    ~H"""
    <span class={["inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium", @bg_class]} 
          role="status"
          aria-label={@aria_label}
          title={@aria_label}>
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
    <div id="flash-messages" class="space-y-4" role="region" aria-live="polite" aria-atomic="true" aria-label="Notifications">
      <%= if flash["info"] do %>
        <div class="bg-blue-50 border-l-4 border-blue-400 text-blue-800 px-4 py-3 rounded shadow-sm" role="status" aria-live="assertive">
          <p class="font-medium flex items-center gap-2">
            <span class="text-lg">ℹ</span>
            <%= flash["info"] %>
          </p>
        </div>
      <% end %>

      <%= if flash["success"] do %>
        <div class="bg-green-50 border-l-4 border-green-400 text-green-800 px-4 py-3 rounded shadow-sm" role="status" aria-live="assertive">
          <p class="font-medium flex items-center gap-2">
            <span class="text-lg">✓</span>
            <%= flash["success"] %>
          </p>
        </div>
      <% end %>

      <%= if flash["error"] do %>
        <div class="bg-red-50 border-l-4 border-red-400 text-red-800 px-4 py-3 rounded shadow-sm" role="alert" aria-live="assertive">
          <p class="font-medium flex items-center gap-2">
            <span class="text-lg">✕</span>
            <%= flash["error"] %>
          </p>
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
    <div class="text-center py-12" role="status" aria-label="No data available">
      <p class="text-4xl mb-4" aria-hidden="true"><%= @icon %></p>
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
    <div class="space-y-4" role="status" aria-label="Loading content...">
      <%= for _ <- 1..@count do %>
        <div class="bg-gray-200 h-12 rounded animate-pulse"></div>
      <% end %>
    </div>
    """
  end

  def loading_skeleton(%{type: :card} = assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4" role="status" aria-label="Loading content...">
      <%= for _ <- 1..@count do %>
        <div class="bg-gray-200 rounded-lg p-6 h-40 animate-pulse"></div>
      <% end %>
    </div>
    """
  end

  def loading_skeleton(%{type: :text} = assigns) do
    ~H"""
    <div class="space-y-2" role="status" aria-label="Loading content...">
      <div class="bg-gray-200 h-4 rounded w-3/4 animate-pulse"></div>
      <div class="bg-gray-200 h-4 rounded w-1/2 animate-pulse"></div>
    </div>
    """
  end

  @doc """
  Renders a severity indicator for alerts and issues.

  Shows severity level with appropriate visual styling:
  - Critical: Red
  - High: Orange
  - Medium: Yellow
  - Low: Blue
  - Info: Gray
  """
  attr(:level, :atom, required: true, values: [:critical, :high, :medium, :low, :info])
  attr(:label, :string, default: nil)

  def severity_indicator(%{level: level} = assigns) do
    {bg_class, text, aria_label} =
      case level do
        :critical -> {"bg-red-100 text-red-800", "Critical", "Critical severity"}
        :high -> {"bg-orange-100 text-orange-800", "High", "High severity"}
        :medium -> {"bg-yellow-100 text-yellow-800", "Medium", "Medium severity"}
        :low -> {"bg-blue-100 text-blue-800", "Low", "Low severity"}
        :info -> {"bg-gray-100 text-gray-800", "Info", "Informational"}
      end

    assigns =
      assigns
      |> assign(:bg_class, bg_class)
      |> assign(:text, assigns[:label] || text)
      |> assign(:aria_label, aria_label)

    ~H"""
    <span class={["inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium", @bg_class]} 
          role="status"
          aria-label={@aria_label}>
      <%= @text %>
    </span>
    """
  end

  @doc """
  Renders a status badge for various operational states.

  Shows operational status with appropriate visual styling:
  - Active: Green
  - Pending: Yellow
  - Failed: Red
  - Inactive: Gray
  """
  attr(:status, :atom, required: true, values: [:active, :pending, :failed, :inactive])
  attr(:label, :string, default: nil)

  def status_badge(%{status: status} = assigns) do
    {bg_class, text, aria_label} =
      case status do
        :active -> {"bg-green-100 text-green-800", "Active", "Status is active"}
        :pending -> {"bg-yellow-100 text-yellow-800", "Pending", "Status is pending"}
        :failed -> {"bg-red-100 text-red-800", "Failed", "Status is failed"}
        :inactive -> {"bg-gray-100 text-gray-800", "Inactive", "Status is inactive"}
      end

    assigns =
      assigns
      |> assign(:bg_class, bg_class)
      |> assign(:text, assigns[:label] || text)
      |> assign(:aria_label, aria_label)

    ~H"""
    <span class={["inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium", @bg_class]} 
          role="status"
          aria-label={@aria_label}>
      <%= @text %>
    </span>
    """
  end

  @doc """
  Renders an error state message with recovery options.

  Shows an error message with optional recovery actions.
  """
  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:action_label, :string, default: nil)
  attr(:action_path, :string, default: nil)

  def error_state(%{title: title, description: description} = assigns) do
    ~H"""
    <div class="border border-red-200 bg-red-50 rounded-lg p-8" role="alert">
      <h3 class="text-lg font-semibold text-red-800"><%= @title %></h3>
      <p class="text-red-700 mt-2"><%= @description %></p>
      <%= if @action_label and @action_path do %>
        <a href={@action_path} class="mt-4 inline-block px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700">
          <%= @action_label %>
        </a>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a status timeline for tracking history.

  Shows a list of timestamped status changes.
  """
  attr(:events, :list, required: true)

  def status_timeline(%{events: events} = assigns) do
    assigns = assign(assigns, :events, events)

    ~H"""
    <div class="flow-root" role="region" aria-label="Status timeline">
      <ul class="divide-y divide-gray-200">
        <%= for {event, index} <- Enum.with_index(@events) do %>
          <li class="py-6">
            <div class="flex flex-col">
              <span class="text-sm font-medium text-gray-900">
                <%= event.title %>
              </span>
              <span class="text-sm text-gray-600">
                <%= event.description %>
              </span>
              <time class="text-xs text-gray-400 mt-1" datetime={event.timestamp}>
                <%= event.timestamp %>
              </time>
            </div>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  @doc """
  Renders a data display row with label and value.

  Shows a key-value pair with consistent styling for data tables.
  """
  attr(:label, :string, required: true)
  attr(:value, :string, required: true)
  attr(:monospace, :boolean, default: false)

  def data_row(%{label: label, value: value} = assigns) do
    ~H"""
    <div class="grid grid-cols-3 gap-4 py-3 border-b border-gray-200">
      <dt class="text-sm font-medium text-gray-900"><%= @label %></dt>
      <dd class={["text-sm text-gray-700 col-span-2", @monospace && "font-mono text-xs"]}>
        <%= @value %>
      </dd>
    </div>
    """
  end

  @doc """
  Renders a skip to main content link for keyboard accessibility.

  Provides keyboard navigation to skip navigation menus.
  """
  def skip_to_main_link(assigns) do
    ~H"""
    <a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-0 focus:left-0 focus:z-50 focus:bg-blue-600 focus:text-white focus:px-4 focus:py-2">
      Skip to main content
    </a>
    """
  end
end

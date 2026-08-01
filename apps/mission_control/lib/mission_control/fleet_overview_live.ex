# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule MissionControl.FleetOverviewLive.Index do
  use Phoenix.LiveView

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fleet-overview">
      <div class="fleet-header">
        <h1>Fleet Overview</h1>
        <div class="fleet-controls">
          <div class="organization-filter">
            <label for="org-select">Organization:</label>
            <select
              id="org-select"
              name="organization_id"
              phx-change="change_organization"
              value={@selected_organization_id}
            >
              <option value="">All Organizations</option>
              <%= for org <- @organizations do %>
                <option value={org.id}><%= org.name %></option>
              <% end %>
            </select>
          </div>
          <div class="sort-controls">
            <label for="sort-select">Sort by:</label>
            <select
              id="sort-select"
              name="sort_field"
              phx-change="change_sort"
              value={@sort_field}
            >
              <option value="name">Name</option>
              <option value="last_contact">Last Contact</option>
              <option value="health">Health Status</option>
              <option value="connectivity">Connectivity</option>
            </select>
          </div>
        </div>
      </div>

      <div class="fleet-stats">
        <div class="stat-card">
          <span class="stat-label">Connected Clusters</span>
          <span class="stat-value"><%= @connected_count %></span>
        </div>
        <div class="stat-card">
          <span class="stat-label">Total Clusters</span>
          <span class="stat-value"><%= @total_count %></span>
        </div>
        <div class="stat-card">
          <span class="stat-label">Healthy Clusters</span>
          <span class="stat-value"><%= @healthy_count %></span>
        </div>
        <div class="stat-card">
          <span class="stat-label">Open Incidents</span>
          <span class="stat-value"><%= @incident_count %></span>
        </div>
      </div>

      <div class="fleet-table-container">
        <table class="fleet-table">
          <thead>
            <tr>
              <th>Cluster Name</th>
              <th>Connectivity</th>
              <th>Health</th>
              <th>Nodes</th>
              <th>Version</th>
              <th>Labels</th>
              <th>Last Contact</th>
              <th>Open Incidents</th>
            </tr>
          </thead>
          <tbody>
            <%= if @loading do %>
              <tr class="loading-row">
                <td colspan="8">Loading clusters...</td>
              </tr>
            <% else %>
              <%= cond do %>
                <% Enum.empty?(@clusters) -> %>
                  <tr class="empty-row">
                    <td colspan="8">No clusters found</td>
                  </tr>
                <% @error -> %>
                  <tr class="error-row">
                    <td colspan="8">Error loading clusters: <%= @error %></td>
                  </tr>
                <% true -> %>
                  <%= for cluster <- @clusters do %>
                    <tr class={"cluster-row #{connectivity_class(cluster)}"} id={"cluster-#{cluster.id}"}>
                      <td class="cluster-name"><%= cluster.name %></td>
                      <td class="connectivity">
                        <span class={"badge connectivity-#{cluster.connectivity}"}>
                          <%= format_connectivity(cluster.connectivity) %>
                        </span>
                      </td>
                      <td class="health">
                        <span class={"badge health-#{cluster.health_status}"}>
                          <%= format_health(cluster.health_status) %>
                        </span>
                      </td>
                      <td class="node-count"><%= cluster.node_count %></td>
                      <td class="version"><%= cluster.version %></td>
                      <td class="labels">
                        <%= for label <- cluster.labels || [] do %>
                          <span class="label-badge"><%= label %></span>
                        <% end %>
                      </td>
                      <td class="last-contact">
                        <%= format_last_contact(cluster.last_contact) %>
                      </td>
                      <td class="incident-count"><%= cluster.open_incident_count %></td>
                    </tr>
                  <% end %>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"organization_id" => org_id}, _session, socket) do
    organization_id = if org_id == "", do: nil, else: org_id

    socket =
      socket
      |> assign(:selected_organization_id, organization_id || "")
      |> assign(:sort_field, "name")
      |> assign(:sort_order, :asc)
      |> assign(:loading, true)
      |> assign(:error, nil)
      |> assign(:clusters, [])
      |> assign(:organizations, [])
      |> assign(:connected_count, 0)
      |> assign(:total_count, 0)
      |> assign(:healthy_count, 0)
      |> assign(:incident_count, 0)

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:selected_organization_id, "")
      |> assign(:sort_field, "name")
      |> assign(:sort_order, :asc)
      |> assign(:loading, true)
      |> assign(:error, nil)
      |> assign(:clusters, [])
      |> assign(:organizations, [])
      |> assign(:connected_count, 0)
      |> assign(:total_count, 0)
      |> assign(:healthy_count, 0)
      |> assign(:incident_count, 0)

    {:ok, socket}
  end

  def handle_mount(:default, _params, socket) do
    if connected?(socket) do
      # Subscribe to cluster updates
      :ok = Phoenix.PubSub.subscribe(MissionControl.PubSub, "clusters:all")

      # Subscribe to organization-scoped cluster updates if organization is selected
      if socket.assigns.selected_organization_id != "" do
        org_id = socket.assigns.selected_organization_id
        :ok = Phoenix.PubSub.subscribe(MissionControl.PubSub, "clusters:org:#{org_id}")
      end

      # Load initial data
      load_clusters(socket)
    else
      {:cont, socket}
    end
  end

  @impl true
  def handle_event("change_organization", %{"organization_id" => org_id}, socket) do
    organization_id = if org_id == "", do: nil, else: org_id

    # Unsubscribe from previous organization updates
    if socket.assigns.selected_organization_id != "" do
      Phoenix.PubSub.unsubscribe(
        MissionControl.PubSub,
        "clusters:org:#{socket.assigns.selected_organization_id}"
      )
    end

    # Subscribe to new organization updates
    if organization_id do
      :ok = Phoenix.PubSub.subscribe(MissionControl.PubSub, "clusters:org:#{organization_id}")
    end

    socket = assign(socket, :selected_organization_id, org_id)
    {:noreply, load_clusters(socket)}
  end

  def handle_event("change_sort", %{"sort_field" => sort_field}, socket) do
    socket = assign(socket, :sort_field, sort_field)
    {:noreply, load_clusters(socket)}
  end

  @impl true
  def handle_info({:cluster, :connected, cluster_id}, socket) do
    # Update cluster connectivity status
    clusters = update_cluster_connectivity(socket.assigns.clusters, cluster_id, :connected)
    socket = assign(socket, clusters: clusters)
    socket = update_counts(socket)
    {:noreply, socket}
  end

  def handle_info({:cluster, :disconnected, cluster_id}, socket) do
    # Update cluster connectivity status
    clusters = update_cluster_connectivity(socket.assigns.clusters, cluster_id, :disconnected)
    socket = assign(socket, clusters: clusters)
    socket = update_counts(socket)
    {:noreply, socket}
  end

  def handle_info({:cluster, :health_updated, cluster_id, health_status}, socket) do
    # Update cluster health status
    clusters =
      Enum.map(socket.assigns.clusters, fn cluster ->
        if cluster.id == cluster_id do
          %{cluster | health_status: health_status}
        else
          cluster
        end
      end)

    socket = assign(socket, clusters: clusters)
    socket = update_counts(socket)
    {:noreply, socket}
  end

  def handle_info({:cluster, :incident_updated, cluster_id, incident_count}, socket) do
    # Update open incident count
    clusters =
      Enum.map(socket.assigns.clusters, fn cluster ->
        if cluster.id == cluster_id do
          %{cluster | open_incident_count: incident_count}
        else
          cluster
        end
      end)

    socket = assign(socket, clusters: clusters)
    socket = update_counts(socket)
    {:noreply, socket}
  end

  defp load_clusters(socket) do
    socket
    |> assign(:loading, true)
    |> assign(:error, nil)
    |> then(fn s ->
      {:ok, organizations, clusters} =
        fetch_clusters(s.assigns.selected_organization_id, s.assigns.sort_field)

      s
      |> assign(:organizations, organizations)
      |> assign(:clusters, clusters)
      |> update_counts()
      |> assign(:loading, false)
    end)
  end

  defp fetch_clusters(_organization_id, sort_field) do
    # This will be implemented by the data layer when dependencies are resolved
    # For now, return empty or test data
    organizations = []
    clusters = []

    {:ok, organizations, sort_clusters(clusters, sort_field)}
  end

  defp sort_clusters(clusters, sort_field) do
    Enum.sort_by(clusters, fn cluster ->
      case sort_field do
        "name" -> cluster.name
        "last_contact" -> cluster.last_contact || ""
        "health" -> format_health_for_sort(cluster.health_status)
        "connectivity" -> format_connectivity_for_sort(cluster.connectivity)
        _ -> cluster.name
      end
    end)
  end

  defp update_counts(socket) do
    clusters = socket.assigns.clusters

    connected_count =
      Enum.count(clusters, fn cluster ->
        cluster.connectivity in [:connected, :healthy]
      end)

    healthy_count =
      Enum.count(clusters, fn cluster ->
        cluster.health_status == :healthy
      end)

    incident_count =
      clusters
      |> Enum.map(fn cluster -> cluster.open_incident_count || 0 end)
      |> Enum.sum()

    socket
    |> assign(:connected_count, connected_count)
    |> assign(:total_count, Enum.count(clusters))
    |> assign(:healthy_count, healthy_count)
    |> assign(:incident_count, incident_count)
  end

  defp update_cluster_connectivity(clusters, cluster_id, connectivity) do
    Enum.map(clusters, fn cluster ->
      if cluster.id == cluster_id do
        %{cluster | connectivity: connectivity}
      else
        cluster
      end
    end)
  end

  defp connectivity_class(%{connectivity: :disconnected}), do: "disconnected"
  defp connectivity_class(%{connectivity: :connected}), do: "connected"
  defp connectivity_class(%{connectivity: :healthy}), do: "healthy"
  defp connectivity_class(_), do: "unknown"

  defp format_connectivity(:disconnected), do: "Disconnected"
  defp format_connectivity(:connected), do: "Connected"
  defp format_connectivity(:healthy), do: "Healthy"
  defp format_connectivity(_), do: "Unknown"

  defp format_connectivity_for_sort(:disconnected), do: 0
  defp format_connectivity_for_sort(:connected), do: 1
  defp format_connectivity_for_sort(:healthy), do: 2
  defp format_connectivity_for_sort(_), do: -1

  defp format_health(:healthy), do: "Healthy"
  defp format_health(:degraded), do: "Degraded"
  defp format_health(:unhealthy), do: "Unhealthy"
  defp format_health(_), do: "Unknown"

  defp format_health_for_sort(:healthy), do: 0
  defp format_health_for_sort(:degraded), do: 1
  defp format_health_for_sort(:unhealthy), do: 2
  defp format_health_for_sort(_), do: -1

  defp format_last_contact(nil), do: "Never"

  defp format_last_contact(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _offset} -> format_time_ago(dt)
      {:error, _} -> "Unknown"
    end
  end

  defp format_last_contact(timestamp) when is_struct(timestamp, DateTime) do
    format_time_ago(timestamp)
  end

  defp format_last_contact(_), do: "Unknown"

  defp format_time_ago(timestamp) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, timestamp, :second)

    cond do
      diff < 60 -> "Just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> "#{div(diff, 604_800)}w ago"
    end
  end
end

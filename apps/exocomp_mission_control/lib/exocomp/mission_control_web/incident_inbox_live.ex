# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControlWeb.IncidentInboxLive do
  @moduledoc "Incident inbox with bounded, organization-scoped filters."

  use Phoenix.LiveView

  alias Exocomp.MissionControl.Incidents.Query
  alias Exocomp.MissionControlWeb.IncidentLiveSupport, as: Support

  @page_size 20

  @impl true
  def mount(_params, session, socket) do
    case Support.user(session) do
      nil ->
        {:ok, assign(socket, denied: true, user: nil)}

      user ->
        if connected?(socket),
          do:
            Phoenix.PubSub.subscribe(
              Exocomp.MissionControl.PubSub,
              Support.topic(user.organization_id)
            )

        {:ok,
         socket
         |> assign(denied: false, user: user, filters: empty_filters())
         |> load_page(1)}
    end
  end

  @impl true
  def handle_params(_params, _uri, %{assigns: %{denied: true}} = socket), do: {:noreply, socket}

  def handle_params(params, _uri, socket) do
    filters = normalize_filters(params)
    {:noreply, socket |> assign(filters: filters) |> load_page(parse_page(params["page"]))}
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    filters = normalize_filters(filters)
    {:noreply, socket |> assign(filters: filters) |> load_page(1)}
  end

  def handle_event("filter", filters, socket) do
    handle_event("filter", %{"filters" => filters}, socket)
  end

  @impl true
  def handle_info({:incident_changed, incident}, socket) do
    if incident.organization_id == socket.assigns.user.organization_id do
      {:noreply, load_page(socket, socket.assigns.page)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl true
  def render(%{denied: true} = assigns) do
    ~H"""
    <main id="incident-inbox" aria-labelledby="incident-inbox-title">
      <h1 id="incident-inbox-title">Incident inbox</h1>
      <p role="alert">You do not have access to incidents.</p>
    </main>
    """
  end

  def render(assigns) do
    ~H"""
    <main id="incident-inbox" aria-labelledby="incident-inbox-title">
      <header>
        <h1 id="incident-inbox-title">Incident inbox</h1>
        <p><%= @total %> incident<%= if @total == 1, do: "", else: "s" %> in your organization.</p>
      </header>

      <form id="incident-filters" phx-change="filter" aria-label="Filter incidents">
        <fieldset>
          <legend>Filters</legend>
          <label>
            Severity
            <select name="filters[severity]" aria-label="Severity">
              <option value="">All severities</option>
              <%= for severity <- ~w(critical high medium low unknown) do %>
                <option value={severity} selected={@filters["severity"] == severity}><%= severity %></option>
              <% end %>
            </select>
          </label>
          <label>
            Status
            <select name="filters[status]" aria-label="Status">
              <option value="">All statuses</option>
              <%= for status <- ~w(open acknowledged resolved) do %>
                <option value={status} selected={@filters["status"] == status}><%= status %></option>
              <% end %>
            </select>
          </label>
          <label>
            Cluster
            <input name="filters[cluster]" value={@filters["cluster"]} placeholder="cluster id" />
          </label>
          <label>
            Label
            <input name="filters[label]" value={@filters["label"]} placeholder="label" />
          </label>
        </fieldset>
      </form>

      <%= if @rows == [] do %>
        <p id="empty-incidents">No incidents match these filters.</p>
      <% else %>
        <div role="region" aria-label="Incidents" tabindex="0">
          <table>
            <thead>
              <tr><th scope="col">Severity</th><th scope="col">Incident</th><th scope="col">Status</th><th scope="col">Cluster</th><th scope="col">Labels</th><th scope="col">Updated</th></tr>
            </thead>
            <tbody>
              <%= for row <- @rows do %>
                <tr id={"incident-#{row.incident.id}"}>
                  <td><span data-severity={row.severity}><%= row.severity %></span></td>
                  <td><a href={"/incidents/#{row.incident.id}"}><%= row.incident.alert_type %> · <%= row.incident.target_identity %></a></td>
                  <td><%= row.incident.state %></td>
                  <td><%= row.incident.cluster_id %></td>
                  <td><%= Enum.join(row.labels, ", ") %></td>
                  <td><time datetime={DateTime.to_iso8601(row.incident.updated_at)}><%= Support.format_time(row.incident.updated_at) %></time></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>

      <nav aria-label="Incident pages">
        <span>Page <%= @page %> of <%= @total_pages %></span>
        <%= if @page > 1 do %>
          <a href={page_path(@filters, @page - 1)}>Previous</a>
        <% end %>
        <%= if @page < @total_pages do %>
          <a href={page_path(@filters, @page + 1)}>Next</a>
        <% end %>
      </nav>
    </main>
    """
  end

  defp load_page(socket, page) do
    user = socket.assigns.user

    result =
      Query.page(
        user.organization_id,
        socket.assigns.filters,
        page,
        @page_size,
        Support.incidents_server()
      )

    assign(socket,
      rows: result.rows,
      page: result.page,
      total: result.total,
      total_pages: result.total_pages
    )
  end

  defp empty_filters, do: %{"severity" => "", "status" => "", "cluster" => "", "label" => ""}

  defp normalize_filters(filters) when is_map(filters) do
    empty_filters()
    |> Map.merge(Map.take(filters, ["severity", "status", "cluster", "label"]))
  end

  defp normalize_filters(_filters), do: empty_filters()

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {page, ""} when page > 0 -> page
      _ -> 1
    end
  end

  defp parse_page(_page), do: 1

  defp page_path(filters, page),
    do: "/incidents?" <> URI.encode_query(Map.put(filters, "page", page))
end

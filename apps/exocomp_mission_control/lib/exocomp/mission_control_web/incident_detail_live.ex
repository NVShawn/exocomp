# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControlWeb.IncidentDetailLive do
  @moduledoc "Incident timeline, evidence, related incidents, and operator controls."

  use Phoenix.LiveView

  alias Exocomp.MissionControl.Incidents
  alias Exocomp.MissionControlWeb.IncidentLiveSupport, as: Support

  @impl true
  def mount(%{"id" => incident_id}, session, socket) do
    case Support.user(session) do
      nil ->
        {:ok, assign(socket, denied: true, user: nil)}

      user ->
        socket =
          assign(socket,
            denied: false,
            user: user,
            incident_id: incident_id,
            error: nil,
            resolve_error: nil
          )

        if connected?(socket),
          do:
            Phoenix.PubSub.subscribe(
              Exocomp.MissionControl.PubSub,
              Support.topic(user.organization_id)
            )

        {:ok, load_detail(socket)}
    end
  end

  @impl true
  def handle_info({:incident_changed, %{id: id}}, %{assigns: %{incident_id: id}} = socket),
    do: {:noreply, load_detail(socket)}

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl true
  def handle_event(_event, _params, %{assigns: %{denied: true}} = socket), do: {:noreply, socket}

  def handle_event("acknowledge", params, socket) do
    with :ok <- current_state(socket, params),
         {:ok, _incident} <-
           Incidents.acknowledge(
             org(socket),
             socket.assigns.incident_id,
             subject(socket),
             org(socket),
             role(socket),
             Support.incidents_server()
           ) do
      {:noreply, success(socket, "Incident acknowledged.")}
    else
      {:error, reason} -> {:noreply, failure(socket, reason)}
      :stale -> {:noreply, stale(socket)}
    end
  end

  def handle_event("assign", params, socket) do
    assignee = String.trim(Map.get(params, "assignee", ""))

    with :ok <- current_state(socket, params),
         false <- assignee == "",
         {:ok, _incident} <-
           Incidents.assign(
             org(socket),
             socket.assigns.incident_id,
             assignee,
             subject(socket),
             org(socket),
             role(socket),
             Support.incidents_server()
           ) do
      {:noreply, success(socket, "Incident assigned to #{assignee}.")}
    else
      true -> {:noreply, failure(socket, :missing_assignee)}
      {:error, reason} -> {:noreply, failure(socket, reason)}
      :stale -> {:noreply, stale(socket)}
    end
  end

  def handle_event("snooze", params, socket) do
    with :ok <- current_state(socket, params),
         {:ok, until} <- parse_datetime(Map.get(params, "snooze_until", "")),
         {:ok, _incident} <-
           Incidents.snooze(
             org(socket),
             socket.assigns.incident_id,
             until,
             subject(socket),
             org(socket),
             role(socket),
             Support.incidents_server()
           ) do
      {:noreply, success(socket, "Incident snoozed until #{Support.format_time(until)}.")}
    else
      {:error, :invalid_datetime} -> {:noreply, failure(socket, :invalid_snooze_time)}
      {:error, reason} -> {:noreply, failure(socket, reason)}
      :stale -> {:noreply, stale(socket)}
    end
  end

  def handle_event("resolve", params, socket) do
    reason = String.trim(Map.get(params, "reason", ""))

    cond do
      reason == "" ->
        {:noreply, assign(socket, resolve_error: "A reason is required.", error: nil)}

      socket.assigns.incident.state == :resolved ->
        {:noreply, stale(socket)}

      true ->
        with :ok <- current_state(socket, params),
             {:ok, _incident} <-
               Incidents.resolve(
                 org(socket),
                 socket.assigns.incident_id,
                 reason,
                 subject(socket),
                 org(socket),
                 role(socket),
                 Support.incidents_server()
               ) do
          {:noreply, success(socket, "Incident resolved.")}
        else
          {:error, reason} -> {:noreply, failure(socket, reason)}
          :stale -> {:noreply, stale(socket)}
        end
    end
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl true
  def render(%{denied: true} = assigns) do
    ~H"""
    <main id="incident-detail" aria-labelledby="incident-detail-title">
      <h1 id="incident-detail-title">Incident</h1>
      <p role="alert">You do not have access to this incident.</p>
    </main>
    """
  end

  def render(%{not_found: true} = assigns) do
    ~H"""
    <main id="incident-detail" aria-labelledby="incident-detail-title">
      <h1 id="incident-detail-title">Incident</h1>
      <p role="alert">Incident not found.</p>
    </main>
    """
  end

  def render(assigns) do
    ~H"""
    <main id="incident-detail" aria-labelledby="incident-detail-title">
      <p><a href="/incidents">Back to incident inbox</a></p>
      <header>
        <h1 id="incident-detail-title"><%= @incident.alert_type %></h1>
        <p><strong>Status:</strong> <%= @incident.state %> · <strong>Severity:</strong> <%= @severity %></p>
        <p><strong>Cluster:</strong> <%= @incident.cluster_id %> · <strong>Target:</strong> <%= @incident.target_identity %></p>
        <p><strong>Assigned to:</strong> <%= @incident.assigned_to || "Unassigned" %></p>
        <%= if @incident.snoozed_until do %>
          <p id="snooze-wake-time"><strong>Snoozed until:</strong> <time datetime={DateTime.to_iso8601(@incident.snoozed_until)}><%= Support.format_time(@incident.snoozed_until) %></time></p>
        <% end %>
      </header>

      <%= if @error do %><p role="alert"><%= @error %></p><% end %>

      <%= if Support.operator?(@user) do %>
        <section aria-labelledby="operator-controls-title">
          <h2 id="operator-controls-title">Operator controls</h2>
          <%= if @incident.state == :open do %>
            <form phx-submit="acknowledge">
              <input type="hidden" name="expected_state" value={@incident.state} />
              <button type="submit">Acknowledge</button>
            </form>
          <% end %>
          <form phx-submit="assign">
            <input type="hidden" name="expected_state" value={@incident.state} />
            <label>Assign to <input name="assignee" value={@incident.assigned_to || ""} autocomplete="email" /></label>
            <button type="submit">Save assignment</button>
          </form>
          <form phx-submit="snooze">
            <input type="hidden" name="expected_state" value={@incident.state} />
            <label>Snooze until <input type="datetime-local" name="snooze_until" required /></label>
            <button type="submit">Snooze</button>
          </form>
          <form phx-submit="resolve">
            <input type="hidden" name="expected_state" value={@incident.state} />
            <label>Resolution reason <textarea name="reason" required aria-describedby="resolution-help"></textarea></label>
            <p id="resolution-help">A reason is recorded in the incident timeline.</p>
            <%= if @resolve_error do %><p role="alert"><%= @resolve_error %></p><% end %>
            <button type="submit">Resolve manually</button>
          </form>
        </section>
      <% else %>
        <p id="viewer-notice">Viewer access is read-only.</p>
      <% end %>

      <section aria-labelledby="timeline-title">
        <h2 id="timeline-title">Timeline and evidence</h2>
        <ol id="incident-timeline">
          <%= for event <- @events do %>
            <li id={"event-#{event.id}"}>
              <time datetime={DateTime.to_iso8601(event.occurred_at)}><%= Support.format_time(event.occurred_at) %></time>
              <strong><%= event.event_type %></strong>
              <pre><%= inspect(event.payload) %></pre>
            </li>
          <% end %>
        </ol>
      </section>

      <section aria-labelledby="related-title">
        <h2 id="related-title">Related incidents</h2>
        <%= if @related == [] do %>
          <p>No related incidents.</p>
        <% else %>
          <ul>
            <%= for incident <- @related do %>
              <li><a href={"/incidents/#{incident.id}"}><%= incident.alert_type %> · <%= incident.target_identity %></a> (<%= incident.state %>)</li>
            <% end %>
          </ul>
        <% end %>
      </section>
    </main>
    """
  end

  defp load_detail(socket) do
    server = Support.incidents_server()

    case Incidents.get(org(socket), socket.assigns.incident_id, server) do
      {:ok, incident} ->
        {:ok, events} = Incidents.events(org(socket), incident.id, server)

        {:ok, related} =
          Incidents.related(
            org(socket),
            incident.id,
            [include_resolved: true, recent_seconds: 86_400],
            server
          )

        row = Exocomp.MissionControl.Incidents.Query.row(incident, server)

        assign(socket,
          not_found: false,
          incident: incident,
          events: events,
          related: related,
          severity: row.severity,
          labels: row.labels,
          error: nil,
          resolve_error: nil
        )

      {:error, _reason} ->
        assign(socket, not_found: true, error: nil)
    end
  end

  defp current_state(socket, params) do
    if Map.get(params, "expected_state") in [nil, Atom.to_string(socket.assigns.incident.state)] do
      :ok
    else
      :stale
    end
  end

  defp parse_datetime(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        {:ok, datetime}

      _ ->
        case NaiveDateTime.from_iso8601(value <> ":00") do
          {:ok, naive} -> {:ok, DateTime.from_naive!(naive, "Etc/UTC")}
          _ -> {:error, :invalid_datetime}
        end
    end
  end

  defp success(socket, message),
    do: socket |> load_detail() |> Phoenix.LiveView.put_flash(:info, message)

  defp stale(socket),
    do:
      socket
      |> load_detail()
      |> Phoenix.LiveView.put_flash(
        :error,
        "Incident changed; reload before applying this action."
      )

  defp failure(socket, :access_denied),
    do:
      Phoenix.LiveView.put_flash(
        socket,
        :error,
        "You do not have permission to change incidents."
      )

  defp failure(socket, :organization_mismatch), do: assign(socket, not_found: true, error: nil)

  defp failure(socket, :missing_assignee),
    do: Phoenix.LiveView.put_flash(socket, :error, "An assignee is required.")

  defp failure(socket, :invalid_snooze_time),
    do: Phoenix.LiveView.put_flash(socket, :error, "Choose a future snooze time.")

  defp failure(socket, :invalid_state), do: stale(socket)

  defp failure(socket, _reason),
    do: Phoenix.LiveView.put_flash(socket, :error, "The incident change could not be applied.")

  defp org(socket), do: socket.assigns.user.organization_id
  defp subject(socket), do: socket.assigns.user.subject
  defp role(socket), do: socket.assigns.user.role
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AdminLive.Index do
  @moduledoc """
  Administration pages for enrollment, identity, retention, and integrations.
  """

  use Phoenix.LiveView

  alias Exocomp.MissionControl.{
    AdminCluster,
    Administration,
    LiveView.RequireRole,
    RetentionSettings
  }

  @impl true
  def mount(_params, session, socket) do
    with {:ok, socket} <- RequireRole.require_admin_or_redirect({:ok, socket}, session) do
      {:ok,
       assign(socket,
         page_title: "Administration",
         invitation_plaintext: nil,
         invitations: [],
         clusters: [],
         role_mappings: [],
         retention: %RetentionSettings{
           organization_id: socket.assigns.operator.organization_id,
           status_history_days: 90,
           incident_days: 365,
           updated_at: nil
         },
         webhooks: [],
         admin_actions: [],
         pending_revocation: nil
       )}
    else
      {:ok, socket} ->
        {:ok, socket}

      {:redirect, _} = redirect ->
        redirect
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    socket =
      socket
      |> assign(:invitation_plaintext, nil)
      |> load_admin_data()

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear-invitation", _params, socket) do
    {:noreply, assign(socket, :invitation_plaintext, nil)}
  end

  def handle_event("create-invitation", %{"invitation" => params}, socket) do
    case Administration.create_invitation(socket.assigns.operator, params) do
      {:ok, invitation, plaintext} ->
        {:noreply,
         socket
         |> assign(:invitation_plaintext, plaintext)
         |> assign(:invitations, [invitation | socket.assigns.invitations])
         |> put_flash(
           :success,
           "Invitation created. Save the token now; it will not be shown again."
         )}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, format_error(reason))}
    end
  end

  def handle_event("create-invitation", _params, socket) do
    {:noreply, put_flash(socket, :error, "Cluster name is required.")}
  end

  def handle_event("request-revoke", %{"id" => cluster_id}, socket) do
    case Enum.find(socket.assigns.clusters, &(&1.id == cluster_id)) do
      %AdminCluster{} = cluster ->
        {:noreply, assign(socket, :pending_revocation, cluster)}

      nil ->
        {:noreply, put_flash(socket, :error, "Cluster not found.")}
    end
  end

  def handle_event("confirm-revoke", %{"id" => cluster_id}, socket) do
    operator = socket.assigns.operator

    case Administration.revoke_cluster(operator, operator.organization_id, cluster_id) do
      {:ok, _cluster, _action} ->
        {:noreply,
         socket
         |> assign(:pending_revocation, nil)
         |> load_admin_data()
         |> put_flash(:success, "Cluster revoked and the administrative action was recorded.")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:pending_revocation, nil)
         |> put_flash(:error, format_error(reason))}
    end
  end

  def handle_event("cancel-revoke", _params, socket) do
    {:noreply, assign(socket, :pending_revocation, nil)}
  end

  def handle_event("create-role-mapping", %{"mapping" => params}, socket) do
    case Administration.create_role_mapping(socket.assigns.operator, params) do
      {:ok, _mapping} ->
        {:noreply,
         socket
         |> load_admin_data()
         |> put_flash(:success, "OIDC role mapping saved.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, format_error(reason))}
    end
  end

  def handle_event("update-retention", %{"retention" => params}, socket) do
    case Administration.update_retention(socket.assigns.operator, params) do
      {:ok, retention} ->
        {:noreply,
         socket
         |> assign(:retention, retention)
         |> put_flash(:success, "Retention settings saved.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, format_error(reason))}
    end
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6" id="administration">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Administration</h2>
        <p class="text-gray-600 mt-1">Manage cluster identity, operator access, retention, and integrations.</p>
      </div>

      <nav id="admin-navigation" aria-label="Administration sections" class="flex flex-wrap gap-2 border-b border-gray-200 pb-3">
        <.admin_link live_action={@live_action} action={:index} label="Overview" path="/admin" />
        <.admin_link live_action={@live_action} action={:invitations} label="Invitations" path="/admin/invitations" />
        <.admin_link live_action={@live_action} action={:clusters} label="Clusters & certificates" path="/admin/clusters" />
        <.admin_link live_action={@live_action} action={:role_mappings} label="OIDC role mappings" path="/admin/role-mappings" />
        <.admin_link live_action={@live_action} action={:retention} label="Retention" path="/admin/retention" />
        <.admin_link live_action={@live_action} action={:webhooks} label="Webhook endpoints" path="/admin/webhooks" />
      </nav>

      <%= case @live_action do %>
        <% :invitations -> %>
          <.invitations_page invitations={@invitations} invitation_plaintext={@invitation_plaintext} />
        <% :clusters -> %>
          <.clusters_page clusters={@clusters} pending_revocation={@pending_revocation} />
        <% :role_mappings -> %>
          <.role_mappings_page role_mappings={@role_mappings} />
        <% :retention -> %>
          <.retention_page retention={@retention} />
        <% :webhooks -> %>
          <.webhooks_page webhooks={@webhooks} />
        <% _ -> %>
          <.overview_page invitations={@invitations} clusters={@clusters} role_mappings={@role_mappings} webhooks={@webhooks} admin_actions={@admin_actions} />
      <% end %>
    </div>
    """
  end

  defp load_admin_data(socket) do
    operator = socket.assigns.operator

    socket
    |> assign(:invitations, fetch_list(Administration.list_invitations(operator)))
    |> assign(:clusters, fetch_list(Administration.list_clusters(operator)))
    |> assign(:role_mappings, fetch_list(Administration.list_role_mappings(operator)))
    |> assign(
      :retention,
      fetch_one(Administration.get_retention(operator), socket.assigns.retention)
    )
    |> assign(:webhooks, fetch_list(Administration.list_webhooks(operator)))
    |> assign(:admin_actions, fetch_list(Administration.list_admin_actions(operator)))
  end

  defp fetch_list({:ok, values}), do: values
  defp fetch_list(_), do: []
  defp fetch_one({:ok, value}, _default), do: value
  defp fetch_one(_, default), do: default

  defp format_error(:invalid_role), do: "Role must be viewer, operator, or admin."

  defp format_error(:invalid_expiration),
    do: "Invitation expiration must be between 1 and 30 days."

  defp format_error(:already_revoked), do: "Cluster is already revoked."
  defp format_error(:not_found), do: "The requested resource was not found."

  defp format_error({:retention_out_of_bounds, key, minimum, maximum}),
    do: "#{key} must be between #{minimum} and #{maximum} days."

  defp format_error({:invalid, "cluster_name"}), do: "Cluster name is required."
  defp format_error({:invalid, "claim"}), do: "An OIDC claim or group is required."
  defp format_error({:invalid, key}), do: "#{key} is invalid."
  defp format_error(:insufficient_role), do: "Only administrators may change these settings."
  defp format_error(:cross_organization), do: "The resource does not belong to your organization."
  defp format_error(_), do: "The requested change could not be saved."

  attr(:live_action, :atom, required: true)
  attr(:action, :atom, required: true)
  attr(:label, :string, required: true)
  attr(:path, :string, required: true)

  defp admin_link(assigns) do
    ~H"""
    <.link patch={@path} phx-click="clear-invitation" class={[
      "rounded-md px-3 py-2 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-blue-500",
      @live_action == @action && "bg-blue-100 text-blue-800",
      @live_action != @action && "text-gray-600 hover:bg-gray-100 hover:text-gray-900"
    ]}>
      <%= @label %>
    </.link>
    """
  end

  attr(:invitations, :list, required: true)
  attr(:invitation_plaintext, :string, default: nil)

  defp invitations_page(assigns) do
    ~H"""
    <section id="admin-invitations" class="space-y-6">
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-gray-900">Create cluster invitation</h3>
        <p class="text-sm text-gray-600 mt-1">The coordinator generates its private key locally. Mission Control stores only a digest of this invitation.</p>
        <form id="invitation-form" phx-submit="create-invitation" class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
          <label class="block">
            <span class="text-sm font-medium text-gray-700">Cluster name</span>
            <input name="invitation[cluster_name]" required autocomplete="off" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" />
          </label>
          <label class="block">
            <span class="text-sm font-medium text-gray-700">Expires in days</span>
            <input name="invitation[expires_in_days]" type="number" min="1" max="30" value="30" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" />
          </label>
          <div class="flex items-end">
            <button type="submit" class="w-full rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500">Create invitation</button>
          </div>
        </form>
      </div>

      <%= if @invitation_plaintext do %>
        <aside id="invitation-plaintext" class="rounded-lg border border-amber-300 bg-amber-50 p-5" role="alert" aria-live="assertive">
          <h3 class="font-semibold text-amber-900">Copy this invitation now</h3>
          <p class="mt-1 text-sm text-amber-800">This plaintext token is shown once and is cleared when you leave this page.</p>
          <code class="mt-3 block select-all break-all rounded bg-white p-3 font-mono text-sm text-gray-900"><%= @invitation_plaintext %></code>
        </aside>
      <% end %>

      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-gray-900">Recent invitations</h3>
        <%= if @invitations == [] do %>
          <p class="mt-3 text-sm text-gray-600">No invitations have been created.</p>
        <% else %>
          <div class="mt-3 overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200" aria-label="Cluster invitations">
              <thead><tr><th scope="col" class="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Cluster</th><th scope="col" class="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Expires</th><th scope="col" class="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Status</th></tr></thead>
              <tbody class="divide-y divide-gray-100">
                <%= for invitation <- @invitations do %>
                  <tr id={"invitation-#{invitation.id}"}><td class="px-3 py-3 text-sm text-gray-900"><%= invitation.cluster_name %></td><td class="px-3 py-3 text-sm text-gray-600"><%= date_text(invitation.expires_at) %></td><td class="px-3 py-3 text-sm text-gray-600"><%= if invitation.consumed_at, do: "Consumed", else: "Available" %></td></tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </section>
    """
  end

  attr(:clusters, :list, required: true)
  attr(:pending_revocation, :any, default: nil)

  defp clusters_page(assigns) do
    ~H"""
    <section id="admin-clusters" class="space-y-6">
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-gray-900">Cluster certificates and status</h3>
        <p class="text-sm text-gray-600 mt-1">Only certificate metadata is shown. Private keys and certificate bodies never leave the coordinator.</p>
        <%= if @clusters == [] do %>
          <p class="mt-4 text-sm text-gray-600">No clusters are enrolled.</p>
        <% else %>
          <div class="mt-4 overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200" aria-label="Cluster certificates">
              <thead><tr><th scope="col" class="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Cluster</th><th scope="col" class="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Connection</th><th scope="col" class="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Certificate</th><th scope="col" class="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Expires</th><th scope="col" class="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Action</th></tr></thead>
              <tbody class="divide-y divide-gray-100">
                <%= for cluster <- @clusters do %>
                  <tr id={"cluster-#{cluster.id}"}>
                    <td class="px-3 py-3 text-sm"><span class="font-medium text-gray-900"><%= cluster.name %></span><span class="block text-xs text-gray-500">Serial: <%= cluster.certificate_serial || "Not issued" %></span><span class="block break-all text-xs text-gray-500">Fingerprint: <%= cluster.certificate_fingerprint || "Not available" %></span></td>
                    <td class="px-3 py-3 text-sm capitalize text-gray-700"><%= cluster.status %></td>
                    <td class="px-3 py-3 text-sm capitalize text-gray-700"><%= cluster.certificate_status %></td>
                    <td class="px-3 py-3 text-sm text-gray-600"><%= date_text(cluster.certificate_expires_at) %></td>
                    <td class="px-3 py-3 text-right"><%= if cluster.certificate_status == :revoked do %><span class="text-sm text-gray-500">Revoked</span><% else %><button id={"revoke-cluster-#{cluster.id}"} type="button" phx-click="request-revoke" phx-value-id={cluster.id} data-confirm="Revoking this cluster immediately prevents new sessions. Continue?" class="rounded-md border border-red-300 px-3 py-2 text-sm font-medium text-red-700 hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-red-500">Revoke</button><% end %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>

      <%= if @pending_revocation do %>
        <div id="revoke-confirmation" role="dialog" aria-modal="true" aria-labelledby="revoke-confirmation-title" class="rounded-lg border border-red-300 bg-red-50 p-5">
          <h3 id="revoke-confirmation-title" class="font-semibold text-red-900">Confirm cluster revocation</h3>
          <p class="mt-1 text-sm text-red-800">Revoking <strong><%= @pending_revocation.name %></strong> immediately prevents new authenticated sessions. This action is recorded and cannot be undone here.</p>
          <div class="mt-4 flex gap-3"><button id="confirm-cluster-revocation" type="button" phx-click="confirm-revoke" phx-value-id={@pending_revocation.id} class="rounded-md bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500">Confirm revocation</button><button id="cancel-cluster-revocation" type="button" phx-click="cancel-revoke" class="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500">Cancel</button></div>
        </div>
      <% end %>
    </section>
    """
  end

  attr(:role_mappings, :list, required: true)

  defp role_mappings_page(assigns) do
    ~H"""
    <section id="admin-role-mappings" class="space-y-6">
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-gray-900">OIDC role mappings</h3>
        <p class="text-sm text-gray-600 mt-1">Map a validated provider claim or group to one of the three Mission Control roles.</p>
        <form id="role-mapping-form" phx-submit="create-role-mapping" class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
          <label class="block md:col-span-2"><span class="text-sm font-medium text-gray-700">Claim or group</span><input name="mapping[claim]" required autocomplete="off" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" /></label>
          <label class="block"><span class="text-sm font-medium text-gray-700">Role</span><select name="mapping[role]" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"><option value="viewer">Viewer</option><option value="operator">Operator</option><option value="admin">Admin</option></select></label>
          <div class="md:col-span-3"><button type="submit" class="rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500">Save mapping</button></div>
        </form>
      </div>
      <div class="bg-white rounded-lg shadow p-6"><h3 class="text-lg font-semibold text-gray-900">Configured mappings</h3><%= if @role_mappings == [] do %><p class="mt-3 text-sm text-gray-600">No role mappings are configured.</p><% else %><ul id="role-mappings" class="mt-3 divide-y divide-gray-100"><%= for mapping <- @role_mappings do %><li id={"role-mapping-#{mapping.id}"} class="flex items-center justify-between py-3 text-sm"><span class="font-medium text-gray-900"><%= mapping.claim %></span><span class="rounded-full bg-blue-100 px-2.5 py-0.5 font-medium capitalize text-blue-800"><%= mapping.role %></span></li><% end %></ul><% end %></div>
    </section>
    """
  end

  attr(:retention, RetentionSettings, required: true)

  defp retention_page(assigns) do
    ~H"""
    <section id="admin-retention" class="space-y-6">
      <div class="bg-white rounded-lg shadow p-6"><h3 class="text-lg font-semibold text-gray-900">Retention settings</h3><p class="text-sm text-gray-600 mt-1">Status history is bounded to 1–365 days. Incidents, conversations, proposals, approvals, executions, and audit events are bounded to 30–3,650 days.</p><form id="retention-form" phx-submit="update-retention" class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4"><label class="block"><span class="text-sm font-medium text-gray-700">Status history (days)</span><input name="retention[status_history_days]" type="number" min="1" max="365" value={@retention.status_history_days} required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" /></label><label class="block"><span class="text-sm font-medium text-gray-700">Incident data (days)</span><input name="retention[incident_days]" type="number" min="30" max="3650" value={@retention.incident_days} required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" /></label><div class="flex items-end"><button type="submit" class="w-full rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500">Save retention</button></div></form></div>
    </section>
    """
  end

  attr(:webhooks, :list, required: true)

  defp webhooks_page(assigns) do
    ~H"""
    <section id="admin-webhooks" class="space-y-6"><div class="bg-white rounded-lg shadow p-6"><h3 class="text-lg font-semibold text-gray-900">Webhook endpoints</h3><p class="text-sm text-gray-600 mt-1">Configure signed HTTPS endpoints for Mission Control events. Delivery attempts are managed separately.</p><%= if @webhooks == [] do %><p class="mt-4 text-sm text-gray-600">No webhook endpoints are configured.</p><% else %><div class="mt-4 overflow-x-auto"><table class="min-w-full divide-y divide-gray-200" aria-label="Webhook endpoints"><thead><tr><th scope="col" class="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">URL</th><th scope="col" class="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Events</th><th scope="col" class="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Status</th></tr></thead><tbody class="divide-y divide-gray-100"><%= for webhook <- @webhooks do %><tr id={"webhook-#{webhook.id}"}><td class="px-3 py-3 text-sm text-gray-900"><%= webhook.url %></td><td class="px-3 py-3 text-sm text-gray-600"><%= Enum.join(webhook.event_types, ", ") %></td><td class="px-3 py-3 text-sm text-gray-600"><%= if webhook.enabled, do: "Enabled", else: "Disabled" %></td></tr><% end %></tbody></table></div><% end %><p class="mt-4 text-xs text-gray-500">Webhook signing secrets are never rendered on this page.</p></div></section>
    """
  end

  attr(:invitations, :list, required: true)
  attr(:clusters, :list, required: true)
  attr(:role_mappings, :list, required: true)
  attr(:webhooks, :list, required: true)
  attr(:admin_actions, :list, required: true)

  defp overview_page(assigns) do
    ~H"""
    <section id="admin-overview" class="space-y-6"><div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4"><.summary_card label="Invitations" value={length(@invitations)} path="/admin/invitations" /><.summary_card label="Clusters" value={length(@clusters)} path="/admin/clusters" /><.summary_card label="Role mappings" value={length(@role_mappings)} path="/admin/role-mappings" /><.summary_card label="Webhooks" value={length(@webhooks)} path="/admin/webhooks" /></div><div class="bg-white rounded-lg shadow p-6"><h3 class="text-lg font-semibold text-gray-900">Recent administrative actions</h3><%= if @admin_actions == [] do %><p class="mt-3 text-sm text-gray-600">No administrative actions have been recorded.</p><% else %><ul id="admin-actions" class="mt-3 divide-y divide-gray-100"><%= for action <- @admin_actions do %><li class="py-3 text-sm text-gray-700"><span class="font-medium"><%= action.action %></span> · <%= action.resource_id %> · <%= date_text(action.inserted_at) %></li><% end %></ul><% end %></div></section>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :integer, required: true)
  attr(:path, :string, required: true)

  defp summary_card(assigns) do
    ~H"""
    <.link patch={@path} phx-click="clear-invitation" class="rounded-lg bg-white p-6 shadow hover:ring-2 hover:ring-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"><span class="block text-sm font-medium text-gray-600"><%= @label %></span><span class="mt-2 block text-3xl font-bold text-gray-900"><%= @value %></span><span class="mt-2 block text-sm text-blue-700">Manage <span aria-hidden="true">→</span></span></.link>
    """
  end

  defp date_text(nil), do: "Not available"
  defp date_text(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp date_text(value), do: to_string(value)
end

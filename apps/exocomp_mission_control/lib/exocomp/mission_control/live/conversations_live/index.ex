# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ConversationsLive.Index do
  @moduledoc """
  Conversation and evidence LiveView interface.

  Displays ordered operator/cluster messages, structured evidence cards, and
  message delivery state. Operators may send bounded messages when the cluster
  is connected. Retry/new-message affordances create new commands rather than
  rewriting history.

  Organization isolation is enforced at all levels. Raw HTML, attachments, and
  arbitrary raw logs are rejected and never rendered.
  """

  use Phoenix.LiveView

  alias Exocomp.MissionControl.{
    Conversations,
    Conversation,
    Message,
    EvidenceReference,
    LiveView.RequireRole
  }

  @max_message_bytes Message.max_bytes()
  @pubsub_topic "conversations"

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket}
    |> RequireRole.require_operator_or_redirect(session)
    |> case do
      {:ok, socket} ->
        %{organization_id: organization_id} = socket.assigns.operator

        socket = assign(socket, :page_title, "Conversations")
        socket = assign(socket, :conversations, [])
        socket = assign(socket, :selected_conversation, nil)
        socket = assign(socket, :messages, [])
        socket = assign(socket, :message_input, "")
        socket = assign(socket, :cluster_online, true)
        socket = assign(socket, :sending_message, false)
        socket = assign(socket, :error_message, nil)

        # Subscribe to conversation updates
        if connected?(socket) do
          Phoenix.PubSub.subscribe(
            Exocomp.MissionControl.PubSub,
            conversation_topic(organization_id)
          )
        end

        {:ok, socket}

      {:redirect, _} = redirect ->
        redirect
    end
  end

  @impl true
  def handle_params(%{"conversation_id" => conversation_id}, _uri, socket) do
    %{organization_id: organization_id} = socket.assigns.operator

    case Conversations.get(organization_id, conversation_id) do
      {:ok, conversation} ->
        messages = Conversations.list_messages(organization_id, conversation_id)
        socket = assign(socket, :selected_conversation, conversation)
        socket = assign(socket, :messages, messages)
        {:noreply, socket}

      {:error, :not_found} ->
        socket = put_flash(socket, :error, "Conversation not found")
        {:noreply, push_navigate(socket, to: ~p"/conversations")}
    end
  end

  def handle_params(_params, _uri, socket) do
    %{organization_id: organization_id} = socket.assigns.operator

    conversations = Conversations.list(organization_id)
    socket = assign(socket, :conversations, conversations)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <%= if @selected_conversation do %>
        <.conversation_detail conversation={@selected_conversation} messages={@messages} assigns={assigns} />
      <% else %>
        <.conversation_list conversations={@conversations} />
      <% end %>
    </div>
    """
  end

  defp conversation_detail(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h2 class="text-2xl font-bold text-gray-900">
          <%= @conversation.title || "Conversation" %>
        </h2>
        <button phx-click="back_to_list" class="text-blue-600 hover:text-blue-800">
          ← Back to List
        </button>
      </div>

      <div class="bg-gray-50 rounded-lg p-4 space-y-4">
        <div class="flex items-center justify-between">
          <div class="text-sm text-gray-600">
            <%= if @cluster_online do %>
              <span class="text-green-600">● Cluster Online</span>
            <% else %>
              <span class="text-red-600">● Cluster Offline</span>
            <% end %>
          </div>
        </div>

        <!-- Messages List -->
        <div class="space-y-4 bg-white rounded border border-gray-200 p-4" style="max-height: 500px; overflow-y: auto;">
          <%= if Enum.empty?(@messages) do %>
            <p class="text-gray-500 text-center py-8">No messages yet</p>
          <% else %>
            <%= for message <- @messages do %>
              <.message_card message={message} />
            <% end %>
          <% end %>
        </div>

        <!-- Error Message Display -->
        <%= if @error_message do %>
          <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
            <%= @error_message %>
          </div>
        <% end %>

        <!-- Message Input Form -->
        <%= if allow_send?(@assigns) do %>
          <.message_form
            cluster_online={@cluster_online}
            message_input={@message_input}
            sending={@sending_message}
          />
        <% else %>
          <div class="bg-blue-50 border border-blue-200 text-blue-700 px-4 py-3 rounded text-sm">
            You have viewer access. Message sending is not available.
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp conversation_list(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900">Conversations</h2>
      <%= if Enum.empty?(@conversations) do %>
        <p class="text-gray-600">No conversations at this time</p>
      <% else %>
        <div class="space-y-2">
          <%= for conversation <- @conversations do %>
            <button
              phx-click="select_conversation"
              phx-value-id={conversation.id}
              class="w-full text-left px-4 py-3 bg-white border border-gray-200 rounded hover:bg-gray-50 transition"
            >
              <div class="font-semibold text-gray-900">
                <%= conversation.title || "Conversation #{String.slice(conversation.id, 0..8)}" %>
              </div>
              <div class="text-sm text-gray-500">
                <%= if conversation.kind == :incident do %>
                  Incident: <%= conversation.incident_id %>
                <% else %>
                  Cluster: <%= conversation.cluster_id %>
                <% end %>
              </div>
              <div class="text-xs text-gray-400 mt-1">
                <%= length(conversation.messages) %> messages
              </div>
            </button>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp message_card(assigns) do
    ~H"""
    <div class="border-l-4 border-gray-300 pl-4 py-2">
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center gap-2">
          <span class="font-semibold text-gray-900">
            <%= message_sender(@message) %>
          </span>
          <.state_badge state={@message.state} />
        </div>
        <span class="text-xs text-gray-500">
          <%= format_time(@message.created_at) %>
        </span>
      </div>

      <div class="text-gray-700 mb-2">
        <%= @message.body %>
      </div>

      <!-- Evidence Cards -->
      <%= if not Enum.empty?(@message.evidence_refs) do %>
        <div class="mt-3 space-y-2">
          <%= for evidence <- @message.evidence_refs do %>
            <.evidence_card evidence={evidence} />
          <% end %>
        </div>
      <% end %>

      <!-- State History -->
      <%= if not Enum.empty?(@message.state_history) do %>
        <div class="mt-2 text-xs text-gray-500 space-y-1">
          <%= for transition <- Enum.reverse(@message.state_history) do %>
            <div>
              State: <%= transition.from || "initial" %> → <%= transition.to %>
              <span class="text-gray-400"><%= format_time(transition.at) %></span>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Failure Reason -->
      <%= if @message.state == :failed && @message.failure_reason do %>
        <div class="mt-2 text-sm text-red-600">
          Failed: <%= @message.failure_reason %>
        </div>
      <% end %>
    </div>
    """
  end

  defp evidence_card(assigns) do
    ~H"""
    <div class="bg-gray-100 rounded p-3 text-sm">
      <div class="font-semibold text-gray-900 mb-1">
        Evidence: <%= @evidence.evidence_type || "Unknown Type" %>
      </div>
      <dl class="space-y-1">
        <%= if @evidence.service do %>
          <div class="flex justify-between">
            <dt class="text-gray-600">Service:</dt>
            <dd class="text-gray-900 font-mono"><%= @evidence.service %></dd>
          </div>
        <% end %>
        <div class="flex justify-between">
          <dt class="text-gray-600">Node:</dt>
          <dd class="text-gray-900 font-mono"><%= String.slice(@evidence.node_id, 0..8) %></dd>
        </div>
        <div class="flex justify-between">
          <dt class="text-gray-600">Observed:</dt>
          <dd class="text-gray-900 font-mono"><%= format_time(@evidence.observed_at) %></dd>
        </div>
        <div class="flex justify-between">
          <dt class="text-gray-600">Hash:</dt>
          <dd class="text-gray-900 font-mono text-xs"><%= String.slice(@evidence.evidence_hash, 0..8) %>...</dd>
        </div>
      </dl>
    </div>
    """
  end

  defp message_form(assigns) do
    ~H"""
    <form phx-submit="send_message" class="space-y-3">
      <div>
        <textarea
          name="message"
          placeholder="Type your message (max <%= @max_message_bytes %> bytes)..."
          class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
          rows="3"
          <%= if not @cluster_online, do: "disabled" %>
        ></textarea>
        <div class="text-xs text-gray-500 mt-1">
          <%= @max_message_bytes %> byte limit
        </div>
      </div>

      <button
        type="submit"
        disabled={not @cluster_online or @sending}
        class={
          "px-4 py-2 rounded font-semibold " <>
          if(@cluster_online and not @sending,
            do: "bg-blue-600 text-white hover:bg-blue-700",
            else: "bg-gray-300 text-gray-500 cursor-not-allowed"
          )
        }
      >
        <%= if @sending, do: "Sending...", else: "Send Message" %>
      </button>
    </form>
    """
  end

  defp state_badge(assigns) do
    ~H"""
    <span class={state_badge_class(@state)} title={atom_to_string(@state)}>
      <%= state_label(@state) %>
    </span>
    """
  end

  defp state_badge_class(:queued),
    do: "px-2 py-1 bg-yellow-100 text-yellow-800 text-xs rounded font-semibold"

  defp state_badge_class(:delivered),
    do: "px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded font-semibold"

  defp state_badge_class(:reasoning),
    do: "px-2 py-1 bg-purple-100 text-purple-800 text-xs rounded font-semibold"

  defp state_badge_class(:completed),
    do: "px-2 py-1 bg-green-100 text-green-800 text-xs rounded font-semibold"

  defp state_badge_class(:failed),
    do: "px-2 py-1 bg-red-100 text-red-800 text-xs rounded font-semibold"

  defp state_badge_class(:expired),
    do: "px-2 py-1 bg-gray-100 text-gray-800 text-xs rounded font-semibold"

  defp state_label(:queued), do: "Queued"
  defp state_label(:delivered), do: "Delivered"
  defp state_label(:reasoning), do: "Reasoning"
  defp state_label(:completed), do: "Completed"
  defp state_label(:failed), do: "Failed"
  defp state_label(:expired), do: "Expired"

  defp message_sender(%Message{sender_type: :operator, sender_id: id}), do: "Operator (#{id})"

  defp message_sender(%Message{sender_type: :cluster, sender_id: id}),
    do: "Cluster (#{String.slice(id, 0..8)})"

  defp message_sender(%Message{sender_type: :system}), do: "System"
  defp message_sender(_), do: "Unknown"

  defp format_time(datetime) do
    datetime
    |> DateTime.shift_zone!("Etc/UTC")
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S UTC")
  end

  defp allow_send?(%{:operator => %{role: role}}) when role in [:operator, :admin], do: true
  defp allow_send?(_), do: false

  defp atom_to_string(atom), do: Atom.to_string(atom)

  defp conversation_topic(organization_id), do: "conversations:#{organization_id}"

  @impl true
  def handle_event("select_conversation", %{"id" => conversation_id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/conversations/#{conversation_id}")}
  end

  def handle_event("back_to_list", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/conversations")}
  end

  def handle_event("send_message", %{"message" => body}, socket) do
    %{organization_id: organization_id} = socket.assigns.operator
    conversation = socket.assigns.selected_conversation

    socket = assign(socket, :sending_message, true)

    case send_operator_message(organization_id, conversation.id, body) do
      {:ok, _message} ->
        socket = assign(socket, :message_input, "")
        socket = assign(socket, :error_message, nil)
        messages = Conversations.list_messages(organization_id, conversation.id)
        socket = assign(socket, :messages, messages)
        socket = assign(socket, :sending_message, false)
        {:noreply, socket}

      {:error, reason} ->
        error_msg = format_error(reason)
        socket = assign(socket, :error_message, error_msg)
        socket = assign(socket, :sending_message, false)
        {:noreply, socket}
    end
  end

  defp send_operator_message(organization_id, conversation_id, body) do
    case Conversations.append_message(
           organization_id,
           conversation_id,
           %{
             body: String.trim(body),
             sender_type: :operator,
             sender_id: "operator"
           }
         ) do
      {:ok, message} ->
        # Broadcast to connected clients
        Phoenix.PubSub.broadcast(
          Exocomp.MissionControl.PubSub,
          conversation_topic(organization_id),
          {:message_added, message}
        )

        {:ok, message}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp format_error({:message_too_large, actual, max}) do
    "Message is too large: #{actual} bytes (max: #{max} bytes)"
  end

  defp format_error(:message_body_required), do: "Message body is required"
  defp format_error(:not_found), do: "Conversation not found"
  defp format_error(:cross_organization), do: "Access denied: organization mismatch"
  defp format_error(reason) when is_atom(reason), do: "Error: #{Atom.to_string(reason)}"
  defp format_error(reason), do: "Error: #{inspect(reason)}"
end

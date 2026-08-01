# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Conversations do
  use GenServer

  @moduledoc """
  Bounded, organization-scoped conversation store.

  This context owns the durable-domain boundary used by Mission Control. The
  current implementation is an in-memory GenServer so transport, database,
  and model integrations can be added independently. Its API and validation
  rules are intentionally the same rules a persistent adapter must preserve.

  Every operation takes an organization ID. A conversation from another
  organization is never returned or mutated. Conversations require a cluster
  and may optionally be attached to one incident.
  """

  alias Exocomp.MissionControl.{Conversation, EvidenceReference, Membership, Message}

  @max_context_messages 50
  @max_context_bytes 64 * 1024

  @type state :: %{
          conversations: %{String.t() => Conversation.t()},
          now: (-> DateTime.t()),
          id: (String.t() -> String.t())
        }

  @doc "Start an isolated conversation store."
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Create a cluster conversation, optionally attached to an incident."
  @spec create_conversation(String.t(), map(), keyword()) ::
          {:ok, Conversation.t()} | {:error, term()}
  def create_conversation(organization_id, attrs \\ %{}, opts \\ [])
      when is_binary(organization_id) and is_map(attrs) do
    call_server(opts, {:create, organization_id, attrs})
  end

  @doc "Convenience constructor for an ad hoc cluster conversation."
  @spec create_cluster_conversation(String.t(), String.t(), keyword()) ::
          {:ok, Conversation.t()} | {:error, term()}
  def create_cluster_conversation(organization_id, cluster_id, opts \\ []) do
    attrs = %{
      cluster_id: cluster_id,
      incident_id: Keyword.get(opts, :incident_id),
      title: Keyword.get(opts, :title)
    }

    create_conversation(organization_id, attrs, opts)
  end

  @doc "Convenience constructor for an incident-attached cluster conversation."
  @spec create_incident_conversation(String.t(), String.t(), String.t(), keyword()) ::
          {:ok, Conversation.t()} | {:error, term()}
  def create_incident_conversation(organization_id, incident_id, cluster_id, opts \\ []) do
    create_conversation(
      organization_id,
      %{cluster_id: cluster_id, incident_id: incident_id, title: Keyword.get(opts, :title)},
      opts
    )
  end

  @doc "Fetch a conversation only when it belongs to `organization_id`."
  @spec get(String.t(), String.t(), keyword()) ::
          {:ok, Conversation.t()} | {:error, :not_found}
  def get(organization_id, conversation_id, opts \\ []) do
    call_server(opts, {:get, organization_id, conversation_id})
  end

  @doc "List only the conversations owned by an organization, in creation order."
  @spec list(String.t(), keyword()) :: [Conversation.t()]
  def list(organization_id, opts \\ []) do
    call_server(opts, {:list, organization_id})
  end

  @doc "Add an operator or cluster membership to a conversation."
  @spec add_membership(String.t(), String.t(), map() | Membership.t(), keyword()) ::
          {:ok, Membership.t()} | {:error, term()}
  def add_membership(organization_id, conversation_id, attrs, opts \\ []) do
    call_server(opts, {:add_membership, organization_id, conversation_id, attrs})
  end

  @doc "Convenience membership API for callers with separate type and ID."
  @spec add_member(String.t(), String.t(), atom() | String.t(), String.t(), keyword()) ::
          {:ok, Membership.t()} | {:error, term()}
  def add_member(organization_id, conversation_id, member_type, member_id, opts \\ []) do
    add_membership(
      organization_id,
      conversation_id,
      %{member_type: member_type, member_id: member_id},
      opts
    )
  end

  @doc "Append a queued message and assign its next conversation sequence."
  @spec append_message(String.t(), String.t(), map() | Message.t(), keyword()) ::
          {:ok, Message.t()} | {:error, term()}
  def append_message(organization_id, conversation_id, attrs, opts \\ []) do
    call_server(opts, {:append_message, organization_id, conversation_id, attrs})
  end

  @doc "Return ordered messages for an organization-owned conversation."
  @spec list_messages(String.t(), String.t(), keyword()) :: [Message.t()] | {:error, :not_found}
  def list_messages(organization_id, conversation_id, opts \\ []) do
    call_server(opts, {:list_messages, organization_id, conversation_id})
  end

  @doc "Transition a message through its queued/delivery/reasoning lifecycle."
  @spec transition_message(String.t(), String.t(), String.t(), Message.state(), keyword()) ::
          {:ok, Message.t()} | {:error, term()}
  def transition_message(organization_id, conversation_id, message_id, target, opts \\ []) do
    call_server(opts, {:transition_message, organization_id, conversation_id, message_id, target})
  end

  @doc "Convenience transition functions for delivery workers and model workers."
  def mark_delivered(org, conversation_id, message_id, opts \\ []),
    do: transition_message(org, conversation_id, message_id, :delivered, opts)

  def mark_reasoning(org, conversation_id, message_id, opts \\ []),
    do: transition_message(org, conversation_id, message_id, :reasoning, opts)

  def complete_message(org, conversation_id, message_id, opts \\ []),
    do: transition_message(org, conversation_id, message_id, :completed, opts)

  def fail_message(org, conversation_id, message_id, reason, opts \\ []) do
    call_server(opts, {:transition_message, org, conversation_id, message_id, :failed, reason})
  end

  def expire_message(org, conversation_id, message_id, opts \\ []),
    do: transition_message(org, conversation_id, message_id, :expired, opts)

  @doc "Select the newest bounded context from a conversation or message list."
  @spec select_context(Conversation.t() | [Message.t()], keyword()) :: [Message.t()]
  def select_context(%Conversation{messages: messages}, opts), do: select_context(messages, opts)

  def select_context(messages, opts) when is_list(messages) do
    max_messages = Keyword.get(opts, :max_messages, @max_context_messages)
    max_bytes = Keyword.get(opts, :max_bytes, @max_context_bytes)

    messages
    |> Enum.reverse()
    |> Enum.reduce_while({[], 0, 0}, fn message, {selected, count, bytes} ->
      message_bytes = Message.bytes(message)

      cond do
        count >= max_messages -> {:halt, {selected, count, bytes}}
        bytes + message_bytes > max_bytes -> {:halt, {selected, count, bytes}}
        true -> {:cont, {[message | selected], count + 1, bytes + message_bytes}}
      end
    end)
    |> elem(0)
  end

  @doc "Return the newest bounded context for a stored conversation."
  @spec context(String.t(), String.t(), keyword()) :: [Message.t()] | {:error, :not_found}
  def context(organization_id, conversation_id, opts \\ []) do
    case get(organization_id, conversation_id, opts) do
      {:ok, conversation} -> select_context(conversation, opts)
      error -> error
    end
  end

  @impl true
  def init(opts) do
    {:ok,
     %{
       conversations: %{},
       now: Keyword.get(opts, :now_fun, &DateTime.utc_now/0),
       id: Keyword.get(opts, :id_fun, &default_id/1)
     }}
  end

  @impl true
  def handle_call({:create, organization_id, attrs}, _from, state) do
    case validate_supplied_scope(attrs, :organization_id, organization_id) do
      :ok ->
        attrs = Map.put_new(attrs, :organization_id, organization_id)
        attrs = Map.put_new(attrs, :id, state.id.("conv_"))
        attrs = Map.put_new(attrs, :created_at, state.now.())

        case Conversation.new(attrs) do
          {:ok, conversation} ->
            if Map.has_key?(state.conversations, conversation.id) do
              {:reply, {:error, :already_exists}, state}
            else
              with {:ok, membership} <-
                     Membership.new(%{
                       id: state.id.("member_"),
                       organization_id: organization_id,
                       conversation_id: conversation.id,
                       member_type: :cluster,
                       member_id: conversation.cluster_id,
                       joined_at: conversation.created_at
                     }) do
                conversation = %{conversation | memberships: [membership]}
                {:reply, {:ok, conversation}, put_conversation(state, conversation)}
              end
            end

          {:error, _reason} = error ->
            {:reply, error, state}
        end

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:get, organization_id, conversation_id}, _from, state) do
    reply =
      case Map.get(state.conversations, conversation_id) do
        %Conversation{organization_id: ^organization_id} = conversation -> {:ok, conversation}
        _ -> {:error, :not_found}
      end

    {:reply, reply, state}
  end

  def handle_call({:list, organization_id}, _from, state) do
    conversations =
      state.conversations
      |> Map.values()
      |> Enum.filter(&(&1.organization_id == organization_id))
      |> Enum.sort_by(&{&1.created_at, &1.id})

    {:reply, conversations, state}
  end

  def handle_call({:add_membership, organization_id, conversation_id, attrs}, _from, state) do
    with {:ok, conversation} <- fetch_owned(state, organization_id, conversation_id),
         :ok <- validate_supplied_scope(attrs, :organization_id, organization_id),
         :ok <- validate_supplied_scope(attrs, :conversation_id, conversation_id),
         {:ok, attrs} <- membership_attrs(attrs, conversation, state),
         {:ok, membership} <- Membership.new(attrs),
         :ok <- validate_membership_scope(membership, conversation),
         :ok <- ensure_unique_membership(conversation, membership) do
      conversation =
        touch(%{conversation | memberships: conversation.memberships ++ [membership]}, state)

      {:reply, {:ok, membership}, put_conversation(state, conversation)}
    else
      {:error, _reason} = error -> {:reply, error, state}
    end
  end

  def handle_call({:append_message, organization_id, conversation_id, attrs}, _from, state) do
    with {:ok, conversation} <- fetch_owned(state, organization_id, conversation_id),
         :ok <- validate_supplied_scope(attrs, :organization_id, organization_id),
         :ok <- validate_supplied_scope(attrs, :conversation_id, conversation_id),
         {:ok, attrs} <- message_attrs(attrs, conversation, state),
         {:ok, message} <- Message.new(attrs),
         :ok <- validate_message_scope(message, conversation),
         :ok <- validate_evidence_input_scope(attrs, conversation),
         :ok <- validate_evidence_scope(message.evidence_refs, conversation) do
      message = %{message | sequence: length(conversation.messages) + 1}
      conversation = touch(%{conversation | messages: conversation.messages ++ [message]}, state)
      {:reply, {:ok, message}, put_conversation(state, conversation)}
    else
      {:error, _reason} = error -> {:reply, error, state}
    end
  end

  def handle_call({:list_messages, organization_id, conversation_id}, _from, state) do
    reply =
      with {:ok, conversation} <- fetch_owned(state, organization_id, conversation_id) do
        conversation.messages
      end

    {:reply, reply, state}
  end

  def handle_call(
        {:transition_message, organization_id, conversation_id, message_id, target},
        _from,
        state
      ) do
    transition_message(state, organization_id, conversation_id, message_id, target, nil)
  end

  def handle_call(
        {:transition_message, organization_id, conversation_id, message_id, target, reason},
        _from,
        state
      ) do
    transition_message(state, organization_id, conversation_id, message_id, target, reason)
  end

  defp transition_message(state, organization_id, conversation_id, message_id, target, reason) do
    with {:ok, conversation} <- fetch_owned(state, organization_id, conversation_id),
         {:ok, message} <- find_message(conversation, message_id),
         {:ok, message} <- Message.transition(message, target, at: state.now.(), reason: reason) do
      messages = Enum.map(conversation.messages, &if(&1.id == message.id, do: message, else: &1))
      conversation = touch(%{conversation | messages: messages}, state)
      {:reply, {:ok, message}, put_conversation(state, conversation)}
    else
      {:error, _reason} = error -> {:reply, error, state}
    end
  end

  defp fetch_owned(state, organization_id, conversation_id) do
    case Map.get(state.conversations, conversation_id) do
      %Conversation{organization_id: ^organization_id} = conversation -> {:ok, conversation}
      %Conversation{} -> {:error, :cross_organization}
      nil -> {:error, :not_found}
    end
  end

  defp membership_attrs(%Membership{} = membership, conversation, _state) do
    {:ok,
     Map.from_struct(membership) |> Map.put_new(:organization_id, conversation.organization_id)}
  end

  defp membership_attrs(attrs, conversation, state) when is_map(attrs) do
    attrs
    |> Map.put_new(:id, state.id.("member_"))
    |> Map.put_new(:organization_id, conversation.organization_id)
    |> Map.put_new(:conversation_id, conversation.id)
    |> then(&{:ok, &1})
  end

  defp membership_attrs(_attrs, _conversation, _state), do: {:error, :invalid_membership}

  defp message_attrs(%Message{} = message, conversation, _state) do
    {:ok,
     message
     |> Map.from_struct()
     |> Map.put_new(:organization_id, conversation.organization_id)
     |> Map.put_new(:conversation_id, conversation.id)}
  end

  defp message_attrs(attrs, conversation, _state) when is_map(attrs) do
    attrs
    |> Map.put_new(:organization_id, conversation.organization_id)
    |> Map.put_new(:conversation_id, conversation.id)
    |> normalize_evidence_defaults(conversation)
    |> then(&{:ok, &1})
  end

  defp message_attrs(_attrs, _conversation, _state), do: {:error, :invalid_message}

  defp normalize_evidence_defaults(attrs, conversation) do
    refs = Map.get(attrs, :evidence_refs, Map.get(attrs, "evidence_refs", []))

    refs =
      if is_list(refs) do
        Enum.map(refs, fn
          %EvidenceReference{} = reference ->
            reference

          reference when is_map(reference) ->
            reference
            |> Map.put_new(:organization_id, conversation.organization_id)
            |> Map.put_new(:cluster_id, conversation.cluster_id)

          reference ->
            reference
        end)
      else
        refs
      end

    Map.put(attrs, :evidence_refs, refs)
  end

  defp validate_membership_scope(%Membership{} = membership, conversation) do
    cond do
      membership.organization_id != conversation.organization_id ->
        {:error, :cross_organization}

      membership.conversation_id != conversation.id ->
        {:error, :wrong_conversation}

      membership.member_type == :cluster and membership.member_id != conversation.cluster_id ->
        {:error, :wrong_cluster}

      true ->
        :ok
    end
  end

  defp ensure_unique_membership(conversation, membership) do
    duplicate =
      Enum.any?(conversation.memberships, fn existing ->
        existing.member_type == membership.member_type and
          existing.member_id == membership.member_id
      end)

    if duplicate, do: {:error, :already_member}, else: :ok
  end

  defp validate_message_scope(%Message{} = message, conversation) do
    cond do
      message.organization_id != conversation.organization_id -> {:error, :cross_organization}
      message.conversation_id != conversation.id -> {:error, :wrong_conversation}
      true -> :ok
    end
  end

  defp validate_evidence_scope(references, conversation) do
    if Enum.all?(references, fn reference ->
         reference.organization_id == conversation.organization_id and
           reference.cluster_id == conversation.cluster_id
       end) do
      :ok
    else
      {:error, :cross_organization}
    end
  end

  defp validate_evidence_input_scope(attrs, conversation) when is_map(attrs) do
    case Map.get(attrs, :evidence_refs, Map.get(attrs, "evidence_refs", [])) do
      references when is_list(references) ->
        if Enum.all?(references, &evidence_belongs_to?(&1, conversation)) do
          :ok
        else
          {:error, :cross_organization}
        end

      _ ->
        :ok
    end
  end

  defp validate_evidence_input_scope(_attrs, _conversation), do: :ok

  defp evidence_belongs_to?(%EvidenceReference{} = reference, conversation) do
    reference.organization_id == conversation.organization_id and
      reference.cluster_id == conversation.cluster_id
  end

  defp evidence_belongs_to?(reference, conversation) when is_map(reference) do
    supplied_scope_matches?(reference, :organization_id, conversation.organization_id) and
      supplied_scope_matches?(reference, :cluster_id, conversation.cluster_id)
  end

  defp evidence_belongs_to?(_reference, _conversation), do: true

  defp find_message(conversation, message_id) do
    case Enum.find(conversation.messages, &(&1.id == message_id)) do
      nil -> {:error, :message_not_found}
      message -> {:ok, message}
    end
  end

  defp touch(conversation, state), do: %{conversation | updated_at: state.now.()}

  defp validate_supplied_scope(attrs, field, expected) when is_map(attrs) do
    if supplied_scope_matches?(attrs, field, expected) do
      :ok
    else
      {:error, :cross_organization}
    end
  end

  defp validate_supplied_scope(_attrs, _field, _expected), do: :ok

  defp supplied_scope_matches?(attrs, field, expected) do
    attrs
    |> supplied_values(field)
    |> Enum.all?(&(&1 == expected))
  end

  defp supplied_values(attrs, field) do
    [Map.get(attrs, field), Map.get(attrs, Atom.to_string(field))]
    |> Enum.reject(&is_nil/1)
  end

  defp put_conversation(state, conversation),
    do: %{state | conversations: Map.put(state.conversations, conversation.id, conversation)}

  defp call_server(opts, request),
    do: GenServer.call(Keyword.get(opts, :server, __MODULE__), request)

  defp default_id(prefix),
    do: prefix <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
end

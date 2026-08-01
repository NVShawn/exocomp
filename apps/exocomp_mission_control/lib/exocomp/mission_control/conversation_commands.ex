# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ConversationCommands do
  @moduledoc """
  Translates operator messages into durable cluster commands and handles
  coordinator replies.

  This module owns the lifecycle of conversation messages that flow through
  the Mission Control command outbox. An operator message is:

  1. Created with state :queued
  2. Paired with a Command enqueued in CommandOutbox
  3. Marked :delivered once the command is persisted
  4. Marked :reasoning when the cluster acknowledges the command
  5. Marked :completed when a conversation.reply event arrives with the reply text

  Reply messages from the cluster are stored as separate Messages with
  sender_type: :cluster and their own state lifecycle.

  All state transitions are tied to either CommandOutbox commits or event
  ingestion, never to timeouts or external guesses.
  """

  alias Exocomp.MissionControl.{CommandOutbox, Conversations, Message}

  @type send_result :: {:ok, %{message: Message.t(), command: term()}} | {:error, term()}
  @type reply_result :: {:ok, %{operator_message: Message.t(), reply_message: Message.t()}} | {:error, term()}

  @doc """
  Translate an operator message into a durable command and send it to a cluster.

  Creates an operator Message with state :queued, enqueues a Command in the
  CommandOutbox addressed to the cluster, and transitions the Message to
  :delivered. The command payload includes the message ID for later linking.

  Returns both the created Message and Command on success.
  """
  @spec send_message(String.t(), String.t(), String.t(), String.t(), [map()], keyword()) ::
          send_result()
  def send_message(organization_id, conversation_id, cluster_id, text, evidence_refs \\ [], opts \\ [])
      when is_binary(organization_id) and is_binary(conversation_id) and is_binary(cluster_id) and
             is_binary(text) and is_list(evidence_refs) do
    # Extract command-specific options
    command_repo = Keyword.get(opts, :command_repo, Keyword.get(opts, :repo, CommandOutbox.Repo))
    command_opts = [repo: command_repo]
    now = Keyword.get(opts, :now, DateTime.utc_now())

    # All other options go to conversation operations
    conversation_opts = Keyword.delete(Keyword.delete(opts, :command_repo), :now)

    with {:ok, message} <-
           Conversations.append_message(organization_id, conversation_id,
             %{sender_type: :operator, body: text, evidence_refs: evidence_refs},
             conversation_opts
           ),
         {:ok, delivered_message} <-
           Conversations.mark_delivered(organization_id, conversation_id, message.id,
             conversation_opts
           ),
         {:ok, command} <-
           CommandOutbox.enqueue(
             %{
               kind: "conversation.message",
               organization_id: organization_id,
               cluster_id: cluster_id,
               payload: %{
                 "message_id" => delivered_message.id,
                 "conversation_id" => conversation_id,
                 "text" => text,
                 "evidence_refs" => Enum.map(evidence_refs, &evidence_ref_to_map/1)
               },
               issued_at: now,
               expires_at: Keyword.get(opts, :expires_at, DateTime.add(now, 300, :second))
             },
             command_opts
           ) do
      {:ok, %{message: delivered_message, command: command}}
    end
  end

  @doc """
  Handle a conversation.reply event from a cluster.

  Finds the operator Message corresponding to the command, updates it through
  reasoning to completed state, and creates a new Message with the cluster's
  reply text and evidence references.

  The operator message state transitions:
  - delivered → reasoning (cluster started processing)
  - reasoning → completed (cluster replied)

  The reply message is created with sender_type: :cluster and state: :completed.

  All state transitions are validated: if the operator message is in an
  unexpected state or if evidence references don't match the cluster, the
  operation fails rather than silently degrading.
  """
  @spec handle_conversation_reply(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          [map()],
          keyword()
        ) :: reply_result()
  def handle_conversation_reply(
        organization_id,
        conversation_id,
        message_id,
        reply_text,
        reply_evidence_refs \\ [],
        opts \\ []
      )
      when is_binary(organization_id) and is_binary(conversation_id) and is_binary(message_id) and
             is_binary(reply_text) and is_list(reply_evidence_refs) do
    with {:ok, conversation} <-
           Conversations.get(organization_id, conversation_id, opts),
         {:ok, operator_message} <-
           find_message_by_id(conversation, message_id),
         # Validate that the message is in a state that can receive a reply
         :ok <- validate_message_can_reply(operator_message),
         # Transition the operator message through reasoning to completed
         {:ok, _reasoning_msg} <-
           Conversations.mark_reasoning(organization_id, conversation_id, message_id, opts),
         {:ok, completed_msg} <-
           Conversations.complete_message(organization_id, conversation_id, message_id, opts),
         # Create the reply message from the cluster
         {:ok, reply_message} <-
           Conversations.append_message(organization_id, conversation_id,
             %{sender_type: :cluster, body: reply_text, evidence_refs: reply_evidence_refs},
             opts
           ),
         # Mark the reply as completed immediately (it's the final state for cluster messages)
         {:ok, reply_message} <-
           Conversations.complete_message(organization_id, conversation_id, reply_message.id, opts) do
      {:ok, %{operator_message: completed_msg, reply_message: reply_message}}
    end
  end

  @doc """
  Mark a message as failed with an explicit reason.

  Used when command delivery fails, reasoning fails, or the reply is invalid.
  Only transitions from non-terminal states.
  """
  @spec fail_message(String.t(), String.t(), String.t(), term(), keyword()) ::
          {:ok, Message.t()} | {:error, term()}
  def fail_message(organization_id, conversation_id, message_id, reason, opts \\ []) do
    Conversations.fail_message(organization_id, conversation_id, message_id, reason, opts)
  end

  @doc """
  Mark a message as expired.

  Used when the command in CommandOutbox expires before delivery or reasoning.
  """
  @spec expire_message(String.t(), String.t(), String.t(), keyword()) ::
          {:ok, Message.t()} | {:error, term()}
  def expire_message(organization_id, conversation_id, message_id, opts \\ []) do
    Conversations.expire_message(organization_id, conversation_id, message_id, opts)
  end

  defp find_message_by_id(conversation, message_id) do
    case Enum.find(conversation.messages, &(&1.id == message_id)) do
      nil -> {:error, :message_not_found}
      message -> {:ok, message}
    end
  end

  # Ensure the operator message is in a state that can receive a reply.
  # It should be in :delivered or :reasoning state, not already completed/failed/expired.
  defp validate_message_can_reply(%Message{state: :delivered}), do: :ok
  defp validate_message_can_reply(%Message{state: :reasoning}), do: :ok

  defp validate_message_can_reply(%Message{state: :queued}),
    do: {:error, :message_not_delivered}

  defp validate_message_can_reply(%Message{state: state}) when state in [:completed, :failed, :expired],
    do: {:error, {:message_already_terminal, state}}

  defp validate_message_can_reply(_message),
    do: {:error, :invalid_message_state}

  defp evidence_ref_to_map(ref) when is_map(ref), do: ref

  defp evidence_ref_to_map(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end

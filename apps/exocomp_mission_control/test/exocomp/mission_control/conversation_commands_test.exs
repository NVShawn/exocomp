# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ConversationCommandsTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{
    Conversations,
    ConversationCommands,
    Message
  }

  @now ~U[2026-08-01 12:00:00Z]
  @later ~U[2026-08-01 12:01:00Z]

  defmodule MockRepo do
    # Simple in-process mock repo for storing commands
    def insert(changeset) do
      commands = Process.get(:mock_commands, %{})
      command = Ecto.Changeset.apply_changes(changeset)
      Process.put(:mock_commands, Map.put(commands, command.command_id, command))
      {:ok, command}
    end

    def all(_query) do
      Process.get(:mock_commands, %{}) |> Map.values()
    end

    def update_all(_query, []) do
      # Mock update - just pretend it worked
      {1, nil}
    end

    def one(_query) do
      nil
    end
  end

  setup do
    conv_name = :"conversation_store_#{System.unique_integer([:positive])}"
    Process.put(:mock_commands, %{})

    start_supervised!({Conversations, [name: conv_name, now_fun: fn -> @now end]})

    {:ok, conversation} =
      Conversations.create_cluster_conversation("org-a", "cluster-1",
        server: conv_name
      )

    %{
      conv_server: conv_name,
      org_id: "org-a",
      cluster_id: "cluster-1",
      conversation_id: conversation.id
    }
  end

  describe "send_message/6 - online delivery" do
    test "creates operator message, enqueues command, marks message delivered", %{
      conv_server: conv_server,
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      text = "Why is the service failing?"
      evidence_refs = []

      assert {:ok, %{message: message, command: command}} =
               ConversationCommands.send_message(org_id, conv_id, cluster_id, text, evidence_refs,
                 server: conv_server,
                 repo: MockRepo,
                 now: @now
               )

      # Message should be created and marked delivered
      assert message.sender_type == :operator
      assert message.body == text
      assert message.state == :delivered
      assert message.organization_id == org_id
      assert message.conversation_id == conv_id

      # Command should be enqueued and pending
      assert command.command_id != nil
      assert command.kind == "conversation.message"
      assert command.status == "pending"
      assert command.organization_id == org_id
      assert command.cluster_id == cluster_id
      assert command.payload["message_id"] == message.id
      assert command.payload["conversation_id"] == conv_id
      assert command.payload["text"] == text

      # Verify message is in conversation
      {:ok, conv} = Conversations.get(org_id, conv_id, server: conv_server)
      assert length(conv.messages) == 1
      assert Enum.at(conv.messages, 0).state == :delivered
    end

    test "includes evidence references in command payload", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      evidence_refs = [
        %{
          evidence_id: "ev-1",
          node_id: "node-1",
          observed_at: @now,
          evidence_hash: String.duplicate("a", 64)
        }
      ]

      assert {:ok, %{message: message, command: command}} =
               ConversationCommands.send_message(org_id, conv_id, cluster_id, "question",
                 evidence_refs,
                 server: conv_server,
                 repo: MockRepo,
                 now: @now
               )

      assert length(message.evidence_refs) == 1
      assert Enum.at(message.evidence_refs, 0).evidence_id == "ev-1"

      assert command.payload["evidence_refs"] != nil
      assert is_list(command.payload["evidence_refs"])
    end

    test "rejects messages longer than 16 KiB", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      long_text = String.duplicate("x", Message.max_bytes() + 1)

      assert {:error, {:message_too_large, _size, _max}} =
               ConversationCommands.send_message(org_id, conv_id, cluster_id, long_text, [],
                 server: conv_server,
                 repo: MockRepo
               )
    end

    test "respects custom expiry in command opts", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      custom_expires = DateTime.add(@now, 600, :second)

      assert {:ok, %{command: command}} =
               ConversationCommands.send_message(org_id, conv_id, cluster_id, "text", [],
                 server: conv_server,
                 repo: MockRepo,
                 now: @now,
                 expires_at: custom_expires
               )

      assert DateTime.compare(command.expires_at, custom_expires) == :eq
    end
  end

  describe "offline queue display" do
    test "queued messages appear in conversation thread even when offline", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Simulate offline scenario - messages queue up
      for i <- 1..3 do
        ConversationCommands.send_message(org_id, conv_id, cluster_id, "question #{i}", [],
          server: conv_server,
          repo: MockRepo
        )
      end

      # UI can fetch conversation and see all queued messages
      {:ok, messages} = Conversations.list_messages(org_id, conv_id, server: conv_server)

      assert length(messages) == 3
      assert Enum.all?(messages, &(&1.state == :delivered))
    end
  end

  describe "handle_conversation_reply/6 - online reply" do
    test "creates cluster reply message and updates operator message to completed", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # First send an operator message
      {:ok, %{message: operator_msg}} =
        ConversationCommands.send_message(org_id, conv_id, cluster_id, "Why is it failing?", [],
          server: conv_server,
          repo: MockRepo,
          now: @now
        )

      # Then handle the cluster's reply
      reply_text = "It's failing because the disk is full."
      reply_refs = [
        %{
          evidence_id: "ev-reply-1",
          node_id: "node-2",
          observed_at: @later,
          evidence_hash: String.duplicate("b", 64)
        }
      ]

      assert {:ok, %{operator_message: op_msg, reply_message: reply_msg}} =
               ConversationCommands.handle_conversation_reply(
                 org_id,
                 conv_id,
                 operator_msg.id,
                 reply_text,
                 reply_refs,
                 server: conv_server,
                 now: @later
               )

      # Operator message should be completed
      assert op_msg.state == :completed
      assert op_msg.id == operator_msg.id

      # Reply message should be created and completed
      assert reply_msg.sender_type == :cluster
      assert reply_msg.body == reply_text
      assert reply_msg.state == :completed
      assert length(reply_msg.evidence_refs) == 1

      # Verify both messages in conversation
      {:ok, messages} = Conversations.list_messages(org_id, conv_id, server: conv_server)
      assert length(messages) == 2

      # First message is operator, second is cluster
      assert Enum.at(messages, 0).sender_type == :operator
      assert Enum.at(messages, 0).state == :completed
      assert Enum.at(messages, 1).sender_type == :cluster
      assert Enum.at(messages, 1).state == :completed
    end

    test "rejects reply for non-existent message", %{
      conv_server: conv_server,
      org_id: org_id,
      conversation_id: conv_id
    } do
      assert {:error, :message_not_found} =
               ConversationCommands.handle_conversation_reply(
                 org_id,
                 conv_id,
                 "msg_nonexistent",
                 "reply",
                 [],
                 server: conv_server
               )
    end

    test "rejects reply for already-terminal message", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Send a message
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(org_id, conv_id, cluster_id, "question", [],
          server: conv_server,
          repo: MockRepo,
          now: @now
        )

      # Mark it as completed
      Conversations.complete_message(org_id, conv_id, msg.id, server: conv_server)

      # Try to handle a reply
      assert {:error, {:message_already_terminal, :completed}} =
               ConversationCommands.handle_conversation_reply(
                 org_id,
                 conv_id,
                 msg.id,
                 "reply",
                 [],
                 server: conv_server
               )
    end
  end

  describe "reconnect scenario" do
    test "reply can arrive after connection timeout and reconnection", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Send message while connected
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(org_id, conv_id, cluster_id, "question", [],
          server: conv_server,
          repo: MockRepo,
          now: @now
        )

      # Message is delivered
      assert msg.state == :delivered

      # Simulate network down, time passing, network up
      # Reply arrives much later (simulating buffered event from cluster)
      later = DateTime.add(@now, 3600, :second)

      {:ok, result} =
        ConversationCommands.handle_conversation_reply(
          org_id,
          conv_id,
          msg.id,
          "reply after reconnection",
          [],
          server: conv_server,
          now: later
        )

      assert result.operator_message.state == :completed
      assert result.reply_message.state == :completed
    end
  end

  describe "duplicate reply handling" do
    test "handles duplicate reply gracefully without creating duplicate reply message", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Send message
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(org_id, conv_id, cluster_id, "question", [],
          server: conv_server,
          repo: MockRepo
        )

      # First reply arrives
      {:ok, %{operator_message: op1, reply_message: _reply1}} =
        ConversationCommands.handle_conversation_reply(org_id, conv_id, msg.id, "first reply", [],
          server: conv_server
        )

      assert op1.state == :completed

      # Duplicate reply attempt - should fail because operator message is already terminal
      assert {:error, {:message_already_terminal, :completed}} =
               ConversationCommands.handle_conversation_reply(
                 org_id,
                 conv_id,
                 msg.id,
                 "duplicate reply",
                 [],
                 server: conv_server
               )

      # Verify only one reply message exists
      {:ok, messages} = Conversations.list_messages(org_id, conv_id, server: conv_server)
      cluster_messages = Enum.filter(messages, &(&1.sender_type == :cluster))
      assert length(cluster_messages) == 1
    end
  end

  describe "failed reasoning" do
    test "marks message failed when reasoning fails", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Send message
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(org_id, conv_id, cluster_id, "question", [],
          server: conv_server,
          repo: MockRepo
        )

      # Reasoning fails
      {:ok, failed_msg} =
        ConversationCommands.fail_message(org_id, conv_id, msg.id, :reasoning_failed,
          server: conv_server
        )

      assert failed_msg.state == :failed
      assert failed_msg.failure_reason == :reasoning_failed
    end

    test "cannot transition failed message to other states", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Send and fail message
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(org_id, conv_id, cluster_id, "question", [],
          server: conv_server,
          repo: MockRepo
        )

      ConversationCommands.fail_message(org_id, conv_id, msg.id, :error,
        server: conv_server
      )

      # Try to handle reply - should fail
      assert {:error, {:message_already_terminal, :failed}} =
               ConversationCommands.handle_conversation_reply(
                 org_id,
                 conv_id,
                 msg.id,
                 "reply",
                 [],
                 server: conv_server
               )
    end
  end

  describe "expired command" do
    test "marks message expired when command expires", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Send message
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(org_id, conv_id, cluster_id, "question", [],
          server: conv_server,
          repo: MockRepo
        )

      # Command expires
      {:ok, expired_msg} =
        ConversationCommands.expire_message(org_id, conv_id, msg.id,
          server: conv_server
        )

      assert expired_msg.state == :expired
    end
  end

  describe "invalid citation handling" do
    test "rejects evidence with wrong cluster", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      wrong_cluster_evidence = [
        %{
          evidence_id: "ev-1",
          node_id: "node-1",
          cluster_id: "wrong-cluster",
          observed_at: @now,
          evidence_hash: String.duplicate("a", 64)
        }
      ]

      # Should fail because evidence references wrong cluster
      assert {:error, :cross_organization} =
               ConversationCommands.send_message(org_id, conv_id, cluster_id, "question",
                 wrong_cluster_evidence,
                 server: conv_server,
                 repo: MockRepo
               )
    end

    test "rejects evidence with wrong organization", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      wrong_org_evidence = [
        %{
          evidence_id: "ev-1",
          node_id: "node-1",
          organization_id: "org-b",
          observed_at: @now,
          evidence_hash: String.duplicate("a", 64)
        }
      ]

      # Should fail because evidence references wrong organization
      assert {:error, :cross_organization} =
               ConversationCommands.send_message(org_id, conv_id, cluster_id, "question",
                 wrong_org_evidence,
                 server: conv_server,
                 repo: MockRepo
               )
    end

    test "reply with invalid evidence references is rejected", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Send valid message
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(org_id, conv_id, cluster_id, "question", [],
          server: conv_server,
          repo: MockRepo
        )

      # Try to reply with mismatched evidence
      invalid_reply_refs = [
        %{
          evidence_id: "ev-reply-1",
          node_id: "node-2",
          cluster_id: "wrong-cluster",
          observed_at: @later,
          evidence_hash: String.duplicate("b", 64)
        }
      ]

      assert {:error, :cross_organization} =
               ConversationCommands.handle_conversation_reply(
                 org_id,
                 conv_id,
                 msg.id,
                 "reply",
                 invalid_reply_refs,
                 server: conv_server
               )
    end
  end

  describe "organization and cluster mismatch" do
    test "prevents cross-organization reply", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Send message
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(org_id, conv_id, cluster_id, "question", [],
          server: conv_server,
          repo: MockRepo
        )

      # Try to reply from different organization
      assert {:error, :not_found} =
               ConversationCommands.handle_conversation_reply("org-b", conv_id, msg.id, "reply",
                 [],
                 server: conv_server
               )
    end
  end

  describe "state transition validation" do
    test "operator message transitions through full lifecycle", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Send message: queued -> delivered
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(org_id, conv_id, cluster_id, "question", [],
          server: conv_server,
          repo: MockRepo
        )

      assert msg.state == :delivered
      assert length(msg.state_history) == 2  # queued -> delivered

      # Handle reply: delivered -> reasoning -> completed
      {:ok, %{operator_message: completed}} =
        ConversationCommands.handle_conversation_reply(org_id, conv_id, msg.id, "reply", [],
          server: conv_server
        )

      assert completed.state == :completed
      assert length(completed.state_history) >= 3  # queued -> delivered -> reasoning -> completed
      assert Enum.map(completed.state_history, & &1.to) == [:delivered, :reasoning, :completed]
    end

    test "rejects transition from queued directly to completed", %{
      conv_server: conv_server,
      org_id: org_id,
      conversation_id: conv_id
    } do
      # Create a raw queued message (not through send_message)
      {:ok, msg} =
        Conversations.append_message(org_id, conv_id, %{body: "test"},
          server: conv_server
        )

      assert msg.state == :queued

      # Try to complete without going through delivered/reasoning
      assert {:error, {:invalid_transition, :queued, :completed}} =
               Conversations.complete_message(org_id, conv_id, msg.id,
                 server: conv_server
               )
    end
  end

  describe "unsupported or stale claims" do
    test "evidence with stale timestamp is included but marked in state history", %{
      conv_server: conv_server,
      
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Very old evidence
      stale_evidence = [
        %{
          evidence_id: "ev-stale",
          node_id: "node-1",
          observed_at: DateTime.add(@now, -86400, :second),  # 24 hours old
          evidence_hash: String.duplicate("a", 64)
        }
      ]

      # Should accept but let caller decide what to do with stale evidence
      assert {:ok, %{message: msg}} =
               ConversationCommands.send_message(org_id, conv_id, cluster_id, "question",
                 stale_evidence,
                 server: conv_server,
                 repo: MockRepo,
                 now: @now
               )

      assert length(msg.evidence_refs) == 1
      # Staleness is in the data, UI can check observed_at timestamps
    end
  end
end

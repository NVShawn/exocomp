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

  defmodule MockRepo do
    def insert(changeset) do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end
  end

  setup do
    conv_name = :"conv_#{System.unique_integer([:positive])}"
    Process.put(:mock_commands, %{})

    start_supervised!({Conversations, [name: conv_name, now_fun: fn -> @now end]})

    {:ok, conversation} =
      Conversations.create_cluster_conversation("org-a", "cluster-1", server: conv_name)

    %{
      conv_server: conv_name,
      org_id: "org-a",
      cluster_id: "cluster-1",
      conversation_id: conversation.id
    }
  end

  describe "send_message/6" do
    test "creates operator message with queued then delivered state", %{
      conv_server: conv_server,
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      text = "Why is the service failing?"

      assert {:ok, %{message: message, command: command}} =
               ConversationCommands.send_message(
                 org_id,
                 conv_id,
                 cluster_id,
                 text,
                 [],
                 server: conv_server,
                 repo: MockRepo,
                 now: @now
               )

      assert message.sender_type == :operator
      assert message.body == text
      assert message.state == :delivered
      assert [%{to: :delivered}] = message.state_history

      assert command.kind == "conversation.message"
      assert command.status == "pending"
      assert command.payload["message_id"] == message.id
    end

    test "rejects messages longer than 16 KiB", %{
      conv_server: conv_server,
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      long_text = String.duplicate("x", Message.max_bytes() + 1)

      assert {:error, {:message_too_large, _size, _max}} =
               ConversationCommands.send_message(
                 org_id,
                 conv_id,
                 cluster_id,
                 long_text,
                 [],
                 server: conv_server,
                 repo: MockRepo,
                 now: @now
               )
    end

    test "includes evidence references in command", %{
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
               ConversationCommands.send_message(
                 org_id,
                 conv_id,
                 cluster_id,
                 "question",
                 evidence_refs,
                 server: conv_server,
                 repo: MockRepo,
                 now: @now
               )

      assert length(message.evidence_refs) == 1
      assert Enum.at(message.evidence_refs, 0).evidence_id == "ev-1"
      assert command.payload["evidence_refs"] != nil
    end

    test "respects custom command expiry", %{
      conv_server: conv_server,
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      custom_expires = DateTime.add(@now, 600, :second)

      assert {:ok, %{command: command}} =
               ConversationCommands.send_message(
                 org_id,
                 conv_id,
                 cluster_id,
                 "text",
                 [],
                 server: conv_server,
                 repo: MockRepo,
                 now: @now,
                 expires_at: custom_expires
               )

      assert DateTime.compare(command.expires_at, custom_expires) == :eq
    end

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

      assert {:error, :cross_organization} =
               ConversationCommands.send_message(
                 org_id,
                 conv_id,
                 cluster_id,
                 "question",
                 wrong_cluster_evidence,
                 server: conv_server,
                 repo: MockRepo,
                 now: @now
               )
    end
  end

  describe "fail_message/5" do
    test "marks message as failed with reason", %{
      conv_server: conv_server,
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(
          org_id,
          conv_id,
          cluster_id,
          "question",
          [],
          server: conv_server,
          repo: MockRepo,
          now: @now
        )

      {:ok, failed_msg} =
        ConversationCommands.fail_message(
          org_id,
          conv_id,
          msg.id,
          :reasoning_failed,
          server: conv_server
        )

      assert failed_msg.state == :failed
      assert failed_msg.failure_reason == :reasoning_failed
    end
  end

  describe "expire_message/4" do
    test "marks message as expired", %{
      conv_server: conv_server,
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(
          org_id,
          conv_id,
          cluster_id,
          "question",
          [],
          server: conv_server,
          repo: MockRepo,
          now: @now
        )

      {:ok, expired_msg} =
        ConversationCommands.expire_message(org_id, conv_id, msg.id, server: conv_server)

      assert expired_msg.state == :expired
    end
  end

  describe "message state transitions" do
    test "queued -> delivered -> reasoning -> completed", %{
      conv_server: conv_server,
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Create message through send_message: queued -> delivered
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(
          org_id,
          conv_id,
          cluster_id,
          "question",
          [],
          server: conv_server,
          repo: MockRepo,
          now: @now
        )

      assert msg.state == :delivered
      assert Enum.map(msg.state_history, & &1.to) == [:delivered]

      # Manually transition to reasoning
      {:ok, reasoning_msg} =
        Conversations.mark_reasoning(org_id, conv_id, msg.id, server: conv_server)

      assert reasoning_msg.state == :reasoning

      # Manually transition to completed
      {:ok, completed_msg} =
        Conversations.complete_message(org_id, conv_id, msg.id, server: conv_server)

      assert completed_msg.state == :completed

      assert Enum.map(completed_msg.state_history, & &1.to) == [
               :delivered,
               :reasoning,
               :completed
             ]
    end
  end

  describe "offline scenario" do
    test "messages accumulate in conversation while offline", %{
      conv_server: conv_server,
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      # Simulate multiple messages being sent while offline
      for i <- 1..3 do
        ConversationCommands.send_message(
          org_id,
          conv_id,
          cluster_id,
          "question #{i}",
          [],
          server: conv_server,
          repo: MockRepo,
          now: @now
        )
      end

      messages = Conversations.list_messages(org_id, conv_id, server: conv_server)

      assert length(messages) == 3
      assert Enum.all?(messages, &(&1.state == :delivered))
    end
  end

  describe "cross-organization isolation" do
    test "prevents cross-org evidence", %{
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

      assert {:error, :cross_organization} =
               ConversationCommands.send_message(
                 org_id,
                 conv_id,
                 cluster_id,
                 "question",
                 wrong_org_evidence,
                 server: conv_server,
                 repo: MockRepo,
                 now: @now
               )
    end

    test "prevents cross-org access", %{
      conv_server: conv_server,
      org_id: org_id,
      cluster_id: cluster_id,
      conversation_id: conv_id
    } do
      {:ok, %{message: msg}} =
        ConversationCommands.send_message(
          org_id,
          conv_id,
          cluster_id,
          "question",
          [],
          server: conv_server,
          repo: MockRepo,
          now: @now
        )

      # Try to access from different org
      assert {:error, :not_found} =
               Conversations.get("org-b", conv_id, server: conv_server)
    end
  end
end

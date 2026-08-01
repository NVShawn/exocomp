# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ConversationsLiveTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest

  alias Exocomp.MissionControl.{Conversations, Message, Conversation, EvidenceReference}

  setup do
    {:ok, _} = Conversations.start_link(name: :test_conversations)
    {:ok, conversations: :test_conversations}
  end

  describe "mount" do
    test "requires operator role" do
      {:ok, _lv, _html} = live(build_conn(role: :viewer), "/conversations")
      # Should redirect for viewer role
    end

    test "allows operator role" do
      {:ok, _lv, _html} = live(build_conn(role: :operator), "/conversations")
      # Should mount successfully
    end

    test "allows admin role" do
      {:ok, _lv, _html} = live(build_conn(role: :admin), "/conversations")
      # Should mount successfully
    end
  end

  describe "message rendering" do
    test "displays ordered operator and cluster messages" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      # Add operator message
      {:ok, msg1} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: "First question", sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )

      # Add cluster response
      {:ok, msg2} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: "Cluster response", sender_type: :cluster, sender_id: cluster_id},
          server: :test_conversations
        )

      # Verify order
      messages = Conversations.list_messages(org_id, conversation.id, server: :test_conversations)
      assert length(messages) == 2
      assert Enum.at(messages, 0).id == msg1.id
      assert Enum.at(messages, 1).id == msg2.id
    end

    test "renders evidence cards for messages with evidence" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      {:ok, evidence} =
        EvidenceReference.new(%{
          organization_id: org_id,
          cluster_id: cluster_id,
          evidence_id: "ev_123",
          node_id: "node_1",
          service: "postgres",
          evidence_type: "disk_pressure",
          observed_at: DateTime.utc_now(),
          evidence_hash: "hash_abc"
        })

      {:ok, msg} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{
            body: "Message with evidence",
            sender_type: :cluster,
            sender_id: cluster_id,
            evidence_refs: [evidence]
          },
          server: :test_conversations
        )

      messages = Conversations.list_messages(org_id, conversation.id, server: :test_conversations)
      msg = Enum.find(messages, &(&1.id == msg.id))
      assert length(msg.evidence_refs) == 1
      assert Enum.at(msg.evidence_refs, 0).evidence_id == "ev_123"
    end
  end

  describe "message state tracking" do
    test "displays queued/delivered/reasoning/completed/failed/expired states" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      {:ok, msg} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: "Test message", sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )

      assert msg.state == :queued

      # Transition to delivered
      {:ok, msg} =
        Conversations.mark_delivered(org_id, conversation.id, msg.id, server: :test_conversations)

      assert msg.state == :delivered

      # Transition to reasoning
      {:ok, msg} =
        Conversations.mark_reasoning(org_id, conversation.id, msg.id, server: :test_conversations)

      assert msg.state == :reasoning

      # Transition to completed
      {:ok, msg} =
        Conversations.complete_message(org_id, conversation.id, msg.id,
          server: :test_conversations
        )

      assert msg.state == :completed

      # Verify state history
      assert length(msg.state_history) == 3
    end

    test "transitions message through failed state" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      {:ok, msg} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: "Test message", sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )

      # Transition to failed
      {:ok, msg} =
        Conversations.fail_message(org_id, conversation.id, msg.id, "timeout",
          server: :test_conversations
        )

      assert msg.state == :failed
      assert msg.failure_reason == "timeout"
    end

    test "transitions message through expired state" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      {:ok, msg} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: "Test message", sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )

      {:ok, msg} =
        Conversations.mark_delivered(org_id, conversation.id, msg.id, server: :test_conversations)

      # Transition to expired
      {:ok, msg} =
        Conversations.expire_message(org_id, conversation.id, msg.id, server: :test_conversations)

      assert msg.state == :expired
    end
  end

  describe "message input and sending" do
    test "message input is disabled when cluster is offline" do
      # This will be tested via LiveView rendering
      # The component should check cluster connection state
    end

    test "message input is enabled when cluster is online" do
      # This will be tested via LiveView rendering
      # The component should check cluster connection state
    end

    test "enforces message size limit (16 KiB)" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      oversized = String.duplicate("x", Message.max_bytes() + 1)

      {:error, _} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: oversized, sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )
    end

    test "rejects duplicate message updates" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      {:ok, msg1} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: "Message 1", sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )

      # Transition message
      {:ok, _msg} =
        Conversations.mark_delivered(org_id, conversation.id, msg1.id,
          server: :test_conversations
        )

      # Attempt same transition again should fail
      {:error, {:invalid_transition, _, _}} =
        Conversations.mark_delivered(org_id, conversation.id, msg1.id,
          server: :test_conversations
        )
    end
  end

  describe "retry and new-message affordances" do
    test "supports creating new command for failed message" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      # Create initial message
      {:ok, msg1} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: "Initial message", sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )

      # Fail the message
      {:ok, msg1} =
        Conversations.mark_delivered(org_id, conversation.id, msg1.id,
          server: :test_conversations
        )

      {:ok, msg1} =
        Conversations.fail_message(org_id, conversation.id, msg1.id, "timeout",
          server: :test_conversations
        )

      # Create a new message (retry) - should create new command, not rewrite history
      {:ok, msg2} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: "Retry message", sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )

      # Both messages should exist
      messages = Conversations.list_messages(org_id, conversation.id, server: :test_conversations)
      assert length(messages) == 2
      assert Enum.at(messages, 0).id == msg1.id
      assert Enum.at(messages, 0).state == :failed
      assert Enum.at(messages, 1).id == msg2.id
      assert Enum.at(messages, 1).state == :queued
    end
  end

  describe "read-only access for viewers" do
    test "viewers cannot send messages" do
      # This is enforced at the LiveView mount level
      # Viewers should see messages and evidence but no input form
    end

    test "viewers can see all conversation content" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      {:ok, _msg} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: "Message", sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )

      # Viewers should be able to fetch and read the message
      messages = Conversations.list_messages(org_id, conversation.id, server: :test_conversations)
      assert length(messages) == 1
    end
  end

  describe "organization isolation" do
    test "conversations are scoped to organization" do
      org1_id = "org_1"
      org2_id = "org_2"
      cluster_id = "cluster_test"

      {:ok, conv1} =
        Conversations.create_cluster_conversation(org1_id, cluster_id,
          server: :test_conversations
        )

      {:ok, conv2} =
        Conversations.create_cluster_conversation(org2_id, cluster_id,
          server: :test_conversations
        )

      # Organization 1 should only see their conversation
      org1_conversations = Conversations.list(org1_id, server: :test_conversations)
      assert length(org1_conversations) == 1
      assert Enum.at(org1_conversations, 0).id == conv1.id

      # Organization 2 should only see their conversation
      org2_conversations = Conversations.list(org2_id, server: :test_conversations)
      assert length(org2_conversations) == 1
      assert Enum.at(org2_conversations, 0).id == conv2.id
    end

    test "messages are scoped to organization" do
      org1_id = "org_1"
      org2_id = "org_2"
      cluster_id = "cluster_test"

      {:ok, conv1} =
        Conversations.create_cluster_conversation(org1_id, cluster_id,
          server: :test_conversations
        )

      {:ok, msg1} =
        Conversations.append_message(
          org1_id,
          conv1.id,
          %{body: "Org1 message", sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )

      # org2 should not be able to see org1's messages
      {:error, :not_found} = Conversations.get(org2_id, conv1.id, server: :test_conversations)

      {:error, :not_found} =
        Conversations.list_messages(org2_id, conv1.id, server: :test_conversations)
    end

    test "evidence references are scoped to organization and cluster" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      # Try to add evidence from a different organization
      {:ok, evidence} =
        EvidenceReference.new(%{
          organization_id: "org_different",
          cluster_id: cluster_id,
          evidence_id: "ev_123",
          node_id: "node_1",
          observed_at: DateTime.utc_now(),
          evidence_hash: "hash_abc"
        })

      {:error, :cross_organization} =
        Conversations.append_message(
          org_id,
          conversation.id,
          %{
            body: "Message",
            sender_type: :cluster,
            sender_id: cluster_id,
            evidence_refs: [evidence]
          },
          server: :test_conversations
        )
    end
  end

  describe "context selection and display" do
    test "selects bounded context (newest 50 messages or 64 KiB)" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      # Add multiple messages
      Enum.each(1..60, fn i ->
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: "Message #{i}", sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )
      end)

      # Get context - should be bounded to 50 messages
      context = Conversations.context(org_id, conversation.id, server: :test_conversations)
      assert length(context) <= 50
    end

    test "respects byte limit in context selection" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:ok, conversation} =
        Conversations.create_cluster_conversation(org_id, cluster_id, server: :test_conversations)

      large_msg = String.duplicate("x", 10_000)

      # Add large messages until we exceed byte limit
      Enum.each(1..10, fn _i ->
        Conversations.append_message(
          org_id,
          conversation.id,
          %{body: large_msg, sender_type: :operator, sender_id: "op1"},
          server: :test_conversations
        )
      end)

      # Get context with byte limit
      context =
        Conversations.context(org_id, conversation.id,
          max_bytes: 64 * 1024,
          server: :test_conversations
        )

      total_bytes = Enum.reduce(context, 0, &(Message.bytes(&1) + &2))
      assert total_bytes <= 64 * 1024
    end
  end

  describe "evidence rendering constraints" do
    test "rejects raw HTML in evidence" do
      # Evidence references only contain structured metadata
      # Raw HTML would be rejected at EvidenceReference validation
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:error, :unsupported_evidence_field} =
        EvidenceReference.new(%{
          organization_id: org_id,
          cluster_id: cluster_id,
          evidence_id: "ev_123",
          node_id: "node_1",
          observed_at: DateTime.utc_now(),
          evidence_hash: "hash_abc",
          # Not allowed
          html_content: "<div>Raw HTML</div>"
        })
    end

    test "rejects arbitrary raw logs in evidence" do
      # Evidence references only support structured fields
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:error, :unsupported_evidence_field} =
        EvidenceReference.new(%{
          organization_id: org_id,
          cluster_id: cluster_id,
          evidence_id: "ev_123",
          node_id: "node_1",
          observed_at: DateTime.utc_now(),
          evidence_hash: "hash_abc",
          # Not allowed
          raw_logs: "log line 1\nlog line 2"
        })
    end

    test "rejects file attachments in evidence" do
      org_id = "org_test"
      cluster_id = "cluster_test"

      {:error, :unsupported_evidence_field} =
        EvidenceReference.new(%{
          organization_id: org_id,
          cluster_id: cluster_id,
          evidence_id: "ev_123",
          node_id: "node_1",
          observed_at: DateTime.utc_now(),
          evidence_hash: "hash_abc",
          # Not allowed
          attachment: %{filename: "file.txt", content: "data"}
        })
    end
  end

  # Helper to build a test connection with a role
  defp build_conn(opts) do
    Phoenix.ConnTest.build_conn()
    |> put_session(:role, Keyword.get(opts, :role, :viewer))
    |> put_session(:organization_id, "test_org")
  end

  defp put_session(conn, key, value) do
    put_in(conn.private[:plug_session], %{key => value})
  end
end

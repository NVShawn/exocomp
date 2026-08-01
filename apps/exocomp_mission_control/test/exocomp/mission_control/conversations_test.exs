# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ConversationsTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{Conversation, Conversations, Message}

  @now ~U[2026-08-01 12:00:00Z]

  setup do
    name = :"conversation_store_#{System.unique_integer([:positive])}"

    start_supervised!(
      {Conversations,
       [
         name: name,
         now_fun: fn -> @now end,
         id_fun: fn prefix -> prefix <> Integer.to_string(System.unique_integer([:positive])) end
       ]}
    )

    %{server: name}
  end

  test "creates incident and ad hoc cluster conversations with cluster membership", %{
    server: server
  } do
    assert {:ok, incident} =
             Conversations.create_incident_conversation(
               "org-a",
               "incident-1",
               "cluster-1",
               server: server
             )

    assert incident.kind == :incident
    assert incident.incident_id == "incident-1"
    assert [%{member_type: :cluster, member_id: "cluster-1"}] = incident.memberships

    assert {:ok, ad_hoc} =
             Conversations.create_cluster_conversation("org-a", "cluster-2", server: server)

    assert Conversation.cluster?(ad_hoc)
    assert ad_hoc.incident_id == nil

    assert {:ok, membership} =
             Conversations.add_member("org-a", incident.id, :operator, "operator-1",
               server: server
             )

    assert membership.member_type == :operator
    assert membership.organization_id == "org-a"
  end

  test "assigns monotonically increasing message sequence numbers", %{server: server} do
    {:ok, conversation} =
      Conversations.create_cluster_conversation("org-a", "cluster-1", server: server)

    assert {:ok, first} =
             Conversations.append_message("org-a", conversation.id, %{body: "first"},
               server: server
             )

    assert {:ok, second} =
             Conversations.append_message("org-a", conversation.id, %{body: "second"},
               server: server
             )

    assert [1, 2] =
             Conversations.list_messages("org-a", conversation.id, server: server)
             |> Enum.map(& &1.sequence)

    assert first.sequence == 1
    assert second.sequence == 2
  end

  test "enforces the 16 KiB text limit and rejects attachments and raw logs", %{server: server} do
    {:ok, conversation} =
      Conversations.create_cluster_conversation("org-a", "cluster-1", server: server)

    assert {:ok, message} =
             Conversations.append_message(
               "org-a",
               conversation.id,
               %{body: String.duplicate("x", Message.max_bytes())},
               server: server
             )

    assert byte_size(message.body) == Message.max_bytes()

    assert {:error, {:message_too_large, 16_385, 16_384}} =
             Conversations.append_message(
               "org-a",
               conversation.id,
               %{body: String.duplicate("x", Message.max_bytes() + 1)},
               server: server
             )

    assert {:error, {:unsupported_message_field, :attachments}} =
             Conversations.append_message(
               "org-a",
               conversation.id,
               %{body: "not a file", attachments: [%{name: "dump.txt"}]},
               server: server
             )

    assert {:error, {:unsupported_message_field, :raw_log}} =
             Conversations.append_message(
               "org-a",
               conversation.id,
               %{body: "not a blob", raw_log: String.duplicate("log ", 100)},
               server: server
             )

    assert {:error, :invalid_evidence_references} =
             Conversations.append_message(
               "org-a",
               conversation.id,
               %{body: "invalid reference shape", evidence_refs: "raw blob"},
               server: server
             )
  end

  test "selects newest 50 messages in chronological order", %{server: server} do
    {:ok, conversation} =
      Conversations.create_cluster_conversation("org-a", "cluster-1", server: server)

    for sequence <- 1..55 do
      assert {:ok, _message} =
               Conversations.append_message(
                 "org-a",
                 conversation.id,
                 %{body: "message #{sequence}"},
                 server: server
               )
    end

    context = Conversations.context("org-a", conversation.id, server: server)

    assert length(context) == 50
    assert Enum.map(context, & &1.sequence) == Enum.to_list(6..55)
  end

  test "selects a newest context no larger than 64 KiB", %{server: server} do
    {:ok, conversation} =
      Conversations.create_cluster_conversation("org-a", "cluster-1", server: server)

    for _ <- 1..5 do
      assert {:ok, _message} =
               Conversations.append_message(
                 "org-a",
                 conversation.id,
                 %{body: String.duplicate("x", 16_000)},
                 server: server
               )
    end

    context = Conversations.context("org-a", conversation.id, server: server)

    assert length(context) == 4
    assert Enum.map(context, & &1.sequence) == [2, 3, 4, 5]
    assert Enum.sum(Enum.map(context, &Message.bytes/1)) <= 64 * 1024
  end

  test "stores structured evidence references and rejects payload fields", %{server: server} do
    {:ok, conversation} =
      Conversations.create_cluster_conversation("org-a", "cluster-1", server: server)

    reference = %{
      evidence_id: "evidence-1",
      node_id: "node-1",
      observed_at: @now,
      evidence_hash: String.duplicate("a", 64)
    }

    assert {:ok, message} =
             Conversations.append_message(
               "org-a",
               conversation.id,
               %{body: "The service is unhealthy.", evidence_refs: [reference]},
               server: server
             )

    assert [%{organization_id: "org-a", cluster_id: "cluster-1", evidence_id: "evidence-1"}] =
             message.evidence_refs

    assert {:error, {:unsupported_evidence_field, :raw_log}} =
             Conversations.append_message(
               "org-a",
               conversation.id,
               %{
                 body: "unsupported",
                 evidence_refs: [Map.put(reference, :raw_log, "journal output")]
               },
               server: server
             )

    assert {:error, :cross_organization} =
             Conversations.append_message(
               "org-a",
               conversation.id,
               %{
                 body: "wrong owner",
                 evidence_refs: [Map.put(reference, :organization_id, "org-b")]
               },
               server: server
             )
  end

  test "tracks legal lifecycle states and rejects terminal rewrites", %{server: server} do
    {:ok, conversation} =
      Conversations.create_cluster_conversation("org-a", "cluster-1", server: server)

    {:ok, message} =
      Conversations.append_message("org-a", conversation.id, %{body: "question"}, server: server)

    assert {:ok, %{state: :delivered}} =
             Conversations.mark_delivered("org-a", conversation.id, message.id, server: server)

    assert {:ok, %{state: :reasoning}} =
             Conversations.mark_reasoning("org-a", conversation.id, message.id, server: server)

    assert {:ok, %{state: :completed, state_history: history}} =
             Conversations.complete_message("org-a", conversation.id, message.id, server: server)

    assert Enum.map(history, & &1.to) == [:delivered, :reasoning, :completed]

    assert {:error, {:invalid_transition, :completed, :failed}} =
             Conversations.fail_message(
               "org-a",
               conversation.id,
               message.id,
               :late_failure,
               server: server
             )

    {:ok, expiring} =
      Conversations.append_message("org-a", conversation.id, %{body: "expires"}, server: server)

    assert {:ok, %{state: :expired}} =
             Conversations.expire_message("org-a", conversation.id, expiring.id, server: server)

    {:ok, failing} =
      Conversations.append_message("org-a", conversation.id, %{body: "fails"}, server: server)

    assert {:ok, %{state: :failed, failure_reason: :delivery_failed}} =
             Conversations.fail_message(
               "org-a",
               conversation.id,
               failing.id,
               :delivery_failed,
               server: server
             )
  end

  test "isolates reads and writes by organization", %{server: server} do
    {:ok, conversation} =
      Conversations.create_cluster_conversation("org-a", "cluster-1", server: server)

    assert {:error, :not_found} = Conversations.get("org-b", conversation.id, server: server)
    assert [] = Conversations.list("org-b", server: server)

    assert {:error, :cross_organization} =
             Conversations.append_message(
               "org-b",
               conversation.id,
               %{body: "cross-org write"},
               server: server
             )

    assert {:error, :cross_organization} =
             Conversations.add_member("org-b", conversation.id, :operator, "operator-2",
               server: server
             )

    assert {:ok, _} =
             Conversations.append_message("org-a", conversation.id, %{body: "owner write"},
               server: server
             )
  end
end
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.EventOutboxTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.EventOutbox

  defp unique_name, do: String.to_atom("event_outbox_test_#{System.unique_integer([:positive])}")

  defp start_outbox(path, opts \\ []) do
    name = unique_name()
    {:ok, pid} = EventOutbox.start_link(Keyword.merge([name: name, path: path], opts))
    {pid, name}
  end

  defp event(kind, payload \\ %{}) do
    %{
      kind: kind,
      occurred_at: "2026-08-01T00:00:00Z",
      correlation_id: "corr-test",
      payload: payload
    }
  end

  defp stop_outbox(pid), do: GenServer.stop(pid)

  @tag :tmp_dir
  test "allocates monotonic sequences and reopens state after a process restart", %{
    tmp_dir: tmp_dir
  } do
    path = Path.join(tmp_dir, "event_outbox.json")
    {pid, name} = start_outbox(path)

    assert {:ok, first} = EventOutbox.enqueue("cluster-a", event("alert.opened"), server: name)
    assert first.cluster_seq == 1
    stop_outbox(pid)

    {pid, name} = start_outbox(path)
    assert [reopened] = EventOutbox.events(server: name)
    assert reopened.event_id == first.event_id
    assert {:ok, second} = EventOutbox.enqueue("cluster-a", event("audit.event"), server: name)
    assert second.cluster_seq == 2
    stop_outbox(pid)
  end

  @tag :tmp_dir
  test "duplicate event IDs are idempotent and conflicting duplicates are rejected", %{
    tmp_dir: tmp_dir
  } do
    path = Path.join(tmp_dir, "event_outbox.json")
    {pid, name} = start_outbox(path)
    original = Map.put(event("alert.updated", %{"state" => "degraded"}), :event_id, "evt-fixed")

    assert {:ok, first} = EventOutbox.enqueue("cluster-a", original, server: name)
    assert {:ok, duplicate} = EventOutbox.enqueue("cluster-a", original, server: name)
    assert duplicate == first
    assert length(EventOutbox.events(server: name)) == 1

    conflicting = Map.put(original, :payload, %{"state" => "healthy"})

    assert {:error, {:duplicate_event_id, "evt-fixed"}} =
             EventOutbox.enqueue("cluster-a", conflicting, server: name)

    stop_outbox(pid)
  end

  @tag :tmp_dir
  test "coalesces only unsent status snapshots and preserves sequence continuity", %{
    tmp_dir: tmp_dir
  } do
    path = Path.join(tmp_dir, "event_outbox.json")
    {pid, name} = start_outbox(path)

    assert {:ok, old_snapshot} =
             EventOutbox.enqueue("cluster-a", event("status.snapshot", %{"state" => "old"}),
               server: name
             )

    assert {:ok, new_snapshot} =
             EventOutbox.enqueue("cluster-a", event("status.snapshot", %{"state" => "new"}),
               server: name
             )

    assert new_snapshot.cluster_seq == old_snapshot.cluster_seq
    assert new_snapshot.event_id != old_snapshot.event_id
    new_event_id = new_snapshot.event_id
    assert [%{event_id: ^new_event_id, sent: false}] = EventOutbox.events(server: name)

    assert {:ok, alert} = EventOutbox.enqueue("cluster-a", event("alert.opened"), server: name)
    assert alert.cluster_seq == 2
    assert :ok = EventOutbox.mark_sent(new_snapshot.event_id, server: name)

    assert {:ok, later_snapshot} =
             EventOutbox.enqueue("cluster-a", event("status.snapshot", %{"state" => "later"}),
               server: name
             )

    assert later_snapshot.cluster_seq == 3
    assert Enum.map(EventOutbox.events("cluster-a", server: name), & &1.cluster_seq) == [1, 2, 3]
    stop_outbox(pid)
  end

  @tag :tmp_dir
  test "retains every durable event kind across reconnect", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "event_outbox.json")
    {pid, name} = start_outbox(path)

    durable_kinds = [
      "alert.opened",
      "alert.updated",
      "alert.resolved",
      "conversation.reply",
      "proposal.created",
      "approval.result",
      "action.status",
      "audit.event"
    ]

    for kind <- durable_kinds do
      assert {:ok, _event} = EventOutbox.enqueue("cluster-a", event(kind), server: name)
    end

    stop_outbox(pid)
    {pid, name} = start_outbox(path)
    assert Enum.map(EventOutbox.events("cluster-a", server: name), & &1.kind) == durable_kinds
    stop_outbox(pid)
  end

  @tag :tmp_dir
  test "deletes only an acknowledged contiguous range and preserves the next sequence", %{
    tmp_dir: tmp_dir
  } do
    path = Path.join(tmp_dir, "event_outbox.json")
    {pid, name} = start_outbox(path)

    assert {:ok, first} = EventOutbox.enqueue("cluster-a", event("alert.opened"), server: name)
    assert {:ok, second} = EventOutbox.enqueue("cluster-a", event("audit.event"), server: name)

    assert {:ok, third} =
             EventOutbox.enqueue("cluster-a", event("proposal.created"), server: name)

    assert {:ok, deleted} = EventOutbox.acknowledge("cluster-a", 2, server: name)
    assert Enum.map(deleted, & &1.event_id) == [first.event_id, second.event_id]
    assert [remaining] = EventOutbox.events(server: name)
    assert remaining.event_id == third.event_id

    assert {:ok, [^third]} = EventOutbox.ack("cluster-a", 3, server: name)
    assert EventOutbox.events(server: name) == []
    stop_outbox(pid)

    {pid, name} = start_outbox(path)
    assert {:ok, next} = EventOutbox.enqueue("cluster-a", event("alert.opened"), server: name)
    assert next.cluster_seq == 4
    stop_outbox(pid)
  end

  @tag :tmp_dir
  test "redacts sensitive payload fields before persistence and validates schema", %{
    tmp_dir: tmp_dir
  } do
    path = Path.join(tmp_dir, "event_outbox.json")
    {pid, name} = start_outbox(path)

    assert {:ok, stored} =
             EventOutbox.enqueue(
               "cluster-a",
               event("audit.event", %{
                 "api_token" => "do-not-store",
                 "nested" => %{"password" => "also-do-not-store"},
                 "state" => :degraded
               }),
               server: name
             )

    assert stored.payload == %{
             "api_token" => "[REDACTED]",
             "nested" => %{"password" => "[REDACTED]"},
             "state" => "degraded"
           }

    contents = File.read!(path)
    refute contents =~ "do-not-store"
    refute contents =~ "also-do-not-store"

    assert {:error, {:invalid_event, :kind}} =
             EventOutbox.enqueue("cluster-a", event("unknown.kind"), server: name)

    assert {:error, {:invalid_event, :schema_version}} =
             EventOutbox.enqueue("cluster-a", Map.put(event("audit.event"), :schema_version, 2),
               server: name
             )

    stop_outbox(pid)
  end

  @tag :tmp_dir
  test "reports bounded storage instead of dropping an event", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "event_outbox.json")
    {pid, name} = start_outbox(path, max_storage_bytes: 180)

    assert {:error, :storage_full} =
             EventOutbox.enqueue(
               "cluster-a",
               event("audit.event", %{"data" => String.duplicate("x", 400)}),
               server: name
             )

    assert EventOutbox.events(server: name) == []
    stop_outbox(pid)
  end

  @tag :tmp_dir
  test "refuses corrupt state rather than reopening it as an empty queue", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "event_outbox.json")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "not-json")

    name = unique_name()

    assert {:error, {{:storage_unavailable, :event_outbox_corrupt}, _}} =
             start_supervised({EventOutbox, name: name, path: path})
  end
end

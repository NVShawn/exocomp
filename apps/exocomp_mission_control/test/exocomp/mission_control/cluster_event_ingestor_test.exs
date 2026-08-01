# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ClusterEventIngestorTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{ClusterEventIngestor, ClusterGateway}

  @identity %{
    spiffe_id: "spiffe://exocomp/organizations/org-a/clusters/cluster-a",
    organization_id: "org-a",
    cluster_id: "cluster-a",
    certificate_der: <<1>>
  }

  test "commits an event and acknowledges the highest contiguous sequence" do
    server = start_ingestor()

    assert {:ok,
            %{acknowledgement: 1, highest_contiguous_sequence: 1, gap?: false, duplicate?: false}} =
             ClusterEventIngestor.ingest(event(1), @identity, server)

    assert [committed] = ClusterEventIngestor.events(@identity, server)
    assert committed.event_id == "event-1"
  end

  test "deduplicates a replay without changing the acknowledgement" do
    server = start_ingestor()
    envelope = event(1)

    assert {:ok, %{duplicate?: false}} = ClusterEventIngestor.ingest(envelope, @identity, server)

    assert {:ok, %{duplicate?: true, acknowledgement: 1}} =
             ClusterEventIngestor.ingest(envelope, @identity, server)

    assert length(ClusterEventIngestor.events(@identity, server)) == 1
  end

  test "deduplicates by organization, cluster, and event ID" do
    server = start_ingestor()
    envelope = event(1)
    other_cluster = %{organization_id: "org-a", cluster_id: "cluster-b"}
    other_organization = %{organization_id: "org-b", cluster_id: "cluster-a"}

    assert {:ok, _} = ClusterEventIngestor.ingest(envelope, @identity, server)

    assert {:ok, %{duplicate?: false, acknowledgement: 1}} =
             ClusterEventIngestor.ingest(envelope, other_cluster, server)

    assert {:ok, %{duplicate?: false, acknowledgement: 1}} =
             ClusterEventIngestor.ingest(envelope, other_organization, server)
  end

  test "retains out-of-order delivery and advances acknowledgement only through a resolved gap" do
    server = start_ingestor()

    assert {:ok, %{acknowledgement: 0, gap?: true, sequence_status: :gap}} =
             ClusterEventIngestor.ingest(event(3), @identity, server)

    assert {:ok, %{acknowledgement: 1, gap?: true}} =
             ClusterEventIngestor.ingest(event(1), @identity, server)

    assert {:ok, %{acknowledgement: 3, gap?: false}} =
             ClusterEventIngestor.ingest(event(2), @identity, server)
  end

  test "rejects invalid payloads, identity override attempts, oversized events, and unsupported versions" do
    server = start_ingestor(max_event_bytes: 200)

    assert {:error, %{code: :invalid_event_schema}} =
             ClusterEventIngestor.ingest(Map.delete(event(1), :payload), @identity, server)

    assert {:error, %{code: :invalid_event_schema}} =
             ClusterEventIngestor.ingest(
               Map.put(event(1), :organization_id, "attacker-org"),
               @identity,
               server
             )

    assert {:error, %{code: :unsupported_event_schema_version}} =
             ClusterEventIngestor.ingest(%{event(1) | schema_version: 2}, @identity, server)

    assert {:error, %{code: :event_too_large}} =
             ClusterEventIngestor.ingest(
               %{event(1) | payload: %{"data" => String.duplicate("x", 500)}},
               @identity,
               server
             )

    assert ClusterEventIngestor.acknowledgement(@identity, server) == 0
    assert ClusterEventIngestor.events(@identity, server) == []
  end

  test "does not acknowledge an event when the transaction cannot persist" do
    test_pid = self()

    server =
      start_ingestor(
        persist_fn: fn snapshot ->
          send(test_pid, {:persist_attempt, snapshot})
          {:error, :disk_full}
        end
      )

    assert {:error, %{code: :event_persistence_failed}} =
             ClusterEventIngestor.ingest(event(1), @identity, server)

    assert_receive {:persist_attempt, %{cursors: %{}, events: events}}
    assert map_size(events) == 1
    assert ClusterEventIngestor.acknowledgement(@identity, server) == 0
    assert ClusterEventIngestor.events(@identity, server) == []
  end

  @tag :tmp_dir
  test "restores committed events and cursors after restart", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "events.bin")
    name = unique_name()
    {:ok, pid} = ClusterEventIngestor.start_link(name: name, store_path: path)

    assert {:ok, %{acknowledgement: 1}} = ClusterEventIngestor.ingest(event(1), @identity, name)
    GenServer.stop(pid)

    {:ok, restored} = ClusterEventIngestor.start_link(name: name, store_path: path)
    assert ClusterEventIngestor.acknowledgement(@identity, name) == 1
    assert length(ClusterEventIngestor.events(@identity, name)) == 1
    GenServer.stop(restored)
  end

  test "gateway sends a contiguous acknowledgement only after the event commits" do
    server = start_ingestor()
    state = gateway_state(server)

    assert {:push, {:text, acknowledgement}, ^state} =
             ClusterGateway.Socket.handle_in(
               {Jason.encode!(event(1)), opcode: :text},
               state
             )

    assert %{
             "type" => "ack",
             "organization_id" => "org-a",
             "cluster_id" => "cluster-a",
             "acknowledged_sequence" => 1
           } = Jason.decode!(acknowledgement)
  end

  test "gateway never sends an acknowledgement for an uncommitted event" do
    server = start_ingestor(persist_fn: fn _snapshot -> {:error, :disk_full} end)
    state = gateway_state(server)

    assert {:push, {:text, rejection}, ^state} =
             ClusterGateway.Socket.handle_in(
               {Jason.encode!(event(1)), opcode: :text},
               state
             )

    decoded = Jason.decode!(rejection)
    assert %{"type" => "error", "error" => "event_persistence_failed"} = decoded

    refute Map.has_key?(decoded, "acknowledged_sequence")
    assert ClusterEventIngestor.acknowledgement(@identity, server) == 0
  end

  defp gateway_state(server) do
    %{
      session_registry: self(),
      event_ingestor: server,
      session_id: "sess_test",
      identity: @identity
    }
  end

  defp start_ingestor(opts \\ []) do
    name = unique_name()
    start_supervised!({ClusterEventIngestor, Keyword.put_new(opts, :name, name)})
    name
  end

  defp unique_name, do: String.to_atom("event_ingestor_#{System.unique_integer([:positive])}")

  defp event(sequence) do
    %{
      schema_version: 1,
      event_id: "event-#{sequence}",
      cluster_seq: sequence,
      kind: "alert.opened",
      occurred_at: "2026-07-29T21:00:00Z",
      correlation_id: "corr-#{sequence}",
      payload: %{"message" => "test"}
    }
  end
end

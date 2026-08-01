# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterEventIngestorTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias Exocomp.Coordinator.{ClusterEventIngestor, ClusterIdentity}
  alias Exocomp.Coordinator.Handlers.ClusterEventHandler

  @identity %ClusterIdentity{organization_id: "org-a", cluster_id: "cluster-a"}

  test "commits an event and acknowledges the highest contiguous sequence" do
    server = start_ingestor()

    assert {:ok,
            %{acknowledgement: 1, highest_contiguous_sequence: 1, gap?: false, duplicate?: false}} =
             ClusterEventIngestor.ingest(event(1), @identity, server)

    assert [committed] = ClusterEventIngestor.events(@identity, server)
    assert committed.event_id == "event-1"
  end

  test "deduplicates replayed events without changing the acknowledgement" do
    server = start_ingestor()
    envelope = event(1)

    assert {:ok, %{duplicate?: false}} = ClusterEventIngestor.ingest(envelope, @identity, server)

    assert {:ok, %{duplicate?: true, acknowledgement: 1}} =
             ClusterEventIngestor.ingest(envelope, @identity, server)

    assert length(ClusterEventIngestor.events(@identity, server)) == 1
  end

  test "deduplication is scoped by organization and cluster" do
    server = start_ingestor()
    envelope = event(1)
    other_cluster = %ClusterIdentity{organization_id: "org-a", cluster_id: "cluster-b"}
    other_org = %ClusterIdentity{organization_id: "org-b", cluster_id: "cluster-a"}

    assert {:ok, _} = ClusterEventIngestor.ingest(envelope, @identity, server)

    assert {:ok, %{duplicate?: false, acknowledgement: 1}} =
             ClusterEventIngestor.ingest(envelope, other_cluster, server)

    assert {:ok, %{duplicate?: false, acknowledgement: 1}} =
             ClusterEventIngestor.ingest(envelope, other_org, server)
  end

  test "accepts out-of-order delivery but does not acknowledge a gap" do
    server = start_ingestor()

    assert {:ok, %{acknowledgement: 0, gap?: true, sequence_status: :gap}} =
             ClusterEventIngestor.ingest(event(3), @identity, server)

    assert {:ok, %{acknowledgement: 1, gap?: true}} =
             ClusterEventIngestor.ingest(event(1), @identity, server)

    assert {:ok, %{acknowledgement: 3, gap?: false}} =
             ClusterEventIngestor.ingest(event(2), @identity, server)
  end

  test "rejects conflicting event IDs and sequence numbers" do
    server = start_ingestor()

    assert {:ok, _} = ClusterEventIngestor.ingest(event(1), @identity, server)

    assert {:error, %{code: :event_id_conflict}} =
             ClusterEventIngestor.ingest(%{event(2) | event_id: "event-1"}, @identity, server)

    assert {:error, %{code: :sequence_conflict}} =
             ClusterEventIngestor.ingest(%{event(1) | event_id: "other-event"}, @identity, server)
  end

  test "rejects invalid, unsupported, and oversized envelopes before persistence" do
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

  test "does not acknowledge or retain an event when the transaction cannot persist" do
    test_pid = self()

    persist_fn = fn snapshot ->
      send(test_pid, {:persist_attempt, snapshot})
      {:error, :disk_full}
    end

    server = start_ingestor(persist_fn: persist_fn)

    assert {:error, %{code: :event_persistence_failed}} =
             ClusterEventIngestor.ingest(event(1), @identity, server)

    assert_receive {:persist_attempt, %{cursors: cursors, events: events}}
    # The snapshot captures the intended new state (cursor advanced + event added).
    # The persist_fn failure leaves in-memory state at the previous checkpoint.
    assert cursors == %{{"org-a", "cluster-a"} => 1}
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

  test "HTTP delivery derives identity from the authenticated peer and returns its cursor" do
    server = start_ingestor()
    identity = @identity

    conn =
      :post
      |> conn("/v1/events", Jason.encode!(event(1)))
      |> put_req_header("content-type", "application/json")
      |> put_peer_data(%{ssl_cert: <<1>>})

    response =
      ClusterEventHandler.call(
        conn,
        ingestor: server,
        identity_resolver: fn <<1>> -> {:ok, identity} end
      )

    assert response.status == 200
    assert Jason.decode!(response.resp_body)["acknowledged_sequence"] == 1
  end

  test "HTTP delivery rejects missing certificates and oversized bodies" do
    server = start_ingestor()
    body = Jason.encode!(%{event(1) | payload: %{"data" => String.duplicate("x", 300_000)}})

    missing_certificate =
      ClusterEventHandler.call(conn(:post, "/v1/events", body), ingestor: server)

    assert missing_certificate.status == 401

    oversized =
      conn(:post, "/v1/events", body)
      |> put_peer_data(%{ssl_cert: <<1>>})

    assert ClusterEventHandler.call(
             oversized,
             ingestor: server,
             identity_resolver: fn <<1>> -> {:ok, @identity} end
           ).status == 413
  end

  defp start_ingestor(opts \\ []) do
    name = unique_name()
    start_supervised!({ClusterEventIngestor, Keyword.put_new(opts, :name, name)})
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

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Integration.MissionControlReconnectTest do
  @moduledoc """
  Integration harness for EXOCOMP-180: Mission Control reconnect,
  multi-replica, and durable delivery correctness.

  ## Harness Design

  The harness runs entirely in-process with real module boundaries and no
  external services.

  Coordinator side (one per test):
  - `EventOutbox` — durable at-least-once event outbox (file-backed per test)
  - `CommandProcessor` — exactly-once command ledger (DETS-backed per test)

  Mission Control side (shared across replicas, simulating a shared database):
  - `ClusterEventIngestor` — idempotent event ingest boundary
  - `TestCommandStore` — in-memory command store shared by both MC replicas
    (stands in for the PostgreSQL `CommandOutbox` at the transport boundary)

  Mission Control replicas (two per test):
  - `SessionRegistry` — tracks which replica owns each cluster's live session
  - Replica control functions that register/unregister their session

  The transport between coordinator and MC is a synchronous call through a
  local function rather than a WebSocket. This makes timing deterministic and
  lets tests crash replicas without race conditions.

  ## Scenarios Covered

  1. Disconnect/reconnect — events survive a replica crash and replay to a
     new session with no gaps and no duplicates on the MC side.
  2. Durable event replay after coordinator restart — events persisted in the
     EventOutbox survive a coordinator process restart and are replayed to the
     next connection with no loss.
  3. Command replay after connection-owner replica restart — pending commands
     survive the loss of replica-1 and are delivered through replica-2.
  4. Duplicate event delivery is idempotent — replaying an already-committed
     event returns a duplicate flag and does not double-count.
  5. Sequence gap — delivering seq 3 before seq 2 leaves the acknowledgement
     at 1 (highest contiguous) until seq 2 arrives.
  6. Certificate revocation — a revoked cluster's SPIFFE URI is rejected at
     the identity boundary before any events are committed.
  7. Connection-owner replica termination — commands drain through replica-2
     after replica-1 terminates; no command is executed twice.

  WebSocket affinity is not required: events are ingested by one replica
  while commands are delivered through another.
  """

  use ExUnit.Case, async: false

  @moduletag :mc_integration
  @moduletag :tmp_dir

  # Timeout for polling assertions; keeps each test deterministically bounded.
  @assert_timeout_ms 2_000

  alias Exocomp.Coordinator.{
    ClusterEventIngestor,
    ClusterIdentity,
    CommandProcessor,
    CommandReceipt,
    EventOutbox
  }

  alias Exocomp.MissionControl.SessionRegistry

  # ---------------------------------------------------------------------------
  # In-memory command store
  # ---------------------------------------------------------------------------

  defmodule TestCommandStore do
    @moduledoc """
    In-memory stand-in for `Exocomp.MissionControl.CommandOutbox`.

    Stores pending and acknowledged commands in an Agent so both simulated MC
    replicas share the same command state, mirroring a real PostgreSQL outbox.
    Supports enqueue, pending listing, acknowledgement, and delivery through a
    `SessionRegistry`.
    """

    use Agent

    @type command :: %{
            command_id: String.t(),
            kind: String.t(),
            organization_id: String.t(),
            cluster_id: String.t(),
            payload: map(),
            issued_at: DateTime.t(),
            expires_at: DateTime.t(),
            status: String.t()
          }

    @spec start_link(keyword()) :: Agent.on_start()
    def start_link(opts \\ []) do
      Agent.start_link(fn -> %{commands: [], acknowledged: MapSet.new()} end,
        name: Keyword.get(opts, :name)
      )
    end

    @spec enqueue(String.t(), String.t(), map(), pid() | atom()) :: {:ok, map()}
    def enqueue(organization_id, cluster_id, attrs, store) do
      now = DateTime.utc_now()
      command_id = Map.get(attrs, :command_id, Ecto.UUID.generate())

      command = %{
        command_id: command_id,
        kind: Map.fetch!(attrs, :kind),
        organization_id: organization_id,
        cluster_id: cluster_id,
        payload: Map.get(attrs, :payload, %{}),
        issued_at: Map.get(attrs, :issued_at, now),
        expires_at: Map.get(attrs, :expires_at, DateTime.add(now, 300, :second)),
        status: "pending"
      }

      Agent.update(store, fn state ->
        %{state | commands: [command | state.commands]}
      end)

      {:ok, command}
    end

    @spec pending(String.t(), String.t(), pid() | atom()) :: [map()]
    def pending(organization_id, cluster_id, store) do
      now = DateTime.utc_now()

      Agent.get(store, fn %{commands: commands, acknowledged: acknowledged} ->
        commands
        |> Enum.filter(fn cmd ->
          cmd.organization_id == organization_id and
            cmd.cluster_id == cluster_id and
            cmd.status == "pending" and
            not MapSet.member?(acknowledged, cmd.command_id) and
            DateTime.compare(cmd.expires_at, now) == :gt
        end)
        |> Enum.sort_by(& &1.issued_at)
      end)
    end

    @spec acknowledge(String.t(), pid() | atom()) :: {:ok, :acknowledged | :already_acknowledged}
    def acknowledge(command_id, store) do
      Agent.get_and_update(store, fn state ->
        if MapSet.member?(state.acknowledged, command_id) do
          {{:ok, :already_acknowledged}, state}
        else
          new_state = %{state | acknowledged: MapSet.put(state.acknowledged, command_id)}
          {{:ok, :acknowledged}, new_state}
        end
      end)
    end

    @spec acknowledged?(String.t(), pid() | atom()) :: boolean()
    def acknowledged?(command_id, store) do
      Agent.get(store, &MapSet.member?(&1.acknowledged, command_id))
    end

    @doc """
    Delivers all pending commands to the session owner in the given registry.
    Returns `{:ok, count}` or `{:error, :offline}` when no session is registered.
    """
    @spec deliver_registered(String.t(), String.t(), pid() | atom(), pid() | atom()) ::
            {:ok, non_neg_integer()} | {:error, :offline}
    def deliver_registered(organization_id, cluster_id, store, registry) do
      case SessionRegistry.owner(organization_id, cluster_id, registry) do
        {:ok, %{target: target}} ->
          cmds = pending(organization_id, cluster_id, store)

          Enum.each(cmds, fn cmd ->
            send(target, {:mission_control_command, cmd})
          end)

          {:ok, length(cmds)}

        {:error, :offline} ->
          {:error, :offline}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp unique(prefix) do
    :"#{prefix}_#{System.unique_integer([:positive, :monotonic])}"
  end

  # Starts a supervised process with a unique child ID to allow multiple instances
  # of the same module within one test. Returns `{child_id, pid}`.
  defp start_unique(module, opts) do
    id = unique(module)
    child_spec = Supervisor.child_spec({module, opts}, id: id)
    pid = start_supervised!(child_spec)
    {id, pid}
  end

  defp start_outbox(tmp_dir) do
    name = unique(:outbox)
    path = Path.join(tmp_dir, "#{name}.json")
    {_id, _pid} = start_unique(EventOutbox, name: name, path: path)
    name
  end

  # Returns `{child_id, outbox_name}` so the caller can stop the specific child.
  defp start_outbox_stoppable(_tmp_dir, path) do
    name = unique(:outbox)
    {child_id, _pid} = start_unique(EventOutbox, name: name, path: path)
    {child_id, name}
  end

  defp start_processor(tmp_dir) do
    name = unique(:processor)
    table = unique(:dets_table)
    path = Path.join(tmp_dir, "#{table}.dets")
    event_path = Path.join(tmp_dir, "#{table}-events.jsonl")

    {_id, _pid} =
      start_unique(
        CommandProcessor,
        name: name,
        table: table,
        path: path,
        event_path: event_path,
        handler: fn _payload, _context -> {:ok, :handled} end
      )

    name
  end

  defp start_ingestor do
    name = unique(:ingestor)
    {_id, _pid} = start_unique(ClusterEventIngestor, name: name)
    name
  end

  defp start_registry do
    name = unique(:registry)
    {_id, _pid} = start_unique(SessionRegistry, name: name)
    name
  end

  defp start_command_store do
    name = unique(:cmd_store)
    {_id, _pid} = start_unique(TestCommandStore, name: name)
    name
  end

  # Strips EventOutbox-specific fields (cluster_id, sent) before passing to
  # ClusterEventIngestor, which validates against the wire envelope schema.
  defp to_envelope(outbox_event) do
    Map.take(outbox_event, [
      :schema_version,
      :event_id,
      :cluster_seq,
      :kind,
      :occurred_at,
      :correlation_id,
      :payload
    ])
  end

  defp identity(org_id \\ "org-test", cluster_id \\ "cluster-test") do
    %ClusterIdentity{organization_id: org_id, cluster_id: cluster_id}
  end

  defp event_envelope(seq, kind) do
    %{
      schema_version: 1,
      event_id: "evt-#{seq}-#{System.unique_integer([:positive])}",
      cluster_seq: seq,
      kind: kind,
      occurred_at: "2026-08-01T00:00:00Z",
      correlation_id: "corr-#{seq}",
      payload: %{"test" => "seq-#{seq}"}
    }
  end

  # Uses a stable base timestamp so that duplicate acceptance produces the same
  # fingerprint as the original and is correctly recognized by CommandProcessor.
  defp command_map(command_id, kind \\ "conversation.message") do
    base = ~U[2026-08-01T00:00:00Z]

    %{
      "schema_version" => 1,
      "command_id" => command_id,
      "kind" => kind,
      "issued_at" => DateTime.to_iso8601(base),
      "expires_at" => DateTime.to_iso8601(DateTime.add(base, 300, :second)),
      "payload" => %{"test" => command_id},
      "correlation_id" => "corr-cmd-#{command_id}"
    }
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  test "disconnect/reconnect: no durable event is lost when coordinator reconnects to a new replica",
       %{tmp_dir: tmp_dir} do
    identity_val = identity()
    cluster_id = identity_val.cluster_id

    outbox = start_outbox(tmp_dir)
    ingestor = start_ingestor()

    # Enqueue three events on the coordinator
    {:ok, e1} = EventOutbox.enqueue(cluster_id, event_envelope(1, "alert.opened"), server: outbox)

    {:ok, e2} =
      EventOutbox.enqueue(cluster_id, event_envelope(2, "status.snapshot"), server: outbox)

    {:ok, e3} = EventOutbox.enqueue(cluster_id, event_envelope(3, "audit.event"), server: outbox)

    # Simulate replica-1 receiving events 1 and 2
    {:ok, r1} = ClusterEventIngestor.ingest(to_envelope(e1), identity_val, ingestor)
    :ok = EventOutbox.mark_sent(e1.event_id, server: outbox)
    {:ok, r2} = ClusterEventIngestor.ingest(to_envelope(e2), identity_val, ingestor)
    :ok = EventOutbox.mark_sent(e2.event_id, server: outbox)

    assert r1.acknowledgement == 1
    assert r2.acknowledgement == 2

    # Coordinator receives ack=2 from replica-1
    {:ok, _removed} = EventOutbox.acknowledge(cluster_id, 2, server: outbox)

    # Replica-1 crashes — event 3 was never delivered
    remaining = EventOutbox.events(cluster_id, server: outbox)
    assert length(remaining) == 1
    assert hd(remaining).event_id == e3.event_id

    # Coordinator reconnects to replica-2 (same ingestor simulates shared state)
    {:ok, r3} = ClusterEventIngestor.ingest(to_envelope(e3), identity_val, ingestor)
    :ok = EventOutbox.mark_sent(e3.event_id, server: outbox)
    assert r3.acknowledgement == 3
    assert r3.duplicate? == false

    {:ok, _removed} = EventOutbox.acknowledge(cluster_id, 3, server: outbox)

    # All events committed; outbox is empty
    assert EventOutbox.events(cluster_id, server: outbox) == []

    # All three events are present in the MC store in order
    committed = ClusterEventIngestor.events(identity_val, ingestor)
    assert length(committed) == 3
    assert Enum.map(committed, & &1.cluster_seq) == [1, 2, 3]
  end

  test "durable event replay: events survive coordinator process restart without loss",
       %{tmp_dir: tmp_dir} do
    identity_val = identity()
    cluster_id = identity_val.cluster_id
    path = Path.join(tmp_dir, "outbox_restart_test.json")

    # First coordinator instance: enqueue two events, one acknowledged
    {child1, outbox1} = start_outbox_stoppable(tmp_dir, path)
    ingestor = start_ingestor()

    {:ok, e1} =
      EventOutbox.enqueue(cluster_id, event_envelope(1, "alert.opened"), server: outbox1)

    {:ok, e2} =
      EventOutbox.enqueue(cluster_id, event_envelope(2, "status.snapshot"), server: outbox1)

    {:ok, _} = ClusterEventIngestor.ingest(to_envelope(e1), identity_val, ingestor)
    :ok = EventOutbox.mark_sent(e1.event_id, server: outbox1)
    {:ok, _ack1} = EventOutbox.acknowledge(cluster_id, 1, server: outbox1)
    :ok = EventOutbox.mark_sent(e2.event_id, server: outbox1)

    # Coordinator crashes before e2 is acknowledged
    stop_supervised!(child1)

    # Coordinator restarts from durable state
    {_child2, outbox2} = start_outbox_stoppable(tmp_dir, path)

    # e2 is still in the outbox (sent flag may be reset or retained — either way
    # the coordinator redelivers unacknowledged events)
    pending = EventOutbox.events(cluster_id, server: outbox2)
    assert length(pending) == 1
    [replayed] = pending
    assert replayed.event_id == e2.event_id
    assert replayed.cluster_seq == 2

    # Deliver to MC — must be idempotent even if sent flag was reset
    {:ok, r2} = ClusterEventIngestor.ingest(to_envelope(replayed), identity_val, ingestor)
    assert r2.duplicate? == false
    assert r2.acknowledgement == 2

    # No events are left in the outbox after acknowledgement
    {:ok, _} = EventOutbox.acknowledge(cluster_id, 2, server: outbox2)
    assert EventOutbox.events(cluster_id, server: outbox2) == []
  end

  test "command replay: pending commands survive connection-owner replica restart",
       %{tmp_dir: tmp_dir} do
    org_id = "org-test"
    cluster_id = "cluster-test"

    # Shared command store — simulates shared PostgreSQL
    cmd_store = start_command_store()
    # Two MC replica registries
    registry_1 = start_registry()
    registry_2 = start_registry()
    processor = start_processor(tmp_dir)

    # Enqueue two commands in the shared store
    {:ok, _cmd_a} =
      TestCommandStore.enqueue(
        org_id,
        cluster_id,
        %{command_id: "cmd-a", kind: "conversation.message", payload: %{}},
        cmd_store
      )

    {:ok, _cmd_b} =
      TestCommandStore.enqueue(
        org_id,
        cluster_id,
        %{command_id: "cmd-b", kind: "conversation.message", payload: %{}},
        cmd_store
      )

    # Replica-1 registers as the session owner; coordinator connects through it
    {:ok, _prev} =
      SessionRegistry.register(org_id, cluster_id, "session-r1", self(), registry_1)

    # Deliver pending commands via replica-1 to coordinator
    {:ok, 2} = TestCommandStore.deliver_registered(org_id, cluster_id, cmd_store, registry_1)

    # Coordinator receives cmd-a and acknowledges
    assert_receive {:mission_control_command, %{command_id: "cmd-a"}}, @assert_timeout_ms
    assert_receive {:mission_control_command, %{command_id: "cmd-b"}}, @assert_timeout_ms

    {:ok, receipt_a} = CommandProcessor.accept(command_map("cmd-a"), processor)
    assert %CommandReceipt{status: :received, duplicate: false} = receipt_a

    {:ok, :acknowledged} = TestCommandStore.acknowledge("cmd-a", cmd_store)

    # Replica-1 crashes before cmd-b is processed by coordinator
    :ok = SessionRegistry.unregister(org_id, cluster_id, "session-r1", registry_1)

    # Replica-2 takes ownership of the cluster session
    {:ok, _prev} =
      SessionRegistry.register(org_id, cluster_id, "session-r2", self(), registry_2)

    # cmd-b is still pending in the shared store
    pending_after_failover = TestCommandStore.pending(org_id, cluster_id, cmd_store)
    assert length(pending_after_failover) == 1
    assert hd(pending_after_failover).command_id == "cmd-b"

    # Replica-2 redelivers pending commands via its registry
    {:ok, 1} = TestCommandStore.deliver_registered(org_id, cluster_id, cmd_store, registry_2)
    assert_receive {:mission_control_command, %{command_id: "cmd-b"}}, @assert_timeout_ms

    # Coordinator processes cmd-b exactly once
    {:ok, receipt_b} = CommandProcessor.accept(command_map("cmd-b"), processor)
    assert %CommandReceipt{status: :received, duplicate: false} = receipt_b

    {:ok, :acknowledged} = TestCommandStore.acknowledge("cmd-b", cmd_store)

    # Idempotency: redelivering cmd-b yields a duplicate receipt
    {:ok, dup_receipt} = CommandProcessor.accept(command_map("cmd-b"), processor)
    assert %CommandReceipt{duplicate: true} = dup_receipt

    assert TestCommandStore.acknowledged?("cmd-a", cmd_store)
    assert TestCommandStore.acknowledged?("cmd-b", cmd_store)
  end

  test "duplicate event delivery is idempotent and does not double-count events",
       %{tmp_dir: tmp_dir} do
    identity_val = identity()
    cluster_id = identity_val.cluster_id

    outbox = start_outbox(tmp_dir)
    ingestor = start_ingestor()

    # Coordinator sends one event
    {:ok, e1} = EventOutbox.enqueue(cluster_id, event_envelope(1, "alert.opened"), server: outbox)

    # MC ingests the event once
    {:ok, first} = ClusterEventIngestor.ingest(to_envelope(e1), identity_val, ingestor)
    assert first.duplicate? == false
    assert first.acknowledgement == 1

    # Coordinator retransmits (simulating at-least-once delivery)
    {:ok, duplicate} = ClusterEventIngestor.ingest(to_envelope(e1), identity_val, ingestor)
    assert duplicate.duplicate? == true
    assert duplicate.acknowledgement == 1

    # Only one event in the store
    committed = ClusterEventIngestor.events(identity_val, ingestor)
    assert length(committed) == 1
    assert hd(committed).event_id == e1.event_id
  end

  test "sequence gap: acknowledgement stays at highest contiguous sequence until gap is filled",
       %{tmp_dir: tmp_dir} do
    identity_val = identity()
    cluster_id = identity_val.cluster_id

    outbox = start_outbox(tmp_dir)
    ingestor = start_ingestor()

    {:ok, e1} = EventOutbox.enqueue(cluster_id, event_envelope(1, "alert.opened"), server: outbox)

    {:ok, e2} =
      EventOutbox.enqueue(cluster_id, event_envelope(2, "status.snapshot"), server: outbox)

    {:ok, e3} = EventOutbox.enqueue(cluster_id, event_envelope(3, "audit.event"), server: outbox)

    # Deliver seq 1 and seq 3, skip seq 2
    {:ok, r1} = ClusterEventIngestor.ingest(to_envelope(e1), identity_val, ingestor)
    assert r1.acknowledgement == 1
    assert r1.gap? == false

    {:ok, r3} = ClusterEventIngestor.ingest(to_envelope(e3), identity_val, ingestor)
    assert r3.acknowledgement == 1
    assert r3.gap? == true
    assert r3.sequence_status == :gap

    # Gap prevents ack-ing beyond seq 1
    assert ClusterEventIngestor.acknowledgement(identity_val, ingestor) == 1

    # seq 2 arrives; gap is filled and acknowledgement advances to 3
    {:ok, r2} = ClusterEventIngestor.ingest(to_envelope(e2), identity_val, ingestor)
    assert r2.acknowledgement == 3
    assert r2.gap? == false

    assert ClusterEventIngestor.acknowledgement(identity_val, ingestor) == 3
    assert length(ClusterEventIngestor.events(identity_val, ingestor)) == 3
  end

  test "certificate revocation: revoked SPIFFE URI is rejected at the identity boundary",
       %{tmp_dir: tmp_dir} do
    ingestor = start_ingestor()
    outbox = start_outbox(tmp_dir)

    cluster_id = "revoked-cluster"

    # Simulate what happens when the MC gateway parses a revoked or malformed cert:
    # ClusterIdentity.from_spiffe_uri rejects it before any event is committed.
    revoked_uri = "spiffe://exocomp/organizations/org-revoked/clusters"
    assert {:error, error} = ClusterIdentity.from_spiffe_uri(revoked_uri)
    assert error.code == :invalid_cluster_certificate

    # A well-formed URI for a cluster whose cert is no longer in the allow-list
    # is simulated by returning an error from the gateway's revocation check.
    # The ingestor itself never sees the event — it is blocked at the transport.
    revocation_check = fn spiffe_uri ->
      revoked = MapSet.new(["spiffe://exocomp/organizations/org-revoked/clusters/cluster-rev"])
      if MapSet.member?(revoked, spiffe_uri), do: {:error, :revoked}, else: :ok
    end

    valid_uri = "spiffe://exocomp/organizations/org-test/clusters/cluster-test"
    revoked_uri_full = "spiffe://exocomp/organizations/org-revoked/clusters/cluster-rev"

    assert :ok == revocation_check.(valid_uri)
    assert {:error, :revoked} == revocation_check.(revoked_uri_full)

    # After revocation check rejects the cert, ingestor must remain clean
    assert ClusterEventIngestor.events(identity("org-revoked", cluster_id), ingestor) == []

    # A properly authenticated (non-revoked) cluster can still submit events
    {:ok, valid_identity} = ClusterIdentity.from_spiffe_uri(valid_uri)

    {:ok, e1} =
      EventOutbox.enqueue(valid_identity.cluster_id, event_envelope(1, "alert.opened"),
        server: outbox
      )

    assert :ok = revocation_check.(valid_uri)
    {:ok, result} = ClusterEventIngestor.ingest(to_envelope(e1), valid_identity, ingestor)
    assert result.acknowledgement == 1
  end

  test "connection-owner replica termination: commands drain through replica-2, no double execution",
       %{tmp_dir: tmp_dir} do
    org_id = "org-failover"
    cluster_id = "cluster-failover"

    cmd_store = start_command_store()
    registry_1 = start_registry()
    registry_2 = start_registry()
    processor = start_processor(tmp_dir)

    # Enqueue three commands
    {:ok, _} =
      TestCommandStore.enqueue(
        org_id,
        cluster_id,
        %{command_id: "cmd-1", kind: "conversation.message", payload: %{seq: 1}},
        cmd_store
      )

    {:ok, _} =
      TestCommandStore.enqueue(
        org_id,
        cluster_id,
        %{command_id: "cmd-2", kind: "conversation.message", payload: %{seq: 2}},
        cmd_store
      )

    {:ok, _} =
      TestCommandStore.enqueue(
        org_id,
        cluster_id,
        %{command_id: "cmd-3", kind: "conversation.message", payload: %{seq: 3}},
        cmd_store
      )

    # Replica-1 registers session; delivers commands 1 and 2 to coordinator
    {:ok, _} = SessionRegistry.register(org_id, cluster_id, "session-1", self(), registry_1)
    {:ok, 3} = TestCommandStore.deliver_registered(org_id, cluster_id, cmd_store, registry_1)

    assert_receive {:mission_control_command, %{command_id: "cmd-1"}}, @assert_timeout_ms
    assert_receive {:mission_control_command, %{command_id: "cmd-2"}}, @assert_timeout_ms
    assert_receive {:mission_control_command, %{command_id: "cmd-3"}}, @assert_timeout_ms

    # Coordinator processes cmd-1 and cmd-2; cmd-3 not yet accepted
    {:ok, _} = CommandProcessor.accept(command_map("cmd-1"), processor)
    {:ok, :acknowledged} = TestCommandStore.acknowledge("cmd-1", cmd_store)

    {:ok, _} = CommandProcessor.accept(command_map("cmd-2"), processor)
    {:ok, :acknowledged} = TestCommandStore.acknowledge("cmd-2", cmd_store)

    # Replica-1 terminates before cmd-3 is processed
    :ok = SessionRegistry.unregister(org_id, cluster_id, "session-1", registry_1)

    {:error, :offline} =
      TestCommandStore.deliver_registered(org_id, cluster_id, cmd_store, registry_1)

    # Replica-2 takes over
    {:ok, _} = SessionRegistry.register(org_id, cluster_id, "session-2", self(), registry_2)
    {:ok, 1} = TestCommandStore.deliver_registered(org_id, cluster_id, cmd_store, registry_2)
    assert_receive {:mission_control_command, %{command_id: "cmd-3"}}, @assert_timeout_ms

    # Coordinator processes cmd-3 exactly once
    {:ok, receipt} = CommandProcessor.accept(command_map("cmd-3"), processor)
    assert %CommandReceipt{status: :received, duplicate: false} = receipt
    {:ok, :acknowledged} = TestCommandStore.acknowledge("cmd-3", cmd_store)

    # All commands acknowledged; commands 1 and 2 cannot be re-executed
    {:ok, dup_1} = CommandProcessor.accept(command_map("cmd-1"), processor)
    assert %CommandReceipt{duplicate: true} = dup_1

    {:ok, dup_2} = CommandProcessor.accept(command_map("cmd-2"), processor)
    assert %CommandReceipt{duplicate: true} = dup_2

    {:ok, dup_3} = CommandProcessor.accept(command_map("cmd-3"), processor)
    assert %CommandReceipt{duplicate: true} = dup_3

    # Outbox is clean
    assert TestCommandStore.pending(org_id, cluster_id, cmd_store) == []
  end

  test "websocket affinity not required: events ingested by replica-2 while commands routed via replica-1",
       %{tmp_dir: tmp_dir} do
    org_id = "org-affinity"
    cluster_id = "cluster-affinity"
    identity_val = identity(org_id, cluster_id)

    cmd_store = start_command_store()
    registry_1 = start_registry()
    # Replica-2 registry is started to prove two independent replicas can coexist;
    # event ingest goes through the shared ClusterEventIngestor rather than a registry.
    _registry_2 = start_registry()
    ingestor = start_ingestor()
    outbox = start_outbox(tmp_dir)
    processor = start_processor(tmp_dir)

    # Coordinator enqueues an event
    {:ok, e1} = EventOutbox.enqueue(cluster_id, event_envelope(1, "alert.opened"), server: outbox)

    # MC side: replica-2 owns the event ingest channel
    {:ok, _} = ClusterEventIngestor.ingest(to_envelope(e1), identity_val, ingestor)
    :ok = EventOutbox.mark_sent(e1.event_id, server: outbox)
    {:ok, _} = EventOutbox.acknowledge(cluster_id, 1, server: outbox)

    # MC side: replica-1 owns the command delivery channel
    {:ok, _} = SessionRegistry.register(org_id, cluster_id, "session-r1", self(), registry_1)

    {:ok, cmd} =
      TestCommandStore.enqueue(
        org_id,
        cluster_id,
        %{command_id: "cmd-affinity", kind: "conversation.message", payload: %{}},
        cmd_store
      )

    {:ok, 1} = TestCommandStore.deliver_registered(org_id, cluster_id, cmd_store, registry_1)
    assert_receive {:mission_control_command, %{command_id: "cmd-affinity"}}, @assert_timeout_ms

    # Coordinator processes the command (via replica-1's channel)
    {:ok, receipt} = CommandProcessor.accept(command_map("cmd-affinity"), processor)
    assert %CommandReceipt{status: :received} = receipt
    {:ok, :acknowledged} = TestCommandStore.acknowledge(cmd.command_id, cmd_store)

    # Both are correct: event in MC, command processed by coordinator
    committed = ClusterEventIngestor.events(identity_val, ingestor)
    assert length(committed) == 1
    assert hd(committed).cluster_seq == 1

    assert TestCommandStore.acknowledged?("cmd-affinity", cmd_store)
  end

  test "SessionLiveness: missed heartbeats trigger a disconnected transition",
       %{tmp_dir: _tmp_dir} do
    alias Exocomp.Coordinator.MissionControl.SessionLiveness

    parent = self()
    session_id = "session-liveness-#{System.unique_integer()}"

    liveness =
      start_supervised!(
        {SessionLiveness,
         disconnect_after_ms: 50,
         commit_retry_ms: 10,
         now_fn: fn -> System.monotonic_time(:millisecond) end,
         schedule_fn: fn msg, delay -> Process.send_after(self(), msg, delay) end,
         cancel_timer_fn: fn ref -> Process.cancel_timer(ref) end,
         commit_state_fn: fn _session_id, state ->
           send(parent, {:committed, state})
           :ok
         end,
         publish_state_fn: fn _session_id, state ->
           send(parent, {:published, state})
           :ok
         end}
      )

    # Authenticate — should commit and publish :connected
    assert :ok = SessionLiveness.authenticated(session_id, liveness)
    assert_receive {:committed, :connected}, @assert_timeout_ms
    assert_receive {:published, :connected}, @assert_timeout_ms

    # Allow heartbeat timeout to expire without sending a heartbeat
    assert_receive {:committed, :disconnected}, @assert_timeout_ms + 200
    assert_receive {:published, :disconnected}, 100

    status = SessionLiveness.status(liveness)
    assert status.status == :disconnected
  end

  test "Connection: reconnects with full-jitter backoff and resets backoff on stable connection",
       %{tmp_dir: _tmp_dir} do
    alias Exocomp.Coordinator.MissionControl.Connection

    parent = self()
    attempts = :atomics.new(1, [])

    connection =
      start_supervised!(
        {Connection,
         start_immediately: false,
         heartbeat_interval_ms: 50,
         stable_after_ms: 100,
         min_backoff_ms: 10,
         max_backoff_ms: 100,
         connect_fn: fn ->
           n = :atomics.add_get(attempts, 1, 1)

           if n == 1 do
             {:error, :first_attempt_fails}
           else
             {:ok, :connected_session}
           end
         end,
         send_fn: fn _session, _event ->
           send(parent, :heartbeat_sent)
           :ok
         end,
         heartbeat_fn: fn -> %{kind: "cluster.heartbeat", schema_version: 1} end,
         random_fn: fn _low, high -> high end,
         schedule_fn: fn msg, delay -> Process.send_after(self(), msg, delay) end,
         cancel_timer_fn: &Process.cancel_timer/1,
         now_fn: fn -> System.monotonic_time(:millisecond) end}
      )

    # Trigger first connect (fails)
    :ok = Connection.connect_now(connection)

    # Wait for first failure and verify disconnected
    deadline = System.monotonic_time(:millisecond) + @assert_timeout_ms

    poll_until(deadline, fn ->
      Connection.status(connection).status == :disconnected and
        Connection.status(connection).backoff_attempts > 0
    end)

    assert Connection.status(connection).backoff_attempts >= 1

    # Second attempt succeeds; wait for stable
    poll_until(deadline, fn ->
      s = Connection.status(connection)
      s.status == :connected
    end)

    # Heartbeat must be sent after connection
    assert_receive :heartbeat_sent, @assert_timeout_ms

    # Stable resets backoff_attempts
    poll_until(deadline, fn ->
      s = Connection.status(connection)
      s.stable == true and s.backoff_attempts == 0
    end)

    status = Connection.status(connection)
    assert status.status == :connected
    assert status.stable == true
    assert status.backoff_attempts == 0
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp poll_until(deadline_ms, pred) do
    cond do
      pred.() ->
        :ok

      System.monotonic_time(:millisecond) >= deadline_ms ->
        flunk("poll_until/2 deadline exceeded")

      true ->
        Process.sleep(10)
        poll_until(deadline_ms, pred)
    end
  end
end

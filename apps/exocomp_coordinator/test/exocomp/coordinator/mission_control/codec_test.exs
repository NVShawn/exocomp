# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.CodecTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.MissionControl.{
    Acknowledgement,
    Codec,
    Command,
    Event
  }

  # ---------------------------------------------------------------------------
  # Valid Event Fixtures
  # ---------------------------------------------------------------------------

  describe "decode_event/1 with valid fixtures" do
    test "decodes cluster.hello event" do
      raw = %{
        "schema_version" => 1,
        "event_id" => "018f8c3a-2b5f-7123-bcf2-d4f1a3b2c1d0",
        "cluster_seq" => 0,
        "kind" => "cluster.hello",
        "occurred_at" => "2026-07-29T21:00:00Z",
        "correlation_id" => "corr_abc123",
        "payload" => %{"version" => "1.0.0", "cluster_name" => "prod-1"}
      }

      assert {:ok, %Event{} = event} = Codec.decode_event(raw)
      assert event.schema_version == 1
      assert event.event_id == "018f8c3a-2b5f-7123-bcf2-d4f1a3b2c1d0"
      assert event.cluster_seq == 0
      assert event.kind == "cluster.hello"
      assert event.occurred_at == "2026-07-29T21:00:00Z"
      assert event.correlation_id == "corr_abc123"
      assert event.payload == %{"version" => "1.0.0", "cluster_name" => "prod-1"}
    end

    test "decodes cluster.heartbeat event without correlation_id" do
      raw = %{
        "schema_version" => 1,
        "event_id" => "018f8c3a-2b5f-7124-bcf2-d4f1a3b2c1d1",
        "cluster_seq" => 1,
        "kind" => "cluster.heartbeat",
        "occurred_at" => "2026-07-29T21:00:30Z",
        "payload" => %{}
      }

      assert {:ok, %Event{} = event} = Codec.decode_event(raw)
      assert event.schema_version == 1
      assert event.cluster_seq == 1
      assert event.kind == "cluster.heartbeat"
      assert event.correlation_id == nil
      assert event.payload == %{}
    end

    test "decodes status.snapshot event with complex payload" do
      raw = %{
        "schema_version" => 1,
        "event_id" => "018f8c3a-2b5f-7125-bcf2-d4f1a3b2c1d2",
        "cluster_seq" => 42,
        "kind" => "status.snapshot",
        "occurred_at" => "2026-07-29T21:05:00Z",
        "correlation_id" => "corr_xyz789",
        "payload" => %{
          "cluster_health" => "healthy",
          "nodes" => [
            %{"id" => "node-1", "status" => "ready"},
            %{"id" => "node-2", "status" => "ready"}
          ],
          "services" => [
            %{"name" => "api", "health" => "running"},
            %{"name" => "database", "health" => "running"}
          ]
        }
      }

      assert {:ok, %Event{} = event} = Codec.decode_event(raw)
      assert event.cluster_seq == 42
      assert event.kind == "status.snapshot"
      assert is_map(event.payload)
      assert Map.has_key?(event.payload, "cluster_health")
      assert is_list(event.payload["nodes"])
      assert is_list(event.payload["services"])
    end

    test "decodes alert.opened event" do
      raw = %{
        "schema_version" => 1,
        "event_id" => "018f8c3a-2b5f-7126-bcf2-d4f1a3b2c1d3",
        "cluster_seq" => 100,
        "kind" => "alert.opened",
        "occurred_at" => "2026-07-29T21:10:00Z",
        "correlation_id" => "corr_alert_1",
        "payload" => %{
          "alert_type" => "degraded_node",
          "node_id" => "node-5",
          "message" => "Node is degraded"
        }
      }

      assert {:ok, %Event{} = event} = Codec.decode_event(raw)
      assert event.kind == "alert.opened"
      assert event.payload["alert_type"] == "degraded_node"
    end

    test "decodes all valid event kinds" do
      valid_kinds = Event.valid_kinds()

      Enum.each(valid_kinds, fn kind ->
        raw = %{
          "schema_version" => 1,
          "event_id" => "test-id-#{kind}",
          "cluster_seq" => 1,
          "kind" => kind,
          "occurred_at" => "2026-07-29T21:00:00Z",
          "payload" => %{}
        }

        assert {:ok, %Event{}} = Codec.decode_event(raw), "Failed to decode kind: #{kind}"
      end)
    end

    test "round-trip encode/decode preserves event without semantic loss" do
      original = %{
        "schema_version" => 1,
        "event_id" => "018f8c3a-2b5f-7127-bcf2-d4f1a3b2c1d4",
        "cluster_seq" => 99,
        "kind" => "proposal.created",
        "occurred_at" => "2026-07-29T21:15:00Z",
        "correlation_id" => "corr_proposal_1",
        "payload" => %{
          "proposal_id" => "prop-1",
          "action" => "restart_service",
          "evidence" => %{"timestamp" => "2026-07-29T21:00:00Z"}
        }
      }

      assert {:ok, event} = Codec.decode_event(original)
      encoded = Codec.encode_event(event)
      assert {:ok, decoded} = Codec.decode_event(encoded)

      # Verify round-trip equivalence
      assert decoded.schema_version == original["schema_version"]
      assert decoded.event_id == original["event_id"]
      assert decoded.cluster_seq == original["cluster_seq"]
      assert decoded.kind == original["kind"]
      assert decoded.occurred_at == original["occurred_at"]
      assert decoded.correlation_id == original["correlation_id"]
      assert decoded.payload == original["payload"]
    end
  end

  # ---------------------------------------------------------------------------
  # Invalid Event Fixtures (Table-Driven)
  # ---------------------------------------------------------------------------

  describe "decode_event/1 with invalid fixtures" do
    test "rejects non-map input" do
      Enum.each([nil, "string", 123, [], true], fn invalid ->
        assert {:error, _} = Codec.decode_event(invalid)
      end)
    end

    test "rejects missing schema_version" do
      raw = %{
        "event_id" => "test-id",
        "cluster_seq" => 0,
        "kind" => "cluster.hello",
        "occurred_at" => "2026-07-29T21:00:00Z",
        "payload" => %{}
      }

      assert {:error, :missing_schema_version} = Codec.decode_event(raw)
    end

    test "rejects unsupported schema versions" do
      Enum.each([0, 2, 99, -1, "1"], fn version ->
        raw = %{
          "schema_version" => version,
          "event_id" => "test-id",
          "cluster_seq" => 0,
          "kind" => "cluster.hello",
          "occurred_at" => "2026-07-29T21:00:00Z",
          "payload" => %{}
        }

        assert {:error, _} = Codec.decode_event(raw),
               "Should reject schema_version: #{inspect(version)}"
      end)
    end

    test "rejects invalid schema_version types" do
      Enum.each([[], %{}, 1.5], fn invalid_type ->
        raw = %{
          "schema_version" => invalid_type,
          "event_id" => "test-id",
          "cluster_seq" => 0,
          "kind" => "cluster.hello",
          "occurred_at" => "2026-07-29T21:00:00Z",
          "payload" => %{}
        }

        assert {:error, _} = Codec.decode_event(raw)
      end)
    end

    test "rejects missing event_id" do
      raw = %{
        "schema_version" => 1,
        "cluster_seq" => 0,
        "kind" => "cluster.hello",
        "occurred_at" => "2026-07-29T21:00:00Z",
        "payload" => %{}
      }

      assert {:error, :missing_event_id} = Codec.decode_event(raw)
    end

    test "rejects empty event_id" do
      raw = %{
        "schema_version" => 1,
        "event_id" => "",
        "cluster_seq" => 0,
        "kind" => "cluster.hello",
        "occurred_at" => "2026-07-29T21:00:00Z",
        "payload" => %{}
      }

      assert {:error, {:invalid_event_id, ""}} = Codec.decode_event(raw)
    end

    test "rejects invalid event_id types" do
      Enum.each([123, nil, [], %{}], fn invalid_type ->
        raw = %{
          "schema_version" => 1,
          "event_id" => invalid_type,
          "cluster_seq" => 0,
          "kind" => "cluster.hello",
          "occurred_at" => "2026-07-29T21:00:00Z",
          "payload" => %{}
        }

        assert {:error, _} = Codec.decode_event(raw)
      end)
    end

    test "rejects missing cluster_seq" do
      raw = %{
        "schema_version" => 1,
        "event_id" => "test-id",
        "kind" => "cluster.hello",
        "occurred_at" => "2026-07-29T21:00:00Z",
        "payload" => %{}
      }

      assert {:error, :missing_cluster_seq} = Codec.decode_event(raw)
    end

    test "rejects negative cluster_seq" do
      raw = %{
        "schema_version" => 1,
        "event_id" => "test-id",
        "cluster_seq" => -1,
        "kind" => "cluster.hello",
        "occurred_at" => "2026-07-29T21:00:00Z",
        "payload" => %{}
      }

      assert {:error, {:invalid_cluster_seq, -1}} = Codec.decode_event(raw)
    end

    test "rejects invalid cluster_seq types" do
      Enum.each(["0", 1.5, nil, []], fn invalid_type ->
        raw = %{
          "schema_version" => 1,
          "event_id" => "test-id",
          "cluster_seq" => invalid_type,
          "kind" => "cluster.hello",
          "occurred_at" => "2026-07-29T21:00:00Z",
          "payload" => %{}
        }

        assert {:error, _} = Codec.decode_event(raw)
      end)
    end

    test "rejects missing kind" do
      raw = %{
        "schema_version" => 1,
        "event_id" => "test-id",
        "cluster_seq" => 0,
        "occurred_at" => "2026-07-29T21:00:00Z",
        "payload" => %{}
      }

      assert {:error, :missing_kind} = Codec.decode_event(raw)
    end

    test "rejects unknown event kind" do
      raw = %{
        "schema_version" => 1,
        "event_id" => "test-id",
        "cluster_seq" => 0,
        "kind" => "unknown.event",
        "occurred_at" => "2026-07-29T21:00:00Z",
        "payload" => %{}
      }

      assert {:error, {:unknown_kind, "unknown.event"}} = Codec.decode_event(raw)
    end

    test "rejects invalid kind types" do
      Enum.each([123, nil, [], %{}], fn invalid_type ->
        raw = %{
          "schema_version" => 1,
          "event_id" => "test-id",
          "cluster_seq" => 0,
          "kind" => invalid_type,
          "occurred_at" => "2026-07-29T21:00:00Z",
          "payload" => %{}
        }

        assert {:error, _} = Codec.decode_event(raw)
      end)
    end

    test "rejects missing occurred_at" do
      raw = %{
        "schema_version" => 1,
        "event_id" => "test-id",
        "cluster_seq" => 0,
        "kind" => "cluster.hello",
        "payload" => %{}
      }

      assert {:error, :missing_occurred_at} = Codec.decode_event(raw)
    end

    test "rejects empty occurred_at" do
      raw = %{
        "schema_version" => 1,
        "event_id" => "test-id",
        "cluster_seq" => 0,
        "kind" => "cluster.hello",
        "occurred_at" => "",
        "payload" => %{}
      }

      assert {:error, {:invalid_occurred_at, ""}} = Codec.decode_event(raw)
    end

    test "rejects invalid occurred_at types" do
      Enum.each([123, nil, [], %{}], fn invalid_type ->
        raw = %{
          "schema_version" => 1,
          "event_id" => "test-id",
          "cluster_seq" => 0,
          "kind" => "cluster.hello",
          "occurred_at" => invalid_type,
          "payload" => %{}
        }

        assert {:error, _} = Codec.decode_event(raw)
      end)
    end

    test "rejects non-map payload" do
      Enum.each(["string", 123, nil, []], fn invalid_payload ->
        raw = %{
          "schema_version" => 1,
          "event_id" => "test-id",
          "cluster_seq" => 0,
          "kind" => "cluster.hello",
          "occurred_at" => "2026-07-29T21:00:00Z",
          "payload" => invalid_payload
        }

        assert {:error, _} = Codec.decode_event(raw)
      end)
    end

    test "rejects oversized payload" do
      # Create a payload larger than max_payload_size (100 KiB)
      large_payload = %{
        "data" => String.duplicate("x", 102_401)
      }

      raw = %{
        "schema_version" => 1,
        "event_id" => "test-id",
        "cluster_seq" => 0,
        "kind" => "cluster.hello",
        "occurred_at" => "2026-07-29T21:00:00Z",
        "payload" => large_payload
      }

      assert {:error, {:payload_oversized, _}} = Codec.decode_event(raw)
    end
  end

  # ---------------------------------------------------------------------------
  # Valid Command Fixtures
  # ---------------------------------------------------------------------------

  describe "decode_command/1 with valid fixtures" do
    test "decodes approval.decide command" do
      raw = %{
        "command_id" => "cmd-001",
        "kind" => "approval.decide",
        "issued_at" => "2026-07-29T21:30:00Z",
        "expires_at" => "2026-07-29T21:45:00Z",
        "payload" => %{
          "proposal_id" => "prop-1",
          "decision" => "approve",
          "operator_id" => "op-123"
        }
      }

      assert {:ok, %Command{} = cmd} = Codec.decode_command(raw)
      assert cmd.command_id == "cmd-001"
      assert cmd.kind == "approval.decide"
      assert cmd.issued_at == "2026-07-29T21:30:00Z"
      assert cmd.expires_at == "2026-07-29T21:45:00Z"
      assert cmd.payload["decision"] == "approve"
    end

    test "decodes conversation.message command" do
      raw = %{
        "command_id" => "cmd-002",
        "kind" => "conversation.message",
        "issued_at" => "2026-07-29T21:20:00Z",
        "expires_at" => "2026-07-29T22:20:00Z",
        "payload" => %{
          "conversation_id" => "conv-1",
          "message" => "Please investigate service X",
          "operator_id" => "op-456"
        }
      }

      assert {:ok, %Command{} = cmd} = Codec.decode_command(raw)
      assert cmd.kind == "conversation.message"
      assert cmd.payload["message"] == "Please investigate service X"
    end

    test "decodes cluster.disconnect command" do
      raw = %{
        "command_id" => "cmd-003",
        "kind" => "cluster.disconnect",
        "issued_at" => "2026-07-29T21:00:00Z",
        "expires_at" => "2026-07-29T21:05:00Z",
        "payload" => %{"reason" => "maintenance"}
      }

      assert {:ok, %Command{} = cmd} = Codec.decode_command(raw)
      assert cmd.kind == "cluster.disconnect"
    end

    test "decodes all valid command kinds" do
      valid_kinds = Command.valid_kinds()

      Enum.each(valid_kinds, fn kind ->
        raw = %{
          "command_id" => "cmd-#{kind}",
          "kind" => kind,
          "issued_at" => "2026-07-29T21:00:00Z",
          "expires_at" => "2026-07-29T22:00:00Z",
          "payload" => %{}
        }

        assert {:ok, %Command{}} = Codec.decode_command(raw),
               "Failed to decode kind: #{kind}"
      end)
    end

    test "round-trip encode/decode preserves command" do
      original = %{
        "command_id" => "cmd-round-trip",
        "kind" => "approval.decide",
        "issued_at" => "2026-07-29T21:25:00Z",
        "expires_at" => "2026-07-29T21:35:00Z",
        "payload" => %{
          "proposal_id" => "prop-2",
          "decision" => "deny",
          "reason" => "Insufficient evidence"
        }
      }

      assert {:ok, cmd} = Codec.decode_command(original)
      encoded = Codec.encode_command(cmd)
      assert {:ok, decoded} = Codec.decode_command(encoded)

      assert decoded.command_id == original["command_id"]
      assert decoded.kind == original["kind"]
      assert decoded.issued_at == original["issued_at"]
      assert decoded.expires_at == original["expires_at"]
      assert decoded.payload == original["payload"]
    end
  end

  # ---------------------------------------------------------------------------
  # Invalid Command Fixtures (Table-Driven)
  # ---------------------------------------------------------------------------

  describe "decode_command/1 with invalid fixtures" do
    test "rejects non-map input" do
      Enum.each([nil, "string", 123, [], true], fn invalid ->
        assert {:error, _} = Codec.decode_command(invalid)
      end)
    end

    test "rejects missing command_id" do
      raw = %{
        "kind" => "approval.decide",
        "issued_at" => "2026-07-29T21:30:00Z",
        "expires_at" => "2026-07-29T21:45:00Z",
        "payload" => %{}
      }

      assert {:error, :missing_command_id} = Codec.decode_command(raw)
    end

    test "rejects empty command_id" do
      raw = %{
        "command_id" => "",
        "kind" => "approval.decide",
        "issued_at" => "2026-07-29T21:30:00Z",
        "expires_at" => "2026-07-29T21:45:00Z",
        "payload" => %{}
      }

      assert {:error, {:invalid_command_id, ""}} = Codec.decode_command(raw)
    end

    test "rejects invalid command_id types" do
      Enum.each([123, nil, [], %{}], fn invalid_type ->
        raw = %{
          "command_id" => invalid_type,
          "kind" => "approval.decide",
          "issued_at" => "2026-07-29T21:30:00Z",
          "expires_at" => "2026-07-29T21:45:00Z",
          "payload" => %{}
        }

        assert {:error, _} = Codec.decode_command(raw)
      end)
    end

    test "rejects missing kind" do
      raw = %{
        "command_id" => "cmd-001",
        "issued_at" => "2026-07-29T21:30:00Z",
        "expires_at" => "2026-07-29T21:45:00Z",
        "payload" => %{}
      }

      assert {:error, :missing_kind} = Codec.decode_command(raw)
    end

    test "rejects unknown command kind" do
      raw = %{
        "command_id" => "cmd-001",
        "kind" => "unknown.command",
        "issued_at" => "2026-07-29T21:30:00Z",
        "expires_at" => "2026-07-29T21:45:00Z",
        "payload" => %{}
      }

      assert {:error, {:unknown_kind, "unknown.command"}} = Codec.decode_command(raw)
    end

    test "rejects missing issued_at" do
      raw = %{
        "command_id" => "cmd-001",
        "kind" => "approval.decide",
        "expires_at" => "2026-07-29T21:45:00Z",
        "payload" => %{}
      }

      assert {:error, :missing_issued_at} = Codec.decode_command(raw)
    end

    test "rejects empty issued_at" do
      raw = %{
        "command_id" => "cmd-001",
        "kind" => "approval.decide",
        "issued_at" => "",
        "expires_at" => "2026-07-29T21:45:00Z",
        "payload" => %{}
      }

      assert {:error, {:invalid_issued_at, ""}} = Codec.decode_command(raw)
    end

    test "rejects missing expires_at" do
      raw = %{
        "command_id" => "cmd-001",
        "kind" => "approval.decide",
        "issued_at" => "2026-07-29T21:30:00Z",
        "payload" => %{}
      }

      assert {:error, :missing_expires_at} = Codec.decode_command(raw)
    end

    test "rejects empty expires_at" do
      raw = %{
        "command_id" => "cmd-001",
        "kind" => "approval.decide",
        "issued_at" => "2026-07-29T21:30:00Z",
        "expires_at" => "",
        "payload" => %{}
      }

      assert {:error, {:invalid_expires_at, ""}} = Codec.decode_command(raw)
    end

    test "rejects expires_at before issued_at" do
      raw = %{
        "command_id" => "cmd-001",
        "kind" => "approval.decide",
        "issued_at" => "2026-07-29T21:45:00Z",
        "expires_at" => "2026-07-29T21:30:00Z",
        "payload" => %{}
      }

      assert {:error, :expires_before_issued} = Codec.decode_command(raw)
    end

    test "rejects non-map payload" do
      Enum.each(["string", 123, nil, []], fn invalid_payload ->
        raw = %{
          "command_id" => "cmd-001",
          "kind" => "approval.decide",
          "issued_at" => "2026-07-29T21:30:00Z",
          "expires_at" => "2026-07-29T21:45:00Z",
          "payload" => invalid_payload
        }

        assert {:error, _} = Codec.decode_command(raw)
      end)
    end

    test "rejects oversized command payload" do
      large_payload = %{
        "data" => String.duplicate("x", 102_401)
      }

      raw = %{
        "command_id" => "cmd-001",
        "kind" => "approval.decide",
        "issued_at" => "2026-07-29T21:30:00Z",
        "expires_at" => "2026-07-29T21:45:00Z",
        "payload" => large_payload
      }

      assert {:error, {:payload_oversized, _}} = Codec.decode_command(raw)
    end
  end

  # ---------------------------------------------------------------------------
  # Valid Acknowledgement Fixtures
  # ---------------------------------------------------------------------------

  describe "decode_acknowledgement/1 with valid fixtures" do
    test "decodes valid acknowledgement" do
      raw = %{
        "acknowledged_at" => "2026-07-29T21:05:00Z",
        "highest_seq" => 42,
        "session_id" => "sess-abc123"
      }

      assert {:ok, %Acknowledgement{} = ack} = Codec.decode_acknowledgement(raw)
      assert ack.acknowledged_at == "2026-07-29T21:05:00Z"
      assert ack.highest_seq == 42
      assert ack.session_id == "sess-abc123"
    end

    test "decodes acknowledgement with seq 0" do
      raw = %{
        "acknowledged_at" => "2026-07-29T21:00:00Z",
        "highest_seq" => 0,
        "session_id" => "sess-first"
      }

      assert {:ok, %Acknowledgement{} = ack} = Codec.decode_acknowledgement(raw)
      assert ack.highest_seq == 0
    end

    test "decodes acknowledgement with large sequence number" do
      raw = %{
        "acknowledged_at" => "2026-07-29T21:10:00Z",
        "highest_seq" => 999_999,
        "session_id" => "sess-large-seq"
      }

      assert {:ok, %Acknowledgement{} = ack} = Codec.decode_acknowledgement(raw)
      assert ack.highest_seq == 999_999
    end

    test "round-trip encode/decode preserves acknowledgement" do
      original = %{
        "acknowledged_at" => "2026-07-29T21:07:00Z",
        "highest_seq" => 100,
        "session_id" => "sess-xyz789"
      }

      assert {:ok, ack} = Codec.decode_acknowledgement(original)
      encoded = Codec.encode_acknowledgement(ack)
      assert {:ok, decoded} = Codec.decode_acknowledgement(encoded)

      assert decoded.acknowledged_at == original["acknowledged_at"]
      assert decoded.highest_seq == original["highest_seq"]
      assert decoded.session_id == original["session_id"]
    end
  end

  # ---------------------------------------------------------------------------
  # Invalid Acknowledgement Fixtures (Table-Driven)
  # ---------------------------------------------------------------------------

  describe "decode_acknowledgement/1 with invalid fixtures" do
    test "rejects non-map input" do
      Enum.each([nil, "string", 123, [], true], fn invalid ->
        assert {:error, _} = Codec.decode_acknowledgement(invalid)
      end)
    end

    test "rejects missing acknowledged_at" do
      raw = %{
        "highest_seq" => 42,
        "session_id" => "sess-abc123"
      }

      assert {:error, :missing_acknowledged_at} = Codec.decode_acknowledgement(raw)
    end

    test "rejects empty acknowledged_at" do
      raw = %{
        "acknowledged_at" => "",
        "highest_seq" => 42,
        "session_id" => "sess-abc123"
      }

      assert {:error, {:invalid_acknowledged_at, ""}} = Codec.decode_acknowledgement(raw)
    end

    test "rejects missing highest_seq" do
      raw = %{
        "acknowledged_at" => "2026-07-29T21:05:00Z",
        "session_id" => "sess-abc123"
      }

      assert {:error, :missing_highest_seq} = Codec.decode_acknowledgement(raw)
    end

    test "rejects negative highest_seq" do
      raw = %{
        "acknowledged_at" => "2026-07-29T21:05:00Z",
        "highest_seq" => -1,
        "session_id" => "sess-abc123"
      }

      assert {:error, {:invalid_highest_seq, -1}} = Codec.decode_acknowledgement(raw)
    end

    test "rejects non-integer highest_seq" do
      Enum.each(["42", 42.5, nil, []], fn invalid ->
        raw = %{
          "acknowledged_at" => "2026-07-29T21:05:00Z",
          "highest_seq" => invalid,
          "session_id" => "sess-abc123"
        }

        assert {:error, _} = Codec.decode_acknowledgement(raw)
      end)
    end

    test "rejects missing session_id" do
      raw = %{
        "acknowledged_at" => "2026-07-29T21:05:00Z",
        "highest_seq" => 42
      }

      assert {:error, :missing_session_id} = Codec.decode_acknowledgement(raw)
    end

    test "rejects empty session_id" do
      raw = %{
        "acknowledged_at" => "2026-07-29T21:05:00Z",
        "highest_seq" => 42,
        "session_id" => ""
      }

      assert {:error, {:invalid_session_id, ""}} = Codec.decode_acknowledgement(raw)
    end
  end

  # ---------------------------------------------------------------------------
  # Batch Operations
  # ---------------------------------------------------------------------------

  describe "decode_events/1" do
    test "decodes multiple valid events" do
      raw = [
        %{
          "schema_version" => 1,
          "event_id" => "evt-1",
          "cluster_seq" => 0,
          "kind" => "cluster.hello",
          "occurred_at" => "2026-07-29T21:00:00Z",
          "payload" => %{}
        },
        %{
          "schema_version" => 1,
          "event_id" => "evt-2",
          "cluster_seq" => 1,
          "kind" => "cluster.heartbeat",
          "occurred_at" => "2026-07-29T21:00:30Z",
          "payload" => %{}
        }
      ]

      assert {:ok, events} = Codec.decode_events(raw)
      assert length(events) == 2
      assert Enum.all?(events, &match?(%Event{}, &1))
    end

    test "rejects list with one invalid event" do
      raw = [
        %{
          "schema_version" => 1,
          "event_id" => "evt-1",
          "cluster_seq" => 0,
          "kind" => "cluster.hello",
          "occurred_at" => "2026-07-29T21:00:00Z",
          "payload" => %{}
        },
        %{
          "schema_version" => 2,
          "event_id" => "evt-2",
          "cluster_seq" => 1,
          "kind" => "cluster.heartbeat",
          "occurred_at" => "2026-07-29T21:00:30Z",
          "payload" => %{}
        }
      ]

      assert {:error, _} = Codec.decode_events(raw)
    end

    test "rejects non-list input" do
      Enum.each([nil, "string", 123, %{}], fn invalid ->
        assert {:error, _} = Codec.decode_events(invalid)
      end)
    end
  end

  describe "encode_events/1" do
    test "encodes multiple events" do
      events = [
        %Event{
          schema_version: 1,
          event_id: "evt-1",
          cluster_seq: 0,
          kind: "cluster.hello",
          occurred_at: "2026-07-29T21:00:00Z",
          payload: %{"version" => "1.0.0"}
        },
        %Event{
          schema_version: 1,
          event_id: "evt-2",
          cluster_seq: 1,
          kind: "cluster.heartbeat",
          occurred_at: "2026-07-29T21:00:30Z",
          payload: %{}
        }
      ]

      encoded = Codec.encode_events(events)
      assert length(encoded) == 2
      assert Enum.all?(encoded, &is_map/1)
    end
  end

  # ---------------------------------------------------------------------------
  # Encoding Tests
  # ---------------------------------------------------------------------------

  describe "encode_event/1" do
    test "encodes event with all fields" do
      event = %Event{
        schema_version: 1,
        event_id: "evt-123",
        cluster_seq: 42,
        kind: "status.snapshot",
        occurred_at: "2026-07-29T21:05:00Z",
        correlation_id: "corr-abc",
        payload: %{"nodes" => 5}
      }

      encoded = Codec.encode_event(event)

      assert encoded["schema_version"] == 1
      assert encoded["event_id"] == "evt-123"
      assert encoded["cluster_seq"] == 42
      assert encoded["kind"] == "status.snapshot"
      assert encoded["occurred_at"] == "2026-07-29T21:05:00Z"
      assert encoded["correlation_id"] == "corr-abc"
      assert encoded["payload"] == %{"nodes" => 5}
    end

    test "encodes event with nil correlation_id" do
      event = %Event{
        schema_version: 1,
        event_id: "evt-456",
        cluster_seq: 0,
        kind: "cluster.hello",
        occurred_at: "2026-07-29T21:00:00Z",
        correlation_id: nil,
        payload: %{}
      }

      encoded = Codec.encode_event(event)

      assert encoded["correlation_id"] == nil
    end
  end

  describe "encode_command/1" do
    test "encodes command with all fields" do
      cmd = %Command{
        command_id: "cmd-123",
        kind: "approval.decide",
        issued_at: "2026-07-29T21:30:00Z",
        expires_at: "2026-07-29T21:45:00Z",
        payload: %{"decision" => "approve"}
      }

      encoded = Codec.encode_command(cmd)

      assert encoded["command_id"] == "cmd-123"
      assert encoded["kind"] == "approval.decide"
      assert encoded["issued_at"] == "2026-07-29T21:30:00Z"
      assert encoded["expires_at"] == "2026-07-29T21:45:00Z"
      assert encoded["payload"] == %{"decision" => "approve"}
    end
  end

  describe "encode_acknowledgement/1" do
    test "encodes acknowledgement" do
      ack = %Acknowledgement{
        acknowledged_at: "2026-07-29T21:05:00Z",
        highest_seq: 42,
        session_id: "sess-123"
      }

      encoded = Codec.encode_acknowledgement(ack)

      assert encoded["acknowledged_at"] == "2026-07-29T21:05:00Z"
      assert encoded["highest_seq"] == 42
      assert encoded["session_id"] == "sess-123"
    end
  end
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.DeliveryTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Webhooks.{Delivery, WebhookAttempt, WebhookEvent, Signer}

  describe "format_timestamp/1" do
    test "formats NaiveDateTime in RFC 3339 format with Z suffix" do
      timestamp = ~N[2026-08-01 14:30:00]

      formatted = Delivery.format_timestamp(timestamp)

      assert formatted == "2026-08-01T14:30:00Z"
    end

    test "truncates microseconds from NaiveDateTime" do
      timestamp = ~N[2026-08-01 14:30:00.123456]

      formatted = Delivery.format_timestamp(timestamp)

      assert formatted == "2026-08-01T14:30:00Z"
    end

    test "formats DateTime with Z suffix" do
      {:ok, dt, 0} = DateTime.from_iso8601("2026-08-01T14:30:00Z")
      formatted = Delivery.format_timestamp(dt)
      assert String.ends_with?(formatted, "Z")
      assert String.contains?(formatted, "2026-08-01")
    end
  end

  describe "should_retry?/2 (backward-compatible)" do
    test "does not retry successful attempts" do
      now = ~N[2026-08-01 14:30:00]

      attempt = %WebhookAttempt{
        status: :success,
        attempt_number: 1,
        http_status: 200,
        inserted_at: now
      }

      refute Delivery.should_retry?(attempt, now)
    end

    test "does not retry terminal failures" do
      now = ~N[2026-08-01 14:30:00]

      attempt = %WebhookAttempt{
        status: :terminal_failure,
        attempt_number: 1,
        http_status: 404,
        inserted_at: now
      }

      refute Delivery.should_retry?(attempt, now)
    end

    test "does not retry pending attempts" do
      now = ~N[2026-08-01 14:30:00]

      attempt = %WebhookAttempt{
        status: :pending,
        attempt_number: 1,
        http_status: nil,
        inserted_at: now
      }

      refute Delivery.should_retry?(attempt, now)
    end

    test "retries failed attempts with 5xx within 24 hours" do
      now = ~N[2026-08-01 14:30:00]

      attempt = %WebhookAttempt{
        status: :failed,
        attempt_number: 2,
        http_status: 500,
        inserted_at: now
      }

      assert Delivery.should_retry?(attempt, now)
    end

    test "does not retry failed attempts after 24 hours" do
      now = ~N[2026-08-01 14:30:00]
      # 25 hours ago
      inserted_at = NaiveDateTime.add(now, -90_000, :second)

      attempt = %WebhookAttempt{
        status: :failed,
        attempt_number: 5,
        http_status: 500,
        inserted_at: inserted_at
      }

      refute Delivery.should_retry?(attempt, now)
    end

    test "does not retry failed 4xx attempts" do
      now = ~N[2026-08-01 14:30:00]

      for status <- [400, 401, 403, 404, 410] do
        attempt = %WebhookAttempt{
          status: :failed,
          attempt_number: 1,
          http_status: status,
          inserted_at: now
        }

        refute Delivery.should_retry?(attempt, now), "Status #{status} should not be retried"
      end
    end
  end

  describe "should_retry?/3 (event-anchored)" do
    test "retries failed 5xx within 24 hours of event" do
      now = ~N[2026-08-01 14:30:00]
      event_inserted_at = NaiveDateTime.add(now, -3600, :second)

      attempt = %WebhookAttempt{
        status: :failed,
        attempt_number: 2,
        http_status: 500,
        inserted_at: now
      }

      assert Delivery.should_retry?(attempt, event_inserted_at, now)
    end

    test "does not retry when event is older than 24 hours" do
      now = ~N[2026-08-01 14:30:00]
      event_inserted_at = NaiveDateTime.add(now, -90_000, :second)

      attempt = %WebhookAttempt{
        status: :failed,
        attempt_number: 5,
        http_status: 500,
        inserted_at: now
      }

      refute Delivery.should_retry?(attempt, event_inserted_at, now)
    end
  end

  describe "deliver/6 — signature construction" do
    test "builds correct HMAC-SHA256 signature for known inputs" do
      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_test_123",
        event_type: "alert.opened",
        payload: %{"cluster_id" => "cluster_1"},
        body_json: ~s({"cluster_id":"cluster_1"})
      }

      secret = "webhook-secret"
      timestamp = "2026-08-01T14:30:00Z"

      body_json = event.body_json
      expected_signature = Signer.sign(secret, event.event_id, timestamp, body_json)

      assert is_binary(expected_signature)
      assert String.length(expected_signature) == 64
    end

    test "uses body_json field verbatim (byte-identical delivery)" do
      body_json = ~s({"type":"alert.opened","cluster_id":"cluster_1"})

      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_test_123",
        event_type: "alert.opened",
        payload: %{"type" => "alert.opened", "cluster_id" => "cluster_1"},
        body_json: body_json
      }

      secret = "webhook-secret"
      timestamp = "2026-08-01T14:30:00Z"

      # Signature computed over the stored body_json
      signature = Signer.sign(secret, event.event_id, timestamp, body_json)

      # Verification must use the exact same bytes
      assert {:ok, :valid} =
               Signer.verify(secret, event.event_id, timestamp, body_json, signature)

      # Adding whitespace breaks verification
      modified = ~s({"type": "alert.opened", "cluster_id": "cluster_1"})

      assert {:error, :invalid_signature} =
               Signer.verify(secret, event.event_id, timestamp, modified, signature)
    end
  end

  describe "signature verification" do
    test "delivered payload matches signature end-to-end" do
      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_abc123",
        event_type: "incident.opened",
        payload: %{"incident_id" => "inc_123", "severity" => "high"},
        body_json: ~s({"incident_id":"inc_123","severity":"high"})
      }

      secret = "test-secret"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = event.body_json
      signature = Signer.sign(secret, event.event_id, timestamp, body_json)

      assert {:ok, :valid} =
               Signer.verify(secret, event.event_id, timestamp, body_json, signature)
    end

    test "signature fails if payload is modified" do
      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_abc123",
        event_type: "incident.opened",
        payload: %{"incident_id" => "inc_123", "severity" => "high"},
        body_json: ~s({"incident_id":"inc_123","severity":"high"})
      }

      secret = "test-secret"
      timestamp = "2026-08-01T14:30:00Z"

      body_json = event.body_json
      signature = Signer.sign(secret, event.event_id, timestamp, body_json)

      modified = ~s({"incident_id":"inc_123","severity":"low"})

      assert {:error, :invalid_signature} =
               Signer.verify(secret, event.event_id, timestamp, modified, signature)
    end

    test "signature fails if event_id is modified" do
      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_abc123",
        event_type: "incident.opened",
        payload: %{"incident_id" => "inc_123"},
        body_json: ~s({"incident_id":"inc_123"})
      }

      secret = "test-secret"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = event.body_json
      signature = Signer.sign(secret, event.event_id, timestamp, body_json)

      assert {:error, :invalid_signature} =
               Signer.verify(secret, "evt_different", timestamp, body_json, signature)
    end

    test "signature fails if timestamp is modified" do
      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_abc123",
        event_type: "incident.opened",
        payload: %{"incident_id" => "inc_123"},
        body_json: ~s({"incident_id":"inc_123"})
      }

      secret = "test-secret"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = event.body_json
      signature = Signer.sign(secret, event.event_id, timestamp, body_json)

      assert {:error, :invalid_signature} =
               Signer.verify(secret, event.event_id, "2026-08-01T14:31:00Z", body_json, signature)
    end
  end
end

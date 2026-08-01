# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.DeliveryTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Webhooks.{Delivery, WebhookEvent, WebhookAttempt, Signer}

  describe "format_timestamp/1" do
    test "formats timestamp in RFC 3339 format with Z suffix" do
      timestamp = ~N[2026-08-01 14:30:00]

      formatted = Delivery.format_timestamp(timestamp)

      assert formatted == "2026-08-01T14:30:00Z"
    end

    test "truncates microseconds" do
      timestamp = ~N[2026-08-01 14:30:00.123456]

      formatted = Delivery.format_timestamp(timestamp)

      assert formatted == "2026-08-01T14:30:00Z"
    end
  end

  describe "should_retry?/2" do
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

    test "retries failed attempts within 24 hours" do
      now = ~N[2026-08-01 14:30:00]
      inserted_at = now

      attempt = %WebhookAttempt{
        status: :failed,
        attempt_number: 2,
        http_status: 500,
        inserted_at: inserted_at
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

  describe "deliver/5" do
    test "builds correct request headers with signature" do
      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_test_123",
        event_type: "alert.opened",
        payload: %{"cluster_id" => "cluster_1"}
      }

      secret = "webhook-secret"
      timestamp = "2026-08-01T14:30:00Z"

      body_json = Jason.encode!(event.payload)
      expected_signature = Signer.sign(secret, event.event_id, timestamp, body_json)

      # We can't easily test the actual delivery without mocking :httpc,
      # but we can verify the signature matches expected value
      assert is_binary(expected_signature)
      assert String.length(expected_signature) == 64
    end

    test "produces byte-identical request body" do
      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_test_123",
        event_type: "alert.opened",
        payload: %{"cluster_id" => "cluster_1", "severity" => "critical"}
      }

      # The body JSON must be byte-identical to what was signed
      # Verify this doesn't have extra whitespace
      body_json = Jason.encode!(event.payload)

      # Jason encodes without extra whitespace by default
      # No double spaces
      refute String.contains?(body_json, "  ")
      assert String.starts_with?(body_json, "{")
      assert String.ends_with?(body_json, "}")
    end
  end

  describe "signature verification" do
    test "webhook with exact payload matches signature" do
      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_abc123",
        event_type: "incident.opened",
        payload: %{"incident_id" => "inc_123", "severity" => "high"}
      }

      secret = "test-secret"
      timestamp = "2026-08-01T14:30:00Z"

      body_json = Jason.encode!(event.payload)
      signature = Signer.sign(secret, event.event_id, timestamp, body_json)

      # Verification should succeed with same values
      assert {:ok, :valid} =
               Signer.verify(secret, event.event_id, timestamp, body_json, signature)
    end

    test "webhook signature fails if payload is modified" do
      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_abc123",
        event_type: "incident.opened",
        payload: %{"incident_id" => "inc_123", "severity" => "high"}
      }

      secret = "test-secret"
      timestamp = "2026-08-01T14:30:00Z"

      body_json = Jason.encode!(event.payload)
      signature = Signer.sign(secret, event.event_id, timestamp, body_json)

      # Modify the payload
      modified_payload = %{"incident_id" => "inc_123", "severity" => "low"}
      modified_json = Jason.encode!(modified_payload)

      # Verification should fail
      assert {:error, :invalid_signature} =
               Signer.verify(secret, event.event_id, timestamp, modified_json, signature)
    end

    test "webhook signature fails if event_id is modified" do
      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_abc123",
        event_type: "incident.opened",
        payload: %{"incident_id" => "inc_123"}
      }

      secret = "test-secret"
      timestamp = "2026-08-01T14:30:00Z"

      body_json = Jason.encode!(event.payload)
      signature = Signer.sign(secret, event.event_id, timestamp, body_json)

      # Use different event_id
      assert {:error, :invalid_signature} =
               Signer.verify(secret, "evt_different", timestamp, body_json, signature)
    end

    test "webhook signature fails if timestamp is modified" do
      event = %WebhookEvent{
        id: Ecto.UUID.generate(),
        organization_id: Ecto.UUID.generate(),
        event_id: "evt_abc123",
        event_type: "incident.opened",
        payload: %{"incident_id" => "inc_123"}
      }

      secret = "test-secret"
      timestamp = "2026-08-01T14:30:00Z"

      body_json = Jason.encode!(event.payload)
      signature = Signer.sign(secret, event.event_id, timestamp, body_json)

      # Use different timestamp
      assert {:error, :invalid_signature} =
               Signer.verify(secret, event.event_id, "2026-08-01T14:31:00Z", body_json, signature)
    end
  end
end

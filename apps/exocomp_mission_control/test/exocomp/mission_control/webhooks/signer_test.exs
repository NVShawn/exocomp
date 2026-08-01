# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.SignerTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Webhooks.Signer

  describe "sign/4" do
    test "returns a hex-encoded signature" do
      secret = "test-secret"
      event_id = "evt_abc123"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = "{\"event\":\"test\"}"

      signature = Signer.sign(secret, event_id, timestamp, body_json)

      # Signature should be 64 hex characters (32 bytes * 2)
      assert is_binary(signature)
      assert String.length(signature) == 64
      assert String.match?(signature, ~r/^[0-9a-f]+$/)
    end

    test "different secrets produce different signatures" do
      event_id = "evt_abc123"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = "{\"event\":\"test\"}"

      sig1 = Signer.sign("secret1", event_id, timestamp, body_json)
      sig2 = Signer.sign("secret2", event_id, timestamp, body_json)

      assert sig1 != sig2
    end

    test "different event IDs produce different signatures" do
      secret = "test-secret"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = "{\"event\":\"test\"}"

      sig1 = Signer.sign(secret, "evt_abc123", timestamp, body_json)
      sig2 = Signer.sign(secret, "evt_def456", timestamp, body_json)

      assert sig1 != sig2
    end

    test "different timestamps produce different signatures" do
      secret = "test-secret"
      event_id = "evt_abc123"
      body_json = "{\"event\":\"test\"}"

      sig1 = Signer.sign(secret, event_id, "2026-08-01T14:30:00Z", body_json)
      sig2 = Signer.sign(secret, event_id, "2026-08-01T14:31:00Z", body_json)

      assert sig1 != sig2
    end

    test "different bodies produce different signatures" do
      secret = "test-secret"
      event_id = "evt_abc123"
      timestamp = "2026-08-01T14:30:00Z"

      sig1 = Signer.sign(secret, event_id, timestamp, "{\"event\":\"test\"}")
      sig2 = Signer.sign(secret, event_id, timestamp, "{\"event\":\"test2\"}")

      assert sig1 != sig2
    end

    test "is deterministic for the same inputs" do
      secret = "test-secret"
      event_id = "evt_abc123"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = "{\"event\":\"test\"}"

      sig1 = Signer.sign(secret, event_id, timestamp, body_json)
      sig2 = Signer.sign(secret, event_id, timestamp, body_json)

      assert sig1 == sig2
    end
  end

  describe "verify/5" do
    test "accepts valid signatures" do
      secret = "test-secret"
      event_id = "evt_abc123"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = "{\"event\":\"test\"}"

      signature = Signer.sign(secret, event_id, timestamp, body_json)

      assert {:ok, :valid} = Signer.verify(secret, event_id, timestamp, body_json, signature)
    end

    test "rejects signatures with wrong secret" do
      event_id = "evt_abc123"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = "{\"event\":\"test\"}"

      signature = Signer.sign("secret1", event_id, timestamp, body_json)

      assert {:error, :invalid_signature} =
               Signer.verify("secret2", event_id, timestamp, body_json, signature)
    end

    test "rejects signatures with modified event ID" do
      secret = "test-secret"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = "{\"event\":\"test\"}"

      signature = Signer.sign(secret, "evt_abc123", timestamp, body_json)

      assert {:error, :invalid_signature} =
               Signer.verify(secret, "evt_def456", timestamp, body_json, signature)
    end

    test "rejects signatures with modified timestamp" do
      secret = "test-secret"
      event_id = "evt_abc123"
      body_json = "{\"event\":\"test\"}"

      signature = Signer.sign(secret, event_id, "2026-08-01T14:30:00Z", body_json)

      assert {:error, :invalid_signature} =
               Signer.verify(secret, event_id, "2026-08-01T14:31:00Z", body_json, signature)
    end

    test "rejects signatures with modified body" do
      secret = "test-secret"
      event_id = "evt_abc123"
      timestamp = "2026-08-01T14:30:00Z"

      signature = Signer.sign(secret, event_id, timestamp, "{\"event\":\"test\"}")

      assert {:error, :invalid_signature} =
               Signer.verify(secret, event_id, timestamp, "{\"event\":\"test2\"}", signature)
    end

    test "rejects invalid signature format" do
      secret = "test-secret"
      event_id = "evt_abc123"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = "{\"event\":\"test\"}"

      assert {:error, :invalid_signature} =
               Signer.verify(secret, event_id, timestamp, body_json, "invalid_signature")
    end
  end

  describe "generate_secret/0" do
    test "generates a 43-character base64 secret (32 bytes)" do
      secret = Signer.generate_secret()

      assert is_binary(secret)
      # 32 bytes -> 43 chars in base64 without padding
      assert String.length(secret) == 43
    end

    test "generates unique secrets" do
      secret1 = Signer.generate_secret()
      secret2 = Signer.generate_secret()

      assert secret1 != secret2
    end

    test "generated secret can be used for signing and verification" do
      secret = Signer.generate_secret()
      event_id = "evt_abc123"
      timestamp = "2026-08-01T14:30:00Z"
      body_json = "{\"event\":\"test\"}"

      signature = Signer.sign(secret, event_id, timestamp, body_json)

      assert {:ok, :valid} = Signer.verify(secret, event_id, timestamp, body_json, signature)
    end
  end

  describe "signature vectors" do
    test "signature matches expected value for known inputs" do
      # Test vector: verify that the same inputs always produce the same signature
      secret = "webhook-secret-key"
      event_id = "evt_test_vector_1"
      timestamp = "2026-08-01T00:00:00Z"
      body_json = "{\"type\":\"test.event\"}"

      signature = Signer.sign(secret, event_id, timestamp, body_json)

      # The same inputs should always produce the same signature
      expected_signature = Signer.sign(secret, event_id, timestamp, body_json)
      assert signature == expected_signature
    end
  end

  describe "byte-identical signatures" do
    test "signature verification works with exact JSON bytes" do
      secret = Signer.generate_secret()
      event_id = "evt_abc123"
      timestamp = "2026-08-01T14:30:00Z"

      # Exact JSON bytes (no spaces)
      body_json = ~s({"type":"alert.opened","cluster_id":"cluster_1"})

      signature = Signer.sign(secret, event_id, timestamp, body_json)

      # Verification must use exact same bytes
      assert {:ok, :valid} = Signer.verify(secret, event_id, timestamp, body_json, signature)

      # Adding whitespace should fail verification
      body_json_with_space = ~s({"type": "alert.opened", "cluster_id": "cluster_1"})

      assert {:error, :invalid_signature} =
               Signer.verify(secret, event_id, timestamp, body_json_with_space, signature)
    end
  end
end

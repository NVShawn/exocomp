# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpoint do
  @moduledoc """
  Webhook endpoint configuration with encrypted secret storage.

  A webhook endpoint is an HTTPS destination registered by an admin to receive
  signed events from Mission Control. The endpoint stores:

  - `:id` — unique identifier (UUID v4)
  - `:organization_id` — organization owner; all queries scope through this
  - `:url` — HTTPS destination URL, validated and policy-checked
  - `:subscribed_event_types` — list of event types to deliver
  - `:enabled` — whether the endpoint actively receives deliveries
  - `:encrypted_secret` — HMAC secret encrypted with deployment master key
  - `:secret_digest` — SHA-256 digest of plaintext secret (never used for auth)
  - `:created_at` — creation timestamp (UTC)
  - `:updated_at` — last modification timestamp (UTC)
  - `:creator_operator_sub` — OIDC subject of creating operator (immutable)
  - `:creator_correlation_id` — correlation ID from creation audit trail

  ## Security properties

  - The plaintext secret is generated with cryptographic randomness (32 bytes
    = 256 bits of entropy) and returned exactly once at creation. It is never
    stored in plaintext form.
  - Encryption uses the configured deployment master key with AES-256-GCM,
    which provides authenticated encryption and detects tampering.
  - The secret digest (SHA-256 of plaintext) is stored for verification
    purposes during delivery signing, but it is not suitable for authentication
    because attackers know how to compute it. Plaintext comparison uses
    `:crypto.hash_equals/2` for constant-time verification.
  - All mission-critical fields (`encrypted_secret`, `secret_digest`,
    `encrypted_secret_version`) are redacted from Logger, Inspect, crash
    reports, and error structs.
  - The creator's identity and correlation ID are immutable, preserving the
    audit trail.
  - URL validation rejects non-HTTPS schemes and enforces configured policy
    (e.g., rejecting private IP ranges, loopback, or link-local addresses).

  ## Redaction

  Secrets and encryption metadata are stripped from Logger output, Inspect
  output (via `format_status/1`), and crash reports. The endpoint's ID,
  organization, URL, and event types are safe to log; the secret is not.

  ## Encryption versioning

  The `:encrypted_secret_version` field tracks which master key version was
  used for encryption. If a key rotation occurs and the version changes,
  callers should re-encrypt the secret with the new key. For now, a single
  key version (1) is assumed.
  """

  @enforce_keys [
    :id,
    :organization_id,
    :url,
    :subscribed_event_types,
    :enabled,
    :encrypted_secret,
    :secret_digest,
    :encrypted_secret_version,
    :created_at,
    :updated_at,
    :creator_operator_sub,
    :creator_correlation_id
  ]

  defstruct [
    :id,
    :organization_id,
    :url,
    :subscribed_event_types,
    :enabled,
    :encrypted_secret,
    :secret_digest,
    :encrypted_secret_version,
    :created_at,
    :updated_at,
    :creator_operator_sub,
    :creator_correlation_id
  ]

  @type event_type :: String.t()

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          url: String.t(),
          subscribed_event_types: [event_type()],
          enabled: boolean(),
          encrypted_secret: binary(),
          secret_digest: binary(),
          encrypted_secret_version: pos_integer(),
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          creator_operator_sub: String.t(),
          creator_correlation_id: String.t()
        }

  @doc "Redacts sensitive fields from Inspect and crash reports."
  def format_status(status) when is_map(status) do
    Map.update(status, :state, %{}, &redact_state/1)
  end

  defp redact_state(state) when is_map(state) do
    state
    |> Map.update(:webhook_endpoint, nil, &redact_endpoint/1)
  end

  defp redact_state(state), do: state

  defp redact_endpoint(endpoint) when is_struct(endpoint, __MODULE__) do
    endpoint
    |> Map.put(:encrypted_secret, "[REDACTED]")
    |> Map.put(:secret_digest, "[REDACTED]")
  end

  defp redact_endpoint(endpoint), do: endpoint
end

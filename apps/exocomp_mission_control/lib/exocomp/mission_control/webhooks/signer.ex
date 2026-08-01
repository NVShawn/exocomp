# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.Signer do
  @moduledoc """
  Signs webhook events with HMAC-SHA256.

  The signature covers the event ID, delivery timestamp, and exact JSON body.
  This ensures that the body cannot be modified after signing and that the
  signature can be verified by consumers using the same secret.
  """

  @doc """
  Signs a webhook event with the given secret.

  The signature is computed over a canonical string formed from:
  - Event ID (url-safe base64 without padding)
  - Delivery timestamp (RFC 3339 format, e.g. "2026-08-01T14:30:00Z")
  - JSON body (exact bytes used for delivery)

  The canonical form is: "event_id.timestamp.body_hash"

  Returns the signature as hex-encoded bytes.

  ## Examples

      iex> secret = "my-secret-key"
      iex> event_id = "evt_abc123"
      iex> timestamp = "2026-08-01T14:30:00Z"
      iex> body_json = "{\\"event\\":\\"test\\"}"
      iex> signature = Signer.sign(secret, event_id, timestamp, body_json)
      iex> is_binary(signature) and String.length(signature) == 64
      true
  """
  @spec sign(secret :: binary, event_id :: binary, timestamp :: binary, body_json :: binary) ::
          binary
  def sign(secret, event_id, timestamp, body_json)
      when is_binary(secret) and is_binary(event_id) and is_binary(timestamp) and
             is_binary(body_json) do
    canonical = canonical_string(event_id, timestamp, body_json)
    signature_bytes = :crypto.mac(:hmac, :sha256, secret, canonical)
    hex_encode(signature_bytes)
  end

  @doc """
  Verifies a webhook signature.

  Computes the expected signature and compares it with the provided signature
  using constant-time comparison to prevent timing attacks.

  Returns `{:ok, :valid}` if the signature is valid, or `{:error, :invalid_signature}`
  if verification fails.
  """
  @spec verify(
          secret :: binary,
          event_id :: binary,
          timestamp :: binary,
          body_json :: binary,
          signature :: binary
        ) :: {:ok, :valid} | {:error, :invalid_signature}
  def verify(secret, event_id, timestamp, body_json, signature) do
    expected = sign(secret, event_id, timestamp, body_json)

    if constant_time_equal(expected, signature) do
      {:ok, :valid}
    else
      {:error, :invalid_signature}
    end
  end

  @doc """
  Generates a random webhook secret.

  Returns a 32-byte secret encoded as url-safe base64 (without padding).
  """
  @spec generate_secret() :: binary
  def generate_secret do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)
  end

  defp canonical_string(event_id, timestamp, body_json) do
    "#{event_id}.#{timestamp}.#{body_json}"
  end

  defp hex_encode(bytes) do
    Base.encode16(bytes, case: :lower)
  end

  defp constant_time_equal(a, b) do
    Plug.Crypto.secure_compare(a, b)
  end
end

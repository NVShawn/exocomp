# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpoints.Encryption do
  @moduledoc """
  Authenticated encryption for webhook endpoint secrets using AES-256-GCM.

  This module handles encryption and decryption of plaintext webhook secrets
  using the configured deployment master key. The encryption scheme provides
  authenticated encryption (AEAD), which means:

  - The ciphertext cannot be decrypted or forged without the correct key
  - Tampering with the ciphertext is detectable; decryption fails
  - The nonce is randomly generated for each encryption operation
  - Encryption is deterministic only in the sense that decryption always
    succeeds or fails; two encryptions of the same plaintext produce different
    ciphertexts due to random nonces.

  ## Master key configuration

  The deployment master key is obtained from the runtime configuration:

  ```elixir
  config :exocomp_mission_control, Exocomp.MissionControl.WebhookEndpoints.Encryption,
    master_key: "<base64-encoded-32-byte-key>"  # Must be exactly 32 bytes
  ```

  If the master key is not configured or is invalid (wrong size), all encryption
  and decryption operations fail immediately with `:master_key_unavailable` or
  `:invalid_master_key`.

  ## Format

  The encrypted output is a binary tuple encoded as:

  ```
  [version_byte | nonce | tag | ciphertext]
  ```

  Where:
  - `version_byte` — single byte (0x01) for forward compatibility
  - `nonce` — 12 random bytes (96-bit nonce for GCM)
  - `tag` — 16 bytes (128-bit AEAD authentication tag)
  - `ciphertext` — AES-256-GCM encrypted plaintext

  The entire encrypted blob is returned as-is (binary) and stored in the
  database without further encoding. For readability in database inspection,
  the binary may be base64-encoded at the storage layer.

  ## Key rotation

  To support key rotation, this module tracks an `encrypted_secret_version`
  field in the WebhookEndpoint. When a new master key is deployed:

  1. Store both old and new keys in configuration with version identifiers
  2. During decryption, read the version from the endpoint and use the
     corresponding key
  3. During rotation, re-encrypt with the new key and update the version
  4. After a retention period, retire the old key

  For now, only version 1 is supported.

  ## Security properties

  - The master key is obtained at startup and cached in process state
  - The key is never logged or included in error messages
  - Encryption uses cryptographically random nonces (no reuse)
  - Decryption fails closed when the key is unavailable
  - The implementation uses `:crypto.block_encrypt/4` with GCM mode
  """

  require Logger

  @doc """
  Encrypts a plaintext secret with the deployment master key.

  Returns `{:ok, encrypted_blob, version}` where `encrypted_blob` is the
  encrypted ciphertext (binary) and `version` is the key version used (currently 1).

  Returns `{:error, reason}` when:
  - `:master_key_unavailable` — master key not configured
  - `:invalid_master_key` — configured key has wrong size
  - `:encryption_failed` — underlying crypto error

  The plaintext may be any binary (typically a base64-encoded secret string).
  The ciphertext should be stored as-is in the database.
  """
  @spec encrypt(binary()) :: {:ok, binary(), pos_integer()} | {:error, atom()}
  def encrypt(plaintext) when is_binary(plaintext) do
    with {:ok, key} <- get_master_key(),
         {:ok, nonce} <- generate_nonce(),
         {:ok, ciphertext, tag} <- do_encrypt(key, nonce, plaintext) do
      # Format: version_byte | nonce | tag | ciphertext
      encrypted_blob = <<0x01, nonce::binary, tag::binary, ciphertext::binary>>
      {:ok, encrypted_blob, 1}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Decrypts a ciphertext with the deployment master key.

  Returns `{:ok, plaintext}` on successful decryption and authentication.

  Returns `{:error, reason}` when:
  - `:master_key_unavailable` — master key not configured
  - `:invalid_master_key` — configured key has wrong size
  - `:invalid_ciphertext` — ciphertext format is invalid
  - `:decryption_failed` — ciphertext could not be authenticated (tampered or
      encrypted with a different key)
  - `:unsupported_version` — ciphertext uses an unknown encryption version

  The decrypted plaintext is returned as-is.
  """
  @spec decrypt(binary(), pos_integer()) :: {:ok, binary()} | {:error, atom()}
  def decrypt(encrypted_blob, version) when is_binary(encrypted_blob) and is_integer(version) do
    with {:ok, key} <- get_master_key(version),
         {:ok, nonce, tag, ciphertext} <- parse_encrypted_blob(encrypted_blob) do
      do_decrypt(key, nonce, ciphertext, tag)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  # Retrieves the deployment master key from configuration.
  # Returns {:ok, key_binary} or {:error, reason}.
  defp get_master_key(version \\ 1) do
    cond do
      version != 1 ->
        {:error, :unsupported_version}

      true ->
        case Application.get_env(:exocomp_mission_control, __MODULE__, []) do
          config when is_list(config) ->
            case Keyword.get(config, :master_key) do
              nil ->
                {:error, :master_key_unavailable}

              encoded_key when is_binary(encoded_key) ->
                case Base.decode64(encoded_key) do
                  {:ok, key} when byte_size(key) == 32 ->
                    {:ok, key}

                  {:ok, _key} ->
                    Logger.warning(
                      "WebhookEndpoints.Encryption: configured master key has invalid size"
                    )

                    {:error, :invalid_master_key}

                  :error ->
                    Logger.warning(
                      "WebhookEndpoints.Encryption: configured master key is not valid base64"
                    )

                    {:error, :invalid_master_key}
                end

              _ ->
                {:error, :invalid_master_key}
            end

          _ ->
            {:error, :master_key_unavailable}
        end
    end
  end

  # Generates a random 96-bit (12-byte) nonce for AES-GCM.
  # Returns {:ok, nonce_binary} or {:error, reason}.
  defp generate_nonce do
    try do
      nonce = :crypto.strong_rand_bytes(12)
      {:ok, nonce}
    rescue
      _ -> {:error, :nonce_generation_failed}
    end
  end

  # Encrypts plaintext with AES-256-GCM.
  # Returns {:ok, ciphertext, tag} or {:error, reason}.
  defp do_encrypt(key, nonce, plaintext) do
    try do
      {ciphertext, tag} =
        :crypto.crypto_one_time_aead(
          :aes_256_gcm,
          key,
          nonce,
          plaintext,
          <<>>,
          true
        )

      {:ok, ciphertext, tag}
    rescue
      error ->
        Logger.error("WebhookEndpoints.Encryption: AES-GCM encryption failed: #{inspect(error)}")
        {:error, :encryption_failed}
    end
  end

  # Decrypts AES-256-GCM ciphertext.
  # Returns {:ok, plaintext} or {:error, reason}.
  # Note: crypto_one_time_aead/7 returns :error as plaintext on auth failure.
  defp do_decrypt(key, nonce, ciphertext, tag) do
    try do
      case :crypto.crypto_one_time_aead(
             :aes_256_gcm,
             key,
             nonce,
             ciphertext,
             <<>>,
             tag,
             false
           ) do
        :error ->
          {:error, :decryption_failed}

        plaintext when is_binary(plaintext) ->
          {:ok, plaintext}

        other ->
          Logger.error(
            "WebhookEndpoints.Encryption: unexpected decryption result: #{inspect(other)}"
          )

          {:error, :decryption_failed}
      end
    rescue
      error ->
        Logger.error("WebhookEndpoints.Encryption: AES-GCM decryption failed: #{inspect(error)}")
        {:error, :decryption_failed}
    end
  end

  # Parses the encrypted blob format.
  # Format: version_byte (1) | nonce (12) | tag (16) | ciphertext (rest)
  # Returns {:ok, nonce, tag, ciphertext} or {:error, reason}.
  defp parse_encrypted_blob(blob) when byte_size(blob) >= 29 do
    case blob do
      <<0x01, nonce::binary-size(12), tag::binary-size(16), ciphertext::binary>> ->
        {:ok, nonce, tag, ciphertext}

      <<version, _::binary>> when version != 0x01 ->
        {:error, :unsupported_version}

      _ ->
        {:error, :invalid_ciphertext}
    end
  end

  defp parse_encrypted_blob(_blob), do: {:error, :invalid_ciphertext}
end

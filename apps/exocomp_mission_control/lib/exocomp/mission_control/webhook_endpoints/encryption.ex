# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpoints.Encryption do
  @moduledoc """
  Authenticated encryption for webhook signing secrets.

  Secrets use AES-256-GCM and a 96-bit cryptographically random nonce. The
  deployment master key is supplied at runtime as base64-encoded 32 bytes in
  this module's application configuration. The module never logs a key,
  plaintext, ciphertext, or a cryptographic exception.

  Context callers bind a ciphertext to its organization and endpoint ID using
  additional authenticated data (AAD). Consequently a database-level swap of
  ciphertext between endpoint rows fails authentication rather than silently
  changing which secret is used.
  """

  @version 1
  @nonce_bytes 12
  @tag_bytes 16

  @type reason ::
          :master_key_unavailable
          | :invalid_master_key
          | :encryption_failed
          | :decryption_failed
          | :invalid_ciphertext
          | :unsupported_version

  @doc "Encrypts a plaintext secret without additional authenticated data."
  @spec encrypt(binary()) :: {:ok, binary(), pos_integer()} | {:error, reason()}
  def encrypt(plaintext) when is_binary(plaintext), do: encrypt(plaintext, <<>>)

  @doc "Encrypts a plaintext secret and authenticates the supplied context."
  @spec encrypt(binary(), binary()) :: {:ok, binary(), pos_integer()} | {:error, reason()}
  def encrypt(plaintext, aad) when is_binary(plaintext) and is_binary(aad) do
    with {:ok, key} <- get_master_key(),
         {:ok, nonce} <- generate_nonce(),
         {:ok, ciphertext, tag} <- do_encrypt(key, nonce, plaintext, aad) do
      {:ok, <<@version, nonce::binary, tag::binary, ciphertext::binary>>, @version}
    end
  end

  @doc "Decrypts a ciphertext that was encrypted without authenticated context."
  @spec decrypt(binary(), pos_integer()) :: {:ok, binary()} | {:error, reason()}
  def decrypt(encrypted_blob, version) when is_binary(encrypted_blob) and is_integer(version),
    do: decrypt(encrypted_blob, version, <<>>)

  @doc "Decrypts a ciphertext only when the supplied context matches its AAD."
  @spec decrypt(binary(), pos_integer(), binary()) :: {:ok, binary()} | {:error, reason()}
  def decrypt(encrypted_blob, version, aad)
      when is_binary(encrypted_blob) and is_integer(version) and is_binary(aad) do
    with {:ok, key} <- get_master_key(version),
         {:ok, nonce, tag, ciphertext} <- parse_encrypted_blob(encrypted_blob) do
      do_decrypt(key, nonce, ciphertext, tag, aad)
    end
  end

  defp get_master_key(version \\ @version) do
    with :ok <- supported_version(version),
         {:ok, encoded_key} <- configured_key(),
         {:ok, key} <- decode_key(encoded_key) do
      {:ok, key}
    end
  end

  defp supported_version(@version), do: :ok
  defp supported_version(_version), do: {:error, :unsupported_version}

  defp configured_key do
    case Application.get_env(:exocomp_mission_control, __MODULE__, []) do
      config when is_list(config) ->
        case Keyword.fetch(config, :master_key) do
          {:ok, key} when is_binary(key) -> {:ok, key}
          {:ok, nil} -> {:error, :master_key_unavailable}
          {:ok, _key} -> {:error, :invalid_master_key}
          :error -> {:error, :master_key_unavailable}
        end

      _ ->
        {:error, :master_key_unavailable}
    end
  end

  defp decode_key(encoded_key) do
    case Base.decode64(encoded_key) do
      {:ok, key} when byte_size(key) == 32 -> {:ok, key}
      _ -> {:error, :invalid_master_key}
    end
  end

  defp generate_nonce do
    try do
      {:ok, :crypto.strong_rand_bytes(@nonce_bytes)}
    rescue
      _exception -> {:error, :encryption_failed}
    end
  end

  defp do_encrypt(key, nonce, plaintext, aad) do
    try do
      {ciphertext, tag} =
        :crypto.crypto_one_time_aead(:aes_256_gcm, key, nonce, plaintext, aad, true)

      {:ok, ciphertext, tag}
    rescue
      _exception -> {:error, :encryption_failed}
    end
  end

  defp do_decrypt(key, nonce, ciphertext, tag, aad) do
    try do
      case :crypto.crypto_one_time_aead(:aes_256_gcm, key, nonce, ciphertext, aad, tag, false) do
        :error -> {:error, :decryption_failed}
        plaintext when is_binary(plaintext) -> {:ok, plaintext}
        _other -> {:error, :decryption_failed}
      end
    rescue
      _exception -> {:error, :decryption_failed}
    end
  end

  defp parse_encrypted_blob(
         <<@version, nonce::binary-size(@nonce_bytes), tag::binary-size(@tag_bytes),
           ciphertext::binary>>
       ) do
    {:ok, nonce, tag, ciphertext}
  end

  defp parse_encrypted_blob(<<_other_version, rest::binary>>)
       when byte_size(rest) >= @nonce_bytes + @tag_bytes,
       do: {:error, :unsupported_version}

  defp parse_encrypted_blob(_blob), do: {:error, :invalid_ciphertext}
end

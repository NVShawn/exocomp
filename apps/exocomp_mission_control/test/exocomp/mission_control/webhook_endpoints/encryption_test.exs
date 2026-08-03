# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpoints.EncryptionTest do
  use ExUnit.Case, async: false

  alias Exocomp.MissionControl.WebhookEndpoints.Encryption

  describe "encrypt/1 and decrypt/2" do
    setup do
      # Generate a valid 32-byte master key for testing
      key = :crypto.strong_rand_bytes(32)
      key_b64 = Base.encode64(key)

      # Configure the encryption module with the test key
      Application.put_env(
        :exocomp_mission_control,
        Encryption,
        master_key: key_b64
      )

      on_exit(fn ->
        Application.delete_env(:exocomp_mission_control, Encryption)
      end)

      {:ok, key: key, key_b64: key_b64}
    end

    test "round-trip encryption succeeds" do
      plaintext = "test_secret_value_for_webhook"

      assert {:ok, ciphertext, version} = Encryption.encrypt(plaintext)
      assert is_binary(ciphertext)
      assert version == 1
      assert byte_size(ciphertext) > byte_size(plaintext)

      # Decrypt should recover the original plaintext
      assert {:ok, ^plaintext} = Encryption.decrypt(ciphertext, version)
    end

    test "different encryptions produce different ciphertexts" do
      plaintext = "same_plaintext"

      assert {:ok, ct1, v1} = Encryption.encrypt(plaintext)
      assert {:ok, ct2, v2} = Encryption.encrypt(plaintext)

      assert v1 == v2
      # Different nonces mean different ciphertexts
      assert ct1 != ct2

      # But both decrypt to the same plaintext
      assert {:ok, ^plaintext} = Encryption.decrypt(ct1, v1)
      assert {:ok, ^plaintext} = Encryption.decrypt(ct2, v2)
    end

    test "authenticated context prevents ciphertext swapping between endpoints" do
      plaintext = "secret_data"

      assert {:ok, ciphertext, version} = Encryption.encrypt(plaintext, "org-a\0endpoint-a")
      assert {:ok, ^plaintext} = Encryption.decrypt(ciphertext, version, "org-a\0endpoint-a")

      assert {:error, :decryption_failed} =
               Encryption.decrypt(ciphertext, version, "org-b\0endpoint-b")
    end

    test "decryption fails with wrong master key" do
      plaintext = "secret_data"

      assert {:ok, ciphertext, version} = Encryption.encrypt(plaintext)

      # Change the master key
      wrong_key = :crypto.strong_rand_bytes(32)
      wrong_key_b64 = Base.encode64(wrong_key)

      Application.put_env(
        :exocomp_mission_control,
        Encryption,
        master_key: wrong_key_b64
      )

      # Decryption should fail
      assert {:error, :decryption_failed} = Encryption.decrypt(ciphertext, version)
    end

    test "decryption fails with tampered ciphertext" do
      plaintext = "secret_data"

      assert {:ok, ciphertext, version} = Encryption.encrypt(plaintext)

      # Flip a bit in the ciphertext to tamper with it
      tampered =
        case ciphertext do
          <<head::binary-size(20), byte, tail::binary>> ->
            <<head::binary-size(20), Bitwise.bxor(byte, 0x01), tail::binary>>

          _ ->
            ciphertext
        end

      # Decryption should fail due to authentication tag mismatch
      assert {:error, :decryption_failed} = Encryption.decrypt(tampered, version)
    end

    test "encryption fails when master key is not configured" do
      Application.delete_env(:exocomp_mission_control, Encryption)

      plaintext = "secret_data"

      assert {:error, :master_key_unavailable} = Encryption.encrypt(plaintext)
    end

    test "decryption fails when master key is not configured" do
      plaintext = "secret_data"

      # First encrypt with valid key
      assert {:ok, ciphertext, version} = Encryption.encrypt(plaintext)

      # Remove the key
      Application.delete_env(:exocomp_mission_control, Encryption)

      # Decryption should fail
      assert {:error, :master_key_unavailable} = Encryption.decrypt(ciphertext, version)
    end

    test "encryption fails with invalid master key (wrong size)" do
      # Configure with 16-byte key (too short)
      short_key = :crypto.strong_rand_bytes(16)
      short_key_b64 = Base.encode64(short_key)

      Application.put_env(
        :exocomp_mission_control,
        Encryption,
        master_key: short_key_b64
      )

      plaintext = "secret_data"

      assert {:error, :invalid_master_key} = Encryption.encrypt(plaintext)
    end

    test "decryption fails with invalid master key (wrong size)" do
      plaintext = "secret_data"

      # First encrypt with valid key
      assert {:ok, ciphertext, version} = Encryption.encrypt(plaintext)

      # Change to short key
      short_key = :crypto.strong_rand_bytes(16)
      short_key_b64 = Base.encode64(short_key)

      Application.put_env(
        :exocomp_mission_control,
        Encryption,
        master_key: short_key_b64
      )

      # Decryption should fail
      assert {:error, :invalid_master_key} = Encryption.decrypt(ciphertext, version)
    end

    test "decryption fails with invalid ciphertext format" do
      assert {:error, :invalid_ciphertext} = Encryption.decrypt("too_short", 1)
      assert {:error, :invalid_ciphertext} = Encryption.decrypt("", 1)
    end

    test "decryption fails with unsupported version" do
      plaintext = "secret_data"
      assert {:ok, ciphertext, _version} = Encryption.encrypt(plaintext)

      # Try to decrypt with unsupported version
      assert {:error, :unsupported_version} = Encryption.decrypt(ciphertext, 99)
    end

    test "encrypted data format is correct" do
      plaintext = "test_data"

      assert {:ok, ciphertext, version} = Encryption.encrypt(plaintext)
      assert version == 1

      # Check format: version_byte (1) | nonce (12) | tag (16) | ciphertext (rest)
      assert byte_size(ciphertext) >= 29
      <<version_byte, _nonce::binary-size(12), _tag::binary-size(16), _ct::binary>> = ciphertext
      assert version_byte == 0x01
    end
  end
end
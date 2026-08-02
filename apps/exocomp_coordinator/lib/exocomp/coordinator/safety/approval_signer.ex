# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Safety.ApprovalSigner do
  @moduledoc """
  Signs the shared short-lived approval-token payload inside the coordinator.

  The private approval key is read only at this boundary.  This module returns
  the wire token, never the key, and deliberately has no Mission Control
  integration or serialization path for private material.
  """

  alias Exocomp.Core.ApprovalToken

  @fields ~w(
    action_id
    correlation_id
    evidence_hash
    expires_at
    issued_at
    node_id
    nonce
    operator
    parameter_hash
    schema_version
    task_id
  )

  @private_prefix "-----BEGIN EXOCOMP ED25519 PRIVATE KEY-----\n"
  @private_suffix "\n-----END EXOCOMP ED25519 PRIVATE KEY-----\n"

  @type error ::
          :invalid_payload
          | :approval_private_key_unavailable
          | :invalid_approval_private_key
          | {:signing_failed, term()}

  @doc "Signs a validated shared approval-token payload."
  @spec sign(map(), keyword()) :: {:ok, map()} | {:error, error()}
  def sign(payload, opts \\ [])

  def sign(payload, opts) when is_map(payload) do
    with {:ok, payload} <- normalize_payload(payload),
         {:ok, private_key} <- private_key(opts),
         {:ok, signature} <- sign_payload(payload, private_key) do
      {:ok,
       %{
         "payload" => payload,
         "signature" => Base.url_encode64(signature, padding: false)
       }}
    end
  end

  def sign(_payload, _opts), do: {:error, :invalid_payload}

  defp normalize_payload(payload) do
    keys = payload |> Map.keys() |> Enum.map(&to_string/1) |> MapSet.new()
    known_keys = MapSet.new(@fields)
    normalized = Map.new(@fields, fn field -> {field, fetch(payload, field)} end)

    if MapSet.equal?(keys, known_keys) and
         Enum.all?(@fields, fn field -> valid_field?(field, Map.fetch!(normalized, field)) end) and
         normalized["schema_version"] == "1" do
      {:ok, normalized}
    else
      {:error, :invalid_payload}
    end
  end

  defp valid_field?(_field, value) when is_binary(value) and byte_size(value) > 0, do: true
  defp valid_field?(_field, _value), do: false

  defp fetch(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, String.to_existing_atom(key))
    end
  rescue
    ArgumentError -> nil
  end

  defp private_key(opts) do
    case Keyword.fetch(opts, :private_key) do
      {:ok, key} -> decode_private(key)
      :error -> read_private_key(Keyword.get(opts, :key_path) || configured_key_path())
    end
  end

  defp configured_key_path do
    case Application.get_env(:exocomp_coordinator, :approval_signing_key_path) do
      path when is_binary(path) ->
        path

      _ ->
        case Application.get_env(:exocomp_coordinator, :pki_online_state) do
          path when is_binary(path) -> Path.join(path, "approval_signing.key")
          _ -> nil
        end
    end
  end

  defp read_private_key(path) when is_binary(path) do
    case File.read(path) do
      {:ok, encoded} -> decode_private(encoded)
      _ -> {:error, :approval_private_key_unavailable}
    end
  end

  defp read_private_key(_path), do: {:error, :approval_private_key_unavailable}

  defp decode_private(key) when is_binary(key) and byte_size(key) == 32, do: {:ok, key}

  defp decode_private(encoded) when is_binary(encoded) do
    if String.starts_with?(encoded, @private_prefix) and
         String.ends_with?(encoded, @private_suffix) do
      encoded
      |> String.trim_leading(@private_prefix)
      |> String.trim_trailing(@private_suffix)
      |> Base.decode64()
      |> case do
        {:ok, key} when byte_size(key) == 32 -> {:ok, key}
        _ -> {:error, :invalid_approval_private_key}
      end
    else
      {:error, :invalid_approval_private_key}
    end
  end

  defp decode_private(_key), do: {:error, :invalid_approval_private_key}

  defp sign_payload(payload, private_key) do
    try do
      {:ok,
       :crypto.sign(
         :eddsa,
         :none,
         ApprovalToken.canonical_encode(payload),
         [private_key, :ed25519]
       )}
    rescue
      _ -> {:error, {:signing_failed, :crypto_error}}
    catch
      _kind, _reason -> {:error, {:signing_failed, :crypto_error}}
    end
  end
end

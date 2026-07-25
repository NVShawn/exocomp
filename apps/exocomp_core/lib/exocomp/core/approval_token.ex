# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Core.ApprovalToken do
  @moduledoc """
  Shared canonical encoding and hashing for approval-token payloads.

  Payloads are encoded as JSON with the eleven version-1 keys in
  lexicographic order. Nested parameter and evidence maps are also sorted,
  keeping coordinator signing and node verification byte-for-byte compatible
  without introducing a dependency between those applications.
  """

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

  @doc "Canonically encodes the eleven approval-token payload fields."
  @spec canonical_encode(map() | struct()) :: binary()
  def canonical_encode(payload) when is_map(payload) do
    @fields
    |> Enum.map(fn key -> {key, fetch(payload, key)} end)
    |> encode_object()
  end

  @doc "Returns a lowercase hexadecimal SHA-256 digest."
  @spec sha256_hex(binary()) :: String.t()
  def sha256_hex(data) when is_binary(data) do
    :crypto.hash(:sha256, data)
    |> Base.encode16(case: :lower)
  end

  @doc "Hashes parameters using recursively sorted JSON."
  @spec hash_params(map()) :: String.t()
  def hash_params(params) when is_map(params), do: params |> sorted_json() |> sha256_hex()

  @doc "Hashes evidence using recursively sorted JSON."
  @spec hash_evidence(map()) :: String.t()
  def hash_evidence(evidence) when is_map(evidence), do: evidence |> sorted_json() |> sha256_hex()

  defp fetch(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, String.to_atom(key))
    end
  end

  defp sorted_json(map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), value} end)
    |> Enum.sort_by(&elem(&1, 0))
    |> encode_object()
  end

  defp encode_object(pairs) do
    encoded =
      Enum.map_join(pairs, ",", fn {key, value} ->
        Jason.encode!(key) <> ":" <> encode_value(value)
      end)

    "{" <> encoded <> "}"
  end

  defp encode_value(value) when is_map(value), do: sorted_json(value)
  defp encode_value(value), do: Jason.encode!(value)
end

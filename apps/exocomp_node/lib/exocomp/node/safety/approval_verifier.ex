defmodule Exocomp.Node.Safety.ApprovalVerifier do
  @moduledoc """
  Verifies signed approval tokens before node-side execution.

  The wire format is `%{"payload" => payload, "signature" => signature}`.
  `payload` contains the eleven version-1 fields documented by
  `Exocomp.Core.ApprovalToken`; `signature` is either a raw 64-byte Ed25519
  signature or an unpadded base64url string. Atom-keyed maps are also accepted
  for internal callers.

  The coordinator public key is provisioned as a raw 32-byte file at the path
  configured under `config :exocomp_node, :approval_public_key_path`. It is
  loaded lazily for each verification, which permits safe key replacement and
  makes tests injectable through application configuration. Missing and
  malformed files fail closed as `:public_key_unavailable`; paths and key bytes
  are never included in errors or logs.

  The key is a separate, operator-provisioned trust anchor. It is not currently
  checked against the coordinator TLS certificate because enrollment defines
  no authenticated binding between that certificate and the approval key.
  Adding such a check without that protocol would create a false authenticity
  guarantee.

  Canonical encoding lives in `exocomp_core` so coordinator and node code can
  share signing bytes without a node-to-coordinator application dependency.
  """

  alias Exocomp.Core.ApprovalToken

  @schema_version "1"
  @non_empty_fields [:nonce, :evidence_hash, :operator]
  @context_fields [:node_id, :task_id, :correlation_id]

  @type error ::
          :expired
          | :not_yet_valid
          | :invalid_signature
          | :public_key_unavailable
          | {:binding_mismatch, atom(), term(), term()}

  @doc """
  Verifies a token against an execution context.

  The context requires `node_id`, `task_id`, `correlation_id`, `action`, and
  `parameters`. `action` may be an atom or string. Tests and deterministic
  callers may supply `now` as a `DateTime`; otherwise current UTC time is used.
  """
  @spec verify(map(), map() | keyword()) :: {:ok, map()} | {:error, error()}
  def verify(token, context) when is_map(token) do
    with {:ok, payload, signature} <- split_token(token),
         {:ok, public_key} <- load_public_key(),
         :ok <- verify_signature(payload, signature, public_key),
         :ok <- verify_bindings(payload, context) do
      {:ok, token}
    end
  end

  defp split_token(token) do
    payload = get(token, :payload)
    signature = get(token, :signature)

    cond do
      not is_map(payload) -> {:error, :invalid_signature}
      true -> decode_signature(signature, payload)
    end
  end

  defp decode_signature(signature, payload)
       when is_binary(signature) and byte_size(signature) == 64,
       do: {:ok, payload, signature}

  defp decode_signature(signature, payload) when is_binary(signature) do
    case Base.url_decode64(signature, padding: false) do
      {:ok, decoded} when byte_size(decoded) == 64 -> {:ok, payload, decoded}
      _ -> {:error, :invalid_signature}
    end
  end

  defp decode_signature(_, _), do: {:error, :invalid_signature}

  defp load_public_key do
    path = Application.get_env(:exocomp_node, :approval_public_key_path)

    case is_binary(path) && File.read(path) do
      {:ok, key} when byte_size(key) == 32 -> {:ok, key}
      _ -> {:error, :public_key_unavailable}
    end
  end

  defp verify_signature(payload, signature, public_key) do
    if :crypto.verify(
         :eddsa,
         :none,
         ApprovalToken.canonical_encode(payload),
         signature,
         [public_key, :ed25519]
       ) do
      :ok
    else
      {:error, :invalid_signature}
    end
  rescue
    _ -> {:error, :invalid_signature}
  end

  defp verify_bindings(payload, context) do
    now = context_get(context, :now) || DateTime.utc_now()

    with :ok <- match_field(payload, :schema_version, @schema_version),
         :ok <- verify_non_empty(payload, @non_empty_fields),
         :ok <- verify_context_fields(payload, context),
         :ok <- match_field(payload, :action_id, action_id(context_get(context, :action))),
         :ok <-
           match_field(
             payload,
             :parameter_hash,
             ApprovalToken.hash_params(context_get(context, :parameters))
           ),
         {:ok, issued_at} <- parse_time(payload, :issued_at),
         :ok <- verify_issued_at(issued_at, now),
         {:ok, expires_at} <- parse_time(payload, :expires_at),
         :ok <- verify_expires_at(expires_at, now) do
      :ok
    end
  end

  defp verify_non_empty(payload, fields) do
    Enum.reduce_while(fields, :ok, fn field, :ok ->
      actual = get(payload, field)

      if is_binary(actual) and actual != "" do
        {:cont, :ok}
      else
        {:halt, mismatch(field, :non_empty, actual)}
      end
    end)
  end

  defp verify_context_fields(payload, context) do
    Enum.reduce_while(@context_fields, :ok, fn field, :ok ->
      case match_field(payload, field, context_get(context, field)) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp parse_time(payload, field) do
    actual = get(payload, field)

    case is_binary(actual) && DateTime.from_iso8601(actual) do
      {:ok, datetime, _offset} -> {:ok, datetime}
      _ -> mismatch(field, :iso8601_utc_timestamp, actual)
    end
  end

  defp verify_issued_at(issued_at, now) do
    if DateTime.compare(issued_at, now) == :gt, do: {:error, :not_yet_valid}, else: :ok
  end

  defp verify_expires_at(expires_at, now) do
    if DateTime.compare(expires_at, now) == :gt, do: :ok, else: {:error, :expired}
  end

  defp match_field(payload, field, expected) do
    actual = get(payload, field)
    if actual == expected, do: :ok, else: mismatch(field, expected, actual)
  end

  defp mismatch(field, expected, actual),
    do: {:error, {:binding_mismatch, field, expected, actual}}

  defp action_id(action) when is_atom(action), do: Atom.to_string(action)
  defp action_id(action) when is_binary(action), do: action
  defp action_id(action), do: action

  defp context_get(context, key) when is_list(context), do: Keyword.get(context, key)
  defp context_get(context, key) when is_map(context), do: get(context, key)

  defp get(map, key), do: Map.get(map, key, Map.get(map, Atom.to_string(key)))
end

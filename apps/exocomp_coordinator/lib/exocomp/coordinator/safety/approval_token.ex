defmodule Exocomp.Coordinator.Safety.ApprovalToken do
  @moduledoc """
  Canonical, versioned approval-token payload struct and deterministic binary
  serialisation used to produce the signing input for Ed25519 signatures.

  ## Fields

  - `schema_version` — fixed string `"1"`
  - `nonce` — 32 high-entropy random bytes, base64url-encoded
  - `task_id` — A2A task identifier
  - `correlation_id` — correlation/trace identifier
  - `node_id` — target node identity
  - `action_id` — stable action identifier from the catalog
  - `parameter_hash` — SHA-256 hex digest of the canonical action parameters map
  - `evidence_hash` — SHA-256 hex digest of the canonical evidence map
  - `issued_at` — ISO 8601 UTC timestamp string
  - `expires_at` — ISO 8601 UTC timestamp string (typically 5 minutes after issued_at)
  - `operator` — approving operator identity string

  ## Canonical encoding

  `canonical_encode/1` serialises all 11 fields as a UTF-8 JSON object with
  keys in lexicographic (alphabetical) order. This is reproducible across BEAM
  restarts and language boundaries. The resulting binary is suitable for direct
  use as input to `:crypto.sign/5`.

  Because Elixir maps do not preserve insertion order and Jason 1.4.x does not
  provide a `sort_keys` encoder option, the canonical JSON is built by
  iterating over a manually sorted list of `{key, value}` pairs and
  concatenating their individual encodings. This guarantees a fixed byte
  sequence regardless of BEAM internal map ordering.

  ## Key order (lexicographic)

      action_id, correlation_id, evidence_hash, expires_at, issued_at,
      node_id, nonce, operator, parameter_hash, schema_version, task_id
  """

  @schema_version "1"

  @enforce_keys [
    :schema_version,
    :nonce,
    :task_id,
    :correlation_id,
    :node_id,
    :action_id,
    :parameter_hash,
    :evidence_hash,
    :issued_at,
    :expires_at,
    :operator
  ]

  defstruct @enforce_keys

  @doc "Returns the current schema version string."
  @spec schema_version() :: String.t()
  def schema_version, do: @schema_version

  @doc """
  Validates that the token's `schema_version` matches the expected version.

  Returns `{:ok, token}` if the version matches, or
  `{:error, :unknown_schema_version}` otherwise.
  """
  @spec validate_schema_version(%__MODULE__{}) ::
          {:ok, %__MODULE__{}} | {:error, :unknown_schema_version}
  def validate_schema_version(%__MODULE__{schema_version: @schema_version} = token),
    do: {:ok, token}

  def validate_schema_version(%__MODULE__{}), do: {:error, :unknown_schema_version}

  @doc """
  Produces a deterministic binary encoding of the token suitable for use as
  signing input with `:crypto.sign/5`.

  The encoding is a UTF-8 JSON object with all 11 fields present and keys in
  lexicographic order. The key order is fixed at compile time to guarantee
  identical output across BEAM restarts and language boundaries.
  """
  @spec canonical_encode(%__MODULE__{}) :: binary()
  def canonical_encode(%__MODULE__{} = token) do
    # Keys in strict lexicographic order — do not reorder.
    ordered_pairs = [
      {"action_id", token.action_id},
      {"correlation_id", token.correlation_id},
      {"evidence_hash", token.evidence_hash},
      {"expires_at", token.expires_at},
      {"issued_at", token.issued_at},
      {"node_id", token.node_id},
      {"nonce", token.nonce},
      {"operator", token.operator},
      {"parameter_hash", token.parameter_hash},
      {"schema_version", token.schema_version},
      {"task_id", token.task_id}
    ]

    encode_object(ordered_pairs)
  end

  @doc """
  Returns the lowercase hex-encoded SHA-256 digest of the given binary input.
  """
  @spec sha256_hex(binary()) :: String.t()
  def sha256_hex(data) when is_binary(data) do
    :crypto.hash(:sha256, data)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Encodes a `%{String.t() => term()}` map deterministically (sorted-key JSON)
  and returns the SHA-256 hex digest of the result.

  Map insertion order is irrelevant — output is always identical for the same
  logical content.
  """
  @spec hash_params(%{String.t() => term()}) :: String.t()
  def hash_params(params) when is_map(params) do
    params
    |> sorted_json_binary()
    |> sha256_hex()
  end

  @doc """
  Encodes an evidence map deterministically (sorted-key JSON) and returns the
  SHA-256 hex digest of the result.

  Identical to `hash_params/1` — both exist as named entry-points to clarify
  intent at call sites.
  """
  @spec hash_evidence(%{String.t() => term()}) :: String.t()
  def hash_evidence(evidence) when is_map(evidence) do
    evidence
    |> sorted_json_binary()
    |> sha256_hex()
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Produces a deterministic JSON binary from a map by sorting string keys
  # lexicographically. Nested maps are sorted recursively.
  defp sorted_json_binary(map) when is_map(map) do
    pairs =
      map
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> {k, v} end)

    encode_object(pairs)
  end

  # Encodes a pre-ordered list of {key, value} pairs as a JSON object.
  # Each key and scalar value is encoded with Jason; nested maps are sorted
  # recursively so the output is always deterministic.
  defp encode_object(pairs) do
    inner =
      pairs
      |> Enum.map(fn {k, v} ->
        Jason.encode!(k) <> ":" <> encode_value(v)
      end)
      |> Enum.join(",")

    "{" <> inner <> "}"
  end

  # Scalar values (strings, numbers, booleans, nil, lists) delegate to Jason.
  # Maps are recursively sorted before encoding to maintain determinism.
  defp encode_value(v) when is_map(v) do
    v
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.map(fn {k, inner_v} -> {k, inner_v} end)
    |> encode_object()
  end

  defp encode_value(v), do: Jason.encode!(v)
end

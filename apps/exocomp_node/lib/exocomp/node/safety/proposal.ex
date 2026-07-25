defmodule Exocomp.Node.Safety.Proposal do
  @moduledoc """
  A structured action proposal produced by the LLM inference client.

  ## Trust boundary

  Proposals come from an LLM and are **untrusted input**. Every field is
  strictly validated before the proposal is passed to the policy engine:

  - Unknown schema versions are rejected (no lenient fallback).
  - Unknown or extra fields are rejected (no silent ignore).
  - `action_id` must be a non-empty, printable ASCII string. The policy engine
    will reject any `action_id` that is not in the installed action catalog.
  - `parameters` is a flat `string→string` map. Nested structures are rejected.
  - `rationale` is informational only. It is never treated as evidence, never
    parsed as a command, and must not influence policy decisions.

  ## Schema versioning

  | Version | Description                                |
  |---------|--------------------------------------------|
  | `"1"`   | Initial proposal schema (current)          |

  Unknown versions return `{:error, {:unknown_schema_version, version}}` so
  that a version downgrade cannot bypass stricter validation added later.
  """

  @schema_version "1"

  @type t :: %__MODULE__{
          schema_version: String.t(),
          action_id: String.t(),
          target_id: String.t(),
          parameters: %{String.t() => String.t()},
          evidence_refs: [String.t()],
          rationale: String.t()
        }

  @enforce_keys [
    :schema_version,
    :action_id,
    :target_id,
    :parameters,
    :evidence_refs,
    :rationale
  ]
  defstruct [
    :schema_version,
    :action_id,
    :target_id,
    :parameters,
    :evidence_refs,
    :rationale
  ]

  @doc "Returns the current proposal schema version string."
  @spec schema_version() :: String.t()
  def schema_version, do: @schema_version

  @known_fields ~w[schema_version action_id target_id parameters evidence_refs rationale]

  # Printable ASCII only, no control characters or shell metacharacters.
  @action_id_re ~r/\A[A-Za-z0-9._\-]{1,128}\z/

  @doc """
  Parses a `Proposal` from a map with string keys (typically from decoded JSON).

  ## Validation

  - Rejects unknown schema versions.
  - Rejects unknown or extra map keys.
  - Rejects missing required fields.
  - Validates `action_id` against a strict character allowlist.
  - Validates `parameters` as a flat `string→string` map.
  - Validates `evidence_refs` as a list of non-empty strings.

  Returns `{:ok, %Proposal{}}` or `{:error, reason}`.
  """
  @spec parse(map()) :: {:ok, t()} | {:error, term()}
  def parse(attrs) when is_map(attrs) do
    with :ok <- check_no_unknown_fields(attrs),
         {:ok, vsn} <- fetch_schema_version(attrs),
         {:ok, action_id} <- parse_action_id(Map.get(attrs, "action_id")),
         {:ok, target_id} <- fetch_nonempty(attrs, "target_id"),
         {:ok, parameters} <- parse_parameters(Map.get(attrs, "parameters")),
         {:ok, evidence_refs} <- parse_evidence_refs(Map.get(attrs, "evidence_refs")),
         {:ok, rationale} <- parse_rationale(Map.get(attrs, "rationale")) do
      {:ok,
       %__MODULE__{
         schema_version: vsn,
         action_id: action_id,
         target_id: target_id,
         parameters: parameters,
         evidence_refs: evidence_refs,
         rationale: rationale
       }}
    end
  end

  def parse(_), do: {:error, :invalid_proposal_input}

  # ── private helpers ──────────────────────────────────────────────────────

  defp check_no_unknown_fields(attrs) do
    unknown = Map.keys(attrs) -- @known_fields

    if unknown == [] do
      :ok
    else
      {:error, {:unknown_fields, unknown}}
    end
  end

  defp fetch_schema_version(attrs) do
    case Map.get(attrs, "schema_version") do
      @schema_version -> {:ok, @schema_version}
      nil -> {:error, :missing_schema_version}
      other -> {:error, {:unknown_schema_version, other}}
    end
  end

  defp fetch_nonempty(attrs, key) do
    case Map.get(attrs, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      nil -> {:error, {:missing_field, key}}
      "" -> {:error, {:empty_field, key}}
      other -> {:error, {:invalid_field, key, other}}
    end
  end

  defp parse_action_id(nil), do: {:error, {:missing_field, "action_id"}}

  defp parse_action_id(value) when is_binary(value) do
    if Regex.match?(@action_id_re, value) do
      {:ok, value}
    else
      {:error,
       {:invalid_action_id, "must be 1–128 printable ASCII characters (letters, digits, . _ -)"}}
    end
  end

  defp parse_action_id(value), do: {:error, {:invalid_field, "action_id", value}}

  defp parse_parameters(nil), do: {:error, {:missing_field, "parameters"}}

  defp parse_parameters(params) when is_map(params) do
    if all_string_pairs?(params) do
      {:ok, params}
    else
      {:error, {:invalid_parameters, :values_must_be_flat_string_map}}
    end
  end

  defp parse_parameters(_), do: {:error, {:invalid_field, "parameters", :not_a_map}}

  defp all_string_pairs?(map) do
    Enum.all?(map, fn {k, v} -> is_binary(k) and is_binary(v) end)
  end

  defp parse_evidence_refs(nil), do: {:error, {:missing_field, "evidence_refs"}}

  defp parse_evidence_refs(refs) when is_list(refs) do
    if Enum.all?(refs, &(is_binary(&1) and byte_size(&1) > 0)) do
      {:ok, refs}
    else
      {:error, {:invalid_evidence_refs, :must_be_list_of_nonempty_strings}}
    end
  end

  defp parse_evidence_refs(_), do: {:error, {:invalid_field, "evidence_refs", :not_a_list}}

  defp parse_rationale(nil), do: {:error, {:missing_field, "rationale"}}

  defp parse_rationale(value) when is_binary(value), do: {:ok, value}

  defp parse_rationale(value), do: {:error, {:invalid_field, "rationale", value}}
end

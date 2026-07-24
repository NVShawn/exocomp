defmodule Exocomp.Node.Safety.Evidence do
  @moduledoc """
  Deterministic evidence collected before a safety action is evaluated.

  Evidence is produced by trusted, versioned collector code, not by the LLM.
  The policy engine validates evidence before permitting any state-changing
  operation.

  ## Schema versioning

  The `schema_version` field must match the current version. Unknown versions
  are rejected so that a downgrade cannot bypass newer validation rules.

  ## Required fields

  | Field              | Description                                              |
  |--------------------|----------------------------------------------------------|
  | `schema_version`   | Must equal `"1"`. Unknown versions are rejected.         |
  | `evidence_id`      | Globally unique identifier for this evidence record.     |
  | `collector`        | Collector module name (e.g. `"systemd.service.status"`). |
  | `collector_version`| Semver string of the collector implementation.           |
  | `target_id`        | Identity of the resource observed (e.g. unit name).     |
  | `observed_at`      | ISO 8601 UTC timestamp of the observation.               |
  | `values`           | Map of string→string measurement values.                 |
  | `integrity_hash`   | SHA-256 hex digest over the canonical serialisation.     |

  ## Security notes

  - Validators must check `observed_at` against configured maximum evidence age.
  - Validators must verify `target_id` matches the proposal target.
  - `integrity_hash` must be recomputed and compared before evidence is used
    for approval binding; stale or tampered evidence must be rejected.
  """

  @schema_version "1"

  @type t :: %__MODULE__{
          schema_version: String.t(),
          evidence_id: String.t(),
          collector: String.t(),
          collector_version: String.t(),
          target_id: String.t(),
          observed_at: DateTime.t(),
          values: %{String.t() => String.t()},
          integrity_hash: String.t()
        }

  @enforce_keys [
    :schema_version,
    :evidence_id,
    :collector,
    :collector_version,
    :target_id,
    :observed_at,
    :values,
    :integrity_hash
  ]
  defstruct [
    :schema_version,
    :evidence_id,
    :collector,
    :collector_version,
    :target_id,
    :observed_at,
    :values,
    :integrity_hash
  ]

  @doc "Returns the current evidence schema version string."
  @spec schema_version() :: String.t()
  def schema_version, do: @schema_version

  @known_fields ~w[schema_version evidence_id collector collector_version
                   target_id observed_at values integrity_hash]

  @doc """
  Parses an `Evidence` struct from a map with string keys.

  ## Validation

  - Rejects unknown schema versions (must equal `"1"`).
  - Rejects unknown or extra fields.
  - Rejects missing required fields.
  - Parses `observed_at` as an ISO 8601 UTC datetime.
  - Validates `values` is a flat `string→string` map.
  - Validates `integrity_hash` is a 64-character hex string (SHA-256).

  Returns `{:ok, %Evidence{}}` or `{:error, reason}`.
  """
  @spec parse(map()) :: {:ok, t()} | {:error, term()}
  def parse(attrs) when is_map(attrs) do
    with :ok <- check_no_unknown_fields(attrs),
         {:ok, vsn} <- fetch_schema_version(attrs),
         {:ok, evidence_id} <- fetch_nonempty(attrs, "evidence_id"),
         {:ok, collector} <- fetch_nonempty(attrs, "collector"),
         {:ok, collector_version} <- fetch_nonempty(attrs, "collector_version"),
         {:ok, target_id} <- fetch_nonempty(attrs, "target_id"),
         {:ok, observed_at} <- parse_datetime(Map.get(attrs, "observed_at")),
         {:ok, values} <- parse_values(Map.get(attrs, "values")),
         {:ok, integrity_hash} <- parse_integrity_hash(Map.get(attrs, "integrity_hash")) do
      {:ok,
       %__MODULE__{
         schema_version: vsn,
         evidence_id: evidence_id,
         collector: collector,
         collector_version: collector_version,
         target_id: target_id,
         observed_at: observed_at,
         values: values,
         integrity_hash: integrity_hash
       }}
    end
  end

  def parse(_), do: {:error, :invalid_evidence_input}

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

  defp parse_datetime(nil), do: {:error, {:missing_field, "observed_at"}}

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> {:ok, dt}
      {:error, reason} -> {:error, {:invalid_datetime, "observed_at", reason}}
    end
  end

  defp parse_datetime(value), do: {:error, {:invalid_datetime, "observed_at", value}}

  defp parse_values(nil), do: {:error, {:missing_field, "values"}}

  defp parse_values(values) when is_map(values) do
    if all_string_values?(values) do
      {:ok, values}
    else
      {:error, {:invalid_values, :non_string_value}}
    end
  end

  defp parse_values(_), do: {:error, {:invalid_field, "values", :not_a_map}}

  defp all_string_values?(map) do
    Enum.all?(map, fn {k, v} -> is_binary(k) and is_binary(v) end)
  end

  # SHA-256 hex digest is exactly 64 lowercase hex characters.
  @hex_re ~r/\A[0-9a-f]{64}\z/

  defp parse_integrity_hash(nil), do: {:error, {:missing_field, "integrity_hash"}}

  defp parse_integrity_hash(value) when is_binary(value) do
    if Regex.match?(@hex_re, value) do
      {:ok, value}
    else
      {:error, {:invalid_integrity_hash, :must_be_64_hex_chars}}
    end
  end

  defp parse_integrity_hash(value), do: {:error, {:invalid_integrity_hash, value}}
end

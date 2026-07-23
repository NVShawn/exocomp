defmodule Exocomp.Node.Safety.ValidatorResult do
  @moduledoc """
  The outcome of running the policy engine against a proposal and its evidence.

  ## Possible decisions

  | Decision            | Meaning                                                 |
  |---------------------|---------------------------------------------------------|
  | `:deny`             | The action may not proceed. This is the fail-closed default. |
  | `:allow`            | The action is authorized and may be executed immediately. |
  | `:approval_required`| The action requires an operator approval token before execution. |

  ## Fail-closed default

  Any validator error, missing evidence, ambiguous state, or unrecognized input
  produces a `:deny` result, never a permissive fallback. Callers must check
  the `decision` field; treating any other value as `:allow` is a bug.

  ## Schema versioning

  | Version | Description                                |
  |---------|--------------------------------------------|
  | `"1"`   | Initial validator result schema (current)  |
  """

  @schema_version "1"

  @type decision :: :deny | :allow | :approval_required

  @type t :: %__MODULE__{
          schema_version: String.t(),
          decision: decision(),
          action_id: String.t() | nil,
          reason: String.t(),
          evidence_refs: [String.t()]
        }

  @enforce_keys [:schema_version, :decision, :reason, :evidence_refs]
  defstruct schema_version: @schema_version,
            decision: :deny,
            action_id: nil,
            reason: "",
            evidence_refs: []

  @doc "Returns the current validator result schema version string."
  @spec schema_version() :: String.t()
  def schema_version, do: @schema_version

  @doc """
  Returns the fail-closed deny result for a given reason string.

  Use this helper anywhere validation fails — it guarantees the decision
  is `:deny` and cannot be accidentally changed to a permissive value.
  """
  @spec deny(String.t()) :: t()
  def deny(reason) when is_binary(reason) do
    %__MODULE__{
      schema_version: @schema_version,
      decision: :deny,
      action_id: nil,
      reason: reason,
      evidence_refs: []
    }
  end

  @doc """
  Returns a `:deny` result with an associated action ID and evidence references.
  """
  @spec deny(String.t(), String.t(), [String.t()]) :: t()
  def deny(action_id, reason, evidence_refs)
      when is_binary(action_id) and is_binary(reason) and is_list(evidence_refs) do
    %__MODULE__{
      schema_version: @schema_version,
      decision: :deny,
      action_id: action_id,
      reason: reason,
      evidence_refs: evidence_refs
    }
  end

  @doc """
  Returns an `:allow` result for the given action with supporting evidence.
  """
  @spec allow(String.t(), String.t(), [String.t()]) :: t()
  def allow(action_id, reason, evidence_refs)
      when is_binary(action_id) and is_binary(reason) and is_list(evidence_refs) do
    %__MODULE__{
      schema_version: @schema_version,
      decision: :allow,
      action_id: action_id,
      reason: reason,
      evidence_refs: evidence_refs
    }
  end

  @doc """
  Returns an `:approval_required` result for the given action.
  """
  @spec approval_required(String.t(), String.t(), [String.t()]) :: t()
  def approval_required(action_id, reason, evidence_refs)
      when is_binary(action_id) and is_binary(reason) and is_list(evidence_refs) do
    %__MODULE__{
      schema_version: @schema_version,
      decision: :approval_required,
      action_id: action_id,
      reason: reason,
      evidence_refs: evidence_refs
    }
  end

  @doc """
  Returns `true` if the result permits immediate execution (decision is `:allow`).
  """
  @spec allow?(t()) :: boolean()
  def allow?(%__MODULE__{decision: :allow}), do: true
  def allow?(%__MODULE__{}), do: false

  @doc """
  Returns `true` if the result denies execution.
  """
  @spec deny?(t()) :: boolean()
  def deny?(%__MODULE__{decision: :deny}), do: true
  def deny?(%__MODULE__{}), do: false

  @doc """
  Returns `true` if the result requires an operator approval token.
  """
  @spec approval_required?(t()) :: boolean()
  def approval_required?(%__MODULE__{decision: :approval_required}), do: true
  def approval_required?(%__MODULE__{}), do: false

  @known_fields ~w[schema_version decision action_id reason evidence_refs]

  @doc """
  Parses a `ValidatorResult` from a map with string keys.

  Unknown versions and unknown fields are rejected. An unrecognized or
  malformed input returns a `:deny` result, never a permissive default.

  This is used when deserializing a result produced by another node or
  a coordinator relay. Internal code should use the constructor functions
  (`allow/3`, `deny/1`, `approval_required/3`) instead.
  """
  @spec parse(map()) :: {:ok, t()} | {:error, term()}
  def parse(attrs) when is_map(attrs) do
    with :ok <- check_no_unknown_fields(attrs),
         {:ok, vsn} <- fetch_schema_version(attrs),
         {:ok, decision} <- parse_decision(Map.get(attrs, "decision")),
         {:ok, reason} <- fetch_string(attrs, "reason"),
         {:ok, evidence_refs} <- parse_evidence_refs(Map.get(attrs, "evidence_refs", [])) do
      {:ok,
       %__MODULE__{
         schema_version: vsn,
         decision: decision,
         action_id: Map.get(attrs, "action_id"),
         reason: reason,
         evidence_refs: evidence_refs
       }}
    end
  end

  def parse(_), do: {:error, :invalid_validator_result_input}

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

  defp fetch_string(attrs, key) do
    case Map.get(attrs, key) do
      value when is_binary(value) -> {:ok, value}
      nil -> {:error, {:missing_field, key}}
      other -> {:error, {:invalid_field, key, other}}
    end
  end

  defp parse_decision("deny"), do: {:ok, :deny}
  defp parse_decision("allow"), do: {:ok, :allow}
  defp parse_decision("approval_required"), do: {:ok, :approval_required}
  defp parse_decision(:deny), do: {:ok, :deny}
  defp parse_decision(:allow), do: {:ok, :allow}
  defp parse_decision(:approval_required), do: {:ok, :approval_required}
  defp parse_decision(nil), do: {:error, {:missing_field, "decision"}}
  defp parse_decision(other), do: {:error, {:unknown_decision, other}}

  defp parse_evidence_refs(refs) when is_list(refs) do
    if Enum.all?(refs, &is_binary/1) do
      {:ok, refs}
    else
      {:error, {:invalid_field, "evidence_refs", :must_be_list_of_strings}}
    end
  end

  defp parse_evidence_refs(_), do: {:error, {:invalid_field, "evidence_refs", :not_a_list}}
end

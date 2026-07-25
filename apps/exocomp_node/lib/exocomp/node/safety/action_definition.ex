defmodule Exocomp.Node.Safety.ActionDefinition do
  @moduledoc """
  Typed action definition in the installed action catalog.

  Each `ActionDefinition` describes one safe, allow-listed action that the
  policy engine may select. Action definitions are **not** supplied by the LLM
  or by external callers — they are compiled into or loaded from trusted
  catalog configuration at node startup.

  ## Security invariants

  1. **Deletion-ineligibility**: an action whose `action_class` is `:deletion`
     may only target `:system_data`. Attempting to construct an
     `ActionDefinition` with `action_class: :deletion` and
     `data_classification: :protected_user_data` returns
     `{:error, :user_data_deletion_ineligible}`. This invariant is enforced
     at construction time so it cannot be bypassed at runtime.

  2. **No generic command**: the action catalog has no action class that accepts
     an arbitrary shell command, arbitrary file path, or arbitrary environment
     variable as a parameter. Callers that attempt to register such an action
     receive `{:error, :generic_command_action_forbidden}`.

  3. **Schema versioning**: all action definitions carry the current schema
     version. Unknown versions returned from configuration are rejected.

  ## Catalog fields

  | Field                   | Description                                          |
  |-------------------------|------------------------------------------------------|
  | `schema_version`        | Must equal `"1"`.                                    |
  | `action_id`             | Stable, unique identifier (e.g. `"systemd.service.restart"`). |
  | `action_class`          | `:maintenance` or `:restart` (never `:deletion` for user data). |
  | `target_type`           | Atom describing the resource type (e.g. `:systemd_unit`). |
  | `data_classification`   | `DataClassification.t()` — unknown defaults to `:protected_user_data`. |
  | `reversibility`         | `Reversibility.t()`.                                 |
  | `risk_rank`             | `RiskRank.t()` for policy ordering.                  |
  | `required_evidence`     | List of required evidence collector identifiers.     |
  | `max_evidence_age_secs` | Maximum acceptable age of evidence in seconds.       |
  | `requires_approval`     | Whether operator approval is required.               |
  | `cooldown_secs`         | Minimum interval between successive executions.      |
  | `max_retries`           | Maximum consecutive retry attempts.                  |
  | `timeout_secs`          | Execution timeout in seconds.                        |
  """

  alias Exocomp.Node.Safety.{DataClassification, Reversibility, RiskRank}

  @schema_version "1"

  @type action_class :: :maintenance | :deletion | :restart

  @type t :: %__MODULE__{
          schema_version: String.t(),
          action_id: String.t(),
          action_class: action_class(),
          target_type: atom(),
          data_classification: DataClassification.t(),
          reversibility: Reversibility.t(),
          risk_rank: RiskRank.t(),
          required_evidence: [String.t()],
          max_evidence_age_secs: pos_integer(),
          requires_approval: boolean(),
          cooldown_secs: non_neg_integer(),
          max_retries: non_neg_integer(),
          timeout_secs: pos_integer()
        }

  @enforce_keys [
    :schema_version,
    :action_id,
    :action_class,
    :target_type,
    :data_classification,
    :reversibility,
    :risk_rank,
    :required_evidence,
    :max_evidence_age_secs,
    :requires_approval,
    :cooldown_secs,
    :max_retries,
    :timeout_secs
  ]
  defstruct [
    :schema_version,
    :action_id,
    :action_class,
    :target_type,
    :data_classification,
    :reversibility,
    :risk_rank,
    :required_evidence,
    :max_evidence_age_secs,
    :requires_approval,
    :cooldown_secs,
    :max_retries,
    :timeout_secs
  ]

  @doc "Returns the current action definition schema version string."
  @spec schema_version() :: String.t()
  def schema_version, do: @schema_version

  # Forbidden action classes that must never appear in a public action_id.
  # Validated in build/2 to prevent catalog entries that look like shell
  # commands or wildcard deletions.
  @forbidden_action_id_patterns [
    ~r/shell/i,
    ~r/exec/i,
    ~r/cmd/i,
    ~r/delete.*user/i,
    ~r/rm\b/i,
    ~r/\*/
  ]

  @known_action_classes ~w[maintenance deletion restart]a

  @doc """
  Builds a validated `ActionDefinition` from keyword options.

  Returns `{:ok, %ActionDefinition{}}` or `{:error, reason}`.

  ## Security checks

  - `action_class: :deletion` with `data_classification: :protected_user_data`
    → `{:error, :user_data_deletion_ineligible}`
  - `action_id` matching shell/command/wildcard patterns
    → `{:error, :generic_command_action_forbidden}`
  - Unknown `action_class` values are rejected.
  - `max_evidence_age_secs`, `cooldown_secs`, `max_retries`, and `timeout_secs`
    must be non-negative integers; `max_evidence_age_secs` and `timeout_secs`
    must be positive.
  """
  @spec build(keyword()) :: {:ok, t()} | {:error, term()}
  def build(opts) when is_list(opts) do
    with {:ok, vsn} <- validate_schema_version(Keyword.get(opts, :schema_version)),
         {:ok, action_id} <- validate_action_id(Keyword.get(opts, :action_id)),
         {:ok, action_class} <- validate_action_class(Keyword.get(opts, :action_class)),
         {:ok, target_type} <- validate_target_type(Keyword.get(opts, :target_type)),
         {:ok, data_class} <-
           validate_data_classification(Keyword.get(opts, :data_classification)),
         {:ok, reversibility} <- validate_reversibility(Keyword.get(opts, :reversibility)),
         {:ok, risk_rank} <- validate_risk_rank(Keyword.get(opts, :risk_rank)),
         {:ok, required_evidence} <-
           validate_required_evidence(Keyword.get(opts, :required_evidence, [])),
         {:ok, max_evidence_age_secs} <-
           validate_pos_integer(Keyword.get(opts, :max_evidence_age_secs), :max_evidence_age_secs),
         {:ok, requires_approval} <-
           validate_boolean(Keyword.get(opts, :requires_approval), :requires_approval),
         {:ok, cooldown_secs} <-
           validate_nonneg_integer(Keyword.get(opts, :cooldown_secs, 0), :cooldown_secs),
         {:ok, max_retries} <-
           validate_nonneg_integer(Keyword.get(opts, :max_retries, 0), :max_retries),
         {:ok, timeout_secs} <-
           validate_pos_integer(Keyword.get(opts, :timeout_secs), :timeout_secs),
         :ok <- check_deletion_eligibility(action_class, data_class) do
      {:ok,
       %__MODULE__{
         schema_version: vsn,
         action_id: action_id,
         action_class: action_class,
         target_type: target_type,
         data_classification: data_class,
         reversibility: reversibility,
         risk_rank: risk_rank,
         required_evidence: required_evidence,
         max_evidence_age_secs: max_evidence_age_secs,
         requires_approval: requires_approval,
         cooldown_secs: cooldown_secs,
         max_retries: max_retries,
         timeout_secs: timeout_secs
       }}
    end
  end

  # ── private validators ───────────────────────────────────────────────────

  defp validate_schema_version(@schema_version), do: {:ok, @schema_version}
  defp validate_schema_version(nil), do: {:error, :missing_schema_version}
  defp validate_schema_version(other), do: {:error, {:unknown_schema_version, other}}

  defp validate_action_id(nil), do: {:error, {:missing_field, :action_id}}

  defp validate_action_id(id) when is_binary(id) and byte_size(id) > 0 do
    if Enum.any?(@forbidden_action_id_patterns, &Regex.match?(&1, id)) do
      {:error, :generic_command_action_forbidden}
    else
      {:ok, id}
    end
  end

  defp validate_action_id(_), do: {:error, {:invalid_field, :action_id}}

  defp validate_action_class(nil), do: {:error, {:missing_field, :action_class}}

  defp validate_action_class(class) when class in @known_action_classes, do: {:ok, class}

  defp validate_action_class(other), do: {:error, {:unknown_action_class, other}}

  defp validate_target_type(nil), do: {:error, {:missing_field, :target_type}}

  defp validate_target_type(type) when is_atom(type), do: {:ok, type}

  defp validate_target_type(other), do: {:error, {:invalid_field, :target_type, other}}

  defp validate_data_classification(nil) do
    # Absent classification defaults to :protected_user_data (fail-closed).
    {:ok, :protected_user_data}
  end

  defp validate_data_classification(value) do
    # DataClassification.classify/1 also fails closed for unknown values.
    {:ok, DataClassification.classify(value)}
  end

  defp validate_reversibility(nil), do: {:error, {:missing_field, :reversibility}}

  defp validate_reversibility(value), do: Reversibility.parse(value)

  defp validate_risk_rank(nil), do: {:error, {:missing_field, :risk_rank}}

  defp validate_risk_rank(%RiskRank{} = rr), do: {:ok, rr}

  defp validate_risk_rank(map) when is_map(map), do: RiskRank.parse(map)

  defp validate_risk_rank(_), do: {:error, {:invalid_field, :risk_rank}}

  defp validate_required_evidence(list) when is_list(list) do
    if Enum.all?(list, &(is_binary(&1) and byte_size(&1) > 0)) do
      {:ok, list}
    else
      {:error, {:invalid_field, :required_evidence, :must_be_list_of_nonempty_strings}}
    end
  end

  defp validate_required_evidence(_), do: {:error, {:invalid_field, :required_evidence}}

  defp validate_pos_integer(value, _field) when is_integer(value) and value > 0, do: {:ok, value}
  defp validate_pos_integer(nil, field), do: {:error, {:missing_field, field}}
  defp validate_pos_integer(value, field), do: {:error, {:invalid_field, field, value}}

  defp validate_nonneg_integer(value, _field) when is_integer(value) and value >= 0,
    do: {:ok, value}

  defp validate_nonneg_integer(nil, field), do: {:error, {:missing_field, field}}
  defp validate_nonneg_integer(value, field), do: {:error, {:invalid_field, field, value}}

  defp validate_boolean(value, _field) when is_boolean(value), do: {:ok, value}
  defp validate_boolean(nil, field), do: {:error, {:missing_field, field}}
  defp validate_boolean(value, field), do: {:error, {:invalid_field, field, value}}

  # The core deletion-ineligibility invariant.
  # This is checked after all other fields are validated to produce a clear error.
  defp check_deletion_eligibility(:deletion, :protected_user_data) do
    {:error, :user_data_deletion_ineligible}
  end

  defp check_deletion_eligibility(_class, _data_class), do: :ok
end

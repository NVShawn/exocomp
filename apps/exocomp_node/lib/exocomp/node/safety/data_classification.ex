defmodule Exocomp.Node.Safety.DataClassification do
  @moduledoc """
  Data classification for resources targeted by safety actions.

  ## Security invariant

  Any unrecognized or missing classification is **always** resolved to
  `:protected_user_data`. This ensures that unknown data can never become
  eligible for a deletion-class action. Classification defaults are fail-closed.

  ## Values

  - `:protected_user_data` – data that belongs to or was created by the user.
    Deletion of this classification is permanently ineligible, including when
    a valid approval token is present.

  - `:system_data` – data generated and owned by the system (logs, caches,
    temporary artifacts). May be eligible for bounded, allow-listed cleanup
    actions under deterministic disk-pressure evidence.
  """

  @type t :: :protected_user_data | :system_data

  @doc """
  Classifies a raw value from an external or internal source.

  Unknown, nil, or otherwise unrecognized values resolve to
  `:protected_user_data` per the fail-closed security invariant.

  ## Examples

      iex> Exocomp.Node.Safety.DataClassification.classify("system_data")
      :system_data

      iex> Exocomp.Node.Safety.DataClassification.classify("unknown_type")
      :protected_user_data

      iex> Exocomp.Node.Safety.DataClassification.classify(nil)
      :protected_user_data
  """
  @spec classify(term()) :: t()
  def classify("protected_user_data"), do: :protected_user_data
  def classify("system_data"), do: :system_data
  def classify(:protected_user_data), do: :protected_user_data
  def classify(:system_data), do: :system_data
  # All other values — including nil, unknown strings, unknown atoms — resolve
  # to :protected_user_data. Do not add a generic atom fallback here.
  def classify(_unknown), do: :protected_user_data

  @doc """
  Returns true only if the classification permits a deletion-class action.

  `:protected_user_data` is never deletion-eligible. This predicate is the
  single gate used by `ActionDefinition` to enforce the type-level invariant.
  """
  @spec deletion_eligible?(t()) :: boolean()
  def deletion_eligible?(:system_data), do: true
  def deletion_eligible?(_classification), do: false
end

defmodule Exocomp.Node.Safety.PolicyContext do
  @moduledoc """
  Runtime context supplied to the policy engine's eligibility filter.

  `PolicyContext` carries all node-operator state that the filter pipeline
  needs to evaluate a set of action candidates without side effects. Fields
  are injected at the call site, making behaviour deterministic and testable.

  ## Fields

  | Field                  | Description                                                              |
  |------------------------|--------------------------------------------------------------------------|
  | `authorized_action_ids`| `MapSet` of action IDs explicitly permitted by the node operator.        |
  | `cooldown_state`       | Map of `{action_id, target_id}` → last `DateTime` of execution.         |
  | `retry_counts`         | Map of `{action_id, target_id}` → consecutive failure count.            |
  | `now`                  | Wall-clock `DateTime` used for staleness/cooldown checks (injectable).   |

  ## Fail-closed invariants

  - A `nil` or otherwise invalid `authorized_action_ids`, `cooldown_state`,
    `retry_counts`, or `now` causes every candidate to be denied rather than
    producing a permissive fallback.
  - `authorized_action_ids` must be a `MapSet`; any other value causes
    authorization checks to deny all actions.
  """

  @type t :: %__MODULE__{
          authorized_action_ids: MapSet.t(String.t()),
          cooldown_state: %{{String.t(), String.t()} => DateTime.t()},
          retry_counts: %{{String.t(), String.t()} => non_neg_integer()},
          now: DateTime.t()
        }

  @enforce_keys [:authorized_action_ids, :cooldown_state, :retry_counts, :now]
  defstruct [:authorized_action_ids, :cooldown_state, :retry_counts, :now]

  @doc """
  Builds a valid `PolicyContext` from explicit keyword arguments.

  All fields are required. Returns `{:ok, %PolicyContext{}}` or
  `{:error, reason}`.
  """
  @spec build(keyword()) :: {:ok, t()} | {:error, term()}
  def build(opts) when is_list(opts) do
    with {:ok, ids} <- validate_authorized_action_ids(Keyword.get(opts, :authorized_action_ids)),
         {:ok, cooldown} <- validate_map(Keyword.get(opts, :cooldown_state), :cooldown_state),
         {:ok, retries} <- validate_map(Keyword.get(opts, :retry_counts), :retry_counts),
         {:ok, now} <- validate_datetime(Keyword.get(opts, :now)) do
      {:ok,
       %__MODULE__{
         authorized_action_ids: ids,
         cooldown_state: cooldown,
         retry_counts: retries,
         now: now
       }}
    end
  end

  # ── private validators ───────────────────────────────────────────────────

  defp validate_authorized_action_ids(%MapSet{} = ids), do: {:ok, ids}
  defp validate_authorized_action_ids(nil), do: {:error, {:missing_field, :authorized_action_ids}}

  defp validate_authorized_action_ids(other),
    do: {:error, {:invalid_field, :authorized_action_ids, other}}

  defp validate_map(map, _field) when is_map(map), do: {:ok, map}
  defp validate_map(nil, field), do: {:error, {:missing_field, field}}
  defp validate_map(other, field), do: {:error, {:invalid_field, field, other}}

  defp validate_datetime(%DateTime{} = dt), do: {:ok, dt}
  defp validate_datetime(nil), do: {:error, {:missing_field, :now}}
  defp validate_datetime(other), do: {:error, {:invalid_field, :now, other}}
end

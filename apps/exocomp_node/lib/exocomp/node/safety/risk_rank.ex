defmodule Exocomp.Node.Safety.RiskRank do
  @moduledoc """
  Risk rank for action definitions, used by the policy engine for selection ordering.

  The policy engine selects among eligible actions lexicographically by:

  1. `data_loss`  – risk of irreversible loss of data
  2. `work_loss`  – risk of losing in-progress work
  3. `disruption` – service/user-facing impact
  4. `scope`      – breadth of affected resources

  Lower levels are preferred. The policy never escalates to a higher-impact
  action while a lower-impact eligible candidate remains.

  ## Schema versioning

  Risk rank structures parsed from external input must carry the current schema
  version. Unknown versions are rejected.
  """

  @schema_version "1"

  @type level :: :none | :minimal | :moderate | :high | :critical

  @type t :: %__MODULE__{
          data_loss: level(),
          work_loss: level(),
          disruption: level(),
          scope: level()
        }

  defstruct data_loss: :none,
            work_loss: :none,
            disruption: :none,
            scope: :none

  # Numeric ordinal for comparison — never expose this map externally.
  @level_ordinal %{none: 0, minimal: 1, moderate: 2, high: 3, critical: 4}

  @doc "Returns the current risk rank schema version string."
  @spec schema_version() :: String.t()
  def schema_version, do: @schema_version

  @doc """
  Parses a `RiskRank` from a map with string keys and string level values.

  Rejects unknown level values with `{:error, {:unknown_risk_level, field, value}}`.
  All four fields are optional; missing fields default to `:none`.

  ## Examples

      iex> Exocomp.Node.Safety.RiskRank.parse(%{"data_loss" => "minimal"})
      {:ok, %Exocomp.Node.Safety.RiskRank{data_loss: :minimal, work_loss: :none,
                                           disruption: :none, scope: :none}}

      iex> Exocomp.Node.Safety.RiskRank.parse(%{"data_loss" => "galaxy_brain"})
      {:error, {:unknown_risk_level, :data_loss, "galaxy_brain"}}
  """
  @spec parse(map()) :: {:ok, t()} | {:error, term()}
  def parse(attrs) when is_map(attrs) do
    with {:ok, data_loss} <- parse_level(Map.get(attrs, "data_loss", "none"), :data_loss),
         {:ok, work_loss} <- parse_level(Map.get(attrs, "work_loss", "none"), :work_loss),
         {:ok, disruption} <- parse_level(Map.get(attrs, "disruption", "none"), :disruption),
         {:ok, scope} <- parse_level(Map.get(attrs, "scope", "none"), :scope) do
      {:ok,
       %__MODULE__{
         data_loss: data_loss,
         work_loss: work_loss,
         disruption: disruption,
         scope: scope
       }}
    end
  end

  @doc """
  Compares two risk ranks for policy-selection ordering.

  Returns `:lt` if `a` is strictly preferred over `b` (lower impact),
  `:gt` if `b` is preferred over `a`, or `:eq` if they are equal.
  """
  @spec compare(t(), t()) :: :lt | :eq | :gt
  def compare(%__MODULE__{} = a, %__MODULE__{} = b) do
    compare_fields([
      {a.data_loss, b.data_loss},
      {a.work_loss, b.work_loss},
      {a.disruption, b.disruption},
      {a.scope, b.scope}
    ])
  end

  @doc """
  Returns `true` if `a` is strictly preferred over `b` (lower aggregate impact).
  """
  @spec less_than?(t(), t()) :: boolean()
  def less_than?(%__MODULE__{} = a, %__MODULE__{} = b), do: compare(a, b) == :lt

  # ── private helpers ──────────────────────────────────────────────────────

  defp compare_fields([]), do: :eq

  defp compare_fields([{level_a, level_b} | rest]) do
    ord_a = Map.fetch!(@level_ordinal, level_a)
    ord_b = Map.fetch!(@level_ordinal, level_b)

    cond do
      ord_a < ord_b -> :lt
      ord_a > ord_b -> :gt
      true -> compare_fields(rest)
    end
  end

  # Use explicit pattern matching — never use String.to_atom/1 on external input.
  defp parse_level("none", _field), do: {:ok, :none}
  defp parse_level("minimal", _field), do: {:ok, :minimal}
  defp parse_level("moderate", _field), do: {:ok, :moderate}
  defp parse_level("high", _field), do: {:ok, :high}
  defp parse_level("critical", _field), do: {:ok, :critical}
  defp parse_level(:none, _field), do: {:ok, :none}
  defp parse_level(:minimal, _field), do: {:ok, :minimal}
  defp parse_level(:moderate, _field), do: {:ok, :moderate}
  defp parse_level(:high, _field), do: {:ok, :high}
  defp parse_level(:critical, _field), do: {:ok, :critical}
  defp parse_level(value, field), do: {:error, {:unknown_risk_level, field, value}}
end

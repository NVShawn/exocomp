defmodule Exocomp.Node.Safety.Reversibility do
  @moduledoc """
  Reversibility classification for action definitions.

  An action is either `:reversible` (can be undone with a known rollback
  procedure) or `:irreversible` (cannot be undone once executed). The policy
  engine uses reversibility as a tie-breaker and audit annotation.

  Unknown or missing values are rejected — this field is security-relevant
  and must be explicit in every action definition.
  """

  @type t :: :reversible | :irreversible

  @doc """
  Parses a reversibility value from an external string or atom.

  Returns `{:error, {:unknown_reversibility, value}}` for any unrecognized
  input. There is no default — callers must supply an explicit value.

  ## Examples

      iex> Exocomp.Node.Safety.Reversibility.parse("reversible")
      {:ok, :reversible}

      iex> Exocomp.Node.Safety.Reversibility.parse("unknown")
      {:error, {:unknown_reversibility, "unknown"}}
  """
  @spec parse(term()) :: {:ok, t()} | {:error, {:unknown_reversibility, term()}}
  def parse("reversible"), do: {:ok, :reversible}
  def parse("irreversible"), do: {:ok, :irreversible}
  def parse(:reversible), do: {:ok, :reversible}
  def parse(:irreversible), do: {:ok, :irreversible}
  def parse(value), do: {:error, {:unknown_reversibility, value}}
end

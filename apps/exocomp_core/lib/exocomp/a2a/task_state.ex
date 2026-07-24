defmodule Exocomp.A2A.TaskState do
  @moduledoc """
  Enumeration of valid A2A 1.0 task lifecycle states.

  Corresponds to the `TaskState` string enum in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#taskstate

  The states form a lifecycle: a task starts as `:submitted`, moves to
  `:working` while being processed, may enter `:input_required` if the
  agent needs more information, and ends in one of `:completed`,
  `:canceled`, `:failed`, or `:unknown`.
  """

  @type t ::
          :submitted
          | :working
          | :input_required
          | :completed
          | :canceled
          | :failed
          | :unknown

  @valid_states [:submitted, :working, :input_required, :completed, :canceled, :failed, :unknown]

  @doc "Returns the list of all valid TaskState atom values."
  @spec values() :: [t()]
  def values, do: @valid_states

  @doc "Returns true if the given atom is a valid TaskState."
  @spec valid?(atom()) :: boolean()
  def valid?(state), do: state in @valid_states

  @doc "Returns true if the given state is a terminal (non-resumable) state."
  @spec terminal?(t()) :: boolean()
  def terminal?(:completed), do: true
  def terminal?(:canceled), do: true
  def terminal?(:failed), do: true
  def terminal?(:unknown), do: true
  def terminal?(_), do: false
end

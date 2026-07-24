defmodule Exocomp.Coordinator.Error do
  @moduledoc """
  Structured coordinator error returned at subsystem boundaries.
  """

  @enforce_keys [:code, :message]
  defstruct [:code, :message, details: %{}]

  @type t :: %__MODULE__{
          code: atom(),
          message: String.t(),
          details: map()
        }

  @spec new(atom(), String.t(), map()) :: t()
  def new(code, message, details \\ %{}) do
    %__MODULE__{code: code, message: message, details: details}
  end
end

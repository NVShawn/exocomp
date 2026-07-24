defmodule Exocomp.A2A.TaskStatus do
  @moduledoc """
  The current status of an A2A 1.0 task, including its lifecycle state.

  Corresponds to the `TaskStatus` object in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#taskstatus

  `TaskStatus` is embedded in an `Exocomp.A2A.Task` and updated each time
  the task transitions between lifecycle states (see `Exocomp.A2A.TaskState`).
  An optional `message` from the agent may accompany the status, for example
  to explain why a task failed or what input is required.

  Required fields: `state`.
  Optional fields default to `nil`.
  """

  @enforce_keys [:state]

  defstruct state: nil,
            message: nil,
            timestamp: nil

  @type t :: %__MODULE__{
          state: Exocomp.A2A.TaskState.t(),
          message: Exocomp.A2A.Message.t() | nil,
          timestamp: String.t() | nil
        }
end

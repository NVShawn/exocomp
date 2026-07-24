defmodule Exocomp.A2A.Task do
  @moduledoc """
  An A2A 1.0 task representing a unit of work delegated to an agent.

  Corresponds to the `Task` object in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#task

  A task tracks the full lifecycle of an agent work item from submission
  through completion (or failure). It holds the current `status`, a
  `history` of messages exchanged, and any `artifacts` produced.

  Required fields: `id`, `status`.
  Optional fields default to `nil` or empty list.
  """

  @enforce_keys [:id, :status]

  defstruct id: nil,
            contextId: nil,
            status: nil,
            history: [],
            artifacts: [],
            metadata: nil,
            created_at: nil,
            updated_at: nil

  @type t :: %__MODULE__{
          id: String.t(),
          contextId: String.t() | nil,
          status: Exocomp.A2A.TaskStatus.t(),
          history: [Exocomp.A2A.Message.t()],
          artifacts: [Exocomp.A2A.Artifact.t()],
          metadata: map() | nil,
          created_at: String.t() | nil,
          updated_at: String.t() | nil
        }
end

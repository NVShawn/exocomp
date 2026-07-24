defmodule Exocomp.A2A.Message do
  @moduledoc """
  A single message exchanged between a user and an agent in A2A 1.0.

  Corresponds to the `Message` object in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#message

  A message carries one or more `Part` values (text, data, or file) and
  has a `role` indicating whether it originated from a human user or from
  the agent. All other fields are optional identifiers and timestamps used
  to correlate messages with tasks and conversations.

  Required fields: `role`, `parts`.
  Optional fields default to `nil`.
  """

  @enforce_keys [:role, :parts]

  defstruct role: nil,
            parts: [],
            messageId: nil,
            taskId: nil,
            contextId: nil,
            timestamp: nil

  @type role :: :user | :agent

  @type part ::
          Exocomp.A2A.TextPart.t()
          | Exocomp.A2A.DataPart.t()
          | Exocomp.A2A.FilePart.t()

  @type t :: %__MODULE__{
          role: role(),
          parts: [part()],
          messageId: String.t() | nil,
          taskId: String.t() | nil,
          contextId: String.t() | nil,
          timestamp: String.t() | nil
        }
end

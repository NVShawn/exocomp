defmodule Exocomp.A2A.Artifact do
  @moduledoc """
  A named output artifact produced by an A2A 1.0 task.

  Corresponds to the `Artifact` object in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#artifact

  Artifacts represent discrete units of output (files, data, text) that
  an agent produces during task execution. They may be streamed
  incrementally using `append` and `lastChunk` flags, or delivered as a
  complete unit.

  Required fields: `artifactId`, `parts`.
  Optional fields default to `nil` or `false`.
  """

  @enforce_keys [:artifactId, :parts]

  defstruct artifactId: nil,
            name: nil,
            description: nil,
            parts: [],
            index: nil,
            append: false,
            lastChunk: false,
            metadata: nil

  @type part ::
          Exocomp.A2A.TextPart.t()
          | Exocomp.A2A.DataPart.t()
          | Exocomp.A2A.FilePart.t()

  @type t :: %__MODULE__{
          artifactId: String.t(),
          name: String.t() | nil,
          description: String.t() | nil,
          parts: [part()],
          index: non_neg_integer() | nil,
          append: boolean(),
          lastChunk: boolean(),
          metadata: map() | nil
        }
end

defmodule Exocomp.A2A.TextPart do
  @moduledoc """
  A message part carrying plain text content.

  Corresponds to the `TextPart` variant of the `Part` union type in the
  A2A 1.0 specification:
  https://google.github.io/A2A/specification/#textpart

  The `type` field is always the string `"text"` and is used by the codec
  layer to discriminate between part types during serialisation and
  deserialisation. The `text` field carries the actual content; `metadata`
  is an optional map of arbitrary key/value pairs.
  """

  @enforce_keys [:text]

  defstruct type: "text",
            text: nil,
            metadata: nil

  @type t :: %__MODULE__{
          type: String.t(),
          text: String.t(),
          metadata: map() | nil
        }
end

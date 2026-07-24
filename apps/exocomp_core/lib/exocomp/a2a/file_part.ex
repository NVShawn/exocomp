defmodule Exocomp.A2A.FilePart do
  @moduledoc """
  A message part carrying a file (by reference or by value).

  Corresponds to the `FilePart` variant of the `Part` union type in the
  A2A 1.0 specification:
  https://google.github.io/A2A/specification/#filepart

  The `type` field is always the string `"file"` and is used by the codec
  layer to discriminate between part types during serialisation and
  deserialisation. The `file` field holds an `Exocomp.A2A.FileContent`
  struct describing the file payload; `metadata` is an optional map.
  """

  @enforce_keys [:file]

  defstruct type: "file",
            file: nil,
            metadata: nil

  @type t :: %__MODULE__{
          type: String.t(),
          file: Exocomp.A2A.FileContent.t(),
          metadata: map() | nil
        }
end

defmodule Exocomp.A2A.DataPart do
  @moduledoc """
  A message part carrying structured data as a JSON-compatible map.

  Corresponds to the `DataPart` variant of the `Part` union type in the
  A2A 1.0 specification:
  https://google.github.io/A2A/specification/#datapart

  The `type` field is always the string `"data"` and is used by the codec
  layer to discriminate between part types during serialisation and
  deserialisation. The `data` field holds a map of arbitrary key/value
  pairs; `metadata` is an optional map.
  """

  @enforce_keys [:data]

  defstruct type: "data",
            data: nil,
            metadata: nil

  @type t :: %__MODULE__{
          type: String.t(),
          data: map(),
          metadata: map() | nil
        }
end

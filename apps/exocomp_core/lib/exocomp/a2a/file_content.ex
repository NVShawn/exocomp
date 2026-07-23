defmodule Exocomp.A2A.FileContent do
  @moduledoc """
  Represents the content of a file transferred in an A2A 1.0 message.

  Corresponds to the `FileContent` object in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#filecontent

  A file may be delivered either by reference (`uri`) or by value
  (`bytes`, as a base64-encoded string). Exactly one of `uri` or `bytes`
  must be provided; this constraint is enforced in the codec layer, not in
  the struct definition.

  Required fields: `name`, `mimeType`.
  Optional fields: `uri`, `bytes`.
  """

  @enforce_keys [:name, :mimeType]

  defstruct name: nil,
            mimeType: nil,
            uri: nil,
            bytes: nil

  @type t :: %__MODULE__{
          name: String.t(),
          mimeType: String.t(),
          uri: String.t() | nil,
          bytes: String.t() | nil
        }
end

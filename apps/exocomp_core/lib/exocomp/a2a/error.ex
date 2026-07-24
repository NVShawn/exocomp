defmodule Exocomp.A2A.Error do
  @moduledoc """
  Base struct for A2A 1.0 JSON-RPC error objects.

  Corresponds to the `Error` object returned in JSON-RPC error responses
  in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#error

  Error codes follow the JSON-RPC 2.0 convention: codes in the range
  -32768 to -32000 are reserved for pre-defined errors; A2A-specific
  errors use codes in the range -32099 to -32001.

  Required fields: `code`, `message`.
  Optional fields: `data`.
  """

  @enforce_keys [:code, :message]

  defstruct code: nil,
            message: nil,
            data: nil

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }
end

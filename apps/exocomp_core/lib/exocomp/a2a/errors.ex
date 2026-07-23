defmodule Exocomp.A2A.JSONParseError do
  @moduledoc """
  A2A 1.0 / JSON-RPC 2.0 parse error: invalid JSON was received.

  Error code: -32700. Corresponds to the standard JSON-RPC 2.0 parse
  error as referenced in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#error-codes
  """

  @code -32700
  @default_message "Parse error"

  defstruct code: @code,
            message: @default_message,
            data: nil

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }

  @doc "Returns the fixed error code for this error type."
  @spec code() :: integer()
  def code, do: @code
end

defmodule Exocomp.A2A.InvalidRequestError do
  @moduledoc """
  A2A 1.0 / JSON-RPC 2.0 invalid request error: request is not a valid object.

  Error code: -32600. Corresponds to the standard JSON-RPC 2.0 invalid
  request error as referenced in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#error-codes
  """

  @code -32600
  @default_message "Invalid Request"

  defstruct code: @code,
            message: @default_message,
            data: nil

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }

  @doc "Returns the fixed error code for this error type."
  @spec code() :: integer()
  def code, do: @code
end

defmodule Exocomp.A2A.MethodNotFoundError do
  @moduledoc """
  A2A 1.0 / JSON-RPC 2.0 method not found error: the requested method does not exist.

  Error code: -32601. Corresponds to the standard JSON-RPC 2.0 method
  not found error as referenced in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#error-codes
  """

  @code -32601
  @default_message "Method not found"

  defstruct code: @code,
            message: @default_message,
            data: nil

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }

  @doc "Returns the fixed error code for this error type."
  @spec code() :: integer()
  def code, do: @code
end

defmodule Exocomp.A2A.InvalidParamsError do
  @moduledoc """
  A2A 1.0 / JSON-RPC 2.0 invalid params error: invalid method parameters.

  Error code: -32602. Corresponds to the standard JSON-RPC 2.0 invalid
  params error as referenced in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#error-codes
  """

  @code -32602
  @default_message "Invalid params"

  defstruct code: @code,
            message: @default_message,
            data: nil

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }

  @doc "Returns the fixed error code for this error type."
  @spec code() :: integer()
  def code, do: @code
end

defmodule Exocomp.A2A.InternalError do
  @moduledoc """
  A2A 1.0 / JSON-RPC 2.0 internal error: internal JSON-RPC error.

  Error code: -32603. Corresponds to the standard JSON-RPC 2.0 internal
  error as referenced in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#error-codes
  """

  @code -32603
  @default_message "Internal error"

  defstruct code: @code,
            message: @default_message,
            data: nil

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }

  @doc "Returns the fixed error code for this error type."
  @spec code() :: integer()
  def code, do: @code
end

defmodule Exocomp.A2A.TaskNotFoundError do
  @moduledoc """
  A2A 1.0 application error: the referenced task does not exist.

  Error code: -32001. Returned when a client references a task ID that
  the server does not recognise. Defined in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#error-codes
  """

  @code -32001
  @default_message "Task not found"

  defstruct code: @code,
            message: @default_message,
            data: nil

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }

  @doc "Returns the fixed error code for this error type."
  @spec code() :: integer()
  def code, do: @code
end

defmodule Exocomp.A2A.TaskNotCancelableError do
  @moduledoc """
  A2A 1.0 application error: the task cannot be canceled in its current state.

  Error code: -32002. Returned when a client attempts to cancel a task
  that is in a terminal state. Defined in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#error-codes
  """

  @code -32002
  @default_message "Task not cancelable"

  defstruct code: @code,
            message: @default_message,
            data: nil

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }

  @doc "Returns the fixed error code for this error type."
  @spec code() :: integer()
  def code, do: @code
end

defmodule Exocomp.A2A.PushNotificationNotSupportedError do
  @moduledoc """
  A2A 1.0 application error: the agent does not support push notifications.

  Error code: -32003. Returned when a client attempts to set up push
  notifications but the agent does not have the `pushNotifications`
  capability. Defined in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#error-codes
  """

  @code -32003
  @default_message "Push notification not supported"

  defstruct code: @code,
            message: @default_message,
            data: nil

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }

  @doc "Returns the fixed error code for this error type."
  @spec code() :: integer()
  def code, do: @code
end

defmodule Exocomp.A2A.UnsupportedOperationError do
  @moduledoc """
  A2A 1.0 application error: the requested operation is not supported.

  Error code: -32004. Returned when a client requests an operation that
  the agent does not implement. Defined in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#error-codes
  """

  @code -32004
  @default_message "Unsupported operation"

  defstruct code: @code,
            message: @default_message,
            data: nil

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }

  @doc "Returns the fixed error code for this error type."
  @spec code() :: integer()
  def code, do: @code
end

defmodule Exocomp.A2A.ContentTypeNotSupportedError do
  @moduledoc """
  A2A 1.0 application error: the content type in the request is not supported.

  Error code: -32005. Returned when a client sends a message with a
  content type (MIME type) that the agent does not handle. Defined in
  the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#error-codes
  """

  @code -32005
  @default_message "Content type not supported"

  defstruct code: @code,
            message: @default_message,
            data: nil

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }

  @doc "Returns the fixed error code for this error type."
  @spec code() :: integer()
  def code, do: @code
end

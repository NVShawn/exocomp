defmodule Exocomp.A2A.Codec do
  @moduledoc """
  Converts A2A 1.0 structs to and from JSON-compatible maps.

  Decoding validates required fields and returns protocol error structs instead
  of raising.
  """

  alias Exocomp.A2A.{
    AgentCapabilities,
    AgentCard,
    AgentSkill,
    Artifact,
    DataPart,
    Error,
    FileContent,
    FilePart,
    InvalidParamsError,
    InvalidRequestError,
    Message,
    Task,
    TaskState,
    TaskStatus,
    TextPart,
    UnsupportedOperationError
  }

  @error_modules [
    Error,
    Exocomp.A2A.JSONParseError,
    InvalidRequestError,
    Exocomp.A2A.MethodNotFoundError,
    InvalidParamsError,
    Exocomp.A2A.InternalError,
    Exocomp.A2A.TaskNotFoundError,
    Exocomp.A2A.TaskNotCancelableError,
    Exocomp.A2A.PushNotificationNotSupportedError,
    UnsupportedOperationError,
    Exocomp.A2A.ContentTypeNotSupportedError
  ]

  @type decode_error ::
          InvalidRequestError.t() | InvalidParamsError.t() | UnsupportedOperationError.t()

  @doc "Converts an A2A struct into a JSON-compatible map."
  @spec encode(struct()) :: map()
  def encode(%AgentCapabilities{} = value),
    do:
      compact(%{
        "streaming" => value.streaming,
        "pushNotifications" => value.pushNotifications,
        "stateTransitionHistory" => value.stateTransitionHistory
      })

  def encode(%AgentCard{} = value),
    do:
      compact(%{
        "name" => value.name,
        "description" => value.description,
        "url" => value.url,
        "version" => value.version,
        "capabilities" => encode_optional(value.capabilities),
        "skills" => encode_list(value.skills),
        "defaultInputModes" => value.defaultInputModes,
        "defaultOutputModes" => value.defaultOutputModes
      })

  def encode(%AgentSkill{} = value),
    do:
      compact(%{
        "id" => value.id,
        "name" => value.name,
        "description" => value.description,
        "inputModes" => value.inputModes,
        "outputModes" => value.outputModes
      })

  def encode(%Artifact{} = value),
    do:
      compact(%{
        "artifactId" => value.artifactId,
        "name" => value.name,
        "description" => value.description,
        "parts" => encode_list(value.parts),
        "index" => value.index,
        "append" => value.append,
        "lastChunk" => value.lastChunk,
        "metadata" => value.metadata
      })

  def encode(%DataPart{} = value),
    do: compact(%{"type" => value.type, "data" => value.data, "metadata" => value.metadata})

  def encode(%FileContent{} = value),
    do:
      compact(%{
        "name" => value.name,
        "mimeType" => value.mimeType,
        "uri" => value.uri,
        "bytes" => value.bytes
      })

  def encode(%FilePart{} = value),
    do:
      compact(%{
        "type" => value.type,
        "file" => encode_optional(value.file),
        "metadata" => value.metadata
      })

  def encode(%Message{} = value),
    do:
      compact(%{
        "role" => Atom.to_string(value.role),
        "parts" => encode_list(value.parts),
        "messageId" => value.messageId,
        "taskId" => value.taskId,
        "contextId" => value.contextId,
        "timestamp" => value.timestamp
      })

  def encode(%Task{} = value),
    do:
      compact(%{
        "id" => value.id,
        "contextId" => value.contextId,
        "status" => encode_optional(value.status),
        "history" => encode_list(value.history),
        "artifacts" => encode_list(value.artifacts),
        "metadata" => value.metadata,
        "createdAt" => value.created_at,
        "updatedAt" => value.updated_at
      })

  def encode(%TaskStatus{} = value),
    do:
      compact(%{
        "state" => Atom.to_string(value.state),
        "message" => encode_optional(value.message),
        "timestamp" => value.timestamp
      })

  def encode(%TextPart{} = value),
    do: compact(%{"type" => value.type, "text" => value.text, "metadata" => value.metadata})

  def encode(%{__struct__: module, code: code, message: message, data: data})
      when module in @error_modules,
      do: compact(%{"code" => code, "message" => message, "data" => data})

  @doc "Decodes a parsed JSON map into the requested A2A type."
  @spec decode(term(), module() | :part) :: {:ok, struct()} | {:error, decode_error()}
  def decode(value, _type) when not is_map(value), do: invalid_request("expected a JSON object")

  def decode(value, :part), do: decode_part(value)
  def decode(value, Exocomp.A2A.Part), do: decode_part(value)

  def decode(value, AgentCapabilities) do
    with :ok <- optional_type(value, "streaming", &is_boolean/1),
         :ok <- optional_type(value, "pushNotifications", &is_boolean/1),
         :ok <- optional_type(value, "stateTransitionHistory", &is_boolean/1) do
      {:ok,
       %AgentCapabilities{
         streaming: Map.get(value, "streaming", false),
         pushNotifications: Map.get(value, "pushNotifications", false),
         stateTransitionHistory: Map.get(value, "stateTransitionHistory", false)
       }}
    end
  end

  def decode(value, AgentCard) do
    with {:ok, name} <- required(value, "name", &is_binary/1),
         {:ok, description} <- required(value, "description", &is_binary/1),
         {:ok, url} <- required(value, "url", &is_binary/1),
         {:ok, version} <- required(value, "version", &is_binary/1),
         {:ok, capabilities} <- optional_nested(value, "capabilities", AgentCapabilities),
         {:ok, skills} <- optional_list(value, "skills", AgentSkill, []),
         :ok <- optional_string_list(value, "defaultInputModes"),
         :ok <- optional_string_list(value, "defaultOutputModes") do
      {:ok,
       %AgentCard{
         name: name,
         description: description,
         url: url,
         version: version,
         capabilities: capabilities,
         skills: skills,
         defaultInputModes: Map.get(value, "defaultInputModes"),
         defaultOutputModes: Map.get(value, "defaultOutputModes")
       }}
    end
  end

  def decode(value, AgentSkill) do
    with {:ok, id} <- required(value, "id", &is_binary/1),
         {:ok, name} <- required(value, "name", &is_binary/1),
         :ok <- optional_type(value, "description", &is_binary/1),
         :ok <- optional_string_list(value, "inputModes"),
         :ok <- optional_string_list(value, "outputModes") do
      {:ok,
       %AgentSkill{
         id: id,
         name: name,
         description: Map.get(value, "description"),
         inputModes: Map.get(value, "inputModes"),
         outputModes: Map.get(value, "outputModes")
       }}
    end
  end

  def decode(value, Artifact) do
    with {:ok, artifact_id} <- required(value, "artifactId", &is_binary/1),
         {:ok, parts} <- required_list(value, "parts", :part),
         :ok <- optional_type(value, "name", &is_binary/1),
         :ok <- optional_type(value, "description", &is_binary/1),
         :ok <- optional_type(value, "index", &non_negative_integer?/1),
         :ok <- optional_type(value, "append", &is_boolean/1),
         :ok <- optional_type(value, "lastChunk", &is_boolean/1),
         :ok <- optional_type(value, "metadata", &is_map/1) do
      {:ok,
       %Artifact{
         artifactId: artifact_id,
         name: Map.get(value, "name"),
         description: Map.get(value, "description"),
         parts: parts,
         index: Map.get(value, "index"),
         append: Map.get(value, "append", false),
         lastChunk: Map.get(value, "lastChunk", false),
         metadata: Map.get(value, "metadata")
       }}
    end
  end

  def decode(value, DataPart) do
    with :ok <- discriminator(value, "data"),
         {:ok, data} <- required(value, "data", &is_map/1),
         :ok <- optional_type(value, "metadata", &is_map/1) do
      {:ok, %DataPart{data: data, metadata: Map.get(value, "metadata")}}
    end
  end

  def decode(value, FileContent) do
    with {:ok, name} <- required(value, "name", &is_binary/1),
         {:ok, mime_type} <- required(value, "mimeType", &is_binary/1),
         :ok <- optional_type(value, "uri", &is_binary/1),
         :ok <- optional_type(value, "bytes", &is_binary/1),
         :ok <- exactly_one_file_source(value) do
      {:ok,
       %FileContent{
         name: name,
         mimeType: mime_type,
         uri: Map.get(value, "uri"),
         bytes: Map.get(value, "bytes")
       }}
    end
  end

  def decode(value, FilePart) do
    with :ok <- discriminator(value, "file"),
         {:ok, file} <- required_nested(value, "file", FileContent),
         :ok <- optional_type(value, "metadata", &is_map/1) do
      {:ok, %FilePart{file: file, metadata: Map.get(value, "metadata")}}
    end
  end

  def decode(value, Message) do
    with {:ok, role} <- required(value, "role", &(&1 in ["user", "agent"])),
         {:ok, parts} <- required_list(value, "parts", :part),
         :ok <- optional_type(value, "messageId", &is_binary/1),
         :ok <- optional_type(value, "taskId", &is_binary/1),
         :ok <- optional_type(value, "contextId", &is_binary/1),
         :ok <- optional_type(value, "timestamp", &is_binary/1) do
      {:ok,
       %Message{
         role: decode_role(role),
         parts: parts,
         messageId: Map.get(value, "messageId"),
         taskId: Map.get(value, "taskId"),
         contextId: Map.get(value, "contextId"),
         timestamp: Map.get(value, "timestamp")
       }}
    end
  end

  def decode(value, Task) do
    with {:ok, id} <- required(value, "id", &is_binary/1),
         {:ok, status} <- required_nested(value, "status", TaskStatus),
         {:ok, history} <- optional_list(value, "history", Message, []),
         {:ok, artifacts} <- optional_list(value, "artifacts", Artifact, []),
         :ok <- optional_type(value, "contextId", &is_binary/1),
         :ok <- optional_type(value, "metadata", &is_map/1),
         :ok <- optional_type(value, "createdAt", &is_binary/1),
         :ok <- optional_type(value, "updatedAt", &is_binary/1) do
      {:ok,
       %Task{
         id: id,
         contextId: Map.get(value, "contextId"),
         status: status,
         history: history,
         artifacts: artifacts,
         metadata: Map.get(value, "metadata"),
         created_at: Map.get(value, "createdAt"),
         updated_at: Map.get(value, "updatedAt")
       }}
    end
  end

  def decode(value, TaskStatus) do
    with {:ok, state} <- required(value, "state", &is_binary/1),
         {:ok, state_atom} <- decode_state(state),
         {:ok, message} <- optional_nested(value, "message", Message),
         :ok <- optional_type(value, "timestamp", &is_binary/1) do
      {:ok,
       %TaskStatus{state: state_atom, message: message, timestamp: Map.get(value, "timestamp")}}
    end
  end

  def decode(value, TextPart) do
    with :ok <- discriminator(value, "text"),
         {:ok, text} <- required(value, "text", &is_binary/1),
         :ok <- optional_type(value, "metadata", &is_map/1) do
      {:ok, %TextPart{text: text, metadata: Map.get(value, "metadata")}}
    end
  end

  def decode(value, module) when module in @error_modules do
    with {:ok, code} <- required(value, "code", &is_integer/1),
         {:ok, message} <- required(value, "message", &is_binary/1) do
      {:ok, struct!(module, code: code, message: message, data: Map.get(value, "data"))}
    end
  end

  def decode(_value, _type), do: {:error, %UnsupportedOperationError{}}

  defp decode_part(%{"type" => "text"} = value), do: decode(value, TextPart)
  defp decode_part(%{"type" => "data"} = value), do: decode(value, DataPart)
  defp decode_part(%{"type" => "file"} = value), do: decode(value, FilePart)
  defp decode_part(_value), do: {:error, %UnsupportedOperationError{}}

  defp decode_state(state) do
    atom = String.to_existing_atom(state)

    if TaskState.valid?(atom),
      do: {:ok, atom},
      else: invalid_params("state is not a recognised TaskState")
  rescue
    ArgumentError -> invalid_params("state is not a recognised TaskState")
  end

  defp decode_role("user"), do: :user
  defp decode_role("agent"), do: :agent

  defp required(map, key, validator) do
    case Map.fetch(map, key) do
      {:ok, value} ->
        if validator.(value), do: {:ok, value}, else: invalid_params("#{key} has an invalid type")

      :error ->
        invalid_params("#{key} is required")
    end
  end

  defp optional_type(map, key, validator) do
    case Map.fetch(map, key) do
      :error ->
        :ok

      {:ok, nil} ->
        invalid_params("#{key} has an invalid type")

      {:ok, value} ->
        if validator.(value), do: :ok, else: invalid_params("#{key} has an invalid type")
    end
  end

  defp optional_string_list(map, key),
    do: optional_type(map, key, &(is_list(&1) and Enum.all?(&1, fn item -> is_binary(item) end)))

  defp required_nested(map, key, type) do
    with {:ok, value} <- required(map, key, &is_map/1), do: decode(value, type)
  end

  defp optional_nested(map, key, type) do
    case Map.fetch(map, key) do
      :error -> {:ok, nil}
      {:ok, value} when is_map(value) -> decode(value, type)
      {:ok, _value} -> invalid_params("#{key} has an invalid type")
    end
  end

  defp required_list(map, key, type) do
    with {:ok, values} <- required(map, key, &is_list/1), do: decode_list(values, type)
  end

  defp optional_list(map, key, type, default) do
    case Map.fetch(map, key) do
      :error -> {:ok, default}
      {:ok, values} when is_list(values) -> decode_list(values, type)
      {:ok, _value} -> invalid_params("#{key} has an invalid type")
    end
  end

  defp decode_list(values, type) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, decoded} ->
      case decode(value, type) do
        {:ok, item} -> {:cont, {:ok, [item | decoded]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, decoded} -> {:ok, Enum.reverse(decoded)}
      error -> error
    end
  end

  defp discriminator(map, expected) do
    case Map.fetch(map, "type") do
      {:ok, ^expected} -> :ok
      _other -> invalid_params("type must be #{expected}")
    end
  end

  defp exactly_one_file_source(map) do
    if Enum.count(["uri", "bytes"], &is_binary(Map.get(map, &1))) == 1,
      do: :ok,
      else: invalid_params("exactly one of uri or bytes is required")
  end

  defp non_negative_integer?(value), do: is_integer(value) and value >= 0
  defp encode_list(values), do: Enum.map(values, &encode/1)
  defp encode_optional(nil), do: nil
  defp encode_optional(value), do: encode(value)
  defp compact(map), do: Map.reject(map, fn {_key, value} -> is_nil(value) end)

  defp invalid_request(reason),
    do: {:error, %InvalidRequestError{data: %{"reason" => reason}}}

  defp invalid_params(reason),
    do: {:error, %InvalidParamsError{data: %{"reason" => reason}}}
end

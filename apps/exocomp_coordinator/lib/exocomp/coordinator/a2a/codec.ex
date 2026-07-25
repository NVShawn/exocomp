defmodule Exocomp.Coordinator.A2A.Codec do
  @moduledoc """
  JSON encode/decode helpers for the coordinator A2A 1.0 boundary.

  Server-side (inbound from A2A callers):
  - `decode_message/1`  — parse a JSON map into an `Exocomp.A2A.Message` struct.
  - `extract_skill/1`   — pull the `skill_id` and `params` out of a decoded message.
  - `encode_task/1`     — serialise an `Exocomp.A2A.Task` to a JSON-compatible map.

  Client-side (outbound to node agents):
  - `encode_diagnostic/4` — encode an outbound diagnostic skill message.
  - `decode_task/1`       — decode a Task response from a node agent.

  Supported cluster skills:
  - `exocomp.cluster.health`
  - `exocomp.cluster.diagnose`

  Remediation execution skills are intentionally absent from this codec.
  """

  alias Exocomp.A2A.{
    Artifact,
    DataPart,
    FileContent,
    FilePart,
    InvalidParamsError,
    Message,
    Task,
    TaskState,
    TaskStatus,
    TextPart
  }

  @supported_skills ~w[
    exocomp.cluster.health
    exocomp.cluster.diagnose
  ]

  # ---------------------------------------------------------------------------
  # Client-side: outbound to node agents
  # ---------------------------------------------------------------------------

  @spec encode_diagnostic(String.t(), map(), String.t(), String.t() | nil) :: map()
  def encode_diagnostic(skill_id, params, message_id, context_id) do
    %{
      "role" => "user",
      "messageId" => message_id,
      "contextId" => context_id,
      "parts" => [%{"type" => "data", "data" => Map.put(params, "skill", skill_id)}]
    }
  end

  @spec decode_task(term()) :: {:ok, Task.t()} | {:error, term()}
  def decode_task(%{"id" => id, "status" => %{"state" => state} = status} = raw)
      when is_binary(id) and is_binary(state) do
    with {:ok, state_atom} <- decode_state(state),
         {:ok, artifacts} <- decode_artifacts(Map.get(raw, "artifacts", [])) do
      {:ok,
       %Task{
         id: id,
         contextId: Map.get(raw, "contextId"),
         status: %TaskStatus{
           state: state_atom,
           message: Map.get(status, "message"),
           timestamp: Map.get(status, "timestamp")
         },
         history: Map.get(raw, "history", []),
         artifacts: artifacts,
         metadata: Map.get(raw, "metadata"),
         created_at: Map.get(raw, "createdAt"),
         updated_at: Map.get(raw, "updatedAt")
       }}
    end
  end

  def decode_task(other), do: {:error, {:malformed_task, other}}

  # ---------------------------------------------------------------------------
  # Server-side: inbound from A2A callers
  # ---------------------------------------------------------------------------

  @doc """
  Decode a JSON-parsed map into an `Exocomp.A2A.Message` struct.

  Returns `{:ok, message}` on success, or
  `{:error, %InvalidParamsError{}}` when the input is malformed.
  """
  @spec decode_message(term()) ::
          {:ok, Message.t()} | {:error, InvalidParamsError.t()}
  def decode_message(params) when is_map(params) do
    with {:ok, role} <- decode_role(params["role"]),
         {:ok, parts} <- decode_message_parts(params["parts"]) do
      {:ok,
       %Message{
         role: role,
         parts: parts,
         messageId: params["messageId"],
         taskId: params["taskId"],
         contextId: params["contextId"],
         timestamp: params["timestamp"]
       }}
    end
  end

  def decode_message(_),
    do: {:error, %InvalidParamsError{message: "Message body must be a JSON object"}}

  @doc """
  Extract `{skill_id, params}` from a decoded `Message`.

  Searches the message parts for a `DataPart` whose `data` map contains a
  `"skill"` key. The returned params map includes any selection fields
  (e.g. `node_ids`, `labels`) passed alongside the skill identifier.

  Falls back to a bare `TextPart` whose text is the skill identifier with
  an empty params map.

  Returns `{:ok, {skill_id, params}}` or `{:error, %InvalidParamsError{}}`.
  """
  @spec extract_skill(Message.t()) ::
          {:ok, {String.t(), map()}} | {:error, InvalidParamsError.t()}
  def extract_skill(%Message{parts: parts}) do
    case Enum.find(parts, &data_part_with_skill?/1) do
      %DataPart{data: %{"skill" => skill_id} = data} ->
        validate_skill(skill_id, Map.delete(data, "skill"))

      nil ->
        case Enum.find(parts, &match?(%TextPart{}, &1)) do
          %TextPart{text: skill_id} ->
            validate_skill(skill_id, %{})

          nil ->
            {:error, %InvalidParamsError{message: "No skill identifier found in message parts"}}
        end
    end
  end

  defp data_part_with_skill?(%DataPart{data: %{"skill" => _}}), do: true
  defp data_part_with_skill?(_), do: false

  defp validate_skill(skill_id, params) when skill_id in @supported_skills,
    do: {:ok, {skill_id, params}}

  defp validate_skill(skill_id, _params),
    do: {:error, %InvalidParamsError{message: "Unknown or unsupported skill: #{skill_id}"}}

  @doc """
  Serialise an `Exocomp.A2A.Task` struct to a JSON-compatible map.
  """
  @spec encode_task(Task.t()) :: map()
  def encode_task(%Task{} = task) do
    %{
      "id" => task.id,
      "contextId" => task.contextId,
      "status" => encode_status(task.status),
      "history" => Enum.map(task.history, &encode_message/1),
      "artifacts" => encode_artifacts(task),
      "metadata" => task.metadata,
      "createdAt" => task.created_at,
      "updatedAt" => task.updated_at
    }
  end

  # ---------------------------------------------------------------------------
  # Private: task encoding helpers
  # ---------------------------------------------------------------------------

  defp encode_status(nil), do: nil

  defp encode_status(status) do
    %{
      "state" => to_string(status.state),
      "timestamp" => status.timestamp
    }
  end

  # Artifacts — completed tasks store the artifact in status.message (via TaskRegistry)
  defp encode_artifacts(%Task{status: %{state: :completed, message: %Artifact{} = artifact}}) do
    [encode_artifact(artifact)]
  end

  defp encode_artifacts(%Task{artifacts: artifacts}) when is_list(artifacts) do
    Enum.map(artifacts, &encode_artifact/1)
  end

  defp encode_artifacts(_), do: []

  defp encode_artifact(%Artifact{} = a) do
    %{
      "artifactId" => a.artifactId,
      "name" => a.name,
      "description" => a.description,
      "parts" => Enum.map(a.parts, &encode_part/1),
      "metadata" => a.metadata
    }
  end

  defp encode_message(%Message{} = m) do
    %{
      "role" => to_string(m.role),
      "parts" => Enum.map(m.parts, &encode_part/1),
      "messageId" => m.messageId,
      "taskId" => m.taskId,
      "contextId" => m.contextId,
      "timestamp" => m.timestamp
    }
  end

  defp encode_message(other), do: inspect(other)

  defp encode_part(%TextPart{} = p),
    do: %{"type" => "text", "text" => p.text, "metadata" => p.metadata}

  defp encode_part(%DataPart{} = p),
    do: %{"type" => "data", "data" => p.data, "metadata" => p.metadata}

  defp encode_part(%FilePart{} = p),
    do: %{"type" => "file", "file" => p.file, "metadata" => p.metadata}

  defp encode_part(other), do: inspect(other)

  # ---------------------------------------------------------------------------
  # Private: message decode helpers (server-side inbound)
  # ---------------------------------------------------------------------------

  defp decode_role("user"), do: {:ok, :user}
  defp decode_role("agent"), do: {:ok, :agent}

  defp decode_role(other),
    do: {:error, %InvalidParamsError{message: "Invalid role: #{inspect(other)}"}}

  defp decode_message_parts(nil),
    do: {:error, %InvalidParamsError{message: "Message parts are required"}}

  defp decode_message_parts(parts) when is_list(parts) do
    Enum.reduce_while(parts, {:ok, []}, fn raw, {:ok, acc} ->
      case decode_message_part(raw) do
        {:ok, part} -> {:cont, {:ok, [part | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      err -> err
    end
  end

  defp decode_message_parts(_),
    do: {:error, %InvalidParamsError{message: "Message parts must be an array"}}

  defp decode_message_part(%{"type" => "text", "text" => text}) when is_binary(text),
    do: {:ok, %TextPart{text: text}}

  defp decode_message_part(%{"type" => "data", "data" => data}) when is_map(data),
    do: {:ok, %DataPart{data: data}}

  defp decode_message_part(other),
    do: {:error, %InvalidParamsError{message: "Invalid part: #{inspect(other)}"}}

  # ---------------------------------------------------------------------------
  # Private: task decode helpers (client-side outbound)
  # ---------------------------------------------------------------------------

  defp decode_state(state) do
    atom =
      state
      |> String.replace("-", "_")
      |> String.to_existing_atom()

    if TaskState.valid?(atom), do: {:ok, atom}, else: {:error, {:invalid_task_state, state}}
  rescue
    ArgumentError -> {:error, {:invalid_task_state, state}}
  end

  defp decode_artifacts(artifacts) when is_list(artifacts) do
    Enum.reduce_while(artifacts, {:ok, []}, fn artifact, {:ok, acc} ->
      case decode_artifact(artifact) do
        {:ok, decoded} -> {:cont, {:ok, [decoded | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, decoded} -> {:ok, Enum.reverse(decoded)}
      error -> error
    end
  end

  defp decode_artifacts(other), do: {:error, {:malformed_artifacts, other}}

  defp decode_artifact(%{"artifactId" => id, "parts" => parts} = raw)
       when is_binary(id) and is_list(parts) do
    with {:ok, decoded_parts} <- decode_artifact_parts(parts) do
      {:ok,
       %Artifact{
         artifactId: id,
         parts: decoded_parts,
         name: Map.get(raw, "name"),
         description: Map.get(raw, "description"),
         metadata: Map.get(raw, "metadata")
       }}
    end
  end

  defp decode_artifact(other), do: {:error, {:malformed_artifact, other}}

  defp decode_artifact_parts(parts) do
    Enum.reduce_while(parts, {:ok, []}, fn part, {:ok, acc} ->
      case decode_artifact_part(part) do
        {:ok, decoded} -> {:cont, {:ok, [decoded | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, decoded} -> {:ok, Enum.reverse(decoded)}
      error -> error
    end
  end

  defp decode_artifact_part(%{"type" => "text", "text" => text} = raw) when is_binary(text),
    do: {:ok, %TextPart{text: text, metadata: Map.get(raw, "metadata")}}

  defp decode_artifact_part(%{"type" => "data", "data" => data} = raw) when is_map(data),
    do: {:ok, %DataPart{data: data, metadata: Map.get(raw, "metadata")}}

  defp decode_artifact_part(%{"type" => "file", "file" => file} = raw) when is_map(file) do
    with %{"name" => name, "mimeType" => mime_type}
         when is_binary(name) and is_binary(mime_type) <- file do
      {:ok,
       %FilePart{
         file: %FileContent{
           name: name,
           mimeType: mime_type,
           uri: Map.get(file, "uri"),
           bytes: Map.get(file, "bytes")
         },
         metadata: Map.get(raw, "metadata")
       }}
    else
      _ -> {:error, {:malformed_part, raw}}
    end
  end

  defp decode_artifact_part(other), do: {:error, {:malformed_part, other}}
end

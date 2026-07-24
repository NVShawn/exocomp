defmodule Exocomp.Coordinator.A2A.Codec do
  @moduledoc false

  alias Exocomp.A2A.{
    Artifact,
    DataPart,
    FileContent,
    FilePart,
    Task,
    TaskState,
    TaskStatus,
    TextPart
  }

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
    with {:ok, decoded_parts} <- decode_parts(parts) do
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

  defp decode_parts(parts) do
    Enum.reduce_while(parts, {:ok, []}, fn part, {:ok, acc} ->
      case decode_part(part) do
        {:ok, decoded} -> {:cont, {:ok, [decoded | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, decoded} -> {:ok, Enum.reverse(decoded)}
      error -> error
    end
  end

  defp decode_part(%{"type" => "text", "text" => text} = raw) when is_binary(text),
    do: {:ok, %TextPart{text: text, metadata: Map.get(raw, "metadata")}}

  defp decode_part(%{"type" => "data", "data" => data} = raw) when is_map(data),
    do: {:ok, %DataPart{data: data, metadata: Map.get(raw, "metadata")}}

  defp decode_part(%{"type" => "file", "file" => file} = raw) when is_map(file) do
    with %{"name" => name, "mimeType" => mime_type} when is_binary(name) and is_binary(mime_type) <-
           file do
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

  defp decode_part(other), do: {:error, {:malformed_part, other}}
end

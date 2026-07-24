defmodule Exocomp.Node.A2A.Codec do
  @moduledoc """
  JSON encode/decode helpers for A2A 1.0 HTTP endpoint wiring.

  Provides:
  - `decode_message/1`  — parse a JSON map into an `Exocomp.A2A.Message` struct.
  - `extract_skill/1`   — pull the `skill_id` and `params` out of a decoded message.
  - `encode_task/1`     — serialise an `Exocomp.A2A.Task` to a JSON-compatible map.
  """

  alias Exocomp.A2A.{
    Artifact,
    DataPart,
    FilePart,
    InvalidParamsError,
    Message,
    Task,
    TextPart
  }

  @supported_skills ~w[
    exocomp.system.diagnose
    exocomp.service.diagnose
    exocomp.remediation.propose
  ]

  # ---------------------------------------------------------------------------
  # Decoding
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
         {:ok, parts} <- decode_parts(params["parts"]) do
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
  `"skill"` key, then falls back to a bare `TextPart` whose text is the
  skill identifier.

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
    do: {:error, %InvalidParamsError{message: "Unknown skill: #{skill_id}"}}

  # ---------------------------------------------------------------------------
  # Encoding
  # ---------------------------------------------------------------------------

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

  # Task status
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

  # Message
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

  # Parts
  defp encode_part(%TextPart{} = p),
    do: %{"type" => "text", "text" => p.text, "metadata" => p.metadata}

  defp encode_part(%DataPart{} = p),
    do: %{"type" => "data", "data" => p.data, "metadata" => p.metadata}

  defp encode_part(%FilePart{} = p),
    do: %{"type" => "file", "file" => p.file, "metadata" => p.metadata}

  defp encode_part(other), do: inspect(other)

  # ---------------------------------------------------------------------------
  # Private decode helpers
  # ---------------------------------------------------------------------------

  defp decode_role("user"), do: {:ok, :user}
  defp decode_role("agent"), do: {:ok, :agent}

  defp decode_role(other),
    do: {:error, %InvalidParamsError{message: "Invalid role: #{inspect(other)}"}}

  defp decode_parts(nil),
    do: {:error, %InvalidParamsError{message: "Message parts are required"}}

  defp decode_parts(parts) when is_list(parts) do
    Enum.reduce_while(parts, {:ok, []}, fn raw, {:ok, acc} ->
      case decode_part(raw) do
        {:ok, part} -> {:cont, {:ok, [part | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      err -> err
    end
  end

  defp decode_parts(_),
    do: {:error, %InvalidParamsError{message: "Message parts must be an array"}}

  defp decode_part(%{"type" => "text", "text" => text}) when is_binary(text),
    do: {:ok, %TextPart{text: text}}

  defp decode_part(%{"type" => "data", "data" => data}) when is_map(data),
    do: {:ok, %DataPart{data: data}}

  defp decode_part(other),
    do: {:error, %InvalidParamsError{message: "Invalid part: #{inspect(other)}"}}
end

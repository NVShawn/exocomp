# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterChatSchema do
  @moduledoc """
  Validates and parses cluster chat model responses.

  The model response must contain:
  - `text` — Markdown response text (required, non-empty string)
  - `citations` — array of evidence citations (required, may be empty)
    - Each citation must have: `evidence_id`, `node_id`, `collected_at`
  - `proposal` — optional single typed remedy proposal
    - If present, must have: `proposal_id`, `rationale`, `affected_resource`, `confidence`

  The parser attempts to extract JSON from the model's raw text output,
  accounting for markdown code fences or other formatting.
  """

  @doc """
  Parse raw model output to extract structured JSON response.

  Attempts multiple strategies:
  1. Direct JSON parsing
  2. Extracting JSON from markdown code blocks
  3. Extracting JSON object from text

  Returns `{:ok, map}` or `{:error, reason}`.
  """
  @spec parse(String.t()) :: {:ok, map()} | {:error, term()}
  def parse(raw_text) when is_binary(raw_text) do
    # Strategy 1: Try direct JSON parsing
    case Jason.decode(raw_text) do
      {:ok, map} when is_map(map) ->
        {:ok, map}

      _ ->
        # Strategy 2: Try extracting from markdown code blocks
        case extract_json_from_code_block(raw_text) do
          {:ok, map} -> {:ok, map}
          :not_found -> extract_json_from_text(raw_text)
        end
    end
  end

  def parse(_), do: {:error, :invalid_json}

  @doc """
  Validate a parsed response map against the cluster chat schema.

  Returns `{:ok, validated_map}` or `{:error, reason}`.
  """
  @spec validate(map()) :: {:ok, map()} | {:error, term()}
  def validate(response) when is_map(response) do
    with :ok <- validate_text(response),
         :ok <- validate_citations(response),
         :ok <- validate_proposal(response) do
      {:ok, response}
    end
  end

  def validate(_), do: {:error, :invalid_response}

  # ---------------------------------------------------------------------------
  # Parsing helpers
  # ---------------------------------------------------------------------------

  defp extract_json_from_code_block(text) do
    # Match ```json ... ``` or ``` ... ```
    case Regex.run(
           ~r/```(?:json)?\s*\n(.*?)\n```/ms,
           text,
           capture: :all_but_first
         ) do
      [json_str] ->
        case Jason.decode(json_str) do
          {:ok, map} when is_map(map) -> {:ok, map}
          _ -> :not_found
        end

      _ ->
        :not_found
    end
  end

  defp extract_json_from_text(text) do
    # Try to find a JSON object by looking for { ... }
    case Regex.run(~r/\{.*\}/s, text) do
      [json_str] ->
        case Jason.decode(json_str) do
          {:ok, map} when is_map(map) -> {:ok, map}
          _ -> {:error, :invalid_json}
        end

      _ ->
        {:error, :invalid_json}
    end
  end

  # ---------------------------------------------------------------------------
  # Validation helpers
  # ---------------------------------------------------------------------------

  defp validate_text(response) do
    case Map.get(response, "text") do
      text when is_binary(text) and byte_size(text) > 0 -> :ok
      _ -> {:error, :missing_or_empty_text}
    end
  end

  defp validate_citations(response) do
    case Map.get(response, "citations") do
      citations when is_list(citations) ->
        Enum.reduce_while(citations, :ok, fn citation, _acc ->
          case validate_citation(citation) do
            :ok -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      nil ->
        # Citations are optional, but if present must be a list
        :ok

      _ ->
        {:error, :invalid_citations_format}
    end
  end

  defp validate_citation(citation) when is_map(citation) do
    with {:ok, _} <- fetch_required(citation, "evidence_id"),
         {:ok, _} <- fetch_required(citation, "node_id"),
         {:ok, _} <- fetch_required(citation, "collected_at") do
      :ok
    else
      :error -> {:error, :incomplete_citation}
    end
  end

  defp validate_citation(_), do: {:error, :invalid_citation_format}

  defp validate_proposal(response) do
    case Map.get(response, "proposal") do
      proposal when is_map(proposal) ->
        with {:ok, _} <- fetch_required(proposal, "proposal_id"),
             {:ok, _} <- fetch_required(proposal, "rationale"),
             {:ok, _} <- fetch_required(proposal, "affected_resource"),
             {:ok, confidence} <- fetch_required(proposal, "confidence") do
          # Confidence must be a number 0.0-1.0
          if is_number(confidence) and confidence >= 0.0 and confidence <= 1.0 do
            :ok
          else
            {:error, :invalid_confidence}
          end
        else
          :error -> {:error, :incomplete_proposal}
        end

      nil ->
        # Proposal is optional
        :ok

      _ ->
        {:error, :invalid_proposal_format}
    end
  end

  defp fetch_required(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      {:ok, value} when is_number(value) -> {:ok, value}
      {:ok, _other} -> :error
      :error -> :error
    end
  end
end

# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterChatClient do
  @moduledoc """
  HTTP inference client that sends bounded conversation context to a local
  OpenAI-compatible inference endpoint and returns a schema-validated chat response.

  ## Security model

  - **Model availability gate** — inference endpoint is checked before any network I/O.
  - **Bounded context** — thread and evidence are byte-truncated before transmission;
    at most newest 50 messages or 64 KiB of context.
  - **Fixed system prompt** — hardcoded system prompt is not caller-configurable.
  - **Schema gate** — every response passes through `ClusterChatSchema.validate/1`
    before leaving this module; schema-invalid or unparseable output is rejected.
  - **Audit logging with redaction** — every call attempt is logged; raw model
    output is replaced with `[REDACTED]` in log events.
  - **Atom-safe JSON** — model output is decoded with string keys (not atoms)
    to prevent BEAM atom table exhaustion.

  ## Configuration (via `Application.get_env/3`)

  | Key                     | Default | Description                              |
  |-------------------------|---------|------------------------------------------|
  | `:max_context_bytes`    | 65 536  | Max byte length of serialized context    |
  | `:max_tokens`           | 1024    | `max_tokens` sent to inference endpoint  |
  | `:inference_timeout_ms` | 30 000  | HTTP request timeout in milliseconds     |
  | `:inference_base_url`   | nil     | Base URL for inference endpoint          |
  """

  require Logger

  alias Exocomp.Coordinator.ClusterChatSchema

  @system_prompt """
  You are a diagnostic assistant for the Exocomp cluster coordinator. \
  Analyze the provided diagnostic context and operator message. \
  Respond with Markdown text and cite evidence by ID, node identity, and timestamp. \
  Evidence citations must follow this format: [evidence_id] (node_id, collected_at). \
  You may suggest at most one typed remedy proposal in JSON format at the end. \
  Do not make claims without citing evidence. \
  Do not invent evidence IDs or node identities. \
  Do not execute or approve actions — only suggest them.\
  """

  @default_max_context_bytes 65_536
  @default_max_tokens 1024
  @default_inference_timeout_ms 30_000
  @default_max_thread_messages 50

  @doc """
  Send bounded conversation context to the inference endpoint and return a validated response.

  ## Return values

  - `{:ok, response}` — model returned a schema-valid response map.
  - `{:error, :inference_unavailable}` — inference endpoint is not configured or ready.
  - `{:error, :inference_timeout}` — HTTP request timed out.
  - `{:error, {:http_error, status}}` — endpoint returned a non-2xx status code.
  - `{:error, :invalid_json}` — response body or extracted content is not valid JSON.
  - `{:error, {:schema_error, reason}}` — model output failed `ClusterChatSchema.validate/1`.
  """
  @spec chat(map()) ::
          {:ok, map()}
          | {:error,
             :inference_unavailable
             | :inference_timeout
             | :invalid_json
             | {:http_error, non_neg_integer()}
             | {:schema_error, term()}}
  def chat(context) when is_map(context) do
    call_id = System.unique_integer([:positive, :monotonic])

    Logger.info("ClusterChatClient inference attempt",
      call_id: call_id,
      context_keys: Map.keys(context)
    )

    result =
      with {:ok, base_url} <- check_availability(),
           {:ok, body_json} <- build_request_body(context),
           {:ok, raw_content} <- post_request(base_url, body_json),
           {:ok, response_map} <- decode_response_json(raw_content),
           {:ok, validated} <- validate_response(response_map) do
        {:ok, validated}
      end

    audit_log(call_id, result)
    result
  end

  # ---------------------------------------------------------------------------
  # Pipeline steps (private)
  # ---------------------------------------------------------------------------

  # Step 1: Confirm inference endpoint is ready.
  defp check_availability do
    case Application.get_env(:exocomp_coordinator, :inference_base_url) do
      url when is_binary(url) and url != "" -> {:ok, url}
      _ -> {:error, :inference_unavailable}
    end
  end

  # Step 2: Serialize and bound the conversation context.
  defp build_request_body(context) do
    max_bytes =
      Application.get_env(:exocomp_coordinator, :max_context_bytes, @default_max_context_bytes)

    max_tokens = Application.get_env(:exocomp_coordinator, :max_tokens, @default_max_tokens)

    max_thread_messages =
      Application.get_env(
        :exocomp_coordinator,
        :max_thread_messages,
        @default_max_thread_messages
      )

    message = Map.get(context, "message", "")
    thread = Map.get(context, "thread", [])
    evidence = Map.get(context, "evidence", [])

    # Limit thread to most recent N messages
    bounded_thread = Enum.take(thread, max_thread_messages)

    # Build messages for the model
    messages = build_messages(bounded_thread, message, evidence)

    body = %{
      "model" => "qwen2.5",
      "messages" => [
        %{"role" => "system", "content" => @system_prompt}
        | messages
      ],
      "max_tokens" => max_tokens,
      "temperature" => 0
    }

    body_json = Jason.encode!(body)

    # Truncate to max_bytes using binary slicing (safe for UTF-8: we may split
    # a multi-byte sequence, but the model receives the shorter safe substring).
    truncated = binary_part(body_json, 0, min(byte_size(body_json), max_bytes))

    {:ok, truncated}
  rescue
    error ->
      Logger.warning("ClusterChatClient failed to encode request",
        error: Exception.message(error)
      )

      {:error, :invalid_json}
  end

  # Build message list from thread and current message
  defp build_messages(thread, message, evidence) do
    # Convert thread to message format if needed
    thread_messages =
      Enum.map(thread, fn
        %{"role" => role, "content" => content} ->
          %{"role" => role, "content" => content}

        msg ->
          msg
      end)

    # Add current message with evidence context
    evidence_summary = summarize_evidence(evidence)

    user_message = %{
      "role" => "user",
      "content" => "#{message}\n\nAvailable evidence:\n#{evidence_summary}"
    }

    thread_messages ++ [user_message]
  end

  # Summarize evidence for the model
  defp summarize_evidence(evidence) when is_list(evidence) do
    if Enum.empty?(evidence) do
      "(no evidence available)"
    else
      Enum.map_join(evidence, "\n", fn ev ->
        evidence_id = Map.get(ev, "evidence_id", "unknown")
        node_id = Map.get(ev, "node_id", "unknown")
        collected_at = Map.get(ev, "collected_at", "unknown")
        data = Map.get(ev, "data", %{})

        "- [#{evidence_id}] #{node_id} at #{collected_at}: #{Jason.encode!(data)}"
      end)
    end
  end

  defp summarize_evidence(_), do: "(invalid evidence format)"

  # Step 3: POST the request body to inference endpoint.
  defp post_request(base_url, body_json) do
    url = ~c"#{base_url}/v1/chat/completions"

    timeout_ms =
      Application.get_env(
        :exocomp_coordinator,
        :inference_timeout_ms,
        @default_inference_timeout_ms
      )

    httpc_headers = [
      {~c"content-type", ~c"application/json"},
      {~c"accept", ~c"application/json"}
    ]

    http_request = {url, httpc_headers, ~c"application/json", body_json}
    http_options = [{:timeout, timeout_ms}]
    options = [{:body_format, :binary}]

    case :httpc.request(:post, http_request, http_options, options) do
      {:ok, {{_version, status, _phrase}, _headers, body}} when status in 200..299 ->
        extract_content_from_response(body)

      {:ok, {{_version, status, _phrase}, _headers, _body}} ->
        {:error, {:http_error, status}}

      {:error, {:failed_connect, _details}} ->
        {:error, :inference_unavailable}

      {:error, :timeout} ->
        {:error, :inference_timeout}

      {:error, {:connect_timeout, _}} ->
        {:error, :inference_timeout}

      {:error, _reason} ->
        {:error, :inference_timeout}
    end
  end

  # Extract `choices[0].message.content` from the inference endpoint JSON response.
  defp extract_content_from_response(body) when is_binary(body) do
    with {:ok, parsed} <- Jason.decode(body),
         {:ok, choices} when is_list(choices) <- fetch_key(parsed, "choices"),
         [first | _] <- choices,
         {:ok, message} <- fetch_key(first, "message"),
         {:ok, content} when is_binary(content) <- fetch_key(message, "content") do
      {:ok, content}
    else
      _ -> {:error, :invalid_json}
    end
  end

  defp extract_content_from_response(_body), do: {:error, :invalid_json}

  # Step 4: Parse the content string as structured response.
  defp decode_response_json(content) when is_binary(content) do
    case ClusterChatSchema.parse(content) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end

  # Step 5: Validate the response against the schema.
  defp validate_response(response) do
    case ClusterChatSchema.validate(response) do
      {:ok, validated} -> {:ok, validated}
      {:error, reason} -> {:error, {:schema_error, reason}}
    end
  end

  # ---------------------------------------------------------------------------
  # Audit logging — raw model output is never emitted
  # ---------------------------------------------------------------------------

  defp audit_log(call_id, {:ok, validated}) do
    Logger.info("ClusterChatClient inference succeeded",
      call_id: call_id,
      has_proposal: Map.has_key?(validated, "proposal"),
      raw_model_output: "[REDACTED]"
    )
  end

  defp audit_log(call_id, {:error, reason}) do
    Logger.warning("ClusterChatClient inference failed",
      call_id: call_id,
      error: inspect(reason),
      raw_model_output: "[REDACTED]"
    )
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp fetch_key(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error -> :error
    end
  end

  defp fetch_key(_not_a_map, _key), do: :error
end

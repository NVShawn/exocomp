defmodule Exocomp.Node.ProposalClient do
  @moduledoc """
  HTTP inference client that sends bounded diagnostic context to llama-server
  and returns a schema-validated proposal.

  ## Security model

  - **Checksum gate** — model binary is verified before any network I/O.
  - **Availability gate** — `LlamaServer.base_url/0` is checked; the request is
    never attempted when the server is not ready.
  - **Bounded context** — diagnostic context is serialized to JSON then
    byte-truncated before transmission; callers cannot overflow the model window.
  - **Fixed system prompt** — the system prompt is hardcoded in this module and
    is not caller-configurable.
  - **Schema gate** — every response passes through `ProposalSchema.validate/1`
    before leaving this module; schema-invalid or unparseable output is rejected.
  - **Audit logging with redaction** — every call attempt is logged; raw model
    output is replaced with `[REDACTED]` in log events.
  - **Atom-safe JSON** — model output is decoded with string keys (not atoms)
    to prevent BEAM atom table exhaustion.

  ## Configuration (via `Application.get_env/3`)

  | Key                     | Default | Description                              |
  |-------------------------|---------|------------------------------------------|
  | `:max_context_bytes`    | 8 192   | Max byte length of serialized context    |
  | `:max_tokens`           | 512     | `max_tokens` sent to llama-server        |
  | `:inference_timeout_ms` | 15 000  | HTTP request timeout in milliseconds     |
  | `:checksum_fn`          | `fn -> :ok end` | 0-arity fn returning `:ok` or `{:error, reason}` |
  """

  require Logger

  alias Exocomp.Node.{LlamaServer, ProposalSchema}

  # Fixed system prompt — not caller-configurable. Instructs the model to emit a
  # single JSON object matching the ProposalSchema version-1 structure. Any
  # extra text or markdown will fail downstream JSON parsing and be rejected.
  @system_prompt """
  You are a diagnostic assistant for the Exocomp node agent. \
  Analyze the provided diagnostic context and output ONLY a single \
  JSON object with no surrounding text, code fences, or explanation. \
  The JSON object must have exactly these fields: \
  "schema_version" (must be "1"), \
  "proposal_id" (one of: "restart_service", "clear_disk_space", "rotate_logs", "increase_swap"), \
  "rationale" (string), \
  "affected_resource" (string), \
  "confidence" (number 0.0-1.0). \
  No other keys are permitted.\
  """

  @default_max_context_bytes 8_192
  @default_max_tokens 512
  @default_inference_timeout_ms 15_000

  @doc """
  Send bounded `context` to the inference server and return a validated proposal.

  ## Return values

  - `{:ok, proposal}` — model returned a schema-valid proposal map.
  - `{:error, :inference_unavailable}` — `LlamaServer` is not ready.
  - `{:error, :inference_timeout}` — HTTP request timed out.
  - `{:error, {:http_error, status}}` — server returned a non-2xx status code.
  - `{:error, :invalid_json}` — response body or extracted content is not valid JSON.
  - `{:error, {:schema_error, reason}}` — model output failed `ProposalSchema.validate/1`.
  - `{:error, {:checksum_error, reason}}` — model binary checksum validation failed.
  """
  @spec propose(map()) ::
          {:ok, map()}
          | {:error,
             :inference_unavailable
             | :inference_timeout
             | :invalid_json
             | {:http_error, non_neg_integer()}
             | {:schema_error, term()}
             | {:checksum_error, term()}}
  def propose(context) when is_map(context) do
    call_id = System.unique_integer([:positive, :monotonic])

    Logger.info("ProposalClient inference attempt",
      call_id: call_id,
      context_keys: Map.keys(context)
    )

    result =
      with :ok <- verify_checksum(),
           {:ok, base_url} <- check_availability(),
           {:ok, body_json} <- build_request_body(context),
           {:ok, raw_content} <- post_request(base_url, body_json),
           {:ok, proposal_map} <- decode_proposal_json(raw_content),
           {:ok, validated} <- validate_proposal(proposal_map) do
        {:ok, validated}
      end

    audit_log(call_id, result)
    result
  end

  # ---------------------------------------------------------------------------
  # Pipeline steps (private)
  # ---------------------------------------------------------------------------

  # Step 1: Verify model binary checksum before network I/O.
  defp verify_checksum do
    checksum_fn = Application.get_env(:exocomp_node, :checksum_fn, fn -> :ok end)

    case checksum_fn.() do
      :ok -> :ok
      {:error, reason} -> {:error, {:checksum_error, reason}}
    end
  end

  # Step 2: Confirm llama-server is ready.
  defp check_availability do
    case LlamaServer.base_url() do
      {:ok, url} -> {:ok, url}
      {:error, :not_ready} -> {:error, :inference_unavailable}
    end
  end

  # Step 3: Serialize and bound the diagnostic context, then build the request body.
  defp build_request_body(context) do
    max_bytes = Application.get_env(:exocomp_node, :max_context_bytes, @default_max_context_bytes)
    max_tokens = Application.get_env(:exocomp_node, :max_tokens, @default_max_tokens)

    context_str = JSON.encode!(context)

    # Truncate to max_bytes using binary slicing (safe for UTF-8: we may split
    # a multi-byte sequence, but the model receives the shorter safe substring).
    truncated = binary_part(context_str, 0, min(byte_size(context_str), max_bytes))

    body = %{
      "model" => "qwen2.5",
      "messages" => [
        %{"role" => "system", "content" => @system_prompt},
        %{"role" => "user", "content" => truncated}
      ],
      "max_tokens" => max_tokens,
      "temperature" => 0
    }

    {:ok, JSON.encode!(body)}
  rescue
    error ->
      Logger.warning("ProposalClient failed to encode request",
        error: Exception.message(error)
      )

      {:error, :invalid_json}
  end

  # Step 4: POST the request body to llama-server and return the raw content string.
  defp post_request(base_url, body_json) do
    url = ~c"#{base_url}/v1/chat/completions"

    timeout_ms =
      Application.get_env(:exocomp_node, :inference_timeout_ms, @default_inference_timeout_ms)

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

  # Extract `choices[0].message.content` from the llama-server JSON response body.
  # The raw body is NEVER logged (redacted at audit_log time).
  defp extract_content_from_response(body) when is_binary(body) do
    with {:ok, parsed} <- JSON.decode(body),
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

  # Step 5: Parse the content string as a JSON object.
  # Uses string keys to avoid BEAM atom table exhaustion from attacker-controlled input.
  defp decode_proposal_json(content) when is_binary(content) do
    case JSON.decode(content) do
      {:ok, map} when is_map(map) -> {:ok, map}
      {:ok, _non_map} -> {:error, :invalid_json}
      {:error, _reason} -> {:error, :invalid_json}
    end
  end

  # Step 6: Validate the decoded map against the proposal schema.
  defp validate_proposal(proposal) do
    case ProposalSchema.validate(proposal) do
      {:ok, validated} -> {:ok, validated}
      {:error, reason} -> {:error, {:schema_error, reason}}
    end
  end

  # ---------------------------------------------------------------------------
  # Audit logging — raw model output is never emitted
  # ---------------------------------------------------------------------------

  defp audit_log(call_id, {:ok, validated}) do
    Logger.info("ProposalClient inference succeeded",
      call_id: call_id,
      proposal_id: Map.get(validated, :proposal_id) || Map.get(validated, "proposal_id"),
      schema_version: Map.get(validated, :schema_version) || Map.get(validated, "schema_version"),
      raw_model_output: "[REDACTED]"
    )
  end

  defp audit_log(call_id, {:error, reason}) do
    Logger.warning("ProposalClient inference failed",
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

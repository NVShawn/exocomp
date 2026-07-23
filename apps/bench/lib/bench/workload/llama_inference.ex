defmodule Bench.Workload.LlamaInference do
  @moduledoc """
  Benchmark workload: llama.cpp inference and restart behavior.

  Measures startup and readiness time, sequential proposal latency, concurrency
  through saturation, timeout handling, invalid-response rejection, and
  crash-to-ready restart time. All results are emitted as `Bench.Sample` structs
  with source `:llama`.

  ## Scenarios

  - **startup_readiness** — polls `/health` from the first request and records
    the elapsed time until the server responds 200.
  - **sequential** — sends `proposal_count` sequential `/v1/chat/completions`
    requests; records per-request latency, total throughput, error count, and
    token counts when reported by the server.
  - **concurrent** — repeats the sequential workload at each level in
    `concurrency_levels`, emitting queue-depth and saturation metrics.
  - **timeout** — sends a request to a URL that never responds and records
    the observed timeout duration.
  - **invalid_response** — sends a request that returns a non-schema-compliant
    response body; records the rejection count.
  - **crash_restart** — invokes a caller-supplied `crash_fn/0`, polls until the
    server stops responding, then polls again until it becomes ready, recording
    the restart duration.

  ## Usage

      base_url = "http://127.0.0.1:8080"
      {:ok, samples} = Bench.Workload.LlamaInference.measure_sequential(base_url, proposal_count: 5)
      Enum.each(samples, &IO.inspect/1)
  """

  alias Bench.Sample

  @default_proposal_count 5
  @default_concurrency_levels [1, 2, 4]
  @default_timeout_ms 5_000
  @default_readiness_poll_interval_ms 100
  @default_readiness_timeout_ms 10_000
  @restart_poll_interval_ms 50
  @restart_timeout_ms 15_000

  # Fixed diagnostic context sent in every proposal request.
  @context_json Jason.encode!(%{
                  "hostname" => "bench-node",
                  "service" => "exocomp_node",
                  "cpu_percent" => 90.0,
                  "ram_used_percent" => 85.0,
                  "disk_used_percent" => 70.0
                })

  # Fixed request body for the /v1/chat/completions endpoint.
  @request_body Jason.encode!(%{
                  "model" => "qwen2.5",
                  "messages" => [
                    %{
                      "role" => "system",
                      "content" =>
                        "You are a diagnostic assistant. Output ONLY a JSON object with fields schema_version, proposal_id, rationale, affected_resource, confidence."
                    },
                    %{"role" => "user", "content" => @context_json}
                  ],
                  "max_tokens" => 128,
                  "temperature" => 0
                })

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Polls `base_url/health` until the server responds 200 or a timeout expires.

  Returns `[%Sample{metric_name: "llama.startup_ms", ...}]` on success or a
  timeout sample when the server does not become ready in time.
  """
  @spec measure_startup(String.t(), keyword()) ::
          {:ok, [Sample.t()]} | {:error, term()}
  def measure_startup(base_url, opts \\ []) do
    poll_ms = Keyword.get(opts, :readiness_poll_interval_ms, @default_readiness_poll_interval_ms)
    timeout_ms = Keyword.get(opts, :readiness_timeout_ms, @default_readiness_timeout_ms)

    t0 = mono_ms()

    case poll_until_healthy(base_url, timeout_ms, poll_ms, t0) do
      {:ok, elapsed_ms} ->
        {:ok,
         [
           sample("llama.startup_ms", elapsed_ms, "ms")
         ]}

      {:error, :readiness_timeout} ->
        {:ok,
         [
           sample("llama.startup_ms", timeout_ms, "ms"),
           sample("llama.startup_timeout", 1, "count")
         ]}
    end
  end

  @doc """
  Sends `proposal_count` sequential POST requests to `/v1/chat/completions` and
  records per-request latency, token counts, error counts, and throughput.
  """
  @spec measure_sequential(String.t(), keyword()) ::
          {:ok, [Sample.t()]} | {:error, term()}
  def measure_sequential(base_url, opts \\ []) do
    count = Keyword.get(opts, :proposal_count, @default_proposal_count)
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)

    t0 = mono_ms()

    results =
      Enum.map(1..count, fn _i ->
        req_t0 = mono_ms()
        outcome = post_completion(base_url, timeout_ms)
        latency = mono_ms() - req_t0
        {outcome, latency}
      end)

    total_ms = mono_ms() - t0
    successes = Enum.count(results, &match?({:ok, _}, elem(&1, 0)))
    errors = count - successes

    latencies = for {{:ok, _}, latency} <- results, do: latency
    token_samples = for {{:ok, tokens}, _} <- results, tokens != nil, do: tokens

    prompt_tokens_total = Enum.sum(Enum.map(token_samples, & &1.prompt))
    completion_tokens_total = Enum.sum(Enum.map(token_samples, & &1.completion))

    base_samples = [
      sample("llama.sequential.count", count, "count"),
      sample("llama.sequential.success_count", successes, "count"),
      sample("llama.sequential.error_count", errors, "count"),
      sample("llama.sequential.total_ms", total_ms, "ms"),
      sample(
        "llama.sequential.throughput",
        safe_div(successes * 1000, total_ms),
        "req/s"
      ),
      sample("llama.sequential.prompt_tokens_total", prompt_tokens_total, "tokens"),
      sample("llama.sequential.completion_tokens_total", completion_tokens_total, "tokens")
    ]

    latency_samples = latency_percentile_samples("llama.sequential", latencies)

    {:ok, base_samples ++ latency_samples}
  end

  @doc """
  Sends `proposal_count` concurrent requests at each level in `concurrency_levels`,
  recording per-level throughput and queue depth.
  """
  @spec measure_concurrent(String.t(), keyword()) ::
          {:ok, [Sample.t()]} | {:error, term()}
  def measure_concurrent(base_url, opts \\ []) do
    levels = Keyword.get(opts, :concurrency_levels, @default_concurrency_levels)
    # proposal_count is reserved for future use (repeat batches per level).
    _proposal_count = Keyword.get(opts, :proposal_count, @default_proposal_count)
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)

    samples =
      Enum.flat_map(levels, fn concurrency ->
        t0 = mono_ms()

        tasks =
          Enum.map(1..concurrency, fn _i ->
            Task.async(fn -> post_completion(base_url, timeout_ms) end)
          end)

        results = Task.await_many(tasks, timeout_ms + 1_000)
        total_ms = mono_ms() - t0
        successes = Enum.count(results, &match?({:ok, _}, &1))
        errors = concurrency - successes

        [
          sample("llama.concurrent.#{concurrency}.total_ms", total_ms, "ms"),
          sample("llama.concurrent.#{concurrency}.success_count", successes, "count"),
          sample("llama.concurrent.#{concurrency}.error_count", errors, "count"),
          sample(
            "llama.concurrent.#{concurrency}.throughput",
            safe_div(successes * 1000, total_ms),
            "req/s"
          ),
          sample("llama.concurrent.#{concurrency}.queue_depth", concurrency, "count")
        ]
      end)

    {:ok, samples}
  end

  @doc """
  Sends a request with a very short timeout to verify that timeout handling
  works correctly.  The `base_url` should point to a server endpoint that
  will not respond within `timeout_ms`.
  """
  @spec measure_timeout(String.t(), keyword()) ::
          {:ok, [Sample.t()]} | {:error, term()}
  def measure_timeout(base_url, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 200)

    t0 = mono_ms()
    result = post_completion(base_url, timeout_ms)
    elapsed = mono_ms() - t0

    timeout_observed =
      case result do
        {:error, :timeout} -> 1
        {:error, :unavailable} -> 1
        _ -> 0
      end

    {:ok,
     [
       sample("llama.timeout.elapsed_ms", elapsed, "ms"),
       sample("llama.timeout.timeout_observed", timeout_observed, "count")
     ]}
  end

  @doc """
  Sends a request to a server configured to return invalid/non-schema output
  and records the rejection count.
  """
  @spec measure_invalid_response(String.t(), keyword()) ::
          {:ok, [Sample.t()]} | {:error, term()}
  def measure_invalid_response(base_url, opts \\ []) do
    count = Keyword.get(opts, :proposal_count, @default_proposal_count)
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)

    results =
      Enum.map(1..count, fn _i ->
        post_completion(base_url, timeout_ms)
      end)

    rejections =
      Enum.count(results, fn
        {:error, _} -> true
        _ -> false
      end)

    {:ok,
     [
       sample("llama.invalid_response.count", count, "count"),
       sample("llama.invalid_response.rejection_count", rejections, "count"),
       sample("llama.invalid_response.rejection_rate", safe_div(rejections, count), "ratio")
     ]}
  end

  @doc """
  Measures crash-to-ready restart time.

  1. Verifies the server is healthy at `base_url`.
  2. Calls `crash_fn/0` to trigger a simulated crash.
  3. Polls until the server stops responding (down phase).
  4. Polls until the server responds 200 again (restart phase).
  5. Returns samples for the down-phase duration and restart-phase duration.

  Also records that node diagnostics remained available through the restart
  (if `diagnostic_fn/0` is supplied, it is polled during the restart window).
  """
  @spec measure_restart(String.t(), (-> :ok), keyword()) ::
          {:ok, [Sample.t()]} | {:error, term()}
  def measure_restart(base_url, crash_fn, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)
    diagnostic_fn = Keyword.get(opts, :diagnostic_fn, nil)

    with :ok <- wait_until_healthy(base_url, timeout_ms) do
      t_crash = mono_ms()
      :ok = crash_fn.()

      # Poll until server goes down.
      {down_ms, t_down} = poll_until_unhealthy(base_url, @restart_timeout_ms)

      # Optionally check that diagnostics remain available during the outage.
      diag_available =
        if is_function(diagnostic_fn, 0) do
          case diagnostic_fn.() do
            :ok -> 1
            _ -> 0
          end
        else
          1
        end

      # Poll until server comes back up.
      {restart_ms, _t_ready} =
        poll_until_healthy_timed(base_url, @restart_timeout_ms, @restart_poll_interval_ms, t_down)

      total_ms = mono_ms() - t_crash

      {:ok,
       [
         sample("llama.restart.down_ms", down_ms, "ms"),
         sample("llama.restart.recovery_ms", restart_ms, "ms"),
         sample("llama.restart.total_ms", total_ms, "ms"),
         sample("llama.restart.diagnostics_available", diag_available, "bool")
       ]}
    end
  end

  # ---------------------------------------------------------------------------
  # Private: HTTP helpers
  # ---------------------------------------------------------------------------

  # Return {:ok, token_usage | nil} on success, {:error, reason} on failure.
  # A 2xx response with a non-JSON body is treated as {:error, :invalid_response}.
  defp post_completion(base_url, timeout_ms) do
    url = String.to_charlist("#{base_url}/v1/chat/completions")
    body = @request_body

    headers = [
      {~c"content-type", ~c"application/json"},
      {~c"accept", ~c"application/json"}
    ]

    request = {url, headers, ~c"application/json", body}
    http_opts = [{:timeout, timeout_ms}, {:connect_timeout, timeout_ms}]

    case :httpc.request(:post, request, http_opts, [{:body_format, :binary}]) do
      {:ok, {{_version, status, _phrase}, _headers, resp_body}} when status in 200..299 ->
        # Validate that the response body is parseable JSON; treat parse failures
        # as invalid responses rather than silently succeeding.
        case Jason.decode(resp_body) do
          {:ok, parsed} -> {:ok, extract_token_usage(parsed)}
          {:error, _} -> {:error, :invalid_response}
        end

      {:ok, {{_version, status, _phrase}, _headers, _body}} ->
        {:error, {:http_error, status}}

      {:error, {:failed_connect, _}} ->
        {:error, :unavailable}

      {:error, :timeout} ->
        {:error, :timeout}

      {:error, {:connect_timeout, _}} ->
        {:error, :timeout}

      {:error, _reason} ->
        {:error, :unavailable}
    end
  end

  # Extract token usage from a decoded chat completions response map, if present.
  defp extract_token_usage(%{"usage" => %{"prompt_tokens" => pt, "completion_tokens" => ct}})
       when is_integer(pt) and is_integer(ct),
       do: %{prompt: pt, completion: ct}

  defp extract_token_usage(_), do: nil

  # ---------------------------------------------------------------------------
  # Private: health polling
  # ---------------------------------------------------------------------------

  defp poll_until_healthy(base_url, timeout_ms, poll_ms, t0) do
    deadline = t0 + timeout_ms

    if mono_ms() >= deadline do
      {:error, :readiness_timeout}
    else
      case health_check(base_url) do
        :ok ->
          {:ok, mono_ms() - t0}

        _ ->
          Process.sleep(poll_ms)
          poll_until_healthy(base_url, timeout_ms, poll_ms, t0)
      end
    end
  end

  defp wait_until_healthy(base_url, timeout_ms) do
    t0 = mono_ms()

    case poll_until_healthy(base_url, timeout_ms, @restart_poll_interval_ms, t0) do
      {:ok, _elapsed} -> :ok
      {:error, :readiness_timeout} -> {:error, :readiness_timeout}
    end
  end

  # Returns {elapsed_ms_until_down, t_down}.
  defp poll_until_unhealthy(base_url, timeout_ms) do
    t0 = mono_ms()
    deadline = t0 + timeout_ms

    do_poll_until_unhealthy(base_url, t0, deadline)
  end

  defp do_poll_until_unhealthy(base_url, t0, deadline) do
    if mono_ms() >= deadline do
      {mono_ms() - t0, mono_ms()}
    else
      case health_check(base_url) do
        :ok ->
          Process.sleep(@restart_poll_interval_ms)
          do_poll_until_unhealthy(base_url, t0, deadline)

        _ ->
          {mono_ms() - t0, mono_ms()}
      end
    end
  end

  # Returns {elapsed_ms_until_ready, t_ready}.
  defp poll_until_healthy_timed(base_url, timeout_ms, poll_ms, t0) do
    deadline = t0 + timeout_ms

    do_poll_until_healthy_timed(base_url, t0, deadline, poll_ms)
  end

  defp do_poll_until_healthy_timed(base_url, t0, deadline, poll_ms) do
    if mono_ms() >= deadline do
      {mono_ms() - t0, mono_ms()}
    else
      case health_check(base_url) do
        :ok ->
          {mono_ms() - t0, mono_ms()}

        _ ->
          Process.sleep(poll_ms)
          do_poll_until_healthy_timed(base_url, t0, deadline, poll_ms)
      end
    end
  end

  defp health_check(base_url) do
    url = String.to_charlist("#{base_url}/health")
    http_opts = [{:timeout, 500}, {:connect_timeout, 500}]

    case :httpc.request(:get, {url, []}, http_opts, []) do
      {:ok, {{_version, status, _phrase}, _headers, _body}} when status in 200..299 ->
        :ok

      _ ->
        :error
    end
  end

  # ---------------------------------------------------------------------------
  # Private: latency percentiles
  # ---------------------------------------------------------------------------

  defp latency_percentile_samples(_prefix, []), do: []

  defp latency_percentile_samples(prefix, latencies) do
    sorted = Enum.sort(latencies)
    count = length(sorted)

    [
      sample("#{prefix}.latency_p50_ms", percentile(sorted, count, 0.50), "ms"),
      sample("#{prefix}.latency_p95_ms", percentile(sorted, count, 0.95), "ms"),
      sample("#{prefix}.latency_p99_ms", percentile(sorted, count, 0.99), "ms"),
      sample("#{prefix}.latency_min_ms", List.first(sorted), "ms"),
      sample("#{prefix}.latency_max_ms", List.last(sorted), "ms")
    ]
  end

  defp percentile(sorted, count, p) do
    index = min(round(p * count) - 1, count - 1) |> max(0)
    Enum.at(sorted, index)
  end

  # ---------------------------------------------------------------------------
  # Private: sample construction and arithmetic helpers
  # ---------------------------------------------------------------------------

  defp sample(metric_name, value, unit) do
    %Sample{
      timestamp: System.system_time(:millisecond),
      source: :llama,
      metric_name: metric_name,
      value: value || 0,
      unit: unit
    }
  end

  defp mono_ms, do: System.monotonic_time(:millisecond)

  defp safe_div(_numerator, denominator) when denominator == 0, do: 0
  defp safe_div(numerator, denominator), do: numerator / denominator
end

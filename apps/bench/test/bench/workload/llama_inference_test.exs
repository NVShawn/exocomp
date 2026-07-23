defmodule Bench.Workload.LlamaInferenceTest do
  @moduledoc """
  Focused ExUnit tests for `Bench.Workload.LlamaInference`.

  All scenarios run against an in-process `Bench.Test.FakeLlamaServer` so that
  no real llama-server binary is required.  Tests are tagged `@moduletag
  :bench_llama` so that `make bench-llama-short` can target them selectively.
  """

  use ExUnit.Case, async: true

  @moduletag :bench_llama

  alias Bench.Sample
  alias Bench.Workload.LlamaInference
  alias Bench.Test.FakeLlamaServer

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp start_fake(opts) do
    start_supervised!({FakeLlamaServer, opts})
  end

  defp base_url(fake), do: FakeLlamaServer.base_url(fake)

  defp find_sample(samples, metric_name) do
    Enum.find(samples, &(&1.metric_name == metric_name))
  end

  defp all_samples?(result) do
    match?({:ok, [%Sample{} | _]}, result) or match?({:ok, [%Sample{}]}, result)
  end

  defp sample_value(samples, metric_name) do
    case find_sample(samples, metric_name) do
      %Sample{value: v} -> v
      nil -> nil
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 1: Model startup and readiness
  # ---------------------------------------------------------------------------

  describe "measure_startup/2" do
    test "returns startup_ms sample when server is immediately healthy" do
      fake = start_fake(health_mode: :ok)
      url = base_url(fake)

      assert {:ok, samples} = LlamaInference.measure_startup(url, readiness_timeout_ms: 2_000)
      assert is_list(samples)
      assert length(samples) >= 1

      startup = find_sample(samples, "llama.startup_ms")
      assert %Sample{source: :llama, unit: "ms"} = startup
      assert startup.value >= 0
    end

    test "returns startup_ms and startup_timeout samples when server never becomes healthy" do
      fake = start_fake(health_mode: :error_503)
      url = base_url(fake)

      assert {:ok, samples} =
               LlamaInference.measure_startup(url,
                 readiness_poll_interval_ms: 20,
                 readiness_timeout_ms: 100
               )

      assert find_sample(samples, "llama.startup_ms") != nil
      timeout_sample = find_sample(samples, "llama.startup_timeout")
      assert %Sample{value: 1} = timeout_sample
    end

    test "sample has correct source and unit" do
      fake = start_fake(health_mode: :ok)
      url = base_url(fake)

      assert {:ok, samples} = LlamaInference.measure_startup(url)

      for s <- samples do
        assert s.source == :llama
        assert is_integer(s.timestamp)
        assert is_binary(s.metric_name)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 2: Sequential proposal latency
  # ---------------------------------------------------------------------------

  describe "measure_sequential/2" do
    test "returns latency percentiles and throughput for successful requests" do
      fake = start_fake(completions_mode: :valid_json)
      url = base_url(fake)

      assert {:ok, samples} = LlamaInference.measure_sequential(url, proposal_count: 5)
      assert all_samples?({:ok, samples})

      assert sample_value(samples, "llama.sequential.count") == 5
      assert sample_value(samples, "llama.sequential.success_count") == 5
      assert sample_value(samples, "llama.sequential.error_count") == 0

      assert find_sample(samples, "llama.sequential.latency_p50_ms") != nil
      assert find_sample(samples, "llama.sequential.latency_p95_ms") != nil
      assert find_sample(samples, "llama.sequential.latency_p99_ms") != nil
      assert find_sample(samples, "llama.sequential.latency_min_ms") != nil
      assert find_sample(samples, "llama.sequential.latency_max_ms") != nil
    end

    test "records token counts when server includes usage stats" do
      fake = start_fake(completions_mode: :valid_json)
      url = base_url(fake)

      assert {:ok, samples} = LlamaInference.measure_sequential(url, proposal_count: 3)

      # FakeLlamaServer returns prompt_tokens: 42, completion_tokens: 64 per request.
      assert sample_value(samples, "llama.sequential.prompt_tokens_total") == 3 * 42
      assert sample_value(samples, "llama.sequential.completion_tokens_total") == 3 * 64
    end

    test "records errors when server returns 500" do
      fake = start_fake(completions_mode: :error_500)
      url = base_url(fake)

      assert {:ok, samples} = LlamaInference.measure_sequential(url, proposal_count: 3)

      assert sample_value(samples, "llama.sequential.error_count") == 3
      assert sample_value(samples, "llama.sequential.success_count") == 0
    end

    test "handles unavailable server gracefully" do
      # Point at a port where nothing is listening.
      url = "http://127.0.0.1:19999"

      assert {:ok, samples} =
               LlamaInference.measure_sequential(url,
                 proposal_count: 2,
                 timeout_ms: 300
               )

      assert sample_value(samples, "llama.sequential.error_count") == 2
    end

    test "throughput unit is req/s" do
      fake = start_fake(completions_mode: :valid_json)
      url = base_url(fake)

      assert {:ok, samples} = LlamaInference.measure_sequential(url, proposal_count: 2)
      throughput = find_sample(samples, "llama.sequential.throughput")
      assert %Sample{unit: "req/s"} = throughput
      assert throughput.value >= 0
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 3: Increasing concurrency through saturation
  # ---------------------------------------------------------------------------

  describe "measure_concurrent/2" do
    test "returns per-concurrency-level samples" do
      fake = start_fake(completions_mode: :valid_json)
      url = base_url(fake)

      assert {:ok, samples} =
               LlamaInference.measure_concurrent(url,
                 concurrency_levels: [1, 2],
                 proposal_count: 2,
                 timeout_ms: 2_000
               )

      assert find_sample(samples, "llama.concurrent.1.success_count") != nil
      assert find_sample(samples, "llama.concurrent.2.success_count") != nil
    end

    test "queue depth equals concurrency level" do
      fake = start_fake(completions_mode: :valid_json)
      url = base_url(fake)

      assert {:ok, samples} =
               LlamaInference.measure_concurrent(url,
                 concurrency_levels: [3],
                 proposal_count: 1,
                 timeout_ms: 2_000
               )

      assert sample_value(samples, "llama.concurrent.3.queue_depth") == 3
    end

    test "records errors when server returns 500 under concurrency" do
      fake = start_fake(completions_mode: :error_500)
      url = base_url(fake)

      assert {:ok, samples} =
               LlamaInference.measure_concurrent(url,
                 concurrency_levels: [2],
                 proposal_count: 1,
                 timeout_ms: 1_000
               )

      assert sample_value(samples, "llama.concurrent.2.error_count") == 2
      assert sample_value(samples, "llama.concurrent.2.success_count") == 0
    end

    test "all concurrent samples have correct source" do
      fake = start_fake(completions_mode: :valid_json)
      url = base_url(fake)

      assert {:ok, samples} =
               LlamaInference.measure_concurrent(url,
                 concurrency_levels: [1],
                 proposal_count: 1,
                 timeout_ms: 2_000
               )

      for s <- samples do
        assert s.source == :llama
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 4: Timeout behavior
  # ---------------------------------------------------------------------------

  describe "measure_timeout/2" do
    @tag timeout: 10_000
    test "detects that a non-responding endpoint triggers timeout" do
      fake = start_fake(completions_mode: :timeout)
      url = base_url(fake)

      # Use a very short timeout so the test completes quickly.
      assert {:ok, samples} = LlamaInference.measure_timeout(url, timeout_ms: 300)

      timeout_s = find_sample(samples, "llama.timeout.timeout_observed")
      assert %Sample{value: 1} = timeout_s

      elapsed_s = find_sample(samples, "llama.timeout.elapsed_ms")
      assert elapsed_s.value >= 0
    end

    @tag timeout: 10_000
    test "does not mark a timeout when server responds normally" do
      fake = start_fake(completions_mode: :valid_json)
      url = base_url(fake)

      assert {:ok, samples} = LlamaInference.measure_timeout(url, timeout_ms: 2_000)

      timeout_s = find_sample(samples, "llama.timeout.timeout_observed")
      assert %Sample{value: 0} = timeout_s
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 5: Invalid response handling
  # ---------------------------------------------------------------------------

  describe "measure_invalid_response/2" do
    test "records all requests as rejected when server returns invalid JSON" do
      fake = start_fake(completions_mode: :invalid_json)
      url = base_url(fake)

      assert {:ok, samples} =
               LlamaInference.measure_invalid_response(url,
                 proposal_count: 3,
                 timeout_ms: 2_000
               )

      assert sample_value(samples, "llama.invalid_response.count") == 3
      assert sample_value(samples, "llama.invalid_response.rejection_count") == 3
      rate = find_sample(samples, "llama.invalid_response.rejection_rate")
      assert %Sample{value: 1.0} = rate
    end

    test "records zero rejections when server returns valid responses" do
      fake = start_fake(completions_mode: :valid_json)
      url = base_url(fake)

      assert {:ok, samples} =
               LlamaInference.measure_invalid_response(url,
                 proposal_count: 3,
                 timeout_ms: 2_000
               )

      assert sample_value(samples, "llama.invalid_response.rejection_count") == 0
    end

    test "records HTTP 500 responses as rejected" do
      fake = start_fake(completions_mode: :error_500)
      url = base_url(fake)

      assert {:ok, samples} =
               LlamaInference.measure_invalid_response(url,
                 proposal_count: 2,
                 timeout_ms: 2_000
               )

      assert sample_value(samples, "llama.invalid_response.rejection_count") == 2
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 6: Crash/restart recovery time
  # ---------------------------------------------------------------------------

  describe "measure_restart/3" do
    @tag timeout: 10_000
    test "measures down time and recovery time after a simulated crash" do
      fake = start_fake(health_mode: :ok)
      url = base_url(fake)

      # The crash_fn switches health to :error_503, then after a short delay
      # restores it to :ok (simulating a self-healing restart).
      crash_fn = fn ->
        FakeLlamaServer.set_health_mode(fake, :error_503)

        spawn(fn ->
          Process.sleep(200)
          FakeLlamaServer.set_health_mode(fake, :ok)
        end)

        :ok
      end

      assert {:ok, samples} = LlamaInference.measure_restart(url, crash_fn)

      assert find_sample(samples, "llama.restart.down_ms") != nil
      assert find_sample(samples, "llama.restart.recovery_ms") != nil
      assert find_sample(samples, "llama.restart.total_ms") != nil

      total = find_sample(samples, "llama.restart.total_ms")
      assert total.value >= 0
    end

    @tag timeout: 10_000
    test "records that node diagnostics remain available during restart" do
      fake = start_fake(health_mode: :ok)
      url = base_url(fake)

      # diagnostic_fn returns :ok (diagnostics available during outage).
      diagnostic_fn = fn -> :ok end

      crash_fn = fn ->
        FakeLlamaServer.set_health_mode(fake, :error_503)

        spawn(fn ->
          Process.sleep(150)
          FakeLlamaServer.set_health_mode(fake, :ok)
        end)

        :ok
      end

      assert {:ok, samples} =
               LlamaInference.measure_restart(url, crash_fn, diagnostic_fn: diagnostic_fn)

      diag_s = find_sample(samples, "llama.restart.diagnostics_available")
      assert %Sample{value: 1} = diag_s
    end

    @tag timeout: 10_000
    test "all restart samples have source :llama and integer timestamps" do
      fake = start_fake(health_mode: :ok)
      url = base_url(fake)

      crash_fn = fn ->
        FakeLlamaServer.set_health_mode(fake, :error_503)

        spawn(fn ->
          Process.sleep(100)
          FakeLlamaServer.set_health_mode(fake, :ok)
        end)

        :ok
      end

      assert {:ok, samples} = LlamaInference.measure_restart(url, crash_fn)

      for s <- samples do
        assert s.source == :llama
        assert is_integer(s.timestamp)
        assert is_binary(s.metric_name)
        assert is_number(s.value)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Sample schema validation
  # ---------------------------------------------------------------------------

  describe "sample schema compliance" do
    test "every sample from measure_sequential is a valid Bench.Sample struct" do
      fake = start_fake(completions_mode: :valid_json)
      url = base_url(fake)

      assert {:ok, samples} = LlamaInference.measure_sequential(url, proposal_count: 2)

      for s <- samples do
        assert %Sample{} = s
        assert is_integer(s.timestamp)
        assert s.source == :llama
        assert is_binary(s.metric_name) and byte_size(s.metric_name) > 0
        assert is_number(s.value)
        assert is_binary(s.unit) and byte_size(s.unit) > 0
      end
    end

    test "samples from measure_startup round-trip through to_json/from_json" do
      fake = start_fake(health_mode: :ok)
      url = base_url(fake)

      assert {:ok, samples} = LlamaInference.measure_startup(url)

      for s <- samples do
        assert {:ok, json} = Sample.to_json(s)
        assert is_binary(json)
        assert {:ok, decoded} = Sample.from_json(json)
        assert decoded.metric_name == s.metric_name
        assert decoded.source == :llama
        assert decoded.unit == s.unit
      end
    end
  end
end

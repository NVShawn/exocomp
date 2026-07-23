defmodule Exocomp.Node.ProposalClientTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Exocomp.Node.ProposalClient
  alias Exocomp.Node.Test.FakeLlamaServer

  # ---------------------------------------------------------------------------
  # Mock LlamaServer — minimal GenServer that satisfies the LlamaServer API.
  # Registers itself under the real `Exocomp.Node.LlamaServer` name so that
  # ProposalClient.propose/1 (which calls LlamaServer.base_url/0 and
  # LlamaServer.status/0 without arguments) picks it up automatically.
  # ---------------------------------------------------------------------------

  defmodule MockLlamaServer do
    @moduledoc false
    use GenServer

    def start_link(url) do
      GenServer.start_link(__MODULE__, url, name: Exocomp.Node.LlamaServer)
    end

    @impl true
    def init(url), do: {:ok, url}

    @impl true
    def handle_call(:base_url, _from, url), do: {:reply, {:ok, url}, url}
    def handle_call(:status, _from, url), do: {:reply, :ready, url}
  end

  defmodule MockLlamaServerDegraded do
    @moduledoc false
    use GenServer

    def start_link(_opts) do
      GenServer.start_link(__MODULE__, :degraded, name: Exocomp.Node.LlamaServer)
    end

    @impl true
    def init(state), do: {:ok, state}

    @impl true
    def handle_call(:base_url, _from, state), do: {:reply, {:error, :not_ready}, state}
    def handle_call(:status, _from, state), do: {:reply, :degraded, state}
  end

  # ---------------------------------------------------------------------------
  # Setup helpers
  # ---------------------------------------------------------------------------

  # Starts a FakeLlamaServer and a MockLlamaServer pointing at its URL.
  # Cleans up both on `on_exit`.
  defp setup_with_fake_server(opts \\ []) do
    {:ok, fake} = FakeLlamaServer.start_link(opts)
    fake_port = FakeLlamaServer.port(fake)
    url = "http://127.0.0.1:#{fake_port}"

    {:ok, mock_pid} = MockLlamaServer.start_link(url)

    on_exit(fn ->
      if Process.alive?(fake), do: GenServer.stop(fake, :normal)
      if Process.alive?(mock_pid), do: GenServer.stop(mock_pid, :normal)
    end)

    {fake, url}
  end

  # ---------------------------------------------------------------------------
  # Existing smoke tests (kept for regression coverage)
  # ---------------------------------------------------------------------------

  test "returns {:error, :inference_unavailable} when LlamaServer is not running" do
    assert ProposalClient.propose(%{"cpu" => 99, "memory" => 512}) ==
             {:error, :inference_unavailable}
  end

  test "returns {:error, {:checksum_error, reason}} when checksum_fn fails" do
    Application.put_env(:exocomp_node, :checksum_fn, fn -> {:error, :bad_checksum} end)
    on_exit(fn -> Application.delete_env(:exocomp_node, :checksum_fn) end)

    assert ProposalClient.propose(%{}) == {:error, {:checksum_error, :bad_checksum}}
  end

  test "checksum_fn returning :ok passes the gate (server still unavailable)" do
    Application.put_env(:exocomp_node, :checksum_fn, fn -> :ok end)
    on_exit(fn -> Application.delete_env(:exocomp_node, :checksum_fn) end)

    assert ProposalClient.propose(%{}) == {:error, :inference_unavailable}
  end

  test "oversized diagnostic context is truncated without crashing" do
    large_context = %{"data" => String.duplicate("x", 100_000)}
    assert ProposalClient.propose(large_context) == {:error, :inference_unavailable}
  end

  test "non-map input is rejected at the function clause level" do
    assert_raise FunctionClauseError, fn ->
      ProposalClient.propose("not a map")
    end
  end

  test "all error tuples are structured (never a raw exception)" do
    for ctx <- [%{}, %{"key" => "value"}, %{"nested" => %{"deep" => true}}] do
      result = ProposalClient.propose(ctx)

      assert match?({:ok, _}, result) or match?({:error, _}, result),
             "propose/1 returned unexpected shape: #{inspect(result)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario 6 — Valid proposal round-trip
  # ---------------------------------------------------------------------------

  test "valid proposal round-trip: returns {:ok, proposal} with all required fields" do
    {_fake, _url} = setup_with_fake_server(completions_mode: :valid_json)

    result = ProposalClient.propose(%{"cpu" => 95, "memory_free_mb" => 128})

    assert {:ok, proposal} = result

    # All five required schema fields must be present.
    assert Map.has_key?(proposal, "schema_version") or Map.has_key?(proposal, :schema_version)
    assert Map.has_key?(proposal, "proposal_id") or Map.has_key?(proposal, :proposal_id)
    assert Map.has_key?(proposal, "rationale") or Map.has_key?(proposal, :rationale)

    assert Map.has_key?(proposal, "affected_resource") or
             Map.has_key?(proposal, :affected_resource)

    assert Map.has_key?(proposal, "confidence") or Map.has_key?(proposal, :confidence)

    # Schema version must be "1".
    schema_ver = Map.get(proposal, "schema_version") || Map.get(proposal, :schema_version)
    assert schema_ver == "1"
  end

  # ---------------------------------------------------------------------------
  # Scenario 7 — Invalid JSON from model
  # ---------------------------------------------------------------------------

  test "invalid JSON from model: returns {:error, :invalid_json} without crashing" do
    {_fake, _url} = setup_with_fake_server(completions_mode: :invalid_json)

    assert ProposalClient.propose(%{"disk_usage" => 99}) == {:error, :invalid_json}
  end

  # ---------------------------------------------------------------------------
  # Scenario 8 — Schema violation
  # ---------------------------------------------------------------------------

  test "schema violation: returns {:error, {:schema_error, :unknown_proposal_id}}" do
    {_fake, _url} = setup_with_fake_server(completions_mode: :schema_violation)

    result = ProposalClient.propose(%{"service" => "nginx"})

    assert result == {:error, {:schema_error, :unknown_proposal_id}}
  end

  # ---------------------------------------------------------------------------
  # Scenario 9 — Request timeout
  # ---------------------------------------------------------------------------

  @tag timeout: 30_000
  test "request timeout: returns {:error, :inference_timeout} within configured timeout + tolerance" do
    {_fake, _url} = setup_with_fake_server(completions_mode: :timeout)

    # Use a very short inference timeout (300ms) so the test completes quickly.
    timeout_ms = 300
    Application.put_env(:exocomp_node, :inference_timeout_ms, timeout_ms)
    on_exit(fn -> Application.delete_env(:exocomp_node, :inference_timeout_ms) end)

    tolerance_ms = 2_000
    t_start = System.monotonic_time(:millisecond)
    result = ProposalClient.propose(%{"cpu" => 50})
    elapsed = System.monotonic_time(:millisecond) - t_start

    # Must return an inference timeout error.
    assert result == {:error, :inference_timeout}

    # Must return within timeout + tolerance (not hang indefinitely).
    assert elapsed <= timeout_ms + tolerance_ms,
           "propose/1 took #{elapsed}ms (timeout=#{timeout_ms}ms, tolerance=#{tolerance_ms}ms)"
  end

  # ---------------------------------------------------------------------------
  # Scenario 10 — Unavailable model
  # ---------------------------------------------------------------------------

  test "unavailable model: returns {:error, :inference_unavailable} immediately when degraded" do
    {:ok, mock_pid} = MockLlamaServerDegraded.start_link([])

    on_exit(fn ->
      if Process.alive?(mock_pid), do: GenServer.stop(mock_pid, :normal)
    end)

    t_start = System.monotonic_time(:millisecond)
    result = ProposalClient.propose(%{"cpu" => 99})
    elapsed = System.monotonic_time(:millisecond) - t_start

    assert result == {:error, :inference_unavailable}

    # Must return immediately (not attempt an HTTP request that would block).
    assert elapsed < 500,
           "propose/1 took #{elapsed}ms when server unavailable — expected < 500ms"
  end

  # ---------------------------------------------------------------------------
  # Scenario 11 — Output redaction
  # ---------------------------------------------------------------------------

  # A lightweight OTP logger handler that stores raw log events (including
  # their metadata) in an ETS table so tests can inspect them directly.
  defmodule MetadataCapture do
    @moduledoc false

    @handler_id :metadata_capture_test_handler

    def start do
      table = :ets.new(:metadata_capture, [:public, :bag])
      :logger.add_handler(@handler_id, __MODULE__, %{table: table})
      table
    end

    def stop(table) do
      :logger.remove_handler(@handler_id)
      :ets.delete(table)
    end

    # OTP :logger handler callback
    def log(event, %{table: table}) do
      metadata = Map.get(event, :meta, %{})
      :ets.insert(table, {:event, metadata})
    end
  end

  test "output redaction: raw model content never appears in log output" do
    {_fake, _url} = setup_with_fake_server(completions_mode: :valid_json)

    # The raw model output contains the string below (inside the JSON body).
    # It must NOT appear anywhere in logs.
    raw_content_marker = "High CPU usage detected"

    # Capture both the formatted log text AND raw metadata events.
    table = MetadataCapture.start()

    log_output =
      capture_log(fn ->
        ProposalClient.propose(%{"cpu" => 95})
      end)

    # Collect events BEFORE stopping the table.
    events = :ets.lookup(table, :event)
    MetadataCapture.stop(table)

    # Primary security assertion: raw model content must NOT appear in
    # the formatted log output.
    refute String.contains?(log_output, raw_content_marker),
           "Raw model content appeared in formatted log output:\n#{log_output}"

    # The formatted output must not contain the raw response body.
    refute String.contains?(log_output, "High CPU"),
           "Raw model content fragment appeared in log:\n#{log_output}"

    # Verify that a log event with raw_model_output: "[REDACTED]" was emitted.
    redacted_event =
      Enum.find(events, fn {:event, meta} ->
        Map.get(meta, :raw_model_output) == "[REDACTED]"
      end)

    assert redacted_event != nil,
           "Expected a log event with raw_model_output: \"[REDACTED]\" but none found"
  end

  test "output redaction: error path also redacts raw model content" do
    {_fake, _url} = setup_with_fake_server(completions_mode: :schema_violation)

    raw_content_marker = "make_coffee"

    table = MetadataCapture.start()

    log_output =
      capture_log(fn ->
        ProposalClient.propose(%{"service" => "nginx"})
      end)

    events = :ets.lookup(table, :event)
    MetadataCapture.stop(table)

    refute String.contains?(log_output, raw_content_marker),
           "Raw schema-violation content appeared in formatted log:\n#{log_output}"

    redacted_event =
      Enum.find(events, fn {:event, meta} ->
        Map.get(meta, :raw_model_output) == "[REDACTED]"
      end)

    assert redacted_event != nil,
           "Expected a log event with raw_model_output: \"[REDACTED]\" on error path"
  end

  # ---------------------------------------------------------------------------
  # Existing mock-based tests (kept for regression coverage)
  # ---------------------------------------------------------------------------

  describe "with a mocked LlamaServer that reports ready but no HTTP server" do
    setup do
      {:ok, pid} = MockLlamaServer.start_link("http://127.0.0.1:19_999")

      on_exit(fn ->
        if Process.alive?(pid), do: GenServer.stop(pid)
      end)

      :ok
    end

    test "returns a connection-failure error when no HTTP server is reachable" do
      result = ProposalClient.propose(%{"service" => "nginx"})

      assert result in [
               {:error, :inference_unavailable},
               {:error, :inference_timeout}
             ],
             "expected a structured error, got: #{inspect(result)}"
    end
  end
end

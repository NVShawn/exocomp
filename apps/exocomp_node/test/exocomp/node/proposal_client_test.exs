defmodule Exocomp.Node.ProposalClientTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.ProposalClient

  # ---------------------------------------------------------------------------
  # Smoke test: unavailable server
  # ---------------------------------------------------------------------------

  test "returns {:error, :inference_unavailable} when LlamaServer is not running" do
    # No LlamaServer GenServer registered — base_url/0 will catch the noproc
    # exit and return {:error, :not_ready}, which ProposalClient maps to
    # {:error, :inference_unavailable}.
    assert ProposalClient.propose(%{"cpu" => 99, "memory" => 512}) ==
             {:error, :inference_unavailable}
  end

  # ---------------------------------------------------------------------------
  # Checksum gate
  # ---------------------------------------------------------------------------

  test "returns {:error, {:checksum_error, reason}} when checksum_fn fails" do
    Application.put_env(:exocomp_node, :checksum_fn, fn -> {:error, :bad_checksum} end)

    on_exit(fn -> Application.delete_env(:exocomp_node, :checksum_fn) end)

    assert ProposalClient.propose(%{}) == {:error, {:checksum_error, :bad_checksum}}
  end

  test "checksum_fn returning :ok passes the gate (server still unavailable)" do
    Application.put_env(:exocomp_node, :checksum_fn, fn -> :ok end)

    on_exit(fn -> Application.delete_env(:exocomp_node, :checksum_fn) end)

    # Checksum passes, but server is down — should reach unavailable
    assert ProposalClient.propose(%{}) == {:error, :inference_unavailable}
  end

  # ---------------------------------------------------------------------------
  # Input bounding
  # ---------------------------------------------------------------------------

  test "oversized diagnostic context is truncated without crashing" do
    # A context with a very long value should not raise; it will be truncated
    # before transmission. Server is unavailable so we still get :inference_unavailable,
    # but the function must not crash or raise.
    large_context = %{"data" => String.duplicate("x", 100_000)}

    assert ProposalClient.propose(large_context) == {:error, :inference_unavailable}
  end

  test "non-map input is rejected at the function clause level" do
    assert_raise FunctionClauseError, fn ->
      ProposalClient.propose("not a map")
    end
  end

  # ---------------------------------------------------------------------------
  # Schema validation gate (using a test double for LlamaServer)
  # ---------------------------------------------------------------------------

  # Minimal GenServer stub that satisfies LlamaServer's call protocol.
  defmodule FakeLlamaServer do
    use GenServer

    def start_link(url),
      do: GenServer.start_link(__MODULE__, url, name: Exocomp.Node.LlamaServer)

    @impl true
    def init(url), do: {:ok, url}

    @impl true
    def handle_call(:base_url, _from, url), do: {:reply, {:ok, url}, url}
    def handle_call(:status, _from, url), do: {:reply, :ready, url}
  end

  describe "with a mocked LlamaServer that reports ready" do
    setup do
      # Start the fake server pointing at an unreachable address so the HTTP
      # connection fails quickly (no real llama-server is running there).
      {:ok, pid} = FakeLlamaServer.start_link("http://127.0.0.1:19_999")

      on_exit(fn ->
        if Process.alive?(pid), do: GenServer.stop(pid)
      end)

      :ok
    end

    test "returns a connection-failure error when no HTTP server is reachable" do
      # LlamaServer reports ready, but the HTTP endpoint does not exist.
      # This must return :inference_unavailable or :inference_timeout —
      # never an unhandled exception.
      result = ProposalClient.propose(%{"service" => "nginx"})

      assert result in [
               {:error, :inference_unavailable},
               {:error, :inference_timeout}
             ],
             "expected a structured error, got: #{inspect(result)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Error tuple coverage
  # ---------------------------------------------------------------------------

  test "all error tuples are structured (never a raw exception)" do
    # Verify that propose/1 always returns a tagged tuple, never raises.
    contexts = [
      %{},
      %{"key" => "value"},
      %{"nested" => %{"deep" => true}}
    ]

    for ctx <- contexts do
      result = ProposalClient.propose(ctx)

      assert match?({:ok, _}, result) or match?({:error, _}, result),
             "propose/1 returned unexpected shape: #{inspect(result)}"
    end
  end
end

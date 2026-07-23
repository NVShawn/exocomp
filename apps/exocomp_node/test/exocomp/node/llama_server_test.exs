defmodule Exocomp.Node.LlamaServerTest do
  use ExUnit.Case, async: false

  alias Exocomp.Node.LlamaServer
  alias Exocomp.Node.Test.FakeLlamaServer

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defmodule TestSupervisor do
    @moduledoc false
    use Supervisor

    def start_link(child), do: Supervisor.start_link(__MODULE__, child)

    @impl true
    def init(child), do: Supervisor.init([child], strategy: :one_for_one)
  end

  defp fixture_path(name), do: Path.expand("../../fixtures/#{name}", __DIR__)

  # Poll `fun` until it returns true or we exceed `attempts * sleep_ms` ms.
  defp eventually(fun, attempts \\ 100, sleep_ms \\ 20)
  defp eventually(_fun, 0, _sleep), do: false

  defp eventually(fun, attempts, sleep_ms) do
    if fun.() do
      true
    else
      Process.sleep(sleep_ms)
      eventually(fun, attempts - 1, sleep_ms)
    end
  end

  # Block until LlamaServer reports `expected` status, or `timeout_ms` expires.
  defp wait_for_status(server, expected, timeout_ms \\ 5_000) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    wait_status_loop(server, expected, deadline)
  end

  defp wait_status_loop(server, expected, deadline) do
    current = LlamaServer.status(server)

    if current == expected do
      :ok
    else
      remaining = deadline - System.monotonic_time(:millisecond)

      if remaining <= 0 do
        {:timeout, current}
      else
        Process.sleep(20)
        wait_status_loop(server, expected, deadline)
      end
    end
  end

  # Kill the OS process behind an Erlang Port (simulates a crash of the
  # llama-server process without closing the port from outside its owner).
  defp kill_port_os_process(port) do
    case Port.info(port, :os_pid) do
      {:os_pid, os_pid} ->
        System.cmd("/usr/bin/kill", ["-TERM", Integer.to_string(os_pid)])
        :ok

      _other ->
        # Port may have already exited.
        :ok
    end
  end

  # ---------------------------------------------------------------------------
  # Existing smoke tests (kept for regression coverage)
  # ---------------------------------------------------------------------------

  test "reports stopped when no server is running" do
    assert LlamaServer.status() == :stopped
    assert LlamaServer.base_url() == {:error, :not_ready}
  end

  test "starts under a one-for-one supervisor and remains starting before readiness" do
    supervisor =
      start_supervised!(
        {TestSupervisor,
         {LlamaServer,
          llama_server_path: fixture_path("llama-server-stub"),
          llama_model_path: "/tmp/model.gguf",
          llama_host: "0.0.0.0",
          llama_port: 18_080,
          llama_ready_timeout_ms: 1_000}}
      )

    assert is_pid(supervisor)
    assert LlamaServer.status() == :starting
    assert LlamaServer.base_url() == {:error, :not_ready}

    state = :sys.get_state(LlamaServer)
    assert state.host == "127.0.0.1"
    assert Process.alive?(Process.whereis(LlamaServer))
  end

  test "a nonexistent executable degrades without crashing its supervisor" do
    supervisor =
      start_supervised!(
        {TestSupervisor,
         {LlamaServer,
          llama_server_path: "/definitely/not/a/llama-server",
          llama_port: 18_081,
          llama_ready_timeout_ms: 10}}
      )

    assert eventually(fn -> LlamaServer.status() == :degraded end)
    assert Process.alive?(supervisor)
    assert Process.alive?(Process.whereis(LlamaServer))
    assert :sys.get_state(LlamaServer).restart_count >= 1
  end

  # ---------------------------------------------------------------------------
  # Scenario 1 — Startup and readiness success
  # ---------------------------------------------------------------------------

  test "startup and readiness success: status transitions to :ready when health check passes" do
    {:ok, fake} = start_supervised({FakeLlamaServer, health_mode: :ok})
    port = FakeLlamaServer.port(fake)

    server_pid =
      start_supervised!(
        {LlamaServer,
         name: :ls_test_ready,
         llama_server_path: fixture_path("llama-server-stub"),
         llama_port: port,
         llama_ready_timeout_ms: 5_000}
      )

    assert wait_for_status(:ls_test_ready, :ready) == :ok,
           "expected :ready but timed out with #{inspect(LlamaServer.status(:ls_test_ready))}"

    assert LlamaServer.status(:ls_test_ready) == :ready
    assert {:ok, url} = LlamaServer.base_url(:ls_test_ready)
    assert String.starts_with?(url, "http://127.0.0.1:")
    assert Process.alive?(server_pid)
  end

  # ---------------------------------------------------------------------------
  # Scenario 2 — Readiness timeout
  # ---------------------------------------------------------------------------

  test "readiness timeout: status becomes :degraded when health check never responds" do
    {:ok, fake} = start_supervised({FakeLlamaServer, health_mode: :timeout})
    port = FakeLlamaServer.port(fake)

    supervisor =
      start_supervised!({TestSupervisor,
       {
         LlamaServer,
         # Short timeout so the test doesn't take long.
         llama_server_path: fixture_path("llama-server-stub"),
         llama_port: port,
         llama_ready_timeout_ms: 600
       }})

    assert wait_for_status(LlamaServer, :degraded, 3_000) == :ok,
           "expected :degraded but timed out with #{inspect(LlamaServer.status())}"

    # The supervisor must survive — LlamaServer transitioned to :degraded without crashing.
    assert Process.alive?(supervisor)
    # The LlamaServer GenServer is still alive and responsive.
    assert Process.alive?(Process.whereis(LlamaServer))
    # base_url is not available when degraded.
    assert LlamaServer.base_url() == {:error, :not_ready}
  end

  # ---------------------------------------------------------------------------
  # Scenario 3 — Crash and restart
  # ---------------------------------------------------------------------------

  test "crash and restart: LlamaServer restarts and re-polls readiness after OS process exit" do
    {:ok, fake} = start_supervised({FakeLlamaServer, health_mode: :ok})
    port = FakeLlamaServer.port(fake)

    server_pid =
      start_supervised!({
        LlamaServer,
        # Short cap so the restart happens within the test timeout.
        name: :ls_test_crash,
        llama_server_path: fixture_path("llama-server-forever"),
        llama_port: port,
        llama_ready_timeout_ms: 5_000,
        llama_max_restart_backoff_ms: 200
      })

    assert wait_for_status(:ls_test_crash, :ready) == :ok

    state_before = :sys.get_state(:ls_test_crash)
    restart_count_before = state_before.restart_count

    # Simulate an OS-level crash (SIGTERM the child process).
    :ok = kill_port_os_process(state_before.port)

    # LlamaServer must detect the exit and enter :degraded.
    assert eventually(fn -> LlamaServer.status(:ls_test_crash) == :degraded end),
           "expected :degraded after crash"

    # After the short backoff (≤ 200ms), LlamaServer should spawn a new process
    # and re-poll the fake health endpoint, returning to :ready.
    assert wait_for_status(:ls_test_crash, :ready, 3_000) == :ok,
           "expected :ready after restart"

    state_after = :sys.get_state(:ls_test_crash)
    assert state_after.restart_count > restart_count_before

    # The GenServer process itself must not have been replaced.
    assert Process.alive?(server_pid)
  end

  # ---------------------------------------------------------------------------
  # Scenario 4 — Restart backoff (exponential growth)
  #
  # Strategy: use a non-existent executable so every spawn attempt fails
  # immediately.  Each failure increments `backoff_attempt` WITHOUT resetting
  # it (the reset only happens on successful health check → :ready).  We
  # measure the wall-clock time between consecutive restarts and verify the
  # delays grow.
  # ---------------------------------------------------------------------------

  @tag timeout: 20_000
  test "restart backoff: successive restart delays grow exponentially" do
    # Use a non-existent path so every spawn attempt fails immediately.
    # With max=10_000ms and base=1000ms:
    #   attempt 1: capped=1000ms, range [500..1000]ms
    #   attempt 2: capped=2000ms, range [1000..2000]ms
    _server_pid =
      start_supervised!(
        {LlamaServer,
         name: :ls_test_backoff,
         llama_server_path: "/definitely/not/a/llama-server",
         llama_port: 19_555,
         llama_ready_timeout_ms: 100,
         llama_max_restart_backoff_ms: 10_000}
      )

    # Wait for the first spawn failure → :degraded.
    assert eventually(fn -> LlamaServer.status(:ls_test_backoff) == :degraded end)

    # Wait for restart_count to reach 1 (first restart scheduled).
    assert eventually(fn ->
             :sys.get_state(:ls_test_backoff).restart_count >= 1
           end)

    t0 = System.monotonic_time(:millisecond)

    # Wait for restart_count to reach 2 (second restart fired and failed).
    assert eventually(
             fn ->
               :sys.get_state(:ls_test_backoff).restart_count >= 2
             end,
             200,
             20
           ),
           "restart_count did not reach 2 within expected time"

    t1 = System.monotonic_time(:millisecond)

    # Now wait for restart_count to reach 3 (third restart fired and failed).
    assert eventually(
             fn ->
               :sys.get_state(:ls_test_backoff).restart_count >= 3
             end,
             200,
             30
           ),
           "restart_count did not reach 3 within expected time"

    t2 = System.monotonic_time(:millisecond)

    # `delay1` = time from restart #1 to #2 ≈ backoff(attempt 1) ∈ [500,1000]ms
    # `delay2` = time from restart #2 to #3 ≈ backoff(attempt 2) ∈ [1000,2000]ms
    delay1 = t1 - t0
    delay2 = t2 - t1

    state_final = :sys.get_state(:ls_test_backoff)
    assert state_final.restart_count >= 3
    assert state_final.backoff_attempt >= 3

    assert delay1 >= 200,
           "first backoff delay #{delay1}ms was shorter than expected (≥ 200ms)"

    # delay2 range [1000,2000]ms is strictly >= delay1 range [500,1000]ms.
    # We allow 70% margin to accommodate measurement jitter.
    assert delay2 >= delay1 * 0.7,
           "second backoff delay (#{delay2}ms) was not >= 70% of first (#{delay1}ms); " <>
             "exponential backoff may not be working"
  end

  # ---------------------------------------------------------------------------
  # Scenario 5 — Crash isolation
  # ---------------------------------------------------------------------------

  test "crash isolation: LlamaServer GenServer stays responsive after OS process crash" do
    {:ok, fake} = start_supervised({FakeLlamaServer, health_mode: :ok})
    port = FakeLlamaServer.port(fake)

    supervisor =
      start_supervised!({TestSupervisor,
       {
         LlamaServer,
         # Short cap so the restart happens quickly.
         llama_server_path: fixture_path("llama-server-forever"),
         llama_port: port,
         llama_ready_timeout_ms: 5_000,
         llama_max_restart_backoff_ms: 200
       }})

    assert wait_for_status(LlamaServer, :ready) == :ok

    server_pid = Process.whereis(LlamaServer)
    state = :sys.get_state(LlamaServer)

    # Simulate the llama-server OS process crashing.
    :ok = kill_port_os_process(state.port)

    # Wait until LlamaServer detects the crash (status changes from :ready).
    assert eventually(fn -> LlamaServer.status() != :ready end),
           "expected LlamaServer to leave :ready after crash"

    # The LlamaServer GenServer itself must remain alive (it handles the crash
    # internally via process_exited/schedule_restart — it does NOT crash).
    assert Process.alive?(server_pid),
           "LlamaServer GenServer must not die when its OS process exits"

    # The supervisor that owns LlamaServer must also survive.
    assert Process.alive?(supervisor),
           "Supervisor must remain alive after LlamaServer's OS process exits"

    # LlamaServer must still answer calls while degraded/restarting.
    status_after_crash = LlamaServer.status()

    assert status_after_crash in [:degraded, :starting],
           "unexpected status after crash: #{inspect(status_after_crash)}"

    # Internal state is intact and the GenServer is responsive to sys calls.
    new_state = :sys.get_state(LlamaServer)
    assert new_state.restart_count >= 1

    # Eventually LlamaServer self-heals by spawning a new process.
    assert wait_for_status(LlamaServer, :ready, 3_000) == :ok,
           "LlamaServer did not recover after crash"
  end
end

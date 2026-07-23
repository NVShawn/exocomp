defmodule Exocomp.Node.ExecutorTest do
  @moduledoc """
  Focused security and correctness tests for `Exocomp.Node.Executor`.

  All OS command invocations are stubbed via `MockCommander` so these tests
  run without systemd, journalctl, or sudo present in the test environment.

  Covers:
  - Service allow-list enforcement
  - Unknown unit rejection
  - Shell metacharacter rejection
  - argv injection prevention (caller input never reaches argv)
  - Environment injection prevention (fixed env only)
  - Timeout enforcement
  - Oversized output rejection
  - Sudo denial / non-zero exit code handling
  - Concurrent-target serialization
  - Post-action verifier invoked on success
  - Verifier failure surfaces correctly
  """

  # async: false because we mutate Application env for the mock commander.
  use ExUnit.Case, async: false

  alias Exocomp.Node.Executor
  alias Exocomp.Node.ExecutorLock
  alias Exocomp.Node.MockCommander

  @allow_list ["myapp.service", "nginx.service"]

  # Each test gets its own mock commander and isolated lock server so there is
  # no state leakage between tests.  The mock agent is NOT linked to the test
  # process (uses Agent.start, not start_link), so it survives test-process
  # exit and can be stopped cleanly in on_exit.
  setup do
    {:ok, mock} = MockCommander.start()
    commander_fn = MockCommander.as_commander(mock)
    {:ok, lock} = ExecutorLock.start_link([])

    previous = Application.get_env(:exocomp_node, :os_commander)
    Application.put_env(:exocomp_node, :os_commander, commander_fn)

    on_exit(fn ->
      if previous,
        do: Application.put_env(:exocomp_node, :os_commander, previous),
        else: Application.delete_env(:exocomp_node, :os_commander)

      MockCommander.stop(mock)
    end)

    %{mock: mock, lock: lock}
  end

  # ── allow-list enforcement ────────────────────────────────────────────────

  describe "allow-list enforcement" do
    test "allows execution of a service in the allow-list", %{mock: mock, lock: lock} do
      # Enqueue: action succeeds, verifier (is-active) succeeds.
      MockCommander.push(mock, {:ok, "Restarted.", 0})
      MockCommander.push(mock, {:ok, "", 0})

      assert {:ok, result} =
               Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)

      assert result.action_id == :restart_service
      assert result.target == "myapp.service"
      assert result.verified == true
    end

    test "rejects a service name not in the allow-list", %{lock: lock} do
      assert {:error, :not_allowed} =
               Executor.execute(:restart_service, "unknown.service", @allow_list,
                 lock_server: lock
               )
    end

    test "rejects an empty allow-list", %{lock: lock} do
      assert {:error, :not_allowed} =
               Executor.execute(:restart_service, "myapp.service", [], lock_server: lock)
    end
  end

  # ── unknown unit rejection ────────────────────────────────────────────────

  describe "unknown action rejection" do
    test "rejects an unknown action id", %{lock: lock} do
      assert {:error, :unknown_action} =
               Executor.execute(:run_shell, "myapp.service", @allow_list, lock_server: lock)
    end

    test "rejects a string action id", %{lock: lock} do
      assert {:error, :unknown_action} =
               Executor.execute("systemctl", "myapp.service", @allow_list, lock_server: lock)
    end
  end

  # ── shell metacharacter injection ─────────────────────────────────────────

  describe "shell metacharacter injection in target" do
    @injection_targets [
      "myapp.service; rm -rf /",
      "$(id)",
      "`id`",
      "myapp | cat /etc/passwd",
      "myapp & id",
      "myapp > /tmp/out",
      "myapp\nALL=(root) NOPASSWD: ALL",
      "myapp\x00.service",
      "../../etc/passwd",
      " ",
      ""
    ]

    for target <- @injection_targets do
      @tag target: target
      test "rejects target with injection: #{inspect(target)}", %{lock: lock} do
        target = @tag[:target]
        # Attempt to add the malicious string to the allow-list to bypass that check.
        poisoned_list = [target | @allow_list]

        result =
          Executor.execute(:restart_service, target, poisoned_list, lock_server: lock)

        assert {:error, :not_allowed} = result,
               "Expected :not_allowed for target #{inspect(target)}, got #{inspect(result)}"
      end
    end
  end

  # ── argv injection ────────────────────────────────────────────────────────

  describe "argv invariant" do
    test "the argv passed to OS commander is built from catalog, not caller string",
         %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:ok, "", 0})
      MockCommander.push(mock, {:ok, "", 0})

      Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)

      [{executable, argv, _opts} | _] = MockCommander.calls(mock)
      assert executable == "/usr/bin/systemctl"
      assert argv == ["restart", "myapp.service"]
      # The argv must not contain any string that came from outside the catalog.
      # Specifically, no operator characters that would change shell behaviour.
      for arg <- argv do
        refute String.contains?(arg, [";", "&", "|", "$", "`", ">", "<", "\n"])
      end
    end

    test "caller cannot append extra argv elements via the target string",
         %{mock: mock, lock: lock} do
      # "myapp.service --now" contains a space — must be rejected at name validation.
      assert {:error, :not_allowed} =
               Executor.execute(
                 :restart_service,
                 "myapp.service --now",
                 ["myapp.service --now"],
                 lock_server: lock
               )

      # No call should have reached the commander.
      assert MockCommander.calls(mock) == []
    end
  end

  # ── environment injection ─────────────────────────────────────────────────

  describe "environment invariant" do
    test "the env passed to OS commander is empty (fixed) for restart_service",
         %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:ok, "", 0})
      MockCommander.push(mock, {:ok, "", 0})

      Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)

      [{_exec, _argv, opts} | _] = MockCommander.calls(mock)
      assert Keyword.get(opts, :env) == []
    end

    test "the env passed to OS commander is empty for vacuum_logs",
         %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:ok, "", 0})

      Executor.execute(:vacuum_logs, nil, [], lock_server: lock)

      [{_exec, _argv, opts}] = MockCommander.calls(mock)
      assert Keyword.get(opts, :env) == []
    end
  end

  # ── timeout enforcement ───────────────────────────────────────────────────

  describe "timeout enforcement" do
    test "returns {:error, :timeout} when the OS commander reports timeout",
         %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:error, :timeout})

      assert {:error, :timeout} =
               Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)
    end

    test "lock is released after a timeout", %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:error, :timeout})

      Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)

      # The lock must have been released — a second acquire must succeed.
      assert :ok = ExecutorLock.acquire(lock, "myapp.service")
    end
  end

  # ── oversized output ──────────────────────────────────────────────────────

  describe "oversized output" do
    test "returns {:error, {:output_limit_exceeded, _}} when output exceeds limit",
         %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:error, {:output_limit_exceeded, 200_000}})

      assert {:error, {:output_limit_exceeded, 200_000}} =
               Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)
    end

    test "lock is released after an output-limit error", %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:error, {:output_limit_exceeded, 99_999}})

      Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)

      # Lock must be released.
      assert :ok = ExecutorLock.acquire(lock, "myapp.service")
    end
  end

  # ── sudo denial / non-zero exit ───────────────────────────────────────────

  describe "sudo denial and non-zero exit" do
    test "returns {:error, {:subprocess_failed, exit_code, output}} for non-zero exit",
         %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:ok, "Permission denied", 1})

      assert {:error, {:subprocess_failed, 1, "Permission denied"}} =
               Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)
    end

    test "exit code 1 (sudo NOPASSWD not granted) is treated as a failure",
         %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:ok, "sudo: a terminal is required", 1})

      assert {:error, {:subprocess_failed, 1, _}} =
               Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)
    end

    test "exit code 127 (executable not found) is treated as a failure",
         %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:ok, "", 127})

      assert {:error, {:subprocess_failed, 127, _}} =
               Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)
    end

    test "lock is released after sudo denial", %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:ok, "Permission denied", 1})

      Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)

      assert :ok = ExecutorLock.acquire(lock, "myapp.service")
    end
  end

  # ── concurrent targets ────────────────────────────────────────────────────

  describe "concurrent target serialization" do
    test "concurrent executions on the same target: second returns :concurrent_execution",
         %{mock: _mock, lock: lock} do
      # Acquire the lock manually to simulate an in-progress execution.
      :ok = ExecutorLock.acquire(lock, "myapp.service")

      # The executor should detect the lock is held and reject.
      assert {:error, :concurrent_execution} =
               Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)
    end

    test "concurrent executions on different targets both succeed",
         %{mock: mock, lock: lock} do
      # Enqueue responses for two independent targets (action + verifier each).
      MockCommander.push(mock, {:ok, "", 0})
      MockCommander.push(mock, {:ok, "", 0})
      MockCommander.push(mock, {:ok, "", 0})
      MockCommander.push(mock, {:ok, "", 0})

      task_a =
        Task.async(fn ->
          Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)
        end)

      task_b =
        Task.async(fn ->
          Executor.execute(:restart_service, "nginx.service", @allow_list, lock_server: lock)
        end)

      result_a = Task.await(task_a)
      result_b = Task.await(task_b)

      assert {:ok, %{target: "myapp.service"}} = result_a
      assert {:ok, %{target: "nginx.service"}} = result_b
    end
  end

  # ── post-action verification ──────────────────────────────────────────────

  describe "post-action verification" do
    test "verifier is called after a successful action", %{mock: mock, lock: lock} do
      # First call: action succeeds.
      # Second call: verifier (is-active) succeeds.
      MockCommander.push(mock, {:ok, "", 0})
      MockCommander.push(mock, {:ok, "", 0})

      {:ok, result} =
        Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)

      # The mock should have received exactly two calls: action + verifier.
      calls = MockCommander.calls(mock)
      assert length(calls) == 2

      [action_call, verifier_call] = calls
      {exec1, argv1, _} = action_call
      assert exec1 == "/usr/bin/systemctl"
      assert argv1 == ["restart", "myapp.service"]

      {exec2, argv2, _} = verifier_call
      assert exec2 == "/usr/bin/systemctl"
      assert "is-active" in argv2
      assert "myapp.service" in argv2

      assert result.verified == true
    end

    test "verification failure is returned as {:error, {:verification_failed, _}}",
         %{mock: mock, lock: lock} do
      # Action exits 0, but verifier says the service is not active (exit 3).
      MockCommander.push(mock, {:ok, "", 0})
      MockCommander.push(mock, {:ok, "inactive", 3})

      assert {:error, {:verification_failed, {:service_not_active, 3}}} =
               Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)
    end

    test "vacuum_logs verification always passes (self-verifying via exit code)",
         %{mock: mock, lock: lock} do
      # Only one commander call expected (no separate verifier for vacuum).
      MockCommander.push(mock, {:ok, "Vacuumed 50M", 0})

      assert {:ok, result} =
               Executor.execute(:vacuum_logs, nil, [], lock_server: lock)

      calls = MockCommander.calls(mock)
      assert length(calls) == 1
      assert result.verified == true
    end
  end

  # ── result shape ─────────────────────────────────────────────────────────

  describe "result shape on success" do
    test "exec_result contains expected keys", %{mock: mock, lock: lock} do
      MockCommander.push(mock, {:ok, "output line", 0})
      MockCommander.push(mock, {:ok, "", 0})

      {:ok, result} =
        Executor.execute(:restart_service, "myapp.service", @allow_list, lock_server: lock)

      assert result.action_id == :restart_service
      assert result.target == "myapp.service"
      assert is_binary(result.output)
      assert result.exit_code == 0
      assert result.verified == true
    end
  end
end

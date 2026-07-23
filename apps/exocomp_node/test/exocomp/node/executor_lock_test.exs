defmodule Exocomp.Node.ExecutorLockTest do
  @moduledoc """
  Tests for `Exocomp.Node.ExecutorLock`.

  Covers:
  - Basic acquire/release cycle
  - Concurrent execution rejection for the same target
  - Independent targets can be acquired concurrently
  - Release is idempotent (no-op for unlocked targets)
  - locked_targets/1 reflects current state
  """

  use ExUnit.Case, async: true

  alias Exocomp.Node.ExecutorLock

  setup do
    # Each test gets its own isolated lock server to avoid interference.
    {:ok, lock} = ExecutorLock.start_link([])
    %{lock: lock}
  end

  # ── basic acquire/release ─────────────────────────────────────────────────

  describe "acquire/2 and release/2" do
    test "acquire returns :ok for a fresh target", %{lock: lock} do
      assert :ok = ExecutorLock.acquire(lock, "alpha.service")
    end

    test "release returns :ok", %{lock: lock} do
      ExecutorLock.acquire(lock, "alpha.service")
      assert :ok = ExecutorLock.release(lock, "alpha.service")
    end

    test "target can be re-acquired after release", %{lock: lock} do
      assert :ok = ExecutorLock.acquire(lock, "alpha.service")
      assert :ok = ExecutorLock.release(lock, "alpha.service")
      assert :ok = ExecutorLock.acquire(lock, "alpha.service")
    end

    test "release is safe to call on an unlocked target (no-op)", %{lock: lock} do
      assert :ok = ExecutorLock.release(lock, "never-acquired.service")
    end
  end

  # ── concurrent execution rejection ───────────────────────────────────────

  describe "concurrent execution on the same target" do
    test "second acquire on in-progress target returns {:error, :concurrent_execution}",
         %{lock: lock} do
      assert :ok = ExecutorLock.acquire(lock, "myapp.service")
      assert {:error, :concurrent_execution} = ExecutorLock.acquire(lock, "myapp.service")
    end

    test "third acquire on in-progress target also rejected", %{lock: lock} do
      assert :ok = ExecutorLock.acquire(lock, "myapp.service")
      assert {:error, :concurrent_execution} = ExecutorLock.acquire(lock, "myapp.service")
      assert {:error, :concurrent_execution} = ExecutorLock.acquire(lock, "myapp.service")
    end

    test "after release, concurrent execution is allowed again", %{lock: lock} do
      assert :ok = ExecutorLock.acquire(lock, "myapp.service")
      assert {:error, :concurrent_execution} = ExecutorLock.acquire(lock, "myapp.service")
      ExecutorLock.release(lock, "myapp.service")
      assert :ok = ExecutorLock.acquire(lock, "myapp.service")
    end
  end

  # ── independent targets ───────────────────────────────────────────────────

  describe "independent targets" do
    test "different targets can be acquired concurrently", %{lock: lock} do
      assert :ok = ExecutorLock.acquire(lock, "alpha.service")
      assert :ok = ExecutorLock.acquire(lock, "beta.service")
      assert :ok = ExecutorLock.acquire(lock, "gamma.service")
    end

    test "locking one target does not block another", %{lock: lock} do
      ExecutorLock.acquire(lock, "alpha.service")
      # Should not return :concurrent_execution for a different target.
      assert :ok = ExecutorLock.acquire(lock, "beta.service")
    end
  end

  # ── locked_targets/1 ─────────────────────────────────────────────────────

  describe "locked_targets/1" do
    test "empty at start", %{lock: lock} do
      assert MapSet.size(ExecutorLock.locked_targets(lock)) == 0
    end

    test "reflects acquired targets", %{lock: lock} do
      ExecutorLock.acquire(lock, "alpha.service")
      ExecutorLock.acquire(lock, "beta.service")
      targets = ExecutorLock.locked_targets(lock)
      assert "alpha.service" in targets
      assert "beta.service" in targets
    end

    test "removes released targets", %{lock: lock} do
      ExecutorLock.acquire(lock, "alpha.service")
      ExecutorLock.release(lock, "alpha.service")
      refute "alpha.service" in ExecutorLock.locked_targets(lock)
    end
  end

  # ── concurrent processes ──────────────────────────────────────────────────

  describe "concurrent processes" do
    test "exactly one of two racing acquires succeeds for the same target", %{lock: lock} do
      target = "contested.service"

      # Fire two processes simultaneously, each trying to acquire the lock.
      tasks =
        for _i <- 1..2 do
          Task.async(fn -> ExecutorLock.acquire(lock, target) end)
        end

      results = Enum.map(tasks, &Task.await/1)

      ok_count = Enum.count(results, &(&1 == :ok))
      error_count = Enum.count(results, &match?({:error, :concurrent_execution}, &1))

      assert ok_count == 1,
             "Expected exactly one :ok acquire; got results: #{inspect(results)}"

      assert error_count == 1,
             "Expected exactly one :concurrent_execution; got results: #{inspect(results)}"
    end
  end
end

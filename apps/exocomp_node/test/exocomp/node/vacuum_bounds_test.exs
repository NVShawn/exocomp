defmodule Exocomp.Node.VacuumBoundsTest do
  @moduledoc """
  Focused tests for `Exocomp.Node.VacuumBounds`.

  All tests are `async: false` because they mutate Application env and use a
  private VacuumState GenServer instance per test.

  ## Invariants verified

  - Below-threshold pressure is not eligible.
  - Only `:critical` pressure is eligible.
  - Cooldown blocks a second execution.
  - Retry exhaustion blocks further attempts.
  - Caller-supplied paths are never accepted (only the installed config path).
  - Caller-supplied wider limits are never accepted (config caps everything).
  - User paths in config are rejected by validate_source/1.
  - Unknown paths in config are rejected by validate_source/1.
  - Valid system journal paths pass validate_source/1.
  - The returned bounds_map values are capped at the installed config limits.
  """

  use ExUnit.Case, async: false

  alias Exocomp.Node.Safety.Evidence
  alias Exocomp.Node.{VacuumBounds, VacuumState}

  # ── Config defaults used across tests ─────────────────────────────────────

  @log_source "/var/log/journal"
  @min_retention_secs 86_400
  @max_reclaim_bytes 104_857_600
  @min_free_space_bytes 536_870_912
  @cooldown_secs 3_600
  @max_retries 3

  # ── Setup / teardown ──────────────────────────────────────────────────────

  setup do
    # Snapshot and restore Application env around each test.
    prev_source = Application.get_env(:exocomp_node, :vacuum_log_source)
    prev_retention = Application.get_env(:exocomp_node, :vacuum_min_retention_secs)
    prev_reclaim = Application.get_env(:exocomp_node, :vacuum_max_reclaim_bytes)
    prev_free = Application.get_env(:exocomp_node, :vacuum_min_free_space_bytes)
    prev_cooldown = Application.get_env(:exocomp_node, :vacuum_cooldown_secs)
    prev_retries = Application.get_env(:exocomp_node, :vacuum_max_retries)
    prev_state_server = Application.get_env(:exocomp_node, :vacuum_state_server)

    # Install default bounds.
    Application.put_env(:exocomp_node, :vacuum_log_source, @log_source)
    Application.put_env(:exocomp_node, :vacuum_min_retention_secs, @min_retention_secs)
    Application.put_env(:exocomp_node, :vacuum_max_reclaim_bytes, @max_reclaim_bytes)
    Application.put_env(:exocomp_node, :vacuum_min_free_space_bytes, @min_free_space_bytes)
    Application.put_env(:exocomp_node, :vacuum_cooldown_secs, @cooldown_secs)
    Application.put_env(:exocomp_node, :vacuum_max_retries, @max_retries)

    # Start an isolated VacuumState instance for this test (not the named one).
    {:ok, state_pid} = VacuumState.start_link(name: nil)
    Application.put_env(:exocomp_node, :vacuum_state_server, state_pid)

    on_exit(fn ->
      restore_env(:vacuum_log_source, prev_source)
      restore_env(:vacuum_min_retention_secs, prev_retention)
      restore_env(:vacuum_max_reclaim_bytes, prev_reclaim)
      restore_env(:vacuum_min_free_space_bytes, prev_free)
      restore_env(:vacuum_cooldown_secs, prev_cooldown)
      restore_env(:vacuum_max_retries, prev_retries)
      restore_env(:vacuum_state_server, prev_state_server)

      # Stop the isolated VacuumState process if it's still alive.
      if Process.alive?(state_pid), do: GenServer.stop(state_pid)
    end)

    %{state_pid: state_pid}
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  # Build a minimal Evidence struct suitable for passing to check_eligible/1.
  defp make_evidence do
    %Evidence{
      schema_version: "1",
      evidence_id: "test-evidence-id",
      collector: "system.disk.pressure",
      collector_version: "1.0.0",
      target_id: @log_source,
      observed_at: DateTime.utc_now(),
      values: %{
        "used_bytes" => "10000",
        "free_bytes" => "5000",
        "total_bytes" => "15000",
        "used_pct" => "67"
      },
      integrity_hash: String.duplicate("a", 64)
    }
  end

  defp pressure_result(threshold) do
    {:ok, make_evidence(), threshold}
  end

  defp restore_env(key, nil), do: Application.delete_env(:exocomp_node, key)
  defp restore_env(key, val), do: Application.put_env(:exocomp_node, key, val)

  # ── Threshold gate ────────────────────────────────────────────────────────

  describe "threshold gate" do
    test "returns :below_threshold when pressure is :below_threshold" do
      assert {:error, :below_threshold} =
               VacuumBounds.check_eligible(pressure_result(:below_threshold))
    end

    test "returns :below_threshold when pressure is :warning" do
      # :warning is not sufficient; only :critical triggers eligibility.
      assert {:error, :below_threshold} = VacuumBounds.check_eligible(pressure_result(:warning))
    end

    test "returns :eligible when pressure is :critical" do
      assert {:ok, :eligible, _bounds} = VacuumBounds.check_eligible(pressure_result(:critical))
    end
  end

  # ── Source configuration ──────────────────────────────────────────────────

  describe "source configuration" do
    test "returns :source_not_configured when :vacuum_log_source is absent" do
      Application.delete_env(:exocomp_node, :vacuum_log_source)

      assert {:error, :source_not_configured} =
               VacuumBounds.check_eligible(pressure_result(:critical))
    end

    test "returns :source_not_configured when :vacuum_log_source is an empty string" do
      Application.put_env(:exocomp_node, :vacuum_log_source, "")

      assert {:error, :source_not_configured} =
               VacuumBounds.check_eligible(pressure_result(:critical))
    end
  end

  # ── Cooldown enforcement ──────────────────────────────────────────────────

  describe "cooldown enforcement" do
    test "returns :on_cooldown when cooldown has not elapsed", %{state_pid: state_pid} do
      # Record a success so last_executed_at is set to now.
      VacuumState.record_success(state_pid, @log_source)

      # With a 3600s cooldown and immediate re-check, we are on cooldown.
      assert {:error, :on_cooldown, %DateTime{}} =
               VacuumBounds.check_eligible(pressure_result(:critical))
    end

    test "returns :eligible when cooldown has fully elapsed", %{state_pid: state_pid} do
      # Set cooldown to 0 seconds so any gap is sufficient.
      Application.put_env(:exocomp_node, :vacuum_cooldown_secs, 0)
      VacuumState.record_success(state_pid, @log_source)

      assert {:ok, :eligible, _bounds} = VacuumBounds.check_eligible(pressure_result(:critical))
    end

    test "returns :eligible when no prior execution exists (first run)" do
      # No state for this mount — nil last_executed_at means no cooldown.
      assert {:ok, :eligible, _bounds} = VacuumBounds.check_eligible(pressure_result(:critical))
    end
  end

  # ── Retry limit enforcement ───────────────────────────────────────────────

  describe "retry limit enforcement" do
    test "returns :retry_exhausted when consecutive failures exceed max_retries",
         %{state_pid: state_pid} do
      # Record max_retries failures.
      for _ <- 1..@max_retries do
        VacuumState.record_failure(state_pid, @log_source)
      end

      assert {:error, :retry_exhausted, count} =
               VacuumBounds.check_eligible(pressure_result(:critical))

      assert count == @max_retries
    end

    test "returns :eligible when failures are below max_retries", %{state_pid: state_pid} do
      # One less than the limit is still eligible.
      for _ <- 1..(@max_retries - 1) do
        VacuumState.record_failure(state_pid, @log_source)
      end

      assert {:ok, :eligible, _bounds} = VacuumBounds.check_eligible(pressure_result(:critical))
    end
  end

  # ── Caller path rejection ─────────────────────────────────────────────────

  describe "caller path rejection" do
    test "check_eligible/1 accepts no path argument — callers cannot supply a path" do
      # The public arity is exactly 1.  There is no 2-arity variant.
      assert function_exported?(VacuumBounds, :check_eligible, 1)
      refute function_exported?(VacuumBounds, :check_eligible, 2)
    end

    test "the log_source in the returned bounds_map is always the installed config value" do
      # The config path is /var/log/journal.  Even if an attacker tries to pass a
      # different path via the Evidence struct, the bounds_map always reflects the
      # config, not any field in the Evidence struct.
      evidence_with_foreign_target =
        %Evidence{make_evidence() | target_id: "/home/attacker/evil"}

      result = VacuumBounds.check_eligible({:ok, evidence_with_foreign_target, :critical})

      assert {:ok, :eligible, bounds} = result
      assert bounds.log_source == @log_source
      refute bounds.log_source == "/home/attacker/evil"
    end
  end

  # ── Caller limit rejection ────────────────────────────────────────────────

  describe "caller limit rejection (bounds cannot be widened)" do
    test "check_eligible/1 accepts no limit arguments — arity is exactly 1" do
      assert function_exported?(VacuumBounds, :check_eligible, 1)
      refute function_exported?(VacuumBounds, :check_eligible, 2)
    end

    test "max_reclaim_bytes in bounds_map equals the installed config value" do
      # Install a specific, known value and verify the bounds_map reflects it.
      # 50 MiB
      installed_limit = 52_428_800
      Application.put_env(:exocomp_node, :vacuum_max_reclaim_bytes, installed_limit)

      assert {:ok, :eligible, bounds} = VacuumBounds.check_eligible(pressure_result(:critical))
      assert bounds.max_reclaim_bytes == installed_limit
    end

    test "bounds_map does not contain any key that a caller could use to supply a wider limit" do
      assert {:ok, :eligible, bounds} = VacuumBounds.check_eligible(pressure_result(:critical))

      # These are the only allowed keys in the bounds map.
      expected_keys =
        MapSet.new([:log_source, :min_retention_secs, :max_reclaim_bytes, :min_free_space_bytes])

      actual_keys = MapSet.new(Map.keys(bounds))
      assert actual_keys == expected_keys
    end
  end

  # ── validate_source/1 ─────────────────────────────────────────────────────

  describe "validate_source/1" do
    test "returns :ok for /var/log/journal" do
      assert :ok = VacuumBounds.validate_source("/var/log/journal")
    end

    test "returns :ok for /run/log/journal" do
      assert :ok = VacuumBounds.validate_source("/run/log/journal")
    end

    test "returns :ok for a subdirectory under /var/log/journal" do
      assert :ok = VacuumBounds.validate_source("/var/log/journal/abc123def456")
    end

    test "returns :ok for a subdirectory under /run/log/journal" do
      assert :ok = VacuumBounds.validate_source("/run/log/journal/machine-id")
    end

    test "returns {:error, :user_data_path} for a /home path" do
      assert {:error, :user_data_path} = VacuumBounds.validate_source("/home/alice/logs")
    end

    test "returns {:error, :user_data_path} for /tmp" do
      assert {:error, :user_data_path} = VacuumBounds.validate_source("/tmp")
    end

    test "returns {:error, :user_data_path} for a /tmp subdirectory" do
      assert {:error, :user_data_path} = VacuumBounds.validate_source("/tmp/something")
    end

    test "returns {:error, :user_data_path} for a /root path" do
      assert {:error, :user_data_path} = VacuumBounds.validate_source("/root/.config")
    end

    test "returns {:error, :unknown_path} for /var/log (not a journal path)" do
      assert {:error, :unknown_path} = VacuumBounds.validate_source("/var/log")
    end

    test "returns {:error, :unknown_path} for an arbitrary unknown path" do
      assert {:error, :unknown_path} = VacuumBounds.validate_source("/data/unknown")
    end

    test "returns {:error, :unknown_path} for an empty string" do
      assert {:error, :unknown_path} = VacuumBounds.validate_source("")
    end

    test "returns {:error, :unknown_path} for a non-binary value" do
      assert {:error, :unknown_path} = VacuumBounds.validate_source(nil)
      assert {:error, :unknown_path} = VacuumBounds.validate_source(:atom)
    end
  end

  # ── Bounds map is capped at installed limits ──────────────────────────────

  describe "bounds map contains only installed config values" do
    test "all four bounds fields are present and match Application config" do
      assert {:ok, :eligible, bounds} = VacuumBounds.check_eligible(pressure_result(:critical))

      assert bounds.log_source == @log_source
      assert bounds.min_retention_secs == @min_retention_secs
      assert bounds.max_reclaim_bytes == @max_reclaim_bytes
      assert bounds.min_free_space_bytes == @min_free_space_bytes
    end

    test "max_reclaim_bytes in bounds reflects the installed cap and cannot be widened" do
      # If the config says 50 MiB, no external input can make the bounds return 200 MiB.
      Application.put_env(:exocomp_node, :vacuum_max_reclaim_bytes, 52_428_800)

      assert {:ok, :eligible, bounds} = VacuumBounds.check_eligible(pressure_result(:critical))
      assert bounds.max_reclaim_bytes == 52_428_800
    end

    test "when user path is installed as source, check_eligible returns :invalid_source" do
      Application.put_env(:exocomp_node, :vacuum_log_source, "/home/user/logs")

      assert {:error, :invalid_source, :user_data_path} =
               VacuumBounds.check_eligible(pressure_result(:critical))
    end

    test "when unknown path is installed as source, check_eligible returns :invalid_source" do
      Application.put_env(:exocomp_node, :vacuum_log_source, "/data/custom")

      assert {:error, :invalid_source, :unknown_path} =
               VacuumBounds.check_eligible(pressure_result(:critical))
    end
  end

  # ── Integration: full happy path ──────────────────────────────────────────

  describe "full happy-path integration" do
    test "eligible result with :critical pressure, valid source, no cooldown, no failures" do
      assert {:ok, :eligible, bounds} = VacuumBounds.check_eligible(pressure_result(:critical))

      assert is_binary(bounds.log_source)
      assert is_integer(bounds.min_retention_secs) and bounds.min_retention_secs > 0
      assert is_integer(bounds.max_reclaim_bytes) and bounds.max_reclaim_bytes > 0
      assert is_integer(bounds.min_free_space_bytes) and bounds.min_free_space_bytes > 0
    end
  end
end

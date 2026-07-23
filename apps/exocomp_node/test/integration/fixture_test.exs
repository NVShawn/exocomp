defmodule Exocomp.Integration.FixtureTest do
  @moduledoc """
  ExUnit integration tests for the exocomp-fixture systemd service.

  These tests exercise the fixture daemon (EXOCOMP-69) and its installer/cleanup
  scripts (EXOCOMP-70) through all required fixture states.  They require a VM
  or privileged container running systemd as PID 1, and must be run as root (or
  with an account that has passwordless sudo).

  ## Running these tests

  Do NOT run via `make test` — that target uses an unprivileged Alpine container
  that lacks systemd.  Instead, run inside a privileged container or VM:

      # Install the fixture service first (requires root):
      make fixture-install

      # Run only the integration/systemd-tagged tests:
      make test-integration

  Or directly:

      MIX_ENV=test mix test --only integration \\
        apps/exocomp_node/test/integration/fixture_test.exs

  See docs/testing-systemd-fixture.md for full environment-setup instructions.

  ## Tag filters

  All tests in this module carry `@moduletag :integration` and
  `@moduletag :systemd`.  The umbrella test_helper.exs excludes both tags by
  default so that standard CI (which runs in a container without systemd) is
  unaffected.  Pass `--only integration` (or `--only systemd`) to opt in.
  """

  use ExUnit.Case

  @moduletag :integration
  @moduletag :systemd

  # ── Compile-time path resolution ────────────────────────────────────────────
  # __DIR__ is the directory containing this source file at compile time.
  # File location: apps/exocomp_node/test/integration/fixture_test.exs
  # Project root is four levels up:
  #   integration/ → test/ → exocomp_node/ → apps/ → <root>
  @project_root Path.expand("../../../..", __DIR__)
  @fixture_dir Path.join(@project_root, "test/fixtures/exocomp_fixture")
  @install_sh Path.join(@fixture_dir, "install.sh")
  @cleanup_sh Path.join(@fixture_dir, "cleanup.sh")

  # ── Runtime paths ───────────────────────────────────────────────────────────
  # Where install.sh places the service resources.
  @service_name "exocomp-fixture"
  @fixture_bin "/usr/local/bin/exocomp-fixture"
  @fixture_unit "/etc/systemd/system/exocomp-fixture.service"
  @fixture_state_dir "/run/exocomp-fixture"
  @mode_file Path.join(@fixture_state_dir, "mode")
  @health_url "http://127.0.0.1:8877/health"

  # ── Timeouts ────────────────────────────────────────────────────────────────
  # How long to poll for a service-state transition.
  @state_timeout_ms 15_000
  # Generous timeout for restart-failure: StartLimitBurst=3 within 30 s.
  @restart_burst_timeout_ms 35_000
  # Brief settle period after a mode write before asserting.
  @settle_ms 500

  # ── Lifecycle ───────────────────────────────────────────────────────────────

  setup do
    # Snapshot active non-fixture services BEFORE the fixture is installed.
    # Used by tests 7 and 10 to verify isolation.
    before_snap = snapshot_non_fixture_services()

    # Install the fixture and wait for it to be active.
    install_fixture!()

    # Register cleanup regardless of test outcome so the environment stays clean.
    on_exit(fn ->
      # Restore active mode so the daemon exits cleanly, then clean up.
      reset_mode()
      :timer.sleep(@settle_ms)
      cleanup_fixture()
    end)

    %{before_snap: before_snap}
  end

  # ── Test 1: install ─────────────────────────────────────────────────────────

  test "1. install: fixture installs cleanly and service reaches active state" do
    # The setup block already installed and confirmed active state.
    # Here we explicitly assert all expected artifacts and a healthy health endpoint.
    assert service_active?(),
           "service should be in the 'active' state immediately after install"

    assert health_ok?(),
           "health endpoint should return HTTP 200 {status: ok} when service is active"

    assert File.exists?(@fixture_bin),
           "fixture binary should be installed at #{@fixture_bin}"

    assert File.exists?(@fixture_unit),
           "unit file should be installed at #{@fixture_unit}"
  end

  # ── Test 2: start/stop ──────────────────────────────────────────────────────

  test "2. start/stop: service can be stopped and restarted via systemctl" do
    assert service_active?()

    # Stop the service.
    {_, 0} = run_systemctl(["stop", @service_name])

    assert :ok ==
             wait_for_condition(
               fn -> service_state() in ["inactive", "failed"] end,
               @state_timeout_ms
             ),
           "service should reach inactive/failed state after systemctl stop"

    assert service_state() in ["inactive", "failed"],
           "systemctl stop should leave the service in inactive or failed state"

    # Restart the service.
    {_, 0} = run_systemctl(["start", @service_name])

    assert :ok == wait_for_state("active", @state_timeout_ms),
           "service should reach active state after systemctl start"

    assert service_active?(),
           "service should be active after restart"

    assert health_ok?(),
           "health endpoint should return ok after restart"
  end

  # ── Test 3: crash ───────────────────────────────────────────────────────────

  test "3. crash: fixture enters failed state on demand; systemd reports failed" do
    assert service_active?()

    # Writing 'failed' to the mode file causes the daemon to exit with code 1.
    # systemd will attempt to restart it (Restart=on-failure), but since the
    # service exits immediately on every start when mode=failed, it will quickly
    # exhaust StartLimitBurst and land in the 'failed' ActiveState.
    set_mode("failed")

    assert :ok == wait_for_state("failed", @restart_burst_timeout_ms),
           "service should reach 'failed' state after crash mode is set"

    assert service_state() == "failed",
           "systemd ActiveState should be 'failed' after crash mode"
  end

  # ── Test 4: degrade ─────────────────────────────────────────────────────────

  test "4. degrade: fixture enters degraded mode; systemd shows active but health returns unhealthy" do
    assert service_active?()

    # 'degraded' mode keeps the process alive (systemd sees it as active) but
    # the health endpoint returns HTTP 503 with {"status": "degraded"}.
    set_mode("degraded")

    # Allow up to one poll interval (1 s) plus buffer for the mode to take effect.
    :timer.sleep(2_000)

    # The process must still be running — systemd should report active.
    assert service_active?(),
           "systemd should still show 'active' in degraded mode (process is alive)"

    # The health endpoint must disagree and report unhealthy.
    assert health_degraded?(),
           "health endpoint should return HTTP 503 in degraded mode"
  end

  # ── Test 5: flap ────────────────────────────────────────────────────────────

  test "5. flap: flapping mode causes repeated restart events visible to systemctl" do
    assert service_active?()

    # 'flapping' causes the daemon to exit with code 1 immediately, triggering
    # rapid restart cycles by systemd (Restart=on-failure, RestartSec=1 s).
    set_mode("flapping")

    # Wait a few seconds for at least one restart to complete.
    :timer.sleep(3_000)

    restarts = service_restart_count()

    assert restarts > 0,
           "expected at least one restart in flapping mode; " <>
             "systemd NRestarts property was #{restarts}"
  end

  # ── Test 6: restart-failure ─────────────────────────────────────────────────

  test "6. restart-failure: fixture exhausts StartLimitBurst; systemd reports failed" do
    assert service_active?()

    # 'restart-failure' exits immediately on every start, exhausting
    # StartLimitBurst=3 within StartLimitIntervalSec=30 s.  systemd transitions
    # the unit to ActiveState=failed after the burst limit is hit.
    set_mode("restart-failure")

    assert :ok ==
             wait_for_condition(
               fn -> service_state() == "failed" end,
               @restart_burst_timeout_ms
             ),
           "service should reach 'failed' state after exhausting StartLimitBurst; " <>
             "current state: #{service_state()}"

    assert service_state() == "failed",
           "systemd ActiveState should be 'failed' after restart burst exhausted"
  end

  # ── Test 7: cleanup ─────────────────────────────────────────────────────────

  test "7. cleanup: cleanup.sh leaves no fixture files or units; non-fixture services untouched",
       %{before_snap: before_snap} do
    assert service_active?()

    # Run cleanup explicitly and assert its exit code before on_exit fires.
    {output, exit_code} = run_bash(@cleanup_sh)

    assert exit_code == 0,
           "cleanup.sh should exit 0; got #{exit_code}\n#{output}"

    # Allow systemd to finish daemon-reload.
    :timer.sleep(1_500)

    # ── Fixture artifacts must be gone ──────────────────────────────────────

    refute File.exists?(@fixture_bin),
           "fixture binary #{@fixture_bin} should not exist after cleanup"

    refute File.exists?(@fixture_unit),
           "unit file #{@fixture_unit} should not exist after cleanup"

    refute File.exists?(@fixture_state_dir),
           "state dir #{@fixture_state_dir} should not exist after cleanup"

    # is-enabled exits non-zero for unknown/disabled units.
    {_, enabled_exit} = run_systemctl(["is-enabled", @service_name])

    assert enabled_exit != 0,
           "service should not be enabled after cleanup (is-enabled must return non-zero)"

    # ── Non-fixture services must be unchanged ───────────────────────────────

    after_snap = snapshot_non_fixture_services()

    assert before_snap == after_snap,
           "non-fixture active service set should be identical before and after " <>
             "install+cleanup cycle;\n" <>
             "removed: #{inspect(before_snap -- after_snap)}\n" <>
             "added: #{inspect(after_snap -- before_snap)}"
  end

  # ── Test 8: health vs systemd divergence ────────────────────────────────────

  test "8. health vs systemd divergence: health endpoint can disagree with systemctl is-active" do
    assert service_active?()

    # Enter degraded mode: systemd reports 'active' (process is alive) but the
    # health endpoint returns HTTP 503 — demonstrating the two observation planes
    # can give contradictory answers at the same instant.
    set_mode("degraded")
    :timer.sleep(2_000)

    # systemctl is-active exits 0 when the process is running.
    {_, is_active_exit} = run_systemctl(["is-active", "--quiet", @service_name])

    assert is_active_exit == 0,
           "systemctl is-active should return 0 (process is running) in degraded mode"

    # Health endpoint should return 503.
    health_code = health_status_code()

    assert health_code == 503,
           "health endpoint should return 503 in degraded mode; got #{health_code}"

    # The two observations disagree — this is the divergence scenario.
    assert is_active_exit == 0 and health_code == 503,
           "expected divergence: systemctl is-active=0 (active) AND health HTTP=503 (unhealthy)"
  end

  # ── Test 9: repeated fixture setup ──────────────────────────────────────────

  test "9. repeated fixture setup: idempotent install+cleanup cycle succeeds multiple times" do
    # Cycle 1 was already completed by the setup block.
    # Run two additional full cycles to verify idempotency.
    for cycle <- 2..3 do
      cleanup_fixture()

      assert :ok ==
               wait_for_condition(fn -> !fixture_installed?() end, 10_000),
             "fixture should be fully removed before cycle #{cycle}"

      install_fixture!()

      assert service_active?(),
             "service should be active after install cycle #{cycle}"

      assert health_ok?(),
             "health endpoint should return ok after install cycle #{cycle}"
    end
  end

  # ── Test 10: non-fixture isolation ──────────────────────────────────────────

  test "10. non-fixture isolation: verify no non-fixture services or files were modified",
       %{before_snap: before_snap} do
    assert service_active?()

    # Exercise the fixture with a mode transition to confirm activity.
    set_mode("degraded")
    :timer.sleep(1_000)
    reset_mode()
    :timer.sleep(1_500)
    assert service_active?()

    # Remove the fixture before comparing service snapshots.
    cleanup_fixture()

    assert :ok ==
             wait_for_condition(fn -> !fixture_installed?() end, 10_000),
           "fixture should be fully removed before isolation check"

    # Active non-fixture services must be unchanged.
    after_snap = snapshot_non_fixture_services()

    assert before_snap == after_snap,
           "non-fixture active service set should be identical before and after fixture lifecycle;\n" <>
             "removed: #{inspect(before_snap -- after_snap)}\n" <>
             "added: #{inspect(after_snap -- before_snap)}"

    # Verify no fixture-named files linger outside expected runtime paths.
    refute File.exists?(@fixture_bin),
           "#{@fixture_bin} should not exist after cleanup"

    refute File.exists?(@fixture_unit),
           "#{@fixture_unit} should not exist after cleanup"

    refute File.exists?(@fixture_state_dir),
           "#{@fixture_state_dir} should not exist after cleanup"
  end

  # ── Private helpers ──────────────────────────────────────────────────────────

  # Install the fixture service and block until it is active.
  defp install_fixture! do
    {output, exit_code} = run_bash(@install_sh)
    assert exit_code == 0, "install.sh failed (exit #{exit_code})\n#{output}"

    assert :ok == wait_for_state("active", @state_timeout_ms),
           "service did not reach 'active' state within #{@state_timeout_ms} ms after install"
  end

  # Remove the fixture service.  Safe to call when not installed (idempotent).
  defp cleanup_fixture do
    run_bash(@cleanup_sh)
    :ok
  end

  # Run a systemctl sub-command and return {stdout_and_stderr, exit_code}.
  defp run_systemctl(args) do
    System.cmd("systemctl", args, stderr_to_stdout: true)
  end

  # Run a bash script and return {stdout_and_stderr, exit_code}.
  defp run_bash(script_path) do
    System.cmd("bash", [script_path], stderr_to_stdout: true)
  end

  # Return the ActiveState property value for the fixture service.
  defp service_state do
    {output, _} = run_systemctl(["show", @service_name, "--property=ActiveState"])
    parse_systemd_property(output, "ActiveState")
  end

  # True when the service ActiveState is "active".
  defp service_active? do
    service_state() == "active"
  end

  # Return the NRestarts value for the fixture service (integer).
  defp service_restart_count do
    {output, _} = run_systemctl(["show", @service_name, "--property=NRestarts"])
    parse_systemd_property(output, "NRestarts") |> String.to_integer()
  rescue
    _ -> 0
  end

  # Parse a `KEY=VALUE` line from `systemctl show` output.
  defp parse_systemd_property(output, key) do
    output
    |> String.split("\n")
    |> Enum.find_value("", fn line ->
      case String.split(line, "=", parts: 2) do
        [^key, val] -> String.trim(val)
        _ -> nil
      end
    end)
  end

  # Write a mode string to the fixture's mode file.
  # The daemon polls this file every ~1 s and reacts within one poll cycle.
  defp set_mode(mode) do
    File.mkdir_p!(@fixture_state_dir)
    File.write!(@mode_file, mode <> "\n")
  end

  # Remove the mode file, causing the daemon to revert to 'active' mode.
  defp reset_mode do
    File.rm(@mode_file)
    :ok
  end

  # Return the HTTP status code from the health endpoint (integer), or 0 on error.
  defp health_status_code do
    case System.cmd(
           "curl",
           ["-s", "-o", "/dev/null", "-w", "%{http_code}", "--max-time", "3", @health_url],
           stderr_to_stdout: true
         ) do
      {code_str, 0} ->
        code_str |> String.trim() |> String.to_integer()

      _ ->
        0
    end
  rescue
    _ -> 0
  end

  # True when the health endpoint returns HTTP 200.
  defp health_ok? do
    health_status_code() == 200
  end

  # True when the health endpoint returns HTTP 503 (degraded).
  defp health_degraded? do
    health_status_code() == 503
  end

  # True when either the binary or the unit file exists (fixture is installed).
  defp fixture_installed? do
    File.exists?(@fixture_bin) || File.exists?(@fixture_unit)
  end

  # Block until the service reaches expected_state, or until timeout_ms elapses.
  # Returns :ok on success and :timeout on failure.
  defp wait_for_state(expected_state, timeout_ms) do
    wait_for_condition(fn -> service_state() == expected_state end, timeout_ms)
  end

  # Block until condition_fn returns true, polling every 500 ms.
  # Returns :ok when the condition is met, :timeout otherwise.
  defp wait_for_condition(condition_fn, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    poll_until(condition_fn, deadline)
  end

  defp poll_until(condition_fn, deadline) do
    if condition_fn.() do
      :ok
    else
      if System.monotonic_time(:millisecond) >= deadline do
        :timeout
      else
        :timer.sleep(500)
        poll_until(condition_fn, deadline)
      end
    end
  end

  # Capture the sorted list of active non-fixture service unit names.
  # Used to verify that the fixture lifecycle does not disturb other services.
  defp snapshot_non_fixture_services do
    {output, _} =
      System.cmd(
        "systemctl",
        [
          "list-units",
          "--type=service",
          "--state=active",
          "--no-legend",
          "--no-pager",
          "--plain"
        ],
        stderr_to_stdout: true
      )

    output
    |> String.split("\n")
    |> Enum.reject(&String.contains?(&1, @service_name))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    # Keep only the first field (unit name) to avoid spurious diffs on description
    |> Enum.map(&hd(String.split(&1)))
    |> Enum.sort()
  end
end

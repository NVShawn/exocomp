"""
Tests for the exocomp-fixture daemon.

These tests launch the fixture as a subprocess, interact with its HTTP health
endpoint and mode-control file, then verify correct behaviour.  No systemd
installation is required — the tests work against the raw Python process.

Run with:
    python -m pytest test/fixtures/exocomp_fixture/test/test_fixture.py -v
    # or
    python -m unittest discover -s test/fixtures/exocomp_fixture/test -v
"""

import http.client
import json
import os
import pathlib
import signal
import subprocess
import sys
import tempfile
import time
import unittest

# Path to the fixture script relative to the repo root.
_REPO_ROOT = pathlib.Path(__file__).parents[4]
FIXTURE_BIN = _REPO_ROOT / "test" / "fixtures" / "exocomp_fixture" / "bin" / "exocomp-fixture"

# Use an unprivileged port range that is unlikely to conflict.
# Tests bind to 127.0.0.1 only.
_BASE_PORT = int(os.environ.get("FIXTURE_TEST_BASE_PORT", "18877"))


def _port_for_test(offset: int) -> int:
    return _BASE_PORT + offset


def _get_health(port: int, timeout: float = 2.0) -> tuple[int, dict]:
    """Return (status_code, parsed_json_body) from GET /health."""
    conn = http.client.HTTPConnection("127.0.0.1", port, timeout=timeout)
    conn.request("GET", "/health")
    resp = conn.getresponse()
    body = json.loads(resp.read().decode())
    conn.close()
    return resp.status, body


def _wait_for_health(port: int, deadline: float = 5.0) -> bool:
    """Wait up to *deadline* seconds for the health endpoint to respond."""
    end = time.monotonic() + deadline
    while time.monotonic() < end:
        try:
            _get_health(port, timeout=0.5)
            return True
        except (ConnectionRefusedError, OSError, http.client.HTTPException):
            time.sleep(0.1)
    return False


def _wait_for_exit(proc: subprocess.Popen, deadline: float = 5.0) -> int | None:
    """Wait up to *deadline* seconds for *proc* to exit.  Returns exit code or None."""
    end = time.monotonic() + deadline
    while time.monotonic() < end:
        rc = proc.poll()
        if rc is not None:
            return rc
        time.sleep(0.05)
    return None


def _write_mode(state_dir: pathlib.Path, mode: str) -> None:
    mode_file = state_dir / "mode"
    mode_file.write_text(mode + "\n", encoding="ascii")


def _read_marker(state_dir: pathlib.Path) -> str | None:
    marker = state_dir / "workload.marker"
    try:
        return marker.read_text(encoding="ascii").strip()
    except OSError:
        return None


def _start_fixture(state_dir: pathlib.Path, port: int, extra_env: dict | None = None) -> subprocess.Popen:
    """Start the fixture daemon and return the Popen object."""
    env = os.environ.copy()
    env["FIXTURE_STATE_DIR"] = str(state_dir)
    env["FIXTURE_PORT"] = str(port)
    env["FIXTURE_ADDR"] = "127.0.0.1"
    env["FIXTURE_POLL_INTERVAL"] = "0.1"  # fast poll for tests
    if extra_env:
        env.update(extra_env)

    return subprocess.Popen(
        [sys.executable, str(FIXTURE_BIN)],
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


class TestFixtureActiveMode(unittest.TestCase):
    """Fixture starts in active mode, returns healthy status."""

    def setUp(self):
        self._tmpdir = tempfile.TemporaryDirectory()
        self.state_dir = pathlib.Path(self._tmpdir.name)
        self.port = _port_for_test(0)
        self.proc = _start_fixture(self.state_dir, self.port)

    def tearDown(self):
        if self.proc.poll() is None:
            self.proc.terminate()
            self.proc.wait(timeout=5)
        self._tmpdir.cleanup()

    def test_health_returns_ok_when_active(self):
        self.assertTrue(_wait_for_health(self.port), "fixture did not start in time")
        code, body = _get_health(self.port)
        self.assertEqual(code, 200)
        self.assertEqual(body, {"status": "ok"})

    def test_workload_marker_is_created(self):
        self.assertTrue(_wait_for_health(self.port), "fixture did not start in time")
        # Give the main loop one iteration to write the marker.
        time.sleep(0.3)
        marker_text = _read_marker(self.state_dir)
        self.assertIsNotNone(marker_text, "workload.marker was not created")
        # Must be a valid float (epoch timestamp).
        ts = float(marker_text)
        self.assertGreater(ts, 0)

    def test_sigterm_causes_clean_shutdown(self):
        self.assertTrue(_wait_for_health(self.port), "fixture did not start in time")
        self.proc.send_signal(signal.SIGTERM)
        rc = _wait_for_exit(self.proc, deadline=5.0)
        self.assertIsNotNone(rc, "fixture did not exit after SIGTERM")
        self.assertEqual(rc, 0)

    def test_marker_removed_on_shutdown(self):
        self.assertTrue(_wait_for_health(self.port), "fixture did not start in time")
        time.sleep(0.3)  # ensure marker exists
        self.proc.send_signal(signal.SIGTERM)
        _wait_for_exit(self.proc, deadline=5.0)
        marker = self.state_dir / "workload.marker"
        self.assertFalse(marker.exists(), "workload.marker was not removed on shutdown")


class TestFixtureDegradedMode(unittest.TestCase):
    """Fixture starts degraded (via mode file) and returns degraded health."""

    def setUp(self):
        self._tmpdir = tempfile.TemporaryDirectory()
        self.state_dir = pathlib.Path(self._tmpdir.name)
        self.port = _port_for_test(1)
        _write_mode(self.state_dir, "degraded")
        self.proc = _start_fixture(self.state_dir, self.port)

    def tearDown(self):
        if self.proc.poll() is None:
            self.proc.terminate()
            self.proc.wait(timeout=5)
        self._tmpdir.cleanup()

    def test_health_returns_degraded_when_mode_is_degraded(self):
        self.assertTrue(_wait_for_health(self.port), "fixture did not start in time")
        code, body = _get_health(self.port)
        # Process is alive; health endpoint must report degraded.
        self.assertEqual(code, 503)
        self.assertEqual(body, {"status": "degraded"})

    def test_process_is_still_alive_while_degraded(self):
        """Health disagrees with systemd active state: process up but health bad."""
        self.assertTrue(_wait_for_health(self.port), "fixture did not start in time")
        # Poll interval is 0.1 s; after a short wait the process must still be running.
        time.sleep(0.5)
        self.assertIsNone(self.proc.poll(), "fixture exited unexpectedly in degraded mode")


class TestFixtureModeTransitions(unittest.TestCase):
    """Mode transitions while the process is running."""

    def setUp(self):
        self._tmpdir = tempfile.TemporaryDirectory()
        self.state_dir = pathlib.Path(self._tmpdir.name)
        self.port = _port_for_test(2)
        self.proc = _start_fixture(self.state_dir, self.port)
        self.assertTrue(_wait_for_health(self.port), "fixture did not start in time")

    def tearDown(self):
        if self.proc.poll() is None:
            self.proc.terminate()
            self.proc.wait(timeout=5)
        self._tmpdir.cleanup()

    def test_active_to_degraded_transition(self):
        # Confirm healthy before transition.
        code, body = _get_health(self.port)
        self.assertEqual(code, 200)
        self.assertEqual(body["status"], "ok")

        # Transition to degraded.
        _write_mode(self.state_dir, "degraded")
        # Poll interval is 0.1 s; wait for the daemon to pick up the change.
        deadline = time.monotonic() + 2.0
        while time.monotonic() < deadline:
            code, body = _get_health(self.port)
            if code == 503:
                break
            time.sleep(0.1)

        self.assertEqual(code, 503)
        self.assertEqual(body, {"status": "degraded"})
        self.assertIsNone(self.proc.poll(), "process must remain alive in degraded mode")

    def test_degraded_to_active_transition(self):
        _write_mode(self.state_dir, "degraded")
        # Wait for degraded to take effect.
        deadline = time.monotonic() + 2.0
        while time.monotonic() < deadline:
            code, _ = _get_health(self.port)
            if code == 503:
                break
            time.sleep(0.1)

        # Transition back to active.
        _write_mode(self.state_dir, "active")
        deadline = time.monotonic() + 2.0
        while time.monotonic() < deadline:
            code, body = _get_health(self.port)
            if code == 200:
                break
            time.sleep(0.1)

        self.assertEqual(code, 200)
        self.assertEqual(body, {"status": "ok"})

    def test_active_to_failed_causes_exit_code_1(self):
        _write_mode(self.state_dir, "failed")
        rc = _wait_for_exit(self.proc, deadline=3.0)
        self.assertIsNotNone(rc, "fixture did not exit after 'failed' mode")
        self.assertEqual(rc, 1)

    def test_active_to_flapping_causes_exit_code_1(self):
        _write_mode(self.state_dir, "flapping")
        rc = _wait_for_exit(self.proc, deadline=3.0)
        self.assertIsNotNone(rc, "fixture did not exit after 'flapping' mode")
        self.assertEqual(rc, 1)

    def test_active_to_restart_failure_causes_exit_code_1(self):
        _write_mode(self.state_dir, "restart-failure")
        rc = _wait_for_exit(self.proc, deadline=3.0)
        self.assertIsNotNone(rc, "fixture did not exit after 'restart-failure' mode")
        self.assertEqual(rc, 1)


class TestFixtureExitModesAtStartup(unittest.TestCase):
    """When started with an exit-mode file already in place, fixture exits immediately."""

    def _run_with_mode(self, mode: str) -> tuple[int, bytes]:
        with tempfile.TemporaryDirectory() as tmpdir:
            state_dir = pathlib.Path(tmpdir)
            _write_mode(state_dir, mode)
            proc = _start_fixture(state_dir, _port_for_test(3))
            rc = _wait_for_exit(proc, deadline=3.0)
            _, stderr = proc.communicate(timeout=2)
        return rc, stderr

    def test_failed_mode_exits_immediately(self):
        rc, _ = self._run_with_mode("failed")
        self.assertEqual(rc, 1)

    def test_flapping_mode_exits_immediately(self):
        rc, _ = self._run_with_mode("flapping")
        self.assertEqual(rc, 1)

    def test_restart_failure_mode_exits_immediately(self):
        rc, _ = self._run_with_mode("restart-failure")
        self.assertEqual(rc, 1)

    def test_active_mode_at_startup_does_not_exit_immediately(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            state_dir = pathlib.Path(tmpdir)
            _write_mode(state_dir, "active")
            port = _port_for_test(4)
            proc = _start_fixture(state_dir, port)
            try:
                started = _wait_for_health(port, deadline=5.0)
                self.assertTrue(started, "fixture did not start in active mode")
                # Confirm still alive after startup.
                self.assertIsNone(proc.poll())
            finally:
                proc.terminate()
                proc.wait(timeout=5)

    def test_degraded_mode_at_startup_does_not_exit_immediately(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            state_dir = pathlib.Path(tmpdir)
            _write_mode(state_dir, "degraded")
            port = _port_for_test(5)
            proc = _start_fixture(state_dir, port)
            try:
                started = _wait_for_health(port, deadline=5.0)
                self.assertTrue(started, "fixture did not start in degraded mode")
                self.assertIsNone(proc.poll())
            finally:
                proc.terminate()
                proc.wait(timeout=5)


class TestFixtureHealthEndpointContract(unittest.TestCase):
    """HTTP contract: correct status codes, Content-Type, and JSON shape."""

    def setUp(self):
        self._tmpdir = tempfile.TemporaryDirectory()
        self.state_dir = pathlib.Path(self._tmpdir.name)
        self.port = _port_for_test(6)
        self.proc = _start_fixture(self.state_dir, self.port)
        self.assertTrue(_wait_for_health(self.port), "fixture did not start")

    def tearDown(self):
        if self.proc.poll() is None:
            self.proc.terminate()
            self.proc.wait(timeout=5)
        self._tmpdir.cleanup()

    def _raw_get(self, path: str) -> http.client.HTTPResponse:
        conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=2)
        conn.request("GET", path)
        resp = conn.getresponse()
        resp.read()  # consume body so connection can be reused
        conn.close()
        return resp

    def test_health_200_active(self):
        code, body = _get_health(self.port)
        self.assertEqual(code, 200)
        self.assertIn("status", body)
        self.assertEqual(body["status"], "ok")

    def test_health_503_degraded(self):
        _write_mode(self.state_dir, "degraded")
        deadline = time.monotonic() + 2.0
        while time.monotonic() < deadline:
            code, body = _get_health(self.port)
            if code == 503:
                break
            time.sleep(0.1)
        self.assertEqual(code, 503)
        self.assertEqual(body.get("status"), "degraded")

    def test_unknown_path_returns_404(self):
        resp = self._raw_get("/nonexistent")
        self.assertEqual(resp.status, 404)

    def test_root_path_returns_404(self):
        resp = self._raw_get("/")
        self.assertEqual(resp.status, 404)


class TestFixtureCliFlags(unittest.TestCase):
    """CLI flag parsing: --port, --addr, --state-dir override defaults."""

    def test_custom_port_via_env(self):
        port = _port_for_test(7)
        with tempfile.TemporaryDirectory() as tmpdir:
            env = os.environ.copy()
            env["FIXTURE_PORT"] = str(port)
            env["FIXTURE_ADDR"] = "127.0.0.1"
            env["FIXTURE_STATE_DIR"] = tmpdir
            env["FIXTURE_POLL_INTERVAL"] = "0.1"
            proc = subprocess.Popen(
                [sys.executable, str(FIXTURE_BIN)],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            try:
                self.assertTrue(_wait_for_health(port), "fixture did not bind on custom port")
                code, body = _get_health(port)
                self.assertEqual(code, 200)
            finally:
                proc.terminate()
                proc.wait(timeout=5)

    def test_custom_port_via_cli_flag(self):
        port = _port_for_test(8)
        with tempfile.TemporaryDirectory() as tmpdir:
            env = os.environ.copy()
            env.pop("FIXTURE_PORT", None)
            env["FIXTURE_POLL_INTERVAL"] = "0.1"
            proc = subprocess.Popen(
                [
                    sys.executable,
                    str(FIXTURE_BIN),
                    "--port", str(port),
                    "--addr", "127.0.0.1",
                    "--state-dir", tmpdir,
                ],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            try:
                self.assertTrue(_wait_for_health(port), "fixture did not bind on custom port")
            finally:
                proc.terminate()
                proc.wait(timeout=5)


if __name__ == "__main__":
    unittest.main(verbosity=2)

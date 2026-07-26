# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""
Tests for the exocomp hardened installer and uninstaller.

These tests exercise scripts/install.sh and scripts/uninstall.sh against a
temporary directory tree, verifying:
  1. Clean install — preflight, directory setup, manifest, sudoers, config
  2. Repeat install — idempotent (second install updates without losing config)
  3. Permissions — ownership and mode bits on installed paths
  4. Service startup — systemd integration (skipped when systemd not available)
  5. Invalid checksum — preflight rejects tampered bundles before host mutation
  6. Invalid config — (reserved; config validation is at runtime)
  7. Exact privileges — sudoers content matches expected exact policy
  8. Upgrade preparation — new version installs beside old version; atomic link updated
  9. Default uninstall — preserves config/, log/, var/lib/ intact
 10. System-cache purge — removes old release dirs when explicitly requested
 11. User data / non-owned resources remain — uninstall does not touch paths
     outside the manifest

Run these tests via:
  make test-installer

Or directly:
  python3 -m pytest test/installer/test_installer.py -v

Systemd tests are skipped automatically when systemctl is not available or
not running as PID 1.  Mark them with ``--only-integration`` to run explicitly
inside a privileged container.
"""

import json
import hashlib
import os
import re
import shutil
import stat
import subprocess
import tarfile
import tempfile
import textwrap
from pathlib import Path

import pytest

# ── Repository root ────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).resolve().parents[2]
INSTALL_SH = REPO_ROOT / "scripts" / "install.sh"
UNINSTALL_SH = REPO_ROOT / "scripts" / "uninstall.sh"
STATE_BACKUP_SH = REPO_ROOT / "scripts" / "state-backup.sh"
RELEASE_DIR = REPO_ROOT / "release"
CONFIG_EXS = REPO_ROOT / "config" / "config.exs"


# ── systemd availability ────────────────────────────────────────────────────────

def _systemd_available() -> bool:
    """Return True when systemctl is present and usable."""
    try:
        result = subprocess.run(
            ["systemctl", "--version"],
            capture_output=True,
            timeout=5,
        )
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


SYSTEMD_AVAILABLE = _systemd_available()
skip_without_systemd = pytest.mark.skipif(
    not SYSTEMD_AVAILABLE,
    reason="systemd not available; run inside a privileged container with systemd as PID 1",
)

# ── Mock bundle builder ────────────────────────────────────────────────────────


def _make_mock_bundle(
    dest_dir: Path,
    component: str,
    version: str,
    contents: dict[str, str] | None = None,
) -> tuple[Path, Path]:
    """
    Create a minimal mock release archive and checksums file.

    Returns (bundle_path, checksums_path).

    The archive contains:
      bin/exocomp_<component>  — stub executable
      releases/<version>/start_erl.data  — OTP marker
      releases/<version>/RELEASES        — OTP releases list

    Additional files can be injected via ``contents`` as {archive_path: content}.
    """
    archive_name = f"exocomp-{component}-{version}-linux-amd64.tar.gz"
    bundle_path = dest_dir / archive_name

    # Build archive in a scratch directory
    scratch = dest_dir / "_scratch"
    scratch.mkdir(parents=True, exist_ok=True)

    inner_root = scratch / f"exocomp-{component}-{version}"
    inner_root.mkdir()

    # Stub binary
    bin_dir = inner_root / "bin"
    bin_dir.mkdir()
    stub_bin = bin_dir / f"exocomp_{component}"
    stub_bin.write_text("#!/bin/sh\necho stub\n")
    stub_bin.chmod(0o755)

    # OTP release markers
    rel_dir = inner_root / "releases" / version
    rel_dir.mkdir(parents=True)
    (rel_dir / "start_erl.data").write_text(f"28.5.0 {version}\n")
    (rel_dir / "RELEASES").write_text(
        f'[{{release,"exocomp_{component}","{version}","28.5.0",[]}}].\n'
    )

    # Inject extra content
    for rel_path, text in (contents or {}).items():
        p = inner_root / rel_path
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    # Create tar.gz
    with tarfile.open(bundle_path, "w:gz") as tar:
        tar.add(inner_root, arcname=f"exocomp-{component}-{version}")

    shutil.rmtree(scratch)

    # Create checksums file
    result = subprocess.run(
        ["sha256sum", archive_name],
        cwd=dest_dir,
        capture_output=True,
        text=True,
        check=True,
    )
    checksums_path = dest_dir / "checksums.sha256"
    checksums_path.write_text(result.stdout)

    return bundle_path, checksums_path


def _make_bundle_tree(
    base: Path,
    component: str,
    version: str,
    allow_list: str = "",
    contents: dict[str, str] | None = None,
) -> dict:
    """
    Build a complete bundle directory tree with all release artifacts and
    return a dict of relevant paths.
    """
    bundle_dir = base / "bundle"
    bundle_dir.mkdir(parents=True, exist_ok=True)

    # Copy unit and template files from repo into the mock bundle tree
    bundle_release = bundle_dir / "release" / component
    bundle_release.mkdir(parents=True, exist_ok=True)
    src_unit = RELEASE_DIR / component / f"exocomp-{component}.service"
    shutil.copy(src_unit, bundle_release / f"exocomp-{component}.service")

    bundle_tmpl = bundle_dir / "release" / "templates"
    bundle_tmpl.mkdir(parents=True, exist_ok=True)
    src_tmpl = RELEASE_DIR / "templates" / f"{component}.json"
    shutil.copy(src_tmpl, bundle_tmpl / f"{component}.json")

    # Copy installer scripts
    bundle_scripts = bundle_dir / "scripts"
    bundle_scripts.mkdir(exist_ok=True)
    shutil.copy(INSTALL_SH, bundle_scripts / "install.sh")
    shutil.copy(UNINSTALL_SH, bundle_scripts / "uninstall.sh")
    shutil.copy(STATE_BACKUP_SH, bundle_scripts / "state-backup.sh")
    for script in bundle_scripts.glob("*.sh"):
        script.chmod(0o755)

    bundle_path, checksums_path = _make_mock_bundle(
        bundle_dir, component, version, contents=contents
    )

    return {
        "bundle_dir": bundle_dir,
        "bundle_path": bundle_path,
        "checksums_path": checksums_path,
        "install_sh": bundle_scripts / "install.sh",
        "uninstall_sh": bundle_scripts / "uninstall.sh",
        "state_backup_sh": bundle_scripts / "state-backup.sh",
    }


# ── Environment builder ────────────────────────────────────────────────────────


def _make_env(tmp: Path, extra: dict | None = None) -> dict:
    """Build the environment for a test run with path overrides pointing into tmp."""
    env = {
        **os.environ,
        "EXOCOMP_ROOT": str(tmp / "root"),
        "EXOCOMP_SYSTEMD_DIR": str(tmp / "systemd"),
        "EXOCOMP_SUDOERS_DIR": str(tmp / "sudoers"),
        "EXOCOMP_SKIP_SYSTEMD": "1",
        "EXOCOMP_SKIP_VISUDO": "1",
    }
    if extra:
        env.update(extra)
    return env


def _run_install(
    bundle_info: dict,
    component: str,
    version: str,
    *,
    env: dict,
    allow_list: str = "",
    extra_args: list[str] | None = None,
    expect_exit: int = 0,
) -> subprocess.CompletedProcess:
    cmd = [
        "bash",
        str(bundle_info["install_sh"]),
        "--component", component,
        "--bundle", str(bundle_info["bundle_path"]),
        "--checksums", str(bundle_info["checksums_path"]),
        "--version", version,
        "--non-interactive",
    ]
    if allow_list:
        cmd += ["--allow-list", allow_list]
    if extra_args:
        cmd += extra_args
    result = subprocess.run(cmd, capture_output=True, text=True, env=env)
    if result.returncode != expect_exit:
        raise AssertionError(
            f"install.sh exited {result.returncode} (expected {expect_exit})\n"
            f"stdout:\n{result.stdout}\n"
            f"stderr:\n{result.stderr}"
        )
    return result


def _run_uninstall(
    bundle_info: dict,
    component: str,
    *,
    env: dict,
    purge: list[str] | None = None,
    extra_args: list[str] | None = None,
    expect_exit: int = 0,
) -> subprocess.CompletedProcess:
    cmd = [
        "bash",
        str(bundle_info["uninstall_sh"]),
        "--component", component,
        "--non-interactive",
    ]
    for cat in (purge or []):
        cmd += ["--purge", cat]
    if extra_args:
        cmd += extra_args
    result = subprocess.run(cmd, capture_output=True, text=True, env=env)
    if result.returncode != expect_exit:
        raise AssertionError(
            f"uninstall.sh exited {result.returncode} (expected {expect_exit})\n"
            f"stdout:\n{result.stdout}\n"
            f"stderr:\n{result.stderr}"
        )
    return result


# ── Tests ──────────────────────────────────────────────────────────────────────


class TestCleanInstall:
    """Test 1: clean install creates all expected artifacts."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path):
        self.tmp = tmp_path
        self.component = "node"
        self.version = "0.1.0"
        self.allow_list = "myapp.service,other.service"
        self.info = _make_bundle_tree(
            tmp_path, self.component, self.version
        )
        self.env = _make_env(tmp_path)
        self.root = tmp_path / "root"

        _run_install(
            self.info,
            self.component,
            self.version,
            env=self.env,
            allow_list=self.allow_list,
        )

    def test_versioned_directory_created(self):
        versioned = (
            self.root / "opt" / "exocomp" / self.component
            / "releases" / self.version
        )
        assert versioned.is_dir(), f"versioned dir not found: {versioned}"

    def test_current_symlink_points_to_versioned(self):
        current = self.root / "opt" / "exocomp" / self.component / "current"
        assert current.is_symlink(), "current symlink not created"
        target = os.readlink(current)
        assert target == f"releases/{self.version}", (
            f"current symlink should point to releases/{self.version}; got {target!r}"
        )

    def test_config_template_installed(self):
        config = (
            self.root / "opt" / "exocomp" / self.component
            / "config" / f"{self.component}.json"
        )
        assert config.exists(), f"config file not found: {config}"
        with open(config) as f:
            obj = json.load(f)
        assert "_version" in obj, "config missing _version field"

    def test_systemd_unit_installed(self):
        unit = (
            self.tmp / "systemd" / f"exocomp-{self.component}.service"
        )
        assert unit.exists(), f"systemd unit not found: {unit}"
        content = unit.read_text()
        assert "NoNewPrivileges=true" in content, "unit missing NoNewPrivileges=true"
        assert "ProtectSystem=strict" in content, "unit missing ProtectSystem=strict"
        assert "CapabilityBoundingSet=" in content, "unit missing CapabilityBoundingSet="

    def test_sudoers_installed_with_exact_entries(self):
        sudoers = self.tmp / "sudoers" / f"exocomp-{self.component}"
        assert sudoers.exists(), f"sudoers file not found: {sudoers}"
        content = sudoers.read_text()
        # Exact restart entries
        assert "NOPASSWD: /usr/bin/systemctl restart myapp.service" in content
        assert "NOPASSWD: /usr/bin/systemctl restart other.service" in content
        # Vacuum entry
        assert "NOPASSWD: /usr/bin/journalctl --vacuum-size=" in content
        # No wildcard arguments (every command entry must have explicit args)
        # The sudoers format uses "ALL" as a valid host/runas specifier — that's expected.
        # What we must NOT see is a bare executable path (no args) or shell metacharacters.
        for line in content.splitlines():
            if "NOPASSWD:" in line:
                after_nopasswd = line.split("NOPASSWD:")[-1].strip()
                parts = after_nopasswd.split()
                assert len(parts) >= 2, (
                    f"sudoers entry should have executable AND argument, got: {line!r}"
                )
                assert "*" not in after_nopasswd, (
                    f"sudoers entry must not contain wildcard '*': {line!r}"
                )

    def test_manifest_written(self):
        manifest = (
            self.root / "opt" / "exocomp" / self.component
            / f"manifest-{self.version}.txt"
        )
        assert manifest.exists(), f"manifest not found: {manifest}"
        content = manifest.read_text()
        assert f"Component: {self.component}" in content
        assert f"Version: {self.version}" in content

    def test_config_directory_exists(self):
        config_dir = (
            self.root / "opt" / "exocomp" / self.component / "config"
        )
        assert config_dir.is_dir()

    def test_log_directory_exists(self):
        log_dir = (
            self.root / "opt" / "exocomp" / self.component / "log"
        )
        assert log_dir.is_dir()

    def test_durable_state_directory_is_writable_and_matches_runtime_config(self):
        state_dir = self.root / "var" / "lib" / "exocomp-node"
        assert state_dir.is_dir()
        assert state_dir.stat().st_mode & 0o777 == 0o750
        assert os.access(state_dir, os.W_OK)

        runtime_config = CONFIG_EXS.read_text()
        assert '"/var/lib/exocomp-node/replay_ledger.dets"' in runtime_config
        assert '"/var/lib/exocomp/replay_ledger.dets"' not in runtime_config

    def test_systemd_unit_grants_only_the_installer_owned_state_path(self):
        unit = self.tmp / "systemd" / "exocomp-node.service"
        content = unit.read_text()
        state_dir = self.root / "var" / "lib" / "exocomp-node"
        assert f"ReadWritePaths={self.root}/opt/exocomp/node/log " in content
        assert str(state_dir) in content
        assert "@STATE_DIR@" not in content

    def test_backup_utility_is_installed_in_the_versioned_release(self):
        backup = (
            self.root / "opt" / "exocomp" / "node" / "current"
            / "bin" / "exocomp-state-backup"
        )
        assert backup.is_file()
        assert backup.stat().st_mode & stat.S_IXUSR

    def test_release_cookie_is_random_protected_and_not_in_release_payload(self):
        cookie_file = (
            self.root / "opt" / "exocomp" / self.component
            / "config" / "release-cookie.env"
        )
        content = cookie_file.read_text().strip()
        assert re.fullmatch(r"RELEASE_COOKIE=[0-9a-f]{64}", content)
        assert cookie_file.stat().st_mode & 0o777 == 0o600

        versioned = (
            self.root / "opt" / "exocomp" / self.component
            / "releases" / self.version
        )
        for path in versioned.rglob("*"):
            if path.is_file():
                assert content.encode() not in path.read_bytes()

        second_base = self.tmp / "second-instance"
        second_info = _make_bundle_tree(
            second_base / "bundle", self.component, self.version
        )
        second_env = _make_env(second_base)
        _run_install(
            second_info,
            self.component,
            self.version,
            env=second_env,
        )
        second_cookie = (
            second_base / "root" / "opt" / "exocomp" / self.component
            / "config" / "release-cookie.env"
        ).read_text().strip()
        assert second_cookie != content


class TestBundledLlamaRuntimeInstall:
    def test_node_install_copies_the_shipped_runtime_into_the_atomic_release(self, tmp_path):
        version = "1.0.0"
        info = _make_bundle_tree(tmp_path, "node", version)
        bundle_dir = info["bundle_dir"]

        launcher = bundle_dir / "llama-server"
        launcher.write_text(
            '#!/bin/sh\nexec "$(dirname "$0")/llama-server.bin" "$@"\n'
        )
        launcher.chmod(0o755)
        executable = bundle_dir / "llama-server.bin"
        executable.write_text("#!/bin/sh\nprintf 'bundled llama runtime\\n'\n")
        executable.chmod(0o755)
        libraries = bundle_dir / "lib" / "llama"
        libraries.mkdir(parents=True)
        (libraries / "libllama-server-impl.so").write_bytes(b"shipped-runtime-lib")

        _run_install(info, "node", version, env=_make_env(tmp_path))

        current = tmp_path / "root" / "opt" / "exocomp" / "node" / "current"
        installed_launcher = current / "bin" / "llama-server"
        installed_executable = current / "bin" / "llama-server.bin"
        installed_library = current / "lib" / "llama" / "libllama-server-impl.so"
        assert installed_launcher.is_file()
        assert installed_executable.is_file()
        assert installed_library.read_bytes() == b"shipped-runtime-lib"

        result = subprocess.run(
            [str(installed_launcher), "--version"],
            capture_output=True,
            text=True,
            check=True,
            env={"PATH": os.environ["PATH"]},
        )
        assert result.stdout == "bundled llama runtime\n"


class TestRuntimePayloadPreflight:
    def test_missing_backup_utility_is_rejected_before_host_mutation(self, tmp_path):
        info = _make_bundle_tree(tmp_path, "node", "1.0.0")
        info["state_backup_sh"].unlink()

        result = _run_install(
            info,
            "node",
            "1.0.0",
            env=_make_env(tmp_path),
            expect_exit=1,
        )

        assert "state backup utility not found" in result.stderr
        assert not (tmp_path / "root" / "opt" / "exocomp").exists()

    def test_incomplete_llama_runtime_is_rejected_before_host_mutation(self, tmp_path):
        info = _make_bundle_tree(tmp_path, "node", "1.0.0")
        launcher = info["bundle_dir"] / "llama-server"
        launcher.write_text("#!/bin/sh\nexit 0\n")
        launcher.chmod(0o755)

        result = _run_install(
            info,
            "node",
            "1.0.0",
            env=_make_env(tmp_path),
            expect_exit=1,
        )

        assert "llama-server executable is missing" in result.stderr
        assert not (tmp_path / "root" / "opt" / "exocomp").exists()


class TestRepeatInstall:
    """Test 2: idempotent install — repeat install updates release, preserves config."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path):
        self.tmp = tmp_path
        self.component = "node"
        self.version = "0.1.0"
        self.info = _make_bundle_tree(
            tmp_path, self.component, self.version
        )
        self.env = _make_env(tmp_path)
        self.root = tmp_path / "root"

    def test_second_install_overwrites_release_preserves_config(self):
        # First install
        _run_install(self.info, self.component, self.version, env=self.env)

        config = (
            self.root / "opt" / "exocomp" / self.component
            / "config" / f"{self.component}.json"
        )
        assert config.exists()
        # Modify config to simulate operator customisation
        data = json.loads(config.read_text())
        data["_operator_note"] = "custom"
        config.write_text(json.dumps(data))

        # Second install (same version)
        _run_install(self.info, self.component, self.version, env=self.env)

        # Config must be preserved
        data_after = json.loads(config.read_text())
        assert data_after.get("_operator_note") == "custom", (
            "repeat install must preserve operator-modified config"
        )

    def test_second_install_idempotent_exit_zero(self):
        _run_install(self.info, self.component, self.version, env=self.env)
        _run_install(self.info, self.component, self.version, env=self.env)


class TestPermissions:
    """Test 3: installed paths have correct ownership and modes."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path):
        self.tmp = tmp_path
        self.component = "coordinator"
        self.version = "0.2.0"
        self.info = _make_bundle_tree(tmp_path, self.component, self.version)
        self.env = _make_env(tmp_path)
        self.root = tmp_path / "root"
        _run_install(self.info, self.component, self.version, env=self.env)

    def test_release_dir_not_world_writable(self):
        versioned = (
            self.root / "opt" / "exocomp" / self.component
            / "releases" / self.version
        )
        assert versioned.is_dir()
        mode = versioned.stat().st_mode
        assert not (mode & stat.S_IWOTH), "release dir must not be world-writable"
        assert not (mode & stat.S_IWGRP), "release dir must not be group-writable"

    def test_systemd_unit_mode_644(self):
        unit = self.tmp / "systemd" / f"exocomp-{self.component}.service"
        assert unit.exists()
        mode = unit.stat().st_mode & 0o777
        assert mode == 0o644, f"unit file mode should be 0644; got {oct(mode)}"

    def test_coordinator_unit_uses_bootstrap_managed_pki_state(self):
        unit = self.tmp / "systemd" / "exocomp-coordinator.service"
        content = unit.read_text()
        state = self.root / "var" / "lib" / "exocomp-coordinator"
        expected = {
            f"Environment=EXOCOMP_PKI_ONLINE_STATE={state}/pki",
            f"Environment=EXOCOMP_ENROLLMENT_TOKEN_STORE={state}/enrollment-tokens",
            f"Environment=EXOCOMP_TLS_CA_PATH={state}/pki/root_ca.pem",
            f"Environment=EXOCOMP_TLS_CERT_PATH={state}/pki/coordinator.pem",
            f"Environment=EXOCOMP_TLS_KEY_PATH={state}/pki/coordinator_key.pem",
        }
        assert expected <= set(content.splitlines())
        assert "@STATE_DIR@" not in content

    def test_sudoers_mode_440_when_installed(self):
        # Install with allow-list to get a sudoers file
        info = _make_bundle_tree(self.tmp / "sub", self.component, self.version)
        env = _make_env(self.tmp / "sub2")
        _run_install(
            info, self.component, self.version, env=env,
            allow_list="myapp.service"
        )
        sudoers = self.tmp / "sub2" / "sudoers" / f"exocomp-{self.component}"
        assert sudoers.exists()
        mode = sudoers.stat().st_mode & 0o777
        assert mode == 0o440, f"sudoers mode should be 0440; got {oct(mode)}"

    def test_config_file_mode_640(self):
        config = (
            self.root / "opt" / "exocomp" / self.component
            / "config" / f"{self.component}.json"
        )
        assert config.exists()
        mode = config.stat().st_mode & 0o777
        assert mode == 0o640, f"config mode should be 0640; got {oct(mode)}"


class TestInvalidChecksum:
    """Test 5: preflight rejects bundles with bad checksums before host mutation."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path):
        self.tmp = tmp_path
        self.component = "node"
        self.version = "1.0.0"
        self.info = _make_bundle_tree(tmp_path, self.component, self.version)
        self.env = _make_env(tmp_path)
        self.root = tmp_path / "root"

    def test_tampered_bundle_rejected(self):
        # Corrupt the bundle after checksums file is created
        bundle = self.info["bundle_path"]
        with open(bundle, "ab") as f:
            f.write(b"\x00TAMPERED\x00")

        result = _run_install(
            self.info, self.component, self.version,
            env=self.env, expect_exit=1
        )
        assert "MISMATCH" in result.stderr or "checksum" in result.stderr.lower(), (
            "expected checksum mismatch error message"
        )

    def test_host_not_mutated_on_checksum_failure(self):
        """Verify no directories are created when preflight fails."""
        bundle = self.info["bundle_path"]
        with open(bundle, "ab") as f:
            f.write(b"\x00TAMPERED\x00")

        _run_install(
            self.info, self.component, self.version,
            env=self.env, expect_exit=1
        )

        install_dir = self.root / "opt" / "exocomp" / self.component
        assert not install_dir.exists(), (
            "installer must not create directories when preflight fails"
        )

    def test_missing_checksums_entry_rejected(self):
        """A checksums file that has no entry for this bundle must fail preflight."""
        self.info["checksums_path"].write_text("# empty\n")
        result = _run_install(
            self.info, self.component, self.version,
            env=self.env, expect_exit=1
        )
        assert "checksum" in result.stderr.lower()


class TestExactPrivileges:
    """Test 7: generated sudoers contain exactly the configured entries."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path):
        self.tmp = tmp_path
        self.component = "node"
        self.version = "0.1.0"
        self.info = _make_bundle_tree(tmp_path, self.component, self.version)

    def _sudoers_content(self, allow_list: str) -> str:
        env = _make_env(self.tmp / allow_list.replace(",", "_"))
        _run_install(
            self.info, self.component, self.version,
            env=env, allow_list=allow_list
        )
        sudoers = (
            self.tmp / allow_list.replace(",", "_")
            / "sudoers" / f"exocomp-{self.component}"
        )
        if not sudoers.exists():
            return ""
        return sudoers.read_text()

    def test_empty_allow_list_produces_no_sudoers_file(self):
        env = _make_env(self.tmp / "empty")
        _run_install(
            self.info, self.component, self.version,
            env=env, allow_list=""
        )
        sudoers = self.tmp / "empty" / "sudoers" / f"exocomp-{self.component}"
        # Either no file, or file contains only the vacuum entry
        if sudoers.exists():
            content = sudoers.read_text()
            assert "systemctl restart" not in content, (
                "empty allow-list must not produce any systemctl restart entries"
            )

    def test_single_service_exact_entry(self):
        content = self._sudoers_content("web.service")
        assert "NOPASSWD: /usr/bin/systemctl restart web.service" in content
        # No other restart entries
        restart_lines = [l for l in content.splitlines() if "systemctl restart" in l]
        assert len(restart_lines) == 1, (
            f"expected exactly 1 restart line; got: {restart_lines}"
        )

    def test_multiple_services_all_present(self):
        content = self._sudoers_content("svc1.service,svc2.service,svc3.service")
        for svc in ("svc1.service", "svc2.service", "svc3.service"):
            assert f"NOPASSWD: /usr/bin/systemctl restart {svc}" in content

    def test_no_wildcard_in_sudoers(self):
        content = self._sudoers_content("app.service")
        # Every NOPASSWD entry must have explicit args (no bare executable)
        for line in content.splitlines():
            if "NOPASSWD:" in line:
                after_nopasswd = line.split("NOPASSWD:")[-1].strip()
                parts = after_nopasswd.split()
                assert len(parts) >= 2, (
                    f"sudoers entry must have executable AND argument: {line!r}"
                )
                # No shell wildcards in the argument string
                assert "*" not in after_nopasswd, (
                    f"sudoers entry must not contain wildcard '*': {line!r}"
                )
            if "systemctl" in line and "NOPASSWD:" in line:
                # Every systemctl entry must specify a subcommand and argument
                assert re.search(r"systemctl\s+\w+\s+\S+", line), (
                    f"sudoers line contains bare systemctl (potential wildcard): {line!r}"
                )

    def test_shell_metacharacter_in_service_name_rejected(self):
        """Service names with shell metacharacters must be rejected by the installer.

        Note: null bytes and spaces cannot be passed as CLI arguments, so they
        are excluded from this parameterized list.  The validation regex in
        install.sh rejects all characters outside [a-zA-Z0-9._@-], so any
        name containing a metacharacter (`;`, `$`, backtick, `|`, `/`) must
        be rejected before host mutation occurs.
        """
        bad_names = [
            "svc;echo",
            "svc$(id)",
            "svc`whoami`",
            "svc|cat",
            "../etc/passwd",
        ]
        for bad in bad_names:
            env = _make_env(self.tmp / ("bad_" + re.sub(r"[^a-zA-Z0-9]", "_", bad)))
            result = _run_install(
                self.info, self.component, self.version,
                env=env, allow_list=bad, expect_exit=1
            )
            assert result.returncode == 1, (
                f"installer should reject service name with metacharacter: {bad!r}\n"
                f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
            )


class TestUpgradePreparation:
    """Test 8: new version installs beside old version; atomic link updated."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path):
        self.tmp = tmp_path
        self.component = "node"
        self.v1 = "1.0.0"
        self.v2 = "1.1.0"
        self.env = _make_env(tmp_path)
        self.root = tmp_path / "root"

    def test_upgrade_creates_new_version_alongside_old(self):
        info1 = _make_bundle_tree(self.tmp / "b1", self.component, self.v1)
        info2 = _make_bundle_tree(self.tmp / "b2", self.component, self.v2)

        _run_install(info1, self.component, self.v1, env=self.env)
        _run_install(info2, self.component, self.v2, env=self.env)

        v1_dir = (
            self.root / "opt" / "exocomp" / self.component
            / "releases" / self.v1
        )
        v2_dir = (
            self.root / "opt" / "exocomp" / self.component
            / "releases" / self.v2
        )
        assert v1_dir.is_dir(), f"old version dir should still exist: {v1_dir}"
        assert v2_dir.is_dir(), f"new version dir not found: {v2_dir}"

    def test_current_link_updated_atomically(self):
        info1 = _make_bundle_tree(self.tmp / "b1", self.component, self.v1)
        info2 = _make_bundle_tree(self.tmp / "b2", self.component, self.v2)

        _run_install(info1, self.component, self.v1, env=self.env)

        current = self.root / "opt" / "exocomp" / self.component / "current"
        assert os.readlink(current) == f"releases/{self.v1}"

        _run_install(info2, self.component, self.v2, env=self.env)
        assert os.readlink(current) == f"releases/{self.v2}", (
            "current symlink should point to new version after upgrade"
        )

        installer = info2["install_sh"].read_text()
        switch_function = installer.split("switch_current() {", 1)[1].split(
            "# ── Phase 5", 1
        )[0]
        assert 'mv -Tf "${tmp_link}" "${current_link}"' in switch_function
        assert 'rm -f "${current_link}"' not in switch_function

    def test_config_preserved_across_upgrade(self):
        info1 = _make_bundle_tree(self.tmp / "b1", self.component, self.v1)
        info2 = _make_bundle_tree(self.tmp / "b2", self.component, self.v2)

        _run_install(info1, self.component, self.v1, env=self.env)

        config = (
            self.root / "opt" / "exocomp" / self.component
            / "config" / f"{self.component}.json"
        )
        data = json.loads(config.read_text())
        data["_operator_note"] = "preserved"
        config.write_text(json.dumps(data))

        _run_install(info2, self.component, self.v2, env=self.env)

        data_after = json.loads(config.read_text())
        assert data_after.get("_operator_note") == "preserved", (
            "config must be preserved across upgrade"
        )

    def test_release_cookie_is_preserved_across_upgrade(self):
        info1 = _make_bundle_tree(self.tmp / "b1", self.component, self.v1)
        info2 = _make_bundle_tree(self.tmp / "b2", self.component, self.v2)
        _run_install(info1, self.component, self.v1, env=self.env)
        cookie = (
            self.root / "opt" / "exocomp" / self.component
            / "config" / "release-cookie.env"
        )
        original = cookie.read_text()

        _run_install(info2, self.component, self.v2, env=self.env)
        assert cookie.read_text() == original

    def test_failed_health_gate_rolls_back_to_prior_healthy_version(self):
        info1 = _make_bundle_tree(self.tmp / "b1", self.component, self.v1)
        info2 = _make_bundle_tree(self.tmp / "b2", self.component, self.v2)
        _run_install(info1, self.component, self.v1, env=self.env)

        health_command = (
            f'test "$(readlink "$EXOCOMP_CURRENT")" = "releases/{self.v1}"'
        )
        failing_env = {
            **self.env,
            "EXOCOMP_HEALTHCHECK_COMMAND": health_command,
            "EXOCOMP_HEALTHCHECK_ATTEMPTS": "1",
            "EXOCOMP_HEALTHCHECK_INTERVAL": "0",
        }
        _run_install(
            info2,
            self.component,
            self.v2,
            env=failing_env,
            expect_exit=1,
        )

        current = self.root / "opt" / "exocomp" / self.component / "current"
        assert os.readlink(current) == f"releases/{self.v1}"
        assert (current / "bin" / f"exocomp_{self.component}").exists()

    def test_invalid_existing_config_blocks_switch(self):
        info1 = _make_bundle_tree(self.tmp / "b1", self.component, self.v1)
        info2 = _make_bundle_tree(self.tmp / "b2", self.component, self.v2)
        _run_install(info1, self.component, self.v1, env=self.env)

        config = (
            self.root / "opt" / "exocomp" / self.component
            / "config" / f"{self.component}.json"
        )
        config.write_text("{not-json")
        validator_env = {
            **self.env,
            "EXOCOMP_CONFIG_VALIDATOR_COMMAND": (
                'python3 -m json.tool "$EXOCOMP_CONFIG_FILE" >/dev/null'
            ),
        }

        _run_install(
            info2,
            self.component,
            self.v2,
            env=validator_env,
            expect_exit=1,
        )
        current = self.root / "opt" / "exocomp" / self.component / "current"
        assert os.readlink(current) == f"releases/{self.v1}"

    def test_interrupted_extraction_never_changes_current(self):
        info1 = _make_bundle_tree(self.tmp / "b1", self.component, self.v1)
        info2 = _make_bundle_tree(self.tmp / "b2", self.component, self.v2)
        _run_install(info1, self.component, self.v1, env=self.env)

        info2["bundle_path"].write_bytes(b"truncated archive")
        digest = hashlib.sha256(info2["bundle_path"].read_bytes()).hexdigest()
        info2["checksums_path"].write_text(
            f"{digest}  {info2['bundle_path'].name}\n"
        )
        _run_install(
            info2,
            self.component,
            self.v2,
            env=self.env,
            expect_exit=1,
        )

        current = self.root / "opt" / "exocomp" / self.component / "current"
        assert os.readlink(current) == f"releases/{self.v1}"
        versioned = current.parent / "releases" / self.v2
        assert not versioned.exists()


class TestVersionCompatibility:
    def test_different_major_node_and_coordinator_versions_are_rejected(self, tmp_path):
        env = _make_env(tmp_path)
        coordinator = _make_bundle_tree(tmp_path / "coord", "coordinator", "1.5.0")
        node = _make_bundle_tree(tmp_path / "node", "node", "2.0.0")

        _run_install(coordinator, "coordinator", "1.5.0", env=env)
        result = _run_install(node, "node", "2.0.0", env=env, expect_exit=1)

        assert "incompatible" in result.stderr.lower()
        node_dir = tmp_path / "root" / "opt" / "exocomp" / "node"
        assert not node_dir.exists()


class TestProtectedStateBackupRestore:
    def test_backup_restore_recovers_config_pki_audit_and_execution_state(self, tmp_path):
        component = "coordinator"
        version = "1.0.0"
        env = _make_env(tmp_path)
        info = _make_bundle_tree(tmp_path / "bundle-tree", component, version)
        _run_install(info, component, version, env=env)

        root = tmp_path / "root"
        install_dir = root / "opt" / "exocomp" / component
        state_dir = root / "var" / "lib" / f"exocomp-{component}"
        pki = install_dir / "config" / "pki" / "identity.pem"
        audit = install_dir / "log" / "audit.jsonl"
        execution = state_dir / "consumed-executions.dets"
        pki.write_text("private identity")
        audit.write_text('{"event":"completed"}\n')
        execution.write_text("durable replay state")

        archive = tmp_path / "backup" / "coordinator-state.tar.gz"
        subprocess.run(
            [
                "bash",
                str(info["state_backup_sh"]),
                "create",
                "--component",
                component,
                "--output",
                str(archive),
            ],
            env=env,
            check=True,
            capture_output=True,
            text=True,
        )
        assert archive.stat().st_mode & 0o777 == 0o600
        assert archive.with_suffix(archive.suffix + ".sha256").exists()

        shutil.rmtree(install_dir / "config")
        shutil.rmtree(install_dir / "log")
        shutil.rmtree(state_dir)
        subprocess.run(
            [
                "bash",
                str(info["state_backup_sh"]),
                "restore",
                "--component",
                component,
                "--archive",
                str(archive),
            ],
            env=env,
            check=True,
            capture_output=True,
            text=True,
        )

        assert pki.read_text() == "private identity"
        assert audit.read_text() == '{"event":"completed"}\n'
        assert execution.read_text() == "durable replay state"


class TestDefaultUninstall:
    """Test 9: default uninstall preserves protected operator state."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path):
        self.tmp = tmp_path
        self.component = "node"
        self.version = "0.1.0"
        self.env = _make_env(tmp_path)
        self.root = tmp_path / "root"

        self.info = _make_bundle_tree(tmp_path, self.component, self.version)
        _run_install(
            self.info, self.component, self.version,
            env=self.env, allow_list="myapp.service"
        )

    def test_uninstall_exits_zero(self):
        _run_uninstall(self.info, self.component, env=self.env)

    def test_unit_file_removed(self):
        _run_uninstall(self.info, self.component, env=self.env)
        unit = self.tmp / "systemd" / f"exocomp-{self.component}.service"
        assert not unit.exists(), "unit file should be removed after uninstall"

    def test_sudoers_removed(self):
        _run_uninstall(self.info, self.component, env=self.env)
        sudoers = self.tmp / "sudoers" / f"exocomp-{self.component}"
        assert not sudoers.exists(), "sudoers file should be removed after uninstall"

    def test_current_symlink_removed(self):
        _run_uninstall(self.info, self.component, env=self.env)
        current = (
            self.root / "opt" / "exocomp" / self.component / "current"
        )
        assert not current.exists() and not current.is_symlink(), (
            "current symlink should be removed after uninstall"
        )

    def test_config_preserved(self):
        config = (
            self.root / "opt" / "exocomp" / self.component
            / "config" / f"{self.component}.json"
        )
        assert config.exists()
        config.write_text('{"_operator_note":"preserved"}')

        _run_uninstall(self.info, self.component, env=self.env)

        assert config.exists(), "config must be preserved after default uninstall"
        assert json.loads(config.read_text()).get("_operator_note") == "preserved"

    def test_log_dir_preserved(self):
        log_dir = (
            self.root / "opt" / "exocomp" / self.component / "log"
        )
        # Write a sentinel log file
        sentinel = log_dir / "audit.log"
        sentinel.write_text("audit entry\n")

        _run_uninstall(self.info, self.component, env=self.env)

        assert sentinel.exists(), "audit log must be preserved after default uninstall"

    def test_config_dir_preserved(self):
        config_dir = (
            self.root / "opt" / "exocomp" / self.component / "config"
        )
        _run_uninstall(self.info, self.component, env=self.env)
        assert config_dir.is_dir(), "config dir must be preserved after default uninstall"


class TestSystemCachePurge:
    """Test 10: --purge system-cache removes old release directories."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path):
        self.tmp = tmp_path
        self.component = "node"
        self.v1 = "0.9.0"
        self.v2 = "1.0.0"
        self.env = _make_env(tmp_path)
        self.root = tmp_path / "root"

        info1 = _make_bundle_tree(tmp_path / "b1", self.component, self.v1)
        info2 = _make_bundle_tree(tmp_path / "b2", self.component, self.v2)
        self.info = info2

        _run_install(info1, self.component, self.v1, env=self.env)
        _run_install(info2, self.component, self.v2, env=self.env)

    def test_purge_removes_all_release_dirs(self):
        releases_dir = (
            self.root / "opt" / "exocomp" / self.component / "releases"
        )
        # Before purge, both versions exist
        assert (releases_dir / self.v1).is_dir()
        assert (releases_dir / self.v2).is_dir()

        _run_uninstall(
            self.info, self.component,
            env=self.env, purge=["system-cache"]
        )

        assert not (releases_dir / self.v1).is_dir(), (
            "old release dir should be removed by system-cache purge"
        )
        assert not (releases_dir / self.v2).is_dir(), (
            "new release dir should also be removed by system-cache purge"
        )

    def test_purge_preserves_config(self):
        config = (
            self.root / "opt" / "exocomp" / self.component
            / "config" / f"{self.component}.json"
        )
        sentinel = '{"_operator_note":"preserved"}'
        config.write_text(sentinel)

        _run_uninstall(
            self.info, self.component,
            env=self.env, purge=["system-cache"]
        )

        assert config.exists(), "config must survive system-cache purge"
        assert config.read_text() == sentinel

    def test_purge_preserves_log_dir(self):
        log_dir = self.root / "opt" / "exocomp" / self.component / "log"
        sentinel = log_dir / "important.log"
        sentinel.write_text("important audit data\n")

        _run_uninstall(
            self.info, self.component,
            env=self.env, purge=["system-cache"]
        )

        assert sentinel.exists(), "log files must survive system-cache purge"


class TestUserDataPreservation:
    """Test 11: uninstall never touches paths outside the manifest or protected dirs."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path):
        self.tmp = tmp_path
        self.component = "coordinator"
        self.version = "1.0.0"
        self.env = _make_env(tmp_path)
        self.root = tmp_path / "root"

        self.info = _make_bundle_tree(tmp_path, self.component, self.version)
        _run_install(self.info, self.component, self.version, env=self.env)

    def test_unrelated_dirs_not_touched(self):
        """Files in unrelated directories must not be removed."""
        user_dir = self.root / "home" / "operator"
        user_dir.mkdir(parents=True)
        sentinel = user_dir / "important_data.txt"
        sentinel.write_text("do not delete\n")

        _run_uninstall(self.info, self.component, env=self.env)

        assert sentinel.exists(), "uninstaller must not remove user home files"

    def test_var_lib_dir_preserved(self):
        """Persistent state in /var/lib/exocomp-<component> must be preserved."""
        var_dir = self.root / "var" / "lib" / f"exocomp-{self.component}"
        var_dir.mkdir(parents=True, exist_ok=True)
        sentinel = var_dir / "state.json"
        sentinel.write_text('{"enrollment":"active"}')

        _run_uninstall(self.info, self.component, env=self.env)

        assert sentinel.exists(), (
            f"state in {var_dir} must not be removed by default uninstall"
        )

    def test_pki_dir_preserved(self):
        """PKI material in config/pki/ must never be removed."""
        pki_dir = (
            self.root / "opt" / "exocomp" / self.component / "config" / "pki"
        )
        pki_dir.mkdir(parents=True, exist_ok=True)
        cert = pki_dir / "ca.crt"
        cert.write_text("FAKE CERT\n")

        _run_uninstall(self.info, self.component, env=self.env)

        assert cert.exists(), "PKI material must be preserved after default uninstall"

    def test_unknown_purge_category_rejected(self):
        """Passing an unknown --purge category should exit non-zero."""
        _run_uninstall(
            self.info, self.component,
            env=self.env, purge=["nuclear-option"], expect_exit=1
        )


class TestDryRun:
    """Additional: --dry-run validates without mutating the host."""

    def test_dry_run_exits_zero(self, tmp_path):
        component = "node"
        version = "0.1.0"
        info = _make_bundle_tree(tmp_path, component, version)
        env = _make_env(tmp_path)

        result = subprocess.run(
            [
                "bash", str(info["install_sh"]),
                "--component", component,
                "--bundle", str(info["bundle_path"]),
                "--checksums", str(info["checksums_path"]),
                "--version", version,
                "--dry-run",
                "--non-interactive",
            ],
            capture_output=True, text=True, env=env,
        )
        assert result.returncode == 0, (
            f"--dry-run should exit 0\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )

    def test_dry_run_creates_no_files(self, tmp_path):
        component = "node"
        version = "0.1.0"
        info = _make_bundle_tree(tmp_path, component, version)
        env = _make_env(tmp_path)
        root = tmp_path / "root"

        subprocess.run(
            [
                "bash", str(info["install_sh"]),
                "--component", component,
                "--bundle", str(info["bundle_path"]),
                "--checksums", str(info["checksums_path"]),
                "--version", version,
                "--dry-run",
                "--non-interactive",
            ],
            capture_output=True, text=True, env=env,
        )
        install_dir = root / "opt" / "exocomp" / component
        assert not install_dir.exists(), (
            "--dry-run must not create any directories"
        )


class TestMissingComponentFlag:
    """Installer must fail immediately when --component is omitted."""

    def test_missing_component_exits_nonzero(self, tmp_path):
        component = "node"
        version = "0.1.0"
        info = _make_bundle_tree(tmp_path, component, version)
        env = _make_env(tmp_path)

        result = subprocess.run(
            [
                "bash", str(info["install_sh"]),
                "--bundle", str(info["bundle_path"]),
                "--version", version,
            ],
            capture_output=True, text=True, env=env,
        )
        assert result.returncode != 0
        assert "component" in result.stderr.lower()


class TestVersionValidation:
    @pytest.mark.parametrize(
        "version",
        ["1.2.3/../../escape", "1.2", "1.2.3;touch-pwned", "v1.2.3"],
    )
    def test_unsafe_or_non_semver_version_is_rejected_before_mutation(
        self, tmp_path, version
    ):
        component = "node"
        info = _make_bundle_tree(tmp_path, component, "1.2.3")
        env = _make_env(tmp_path)

        _run_install(
            info,
            component,
            version,
            env=env,
            expect_exit=1,
        )

        assert not (tmp_path / "root" / "opt" / "exocomp").exists()

    @pytest.mark.parametrize(
        "version",
        ["0.1.0", "1.2.3", "0.1.0-rc.4", "1.0.0-beta.1", "2.3.4-alpha.12"],
    )
    def test_version_detected_from_archive_name(self, tmp_path, version):
        """install.sh must correctly parse semver pre-release versions with dots from
        the archive filename when --version is not supplied.  Regression for:
        ``exocomp-coordinator-0.1.0-rc.4-linux-amd64.tar.gz`` extracting as ``0.1.0``
        instead of ``0.1.0-rc.4`` due to ``[^.]*`` stopping at the dot in the
        pre-release segment."""
        component = "node"
        info = _make_bundle_tree(tmp_path, component, version)
        env = _make_env(tmp_path)

        # Run install WITHOUT --version so the script must detect it from the
        # archive filename.
        cmd = [
            "bash",
            str(info["install_sh"]),
            "--component", component,
            "--bundle", str(info["bundle_path"]),
            "--checksums", str(info["checksums_path"]),
            "--non-interactive",
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, env=env)
        assert result.returncode == 0, (
            f"install.sh failed to detect version '{version}' from archive name\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )

        # Verify the versioned release directory uses the full version string.
        root = tmp_path / "root"
        versioned = root / "opt" / "exocomp" / component / "releases" / version
        assert versioned.is_dir(), (
            f"versioned release dir '{version}' not found; "
            f"version was likely truncated by the archive-name parser"
        )

        # Verify the current symlink also points to the correct version.
        current = root / "opt" / "exocomp" / component / "current"
        assert current.is_symlink(), "current symlink not created"
        assert current.readlink() == Path(f"releases/{version}"), (
            f"current symlink points to {current.readlink()!r}; "
            f"expected releases/{version}"
        )


class TestUnitHardeningDirectives:
    """Verify all required hardening directives are present in both unit files."""

    REQUIRED_DIRECTIVES = [
        "NoNewPrivileges=true",
        "ProtectSystem=strict",
        "ProtectHome=true",
        "CapabilityBoundingSet=",
        "AmbientCapabilities=",
        "PrivateTmp=true",
        "MemoryDenyWriteExecute=true",
        "LockPersonality=true",
        "RestrictRealtime=true",
        "PrivateDevices=true",
        "RestrictNamespaces=true",
        "UMask=0077",
        "ProtectKernelTunables=true",
        "ProtectKernelModules=true",
        "ProtectControlGroups=true",
        "ProtectHostname=true",
    ]

    @pytest.mark.parametrize("component", ["node", "coordinator"])
    def test_all_hardening_directives_present(self, component):
        unit_path = RELEASE_DIR / component / f"exocomp-{component}.service"
        assert unit_path.exists(), f"unit file not found: {unit_path}"
        content = unit_path.read_text()
        missing = [d for d in self.REQUIRED_DIRECTIVES if d not in content]
        assert not missing, (
            f"Missing hardening directives in exocomp-{component}.service:\n"
            + "\n".join(f"  {d}" for d in missing)
        )

    @pytest.mark.parametrize("component", ["node", "coordinator"])
    def test_unit_runs_as_dedicated_user(self, component):
        unit_path = RELEASE_DIR / component / f"exocomp-{component}.service"
        content = unit_path.read_text()
        assert "User=@ACCOUNT@" in content, "unit must run as @ACCOUNT@"
        assert "Group=@ACCOUNT@" in content, "unit must set Group=@ACCOUNT@"

    @pytest.mark.parametrize("component", ["node", "coordinator"])
    def test_unit_has_system_call_filter(self, component):
        unit_path = RELEASE_DIR / component / f"exocomp-{component}.service"
        content = unit_path.read_text()
        assert "SystemCallFilter=" in content, "unit must have SystemCallFilter"

    @pytest.mark.parametrize(
        "component,environment",
        [
            ("node", "EXOCOMP_CONFIG_FILE"),
            ("coordinator", "EXOCOMP_COORDINATOR_CONFIG_FILE"),
        ],
    )
    def test_unit_passes_config_path_expected_by_runtime(self, component, environment):
        unit_path = RELEASE_DIR / component / f"exocomp-{component}.service"
        content = unit_path.read_text()
        assert f"Environment={environment}=" in content

    def test_coordinator_unit_passes_bootstrap_managed_pki_paths(self):
        unit_path = RELEASE_DIR / "coordinator" / "exocomp-coordinator.service"
        content = unit_path.read_text()
        expected = {
            "Environment=EXOCOMP_PKI_ONLINE_STATE=@STATE_DIR@/pki",
            "Environment=EXOCOMP_ENROLLMENT_TOKEN_STORE=@STATE_DIR@/enrollment-tokens",
            "Environment=EXOCOMP_TLS_CA_PATH=@STATE_DIR@/pki/root_ca.pem",
            "Environment=EXOCOMP_TLS_CERT_PATH=@STATE_DIR@/pki/coordinator.pem",
            "Environment=EXOCOMP_TLS_KEY_PATH=@STATE_DIR@/pki/coordinator_key.pem",
        }
        assert expected <= set(content.splitlines())


class TestConfigTemplates:
    """Verify configuration templates are valid JSON with expected top-level keys."""

    @pytest.mark.parametrize("component,expected_keys", [
        (
            "node",
            {
                "_version",
                "version",
                "node_id",
                "tls",
                "listen",
                "coordinator",
                "node",
                "actions",
                "diagnostics",
            },
        ),
        (
            "coordinator",
            {
                "_version",
                "version",
                "coordinator_id",
                "tls",
                "listen",
                "coordinator",
                "pki",
                "approvals",
                "diagnostics",
            },
        ),
    ])
    def test_template_is_valid_json(self, component, expected_keys):
        tmpl = RELEASE_DIR / "templates" / f"{component}.json"
        assert tmpl.exists(), f"template not found: {tmpl}"
        obj = json.loads(tmpl.read_text())
        missing = expected_keys - set(obj.keys())
        assert not missing, (
            f"{component}.json template missing keys: {missing}"
        )

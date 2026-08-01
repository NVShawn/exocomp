# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""
Tests for the Exocomp offline bundle assembly, SBOM, provenance, and
tamper-detection verification scripts.

These tests exercise:
  1. Bundle assembly — complete and runtime-only variants
  2. Manifest coverage — every staged file appears in manifest.sha256
  3. SBOM structure — SPDX 2.3 required fields and package references
  4. Provenance structure — SLSA predicate fields
  5. Tamper detection — modified files fail verify-bundle.sh
  6. Missing file detection — deleted files fail verify-bundle.sh
  7. Checksum self-consistency — archive-level checksum file is correct
  8. No-model runtime bundle — verify model is absent from runtime bundle
  9. Model SHA-256 pre-verification — bad model digest causes assembly failure
 10. SBOM complete vs runtime — model package present iff kind==complete

Run via:
  python3 -m pytest tests/test_bundle.py -v
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import tarfile
import tempfile
from pathlib import Path

import pytest

# ── Repository root ────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = REPO_ROOT / "scripts"
ASSEMBLE_SH = SCRIPTS_DIR / "assemble-bundle.sh"
VERIFY_SH = SCRIPTS_DIR / "verify-bundle.sh"
GEN_SBOM_SH = SCRIPTS_DIR / "generate-sbom.sh"
GEN_PROV_SH = SCRIPTS_DIR / "generate-provenance.sh"
SIGN_SH = SCRIPTS_DIR / "sign-bundle.sh"
INSTALLATION_DOC = REPO_ROOT / "docs" / "installation.md"


# ── Mock artifact builders ─────────────────────────────────────────────────────


def _make_otp_archive(dest_dir: Path, component: str, version: str, arch: str) -> Path:
    """Create a minimal mock OTP release archive."""
    archive_name = f"exocomp-{component}-{version}-linux-{arch}.tar.gz"
    archive_path = dest_dir / archive_name
    scratch = dest_dir / f"_scratch_{component}"
    scratch.mkdir(parents=True, exist_ok=True)

    inner = scratch / f"exocomp-{component}-{version}"
    inner.mkdir()
    (inner / "bin").mkdir()
    stub = inner / "bin" / f"exocomp_{component}"
    stub.write_text(
        "#!/bin/sh\n"
        'release_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"\n'
        'exec "${release_root}/erts-28.5.0.3/bin/beam.smp" "$@"\n'
    )
    stub.chmod(0o755)

    beam_dir = inner / "erts-28.5.0.3" / "bin"
    beam_dir.mkdir(parents=True)
    beam = beam_dir / "beam.smp"
    beam.write_text(
        "#!/bin/sh\n"
        'if [ -n "${EXOCOMP_FAKE_RELEASE_LOG:-}" ]; then\n'
        '    printf "%s\\n" "$*" >> "${EXOCOMP_FAKE_RELEASE_LOG}"\n'
        "fi\n"
        'case "$*" in\n'
        '    rpc*"System.halt"*)\n'
        '        echo "health RPC must not halt the service node" >&2\n'
        "        exit 86\n"
        "        ;;\n"
        "esac\n"
        "exit 0\n"
    )
    beam.chmod(0o755)

    rel_dir = inner / "releases" / version
    rel_dir.mkdir(parents=True)
    (rel_dir / "start_erl.data").write_text(f"28.5.0.3 {version}\n")
    (rel_dir / "RELEASES").write_text(
        f'[{{release,"exocomp_{component}","{version}","28.5.0.3",[]}}].\n'
    )

    with tarfile.open(archive_path, "w:gz") as tar:
        tar.add(inner, arcname=inner.name)

    shutil.rmtree(scratch)
    return archive_path


def _make_llama_server(dest_dir: Path) -> Path:
    """Create a stub llama-server binary with a representative companion library."""
    p = dest_dir / "llama-server-stub"
    p.write_bytes(b"#!/bin/sh\necho llama-server-stub\n")
    p.chmod(0o755)
    (dest_dir / "libllama-server-impl.so").write_bytes(b"fake llama runtime library")
    return p


def _build_profile_helper(dest_dir: Path, arch: str) -> Path:
    """Build the shipped helper for the requested ELF architecture."""
    compiler = "cc" if arch == "amd64" else "aarch64-linux-gnu-gcc"
    if shutil.which(compiler) is None:
        pytest.skip(f"{compiler} is required for {arch} helper packaging coverage")
    output = dest_dir / f"profile-action-helper-{arch}"
    subprocess.run(
        [
            compiler,
            "-std=c11",
            "-O2",
            "-Wall",
            "-Wextra",
            "-Wpedantic",
            "-Wconversion",
            "-Wshadow",
            "-Werror",
            "-D_FORTIFY_SOURCE=2",
            "-fstack-protector-strong",
            "-fPIE",
            "-Wl,-z,relro,-z,now",
            "-pie",
            "-I",
            str(REPO_ROOT / "apps" / "exocomp_node" / "priv"),
            str(REPO_ROOT / "apps" / "exocomp_node" / "priv" / "profile_action_helper.c"),
            "-o",
            str(output),
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return output


def _make_model(dest_dir: Path, size: int = 1024) -> tuple[Path, str]:
    """Create a fake GGUF model file. Returns (path, sha256)."""
    p = dest_dir / "qwen2.5-1.5b-instruct-q4_k_m.gguf"
    content = b"FAKE GGUF MODEL " * (size // 16 + 1)
    content = content[:size]
    p.write_bytes(content)
    digest = hashlib.sha256(content).hexdigest()
    return p, digest


def _base_env(tmp: Path) -> dict:
    """Return environment for subprocess calls."""
    env = {**os.environ}
    # Ensure SOURCE_DATE_EPOCH is set for reproducibility
    env["SOURCE_DATE_EPOCH"] = "1700000000"
    return env


def _run_assemble(
    *,
    tmp: Path,
    arch: str,
    version: str,
    kind: str = "complete",
    node_archive: Path | None = None,
    coord_archive: Path | None = None,
    profile_helper: Path | None = None,
    llama_server: Path | None = None,
    llama_lib_dir: Path | None = None,
    model: Path | None = None,
    model_sha256: str = "",
    source_commit: str = "abc1234def5678",
    builder_image: str = "docker.io/hexpm/elixir:test@sha256:000",
    extra_args: list[str] | None = None,
    expect_exit: int = 0,
    dist_dir: Path | None = None,
) -> subprocess.CompletedProcess:
    """Run assemble-bundle.sh and return the completed process."""
    dist = dist_dir or (tmp / "dist")
    cmd = [
        "bash",
        str(ASSEMBLE_SH),
        "--arch", arch,
        "--version", version,
        "--kind", kind,
        "--source-commit", source_commit,
        "--builder-image", builder_image,
        "--dist-dir", str(dist),
    ]
    if node_archive:
        cmd += ["--node-archive", str(node_archive)]
    if coord_archive:
        cmd += ["--coord-archive", str(coord_archive)]
    if profile_helper:
        cmd += ["--profile-helper", str(profile_helper)]
    if llama_server:
        cmd += ["--llama-server", str(llama_server)]
    if llama_lib_dir:
        cmd += ["--llama-lib-dir", str(llama_lib_dir)]
    if model:
        cmd += ["--model", str(model)]
    if model_sha256:
        cmd += ["--model-sha256", model_sha256]
    if extra_args:
        cmd += extra_args

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        env=_base_env(tmp),
    )
    if result.returncode != expect_exit:
        raise AssertionError(
            f"assemble-bundle.sh exited {result.returncode} (expected {expect_exit})\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def _run_verify(
    *,
    bundle_dir: Path,
    public_key: Path | None = None,
    strict: bool = False,
    expect_exit: int = 0,
    env: dict | None = None,
) -> subprocess.CompletedProcess:
    """Run verify-bundle.sh against an extracted bundle directory."""
    cmd = ["bash", str(VERIFY_SH), "--bundle-dir", str(bundle_dir)]
    if public_key:
        cmd += ["--public-key", str(public_key)]
    if strict:
        cmd += ["--strict"]

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        env=env or os.environ.copy(),
    )
    if result.returncode != expect_exit:
        raise AssertionError(
            f"verify-bundle.sh exited {result.returncode} (expected {expect_exit})\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def _extract_bundle(archive: Path, dest: Path) -> Path:
    """Extract a bundle archive and return the inner bundle directory."""
    with tarfile.open(archive, "r:gz") as tar:
        tar.extractall(dest)
    # The archive contains exactly one top-level directory
    entries = list(dest.iterdir())
    assert len(entries) == 1, f"expected 1 top-level entry in archive; got: {entries}"
    return entries[0]


# ── Fixtures ──────────────────────────────────────────────────────────────────


@pytest.fixture()
def artifacts(tmp_path):
    """Create a standard set of mock artifacts for a complete bundle."""
    art = tmp_path / "artifacts"
    art.mkdir()
    node_archive = _make_otp_archive(art, "node", "1.0.0", "amd64")
    coord_archive = _make_otp_archive(art, "coordinator", "1.0.0", "amd64")
    llama = _make_llama_server(art)
    model_path, model_sha256 = _make_model(art)
    return {
        "dir": art,
        "node_archive": node_archive,
        "coord_archive": coord_archive,
        "llama_server": llama,
        "model": model_path,
        "model_sha256": model_sha256,
        "arch": "amd64",
        "version": "1.0.0",
    }


# ── Test 1: Complete bundle assembly ──────────────────────────────────────────


class TestCompleteBundleAssembly:
    """Test 1: complete bundle assembles successfully and produces expected files."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path, artifacts):
        self.tmp = tmp_path
        self.arts = artifacts
        self.dist = tmp_path / "dist"

        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=artifacts["model_sha256"],
            dist_dir=self.dist,
        )

        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"
        self.archive = self.dist / f"{bundle_name}.tar.gz"
        self.extract_dir = tmp_path / "extracted"
        self.extract_dir.mkdir()
        self.bundle_dir = _extract_bundle(self.archive, self.extract_dir)

    def test_archive_created(self):
        assert self.archive.exists(), f"bundle archive not found: {self.archive}"

    def test_archive_checksum_file_created(self):
        sha_file = Path(str(self.archive) + ".sha256")
        assert sha_file.exists(), f"archive checksum file not found: {sha_file}"

    def test_archive_checksum_matches(self):
        sha_file = Path(str(self.archive) + ".sha256")
        expected = sha_file.read_text().split()[0]
        actual = hashlib.sha256(self.archive.read_bytes()).hexdigest()
        assert actual == expected, "archive checksum mismatch"

    def test_manifest_sha256_present(self):
        assert (self.bundle_dir / "manifest.sha256").exists()

    def test_manifest_json_present(self):
        assert (self.bundle_dir / "manifest.json").exists()

    def test_sbom_present(self):
        assert (self.bundle_dir / "sbom.spdx.json").exists()

    def test_profile_action_helper_present_and_authenticated(self):
        helper = self.bundle_dir / "bin" / "profile-action-helper"
        assert helper.is_file()
        assert helper.stat().st_mode & stat.S_IXUSR

        helper_hash = hashlib.sha256(helper.read_bytes()).hexdigest()
        manifest_lines = (self.bundle_dir / "manifest.sha256").read_text().splitlines()
        helper_entries = [line for line in manifest_lines if "bin/profile-action-helper" in line]
        assert len(helper_entries) == 1
        assert helper_hash == helper_entries[0].split()[0]

        manifest = json.loads((self.bundle_dir / "manifest.json").read_text())
        helper_files = [item for item in manifest["files"] if item["path"] == "bin/profile-action-helper"]
        assert helper_files == [{"path": "bin/profile-action-helper", "sha256": helper_hash}]
        assert manifest["components"]["profile_action_helper"] == "bin/profile-action-helper"

    def test_provenance_present(self):
        assert (self.bundle_dir / "provenance.json").exists()

    def test_install_sh_present(self):
        assert (self.bundle_dir / "scripts" / "install.sh").exists()

    def test_uninstall_sh_present(self):
        assert (self.bundle_dir / "scripts" / "uninstall.sh").exists()

    def test_verify_bundle_sh_present(self):
        assert (self.bundle_dir / "scripts" / "verify-bundle.sh").exists()

    def test_state_backup_sh_present(self):
        backup = self.bundle_dir / "scripts" / "state-backup.sh"
        assert backup.exists()
        assert backup.stat().st_mode & stat.S_IXUSR

    def test_state_backup_restore_uses_same_owner(self):
        """Verify restore extraction preserves ownership (--same-owner, not --no-same-owner).

        The restore path must propagate original file ownership from the archive
        so that cp -a in restore_category sets the correct owner on the destination.
        Using --no-same-owner discards owner metadata, causing coordinator config
        files to be restored as root:root instead of exocomp-coordinator:exocomp-coordinator.
        """
        backup_sh = self.bundle_dir / "scripts" / "state-backup.sh"
        text = backup_sh.read_text()
        # The extraction inside validate_archive must not strip owner info.
        assert "--no-same-owner" not in text, (
            "state-backup.sh must not use --no-same-owner during restore extraction; "
            "use --same-owner so that cp -a propagates original file ownership to the destination"
        )

    def test_llama_server_present(self):
        assert (self.bundle_dir / "llama-server").exists()

    def test_llama_server_is_executable(self):
        ls = self.bundle_dir / "llama-server"
        assert ls.stat().st_mode & stat.S_IXUSR, "llama-server must be executable"

    def test_llama_server_executable_and_runtime_libraries_present(self):
        assert (self.bundle_dir / "llama-server.bin").is_file()
        assert (
            self.bundle_dir / "lib" / "llama" / "libllama-server-impl.so"
        ).is_file()

    def test_llama_launcher_starts_using_only_the_shipped_runtime(self):
        env = {"PATH": os.environ["PATH"], "LD_LIBRARY_PATH": ""}
        result = subprocess.run(
            [str(self.bundle_dir / "llama-server"), "--version"],
            capture_output=True,
            text=True,
            check=True,
            env=env,
        )
        assert result.stdout == "llama-server-stub\n"

    def test_model_present_in_complete_bundle(self):
        model_files = list((self.bundle_dir / "models").glob("*.gguf"))
        assert model_files, "complete bundle must contain a GGUF model in models/"

    def test_node_release_archive_present(self):
        releases = list((self.bundle_dir / "releases").glob("exocomp-node-*.tar.gz"))
        assert releases, "bundle must contain a node OTP release archive"

    def test_coordinator_release_archive_present(self):
        releases = list((self.bundle_dir / "releases").glob("exocomp-coordinator-*.tar.gz"))
        assert releases, "bundle must contain a coordinator OTP release archive"


    def test_systemd_node_unit_present(self):
        assert (self.bundle_dir / "release" / "node" / "exocomp-node.service").exists()

    def test_systemd_coordinator_unit_present(self):
        assert (self.bundle_dir / "release" / "coordinator" / "exocomp-coordinator.service").exists()

    @pytest.mark.parametrize("component", ("node", "coordinator"))
    def test_systemd_start_limits_are_in_unit_section(self, component):
        unit = (
            self.bundle_dir
            / "release"
            / component
            / f"exocomp-{component}.service"
        ).read_text()
        unit_section, service_section = unit.split("[Service]", maxsplit=1)
        assert "StartLimitIntervalSec=120s" in unit_section
        assert "StartLimitBurst=4" in unit_section
        assert "StartLimitIntervalSec" not in service_section
        assert "StartLimitBurst" not in service_section

    @pytest.mark.parametrize("component", ("node", "coordinator"))
    def test_systemd_stop_does_not_depend_on_release_rpc(self, component):
        unit = (
            self.bundle_dir
            / "release"
            / component
            / f"exocomp-{component}.service"
        ).read_text()
        assert "ExecStop=/bin/kill -TERM $MAINPID" in unit
        assert f"current/bin/exocomp_{component} stop" not in unit

    def test_license_file_present_when_repo_has_license(self):
        """LICENSE is included in the bundle when it exists in the repo root.

        The LICENSE file is delivered by EXOCOMP-41 (license/governance task).
        This test passes whether or not EXOCOMP-41 has been merged.
        """
        repo_license = REPO_ROOT / "LICENSE"
        if repo_license.exists():
            assert (self.bundle_dir / "LICENSE").exists(), (
                "LICENSE must be included in the bundle when it exists in the repo"
            )

    def test_verify_bundle_passes(self):
        _run_verify(bundle_dir=self.bundle_dir, expect_exit=0)


class TestProfileActionHelperArchitecture:
    """The helper shipped in each bundle must match that bundle's architecture."""

    @pytest.mark.parametrize(
        ("arch", "compiler"),
        (("amd64", "cc"), ("arm64", "aarch64-linux-gnu-gcc")),
    )
    def test_helper_elf_machine_matches_bundle_arch(self, tmp_path, artifacts, arch, compiler):
        if shutil.which(compiler) is None:
            pytest.skip(f"{compiler} is required for {arch} helper packaging coverage")
        helper = _build_profile_helper(tmp_path / "artifacts", arch)
        dist = tmp_path / f"dist-{arch}"
        _run_assemble(
            tmp=tmp_path,
            arch=arch,
            version=artifacts["version"],
            kind="runtime",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            profile_helper=helper,
            llama_server=artifacts["llama_server"],
            dist_dir=dist,
        )
        archive = dist / f"exocomp-runtime-{artifacts['version']}-linux-{arch}.tar.gz"
        bundle_dir = _extract_bundle(archive, tmp_path / f"extracted-{arch}")
        shipped = bundle_dir / "bin" / "profile-action-helper"
        machine = subprocess.run(
            ["readelf", "-h", str(shipped)],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        expected = "Advanced Micro Devices X86-64" if arch == "amd64" else "AArch64"
        assert expected in machine
        manifest = json.loads((bundle_dir / "manifest.json").read_text())
        assert manifest["bundle"]["architecture"] == arch

    def test_wrong_architecture_helper_is_rejected(self, tmp_path, artifacts):
        helper = _build_profile_helper(tmp_path / "artifacts", "amd64")
        _run_assemble(
            tmp=tmp_path,
            arch="arm64",
            version=artifacts["version"],
            kind="runtime",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            profile_helper=helper,
            llama_server=artifacts["llama_server"],
            expect_exit=1,
        )


class TestDocumentedCleanRootWorkflow:
    def test_verbatim_install_commands_and_shipped_backup_restore(self, tmp_path):
        artifacts_dir = tmp_path / "artifacts"
        artifacts_dir.mkdir()
        node_archive = _make_otp_archive(artifacts_dir, "node", "0.1.0", "amd64")
        coord_archive = _make_otp_archive(
            artifacts_dir, "coordinator", "0.1.0", "amd64"
        )
        llama_server = _make_llama_server(artifacts_dir)
        model, model_sha256 = _make_model(artifacts_dir)
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch="amd64",
            version="0.1.0",
            kind="complete",
            node_archive=node_archive,
            coord_archive=coord_archive,
            llama_server=llama_server,
            model=model,
            model_sha256=model_sha256,
            dist_dir=dist,
        )

        command_blocks = re.findall(
            r"```sh\n(.*?)```", INSTALLATION_DOC.read_text(), re.DOTALL
        )
        assert len(command_blocks) >= 2

        tool_guard = tmp_path / "guarded-bin"
        tool_guard.mkdir()
        sudo = tool_guard / "sudo"
        sudo.write_text('#!/bin/sh\nexec "$@"\n')
        sudo.chmod(0o755)
        for forbidden in ("erl", "elixir", "mix", "curl", "wget"):
            guard = tool_guard / forbidden
            guard.write_text(
                f"#!/bin/sh\necho '{forbidden} must not be used' >&2\nexit 99\n"
            )
            guard.chmod(0o755)
        systemctl = tool_guard / "systemctl"
        systemctl.write_text(
            """#!/bin/sh
set -eu
command="$1"
shift
unit=""
for argument in "$@"; do
    unit="$argument"
done
case "${command}" in
    start|restart|stop|is-active)
        unit="${unit%.service}"
        ;;
esac
printf '%s %s\n' "${command}" "${unit}" >> "${EXOCOMP_FAKE_SYSTEMD_LOG}"
case "${command}" in
    is-system-running|enable|daemon-reload|status)
        exit 0
        ;;
    start|restart)
        component="${unit#exocomp-}"
        "${EXOCOMP_ROOT}/opt/exocomp/${component}/current/bin/exocomp_${component}" start
        : > "${EXOCOMP_FAKE_SYSTEMD_STATE}/${unit}"
        exit 0
        ;;
    stop)
        rm -f "${EXOCOMP_FAKE_SYSTEMD_STATE}/${unit}"
        exit 0
        ;;
    is-active)
        test -f "${EXOCOMP_FAKE_SYSTEMD_STATE}/${unit}"
        ;;
    *)
        echo "unexpected systemctl command: ${command}" >&2
        exit 2
        ;;
esac
"""
        )
        systemctl.chmod(0o755)

        clean_root = tmp_path / "clean-root"
        fake_systemd_state = tmp_path / "fake-systemd-state"
        fake_systemd_state.mkdir()
        fake_systemd_log = tmp_path / "fake-systemd.log"
        fake_release_log = tmp_path / "fake-release.log"
        env = {
            **os.environ,
            "PATH": f"{tool_guard}:{os.environ['PATH']}",
            "EXOCOMP_ROOT": str(clean_root),
            "EXOCOMP_SYSTEMD_DIR": str(tmp_path / "systemd"),
            "EXOCOMP_SUDOERS_DIR": str(tmp_path / "sudoers"),
            "EXOCOMP_SKIP_SYSTEMD": "0",
            "EXOCOMP_SKIP_VISUDO": "1",
            "EXOCOMP_CONFIG_VALIDATOR_COMMAND": "true",
            "EXOCOMP_FAKE_SYSTEMD_STATE": str(fake_systemd_state),
            "EXOCOMP_FAKE_SYSTEMD_LOG": str(fake_systemd_log),
            "EXOCOMP_FAKE_RELEASE_LOG": str(fake_release_log),
        }

        subprocess.run(
            ["bash", "-euo", "pipefail", "-c", command_blocks[0]],
            cwd=dist,
            env=env,
            check=True,
            capture_output=True,
            text=True,
        )
        bundle_dir = dist / "exocomp-complete-0.1.0-linux-amd64"
        subprocess.run(
            ["bash", "-euo", "pipefail", "-c", command_blocks[1]],
            cwd=bundle_dir,
            env=env,
            check=True,
            capture_output=True,
            text=True,
        )

        node_current = clean_root / "opt" / "exocomp" / "node" / "current"
        assert (node_current / "bin" / "exocomp_node").is_file()
        assert (node_current / "erts-28.5.0.3" / "bin" / "beam.smp").is_file()
        assert (node_current / "bin" / "llama-server").is_file()
        assert (node_current / "bin" / "exocomp-state-backup").is_file()
        assert Path(shutil.which("erl", path=str(tool_guard))) == tool_guard / "erl"
        assert (fake_systemd_state / "exocomp-node").is_file()
        systemd_calls = fake_systemd_log.read_text()
        assert "start exocomp-node" in systemd_calls
        assert "is-active exocomp-node" in systemd_calls
        release_calls = fake_release_log.read_text().splitlines()
        assert "start" in release_calls
        health_rpc_calls = [
            call for call in release_calls if call.startswith("rpc ")
        ]
        assert health_rpc_calls
        assert all("System.halt" not in call for call in health_rpc_calls)

        install_dir = clean_root / "opt" / "exocomp" / "node"
        state_dir = clean_root / "var" / "lib" / "exocomp-node"
        pki = install_dir / "config" / "pki" / "identity.pem"
        audit = install_dir / "log" / "audit.jsonl"
        ledger = state_dir / "replay_ledger.dets"
        pki.write_text("protected identity")
        audit.write_text('{"event":"installed"}\n')
        ledger.write_text("durable replay ledger")

        backup = tmp_path / "backups" / "node-state.tar.gz"
        installed_backup = node_current / "bin" / "exocomp-state-backup"
        subprocess.run(
            [
                str(installed_backup),
                "create",
                "--component", "node",
                "--output", str(backup),
            ],
            env=env,
            check=True,
            capture_output=True,
            text=True,
        )
        shutil.rmtree(install_dir / "config")
        shutil.rmtree(install_dir / "log")
        shutil.rmtree(state_dir)
        subprocess.run(
            [
                str(installed_backup),
                "restore",
                "--component", "node",
                "--archive", str(backup),
            ],
            env=env,
            check=True,
            capture_output=True,
            text=True,
        )

        assert pki.read_text() == "protected identity"
        assert audit.read_text() == '{"event":"installed"}\n'
        assert ledger.read_text() == "durable replay ledger"
        assert not (fake_systemd_state / "exocomp-node").exists()


# ── Test 2: Manifest covers every file ────────────────────────────────────────


class TestManifestCoverage:
    """Test 2: manifest.sha256 covers every file in the bundle."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path, artifacts):
        self.tmp = tmp_path
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=artifacts["model_sha256"],
            dist_dir=dist,
        )
        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        extract_dir = tmp_path / "extracted"
        extract_dir.mkdir()
        self.bundle_dir = _extract_bundle(archive, extract_dir)

    def test_all_files_in_manifest(self):
        """Every file in the bundle directory is listed in manifest.sha256."""
        manifest = self.bundle_dir / "manifest.sha256"

        # Parse manifest entries
        manifest_paths = set()
        for line in manifest.read_text().splitlines():
            if line.strip():
                _, rel_path = line.split(None, 1)
                manifest_paths.add(rel_path.lstrip("./"))

        # Find all actual files, excluding manifest meta-files
        actual_files = set()
        for path in self.bundle_dir.rglob("*"):
            if path.is_file():
                rel = path.relative_to(self.bundle_dir)
                name = str(rel)
                if name not in ("manifest.sha256", "manifest.json",
                                "sbom.spdx.json", "provenance.json"):
                    actual_files.add(name)

        not_covered = actual_files - manifest_paths
        assert not not_covered, (
            f"Files not covered by manifest.sha256:\n"
            + "\n".join(f"  {f}" for f in sorted(not_covered))
        )

    def test_manifest_has_no_extra_entries(self):
        """manifest.sha256 has no entries for non-existent files."""
        manifest = self.bundle_dir / "manifest.sha256"

        missing_from_disk = []
        for line in manifest.read_text().splitlines():
            if not line.strip():
                continue
            _, rel_path = line.split(None, 1)
            abs_path = self.bundle_dir / rel_path.lstrip("./")
            if not abs_path.exists():
                missing_from_disk.append(rel_path)

        assert not missing_from_disk, (
            "manifest.sha256 references files not present in bundle:\n"
            + "\n".join(f"  {f}" for f in missing_from_disk)
        )


# ── Test 3: SBOM structure ────────────────────────────────────────────────────


class TestSBOMStructure:
    """Test 3: sbom.spdx.json is well-formed SPDX 2.3 with required packages."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path, artifacts):
        self.tmp = tmp_path
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=artifacts["model_sha256"],
            dist_dir=dist,
        )
        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        extract_dir = tmp_path / "extracted"
        extract_dir.mkdir()
        self.bundle_dir = _extract_bundle(archive, extract_dir)
        self.sbom = json.loads((self.bundle_dir / "sbom.spdx.json").read_text())

    def test_spdx_version_2_3(self):
        assert self.sbom.get("spdxVersion") == "SPDX-2.3"

    def test_spdx_id_is_document(self):
        assert self.sbom.get("SPDXID") == "SPDXRef-DOCUMENT"

    def test_data_license_cc0(self):
        assert self.sbom.get("dataLicense") == "CC0-1.0"

    def test_creation_info_present(self):
        assert "creationInfo" in self.sbom
        ci = self.sbom["creationInfo"]
        assert "created" in ci
        assert "creators" in ci
        assert len(ci["creators"]) > 0

    def test_document_describes_bundle(self):
        assert "SPDXRef-Package-Bundle" in self.sbom.get("documentDescribes", [])

    def test_packages_present(self):
        packages = self.sbom.get("packages", [])
        assert packages, "SBOM must contain at least one package"

    def test_exocomp_package_present(self):
        packages = self.sbom.get("packages", [])
        names = [p.get("name") for p in packages]
        assert "Exocomp" in names, f"SBOM must include Exocomp package; got: {names}"

    def test_erlang_otp_package_present(self):
        packages = self.sbom.get("packages", [])
        names = [p.get("name") for p in packages]
        assert "Erlang/OTP" in names, f"SBOM must include Erlang/OTP package; got: {names}"

    def test_llama_cpp_package_present(self):
        packages = self.sbom.get("packages", [])
        names = [p.get("name") for p in packages]
        assert "llama.cpp" in names, f"SBOM must include llama.cpp package; got: {names}"

    def test_profile_action_helper_package_present_and_hash_pinned(self):
        packages = self.sbom.get("packages", [])
        helper = next(
            package for package in packages
            if package.get("name") == "profile-action-helper"
        )
        assert helper["licenseDeclared"] == "Apache-2.0"
        assert helper["checksums"] == [{
            "algorithm": "SHA256",
            "checksumValue": hashlib.sha256(
                (self.bundle_dir / "bin" / "profile-action-helper").read_bytes()
            ).hexdigest(),
        }]
        assert {
            relationship["relatedSpdxElement"]
            for relationship in self.sbom["relationships"]
            if relationship["spdxElementId"] == "SPDXRef-Package-Bundle"
            and relationship["relationshipType"] == "CONTAINS"
        } >= {helper["SPDXID"]}

    def test_qwen_model_package_in_complete_bundle(self):
        """Complete bundle SBOM must include the Qwen model package."""
        packages = self.sbom.get("packages", [])
        qwen = [p for p in packages if "Qwen" in p.get("name", "")]
        assert qwen, "complete bundle SBOM must include a Qwen model package"

    def test_all_packages_have_license(self):
        for pkg in self.sbom.get("packages", []):
            assert "licenseConcluded" in pkg, (
                f"package {pkg.get('name')} missing licenseConcluded"
            )
            assert "licenseDeclared" in pkg, (
                f"package {pkg.get('name')} missing licenseDeclared"
            )

    def test_relationships_present(self):
        rels = self.sbom.get("relationships", [])
        assert rels, "SBOM must have relationships"
        types = {r.get("relationshipType") for r in rels}
        assert "DESCRIBES" in types, "SBOM must have a DESCRIBES relationship"
        assert "CONTAINS" in types, "SBOM must have CONTAINS relationships"

    def test_document_namespace_is_uri(self):
        ns = self.sbom.get("documentNamespace", "")
        assert ns.startswith("https://"), f"documentNamespace must be a URI: {ns!r}"


# ── Test 4: Provenance structure ──────────────────────────────────────────────


class TestProvenanceStructure:
    """Test 4: provenance.json is SLSA-conformant with required fields."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path, artifacts):
        self.tmp = tmp_path
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=artifacts["model_sha256"],
            dist_dir=dist,
        )
        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        extract_dir = tmp_path / "extracted"
        extract_dir.mkdir()
        self.bundle_dir = _extract_bundle(archive, extract_dir)
        self.prov = json.loads((self.bundle_dir / "provenance.json").read_text())

    def test_statement_type_present(self):
        assert "_type" in self.prov
        assert "in-toto.io/Statement" in self.prov["_type"]

    def test_predicate_type_slsa(self):
        assert "predicateType" in self.prov
        assert "slsa.dev/provenance" in self.prov["predicateType"]

    def test_subject_present(self):
        subject = self.prov.get("subject", [])
        assert subject, "provenance must have at least one subject"
        assert "name" in subject[0]
        assert "digest" in subject[0]

    def test_predicate_present(self):
        assert "predicate" in self.prov

    def test_builder_present(self):
        pred = self.prov["predicate"]
        assert "builder" in pred
        assert "id" in pred["builder"]

    def test_materials_present(self):
        pred = self.prov["predicate"]
        assert "materials" in pred
        materials = pred["materials"]
        assert materials, "provenance must list at least one material"

    def test_source_commit_in_materials(self):
        pred = self.prov["predicate"]
        materials = pred.get("materials", [])
        # At least one material should reference the source git repo
        source_materials = [
            m for m in materials
            if "github.com/NVShawn/exocomp" in m.get("uri", "")
        ]
        assert source_materials, (
            "provenance materials must include the source repository"
        )

    def test_toolchain_present(self):
        pred = self.prov["predicate"]
        assert "toolchain" in pred
        tc = pred["toolchain"]
        assert "elixir_version" in tc or "otp_version" in tc, (
            "toolchain must identify Elixir or OTP version"
        )

    def test_dependency_locks_present(self):
        pred = self.prov["predicate"]
        assert "dependency_locks" in pred

    def test_invocation_identifies_source(self):
        pred = self.prov["predicate"]
        invocation = pred.get("invocation", {})
        cfg = invocation.get("configSource", {})
        assert cfg.get("uri", ""), "invocation.configSource.uri must be set"
        assert cfg.get("digest", {}).get("sha1", ""), (
            "invocation.configSource.digest.sha1 must be set"
        )


# ── Test 5: Tamper detection — modified file ───────────────────────────────────


class TestTamperDetectionModifiedFile:
    """Test 5: verify-bundle.sh fails when a bundle file is modified after assembly."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path, artifacts):
        self.tmp = tmp_path
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=artifacts["model_sha256"],
            dist_dir=dist,
        )
        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        self.extract_dir = tmp_path / "extracted"
        self.extract_dir.mkdir()
        self.bundle_dir = _extract_bundle(archive, self.extract_dir)

    def test_tampered_install_sh_fails_verification(self):
        """Modifying install.sh after assembly must cause verify-bundle to fail."""
        install_sh = self.bundle_dir / "scripts" / "install.sh"
        assert install_sh.exists()
        install_sh.write_bytes(install_sh.read_bytes() + b"\n# TAMPERED\n")

        result = _run_verify(bundle_dir=self.bundle_dir, expect_exit=1)
        assert "TAMPERED" in result.stderr or "tampered" in result.stderr.lower() or "MISMATCH" in result.stderr

    def test_tampered_llama_server_fails_verification(self):
        """Modifying the llama-server binary must cause verify-bundle to fail."""
        llama = self.bundle_dir / "llama-server"
        assert llama.exists()
        llama.write_bytes(b"#!/bin/sh\necho MALICIOUS\n")

        result = _run_verify(bundle_dir=self.bundle_dir, expect_exit=1)
        assert result.returncode == 1

    def test_tampered_profile_action_helper_fails_verification(self):
        """Modifying the privileged helper must cause verification to fail."""
        helper = self.bundle_dir / "bin" / "profile-action-helper"
        assert helper.exists()
        helper.write_bytes(helper.read_bytes() + b"\nTAMPERED\n")

        result = _run_verify(bundle_dir=self.bundle_dir, expect_exit=1)
        assert result.returncode == 1

    def test_tampered_model_fails_verification(self):
        """Modifying the model file must cause verify-bundle to fail."""
        model_files = list((self.bundle_dir / "models").glob("*.gguf"))
        assert model_files, "no model file in bundle"
        model_files[0].write_bytes(b"FAKE REPLACEMENT MODEL DATA")

        result = _run_verify(bundle_dir=self.bundle_dir, expect_exit=1)
        assert result.returncode == 1

    def test_tampered_systemd_unit_fails_verification(self):
        """Modifying a systemd unit file must cause verify-bundle to fail."""
        unit = self.bundle_dir / "release" / "node" / "exocomp-node.service"
        assert unit.exists()
        original = unit.read_text()
        unit.write_text(original + "\n# INJECTED MALICIOUS DIRECTIVE\nExecStart=/bin/evil\n")

        result = _run_verify(bundle_dir=self.bundle_dir, expect_exit=1)
        assert result.returncode == 1


# ── Test 6: Tamper detection — deleted file ───────────────────────────────────


class TestTamperDetectionDeletedFile:
    """Test 6: verify-bundle.sh fails when a manifest-listed file is removed."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path, artifacts):
        self.tmp = tmp_path
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=artifacts["model_sha256"],
            dist_dir=dist,
        )
        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        self.extract_dir = tmp_path / "extracted"
        self.extract_dir.mkdir()
        self.bundle_dir = _extract_bundle(archive, self.extract_dir)

    def test_deleted_file_fails_verification(self):
        """Removing a file covered by the manifest must fail verification."""
        llama = self.bundle_dir / "llama-server"
        llama.unlink()

        result = _run_verify(bundle_dir=self.bundle_dir, expect_exit=1)
        assert "MISSING" in result.stderr or "missing" in result.stderr.lower()


# ── Test 7: Checksum self-consistency ─────────────────────────────────────────


class TestChecksumConsistency:
    """Test 7: the archive-level .sha256 file correctly covers the archive."""

    def test_archive_sha256_file_matches_archive(self, tmp_path, artifacts):
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="runtime",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            dist_dir=dist,
        )

        archives = list(dist.glob("*.tar.gz"))
        assert archives, "no bundle archive in dist/"
        archive = archives[0]
        sha_file = Path(str(archive) + ".sha256")
        assert sha_file.exists(), f".sha256 file not found: {sha_file}"

        recorded = sha_file.read_text().split()[0]
        actual = hashlib.sha256(archive.read_bytes()).hexdigest()
        assert actual == recorded, (
            f"Archive checksum mismatch:\n  recorded: {recorded}\n  actual:   {actual}"
        )


@pytest.mark.skipif(
    shutil.which("cc") is None or shutil.which("readelf") is None,
    reason="C compiler and readelf are required for native loader coverage",
)
class TestLlamaRuntimeClosure:
    @staticmethod
    def _build_dynamic_runtime(tmp_path: Path) -> tuple[Path, Path]:
        source = tmp_path / "source"
        libraries = tmp_path / "llama-libs"
        source.mkdir()
        libraries.mkdir()

        (source / "ggml.c").write_text(
            'const char *ggml_message(void) { return "runtime closure ok"; }\n'
        )
        (source / "impl.c").write_text(
            "extern const char *ggml_message(void);\n"
            "const char *server_message(void) { return ggml_message(); }\n"
        )
        (source / "server.c").write_text(
            "#include <stdio.h>\n"
            "extern const char *server_message(void);\n"
            "int main(void) { puts(server_message()); return 0; }\n"
        )

        subprocess.run(
            [
                "cc", "-fPIC", "-shared",
                "-Wl,-soname,libggml-base.so",
                "-o", str(libraries / "libggml-base.so"),
                str(source / "ggml.c"),
            ],
            check=True,
        )
        subprocess.run(
            [
                "cc", "-fPIC", "-shared",
                "-Wl,-soname,libllama-server-impl.so",
                "-o", str(libraries / "libllama-server-impl.so"),
                str(source / "impl.c"),
                "-L", str(libraries),
                "-Wl,--no-as-needed",
                "-l:libggml-base.so",
            ],
            check=True,
        )
        server = tmp_path / "llama-server"
        subprocess.run(
            [
                "cc",
                "-o", str(server),
                str(source / "server.c"),
                "-L", str(libraries),
                f"-Wl,-rpath-link,{libraries}",
                "-Wl,--no-as-needed",
                "-l:libllama-server-impl.so",
            ],
            check=True,
        )
        return server, libraries

    def test_dynamic_server_starts_with_transitive_shipped_libraries(self, tmp_path):
        server, libraries = self._build_dynamic_runtime(tmp_path)
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch="amd64",
            version="1.0.0",
            kind="runtime",
            llama_server=server,
            llama_lib_dir=libraries,
            dist_dir=dist,
        )
        archive = dist / "exocomp-runtime-1.0.0-linux-amd64.tar.gz"
        extract_dir = tmp_path / "extracted"
        extract_dir.mkdir()
        bundle_dir = _extract_bundle(archive, extract_dir)

        result = subprocess.run(
            [str(bundle_dir / "llama-server"), "--version"],
            capture_output=True,
            text=True,
            check=True,
            env={"PATH": os.environ["PATH"], "LD_LIBRARY_PATH": ""},
        )
        assert result.stdout == "runtime closure ok\n"
        assert (bundle_dir / "lib" / "llama" / "libggml-base.so").is_file()
        assert (
            bundle_dir / "lib" / "llama" / "libllama-server-impl.so"
        ).is_file()

    def test_assembly_rejects_an_incomplete_dynamic_runtime(self, tmp_path):
        server, _libraries = self._build_dynamic_runtime(tmp_path)
        empty_libraries = tmp_path / "empty-libs"
        empty_libraries.mkdir()

        result = _run_assemble(
            tmp=tmp_path,
            arch="amd64",
            version="1.0.0",
            kind="runtime",
            llama_server=server,
            llama_lib_dir=empty_libraries,
            dist_dir=tmp_path / "dist",
            expect_exit=1,
        )
        assert "libllama-server-impl.so" in result.stderr
        assert "not bundled" in result.stderr


# ── Test 8: Runtime-only bundle — model absent ────────────────────────────────


class TestRuntimeBundle:
    """Test 8: runtime-only bundle is assembled without the model."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path, artifacts):
        self.tmp = tmp_path
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="runtime",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            # No --model or --model-sha256 for runtime kind
            dist_dir=dist,
        )
        bundle_name = f"exocomp-runtime-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        extract_dir = tmp_path / "extracted"
        extract_dir.mkdir()
        self.bundle_dir = _extract_bundle(archive, extract_dir)

    def test_runtime_bundle_archive_name(self):
        assert self.bundle_dir.name.startswith("exocomp-runtime-")

    def test_model_absent_from_runtime_bundle(self):
        gguf_files = list(self.bundle_dir.rglob("*.gguf"))
        assert not gguf_files, (
            "runtime bundle must not contain any GGUF model files"
        )

    def test_llama_server_present_in_runtime_bundle(self):
        assert (self.bundle_dir / "llama-server").exists()

    def test_verification_passes_for_runtime_bundle(self):
        _run_verify(bundle_dir=self.bundle_dir, expect_exit=0)

    def test_sbom_excludes_model_package(self):
        sbom = json.loads((self.bundle_dir / "sbom.spdx.json").read_text())
        packages = sbom.get("packages", [])
        qwen = [p for p in packages if "Qwen" in p.get("name", "")]
        assert not qwen, (
            "runtime bundle SBOM must NOT include a Qwen model package"
        )


# ── Test 9: Bad model SHA-256 causes assembly failure ─────────────────────────


class TestModelSHA256PreVerification:
    """Test 9: assemble-bundle.sh fails immediately when model SHA-256 is wrong."""

    def test_bad_model_sha256_fails_before_staging(self, tmp_path, artifacts):
        dist = tmp_path / "dist"
        bad_sha256 = "0" * 64

        result = _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=bad_sha256,
            dist_dir=dist,
            expect_exit=1,
        )
        assert "MISMATCH" in result.stderr or "mismatch" in result.stderr.lower()

        # No archive should be created
        archives = list(dist.glob("*.tar.gz")) if dist.exists() else []
        assert not archives, "no archive should be created when model SHA-256 is wrong"


# ── Test 10: SBOM complete vs runtime ─────────────────────────────────────────


class TestSBOMCompleteVsRuntime:
    """Test 10: SBOM includes model package for complete, excludes for runtime."""

    def _sbom_for(self, tmp_path, artifacts, kind: str) -> dict:
        dist = tmp_path / f"dist-{kind}"
        kwargs = dict(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind=kind,
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            dist_dir=dist,
        )
        if kind == "complete":
            kwargs["model"] = artifacts["model"]
            kwargs["model_sha256"] = artifacts["model_sha256"]

        _run_assemble(**kwargs)
        bundle_name = f"exocomp-{kind}-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        extract_dir = tmp_path / f"extracted-{kind}"
        extract_dir.mkdir()
        bundle_dir = _extract_bundle(archive, extract_dir)
        return json.loads((bundle_dir / "sbom.spdx.json").read_text())

    def test_complete_sbom_includes_model(self, tmp_path, artifacts):
        sbom = self._sbom_for(tmp_path, artifacts, "complete")
        packages = sbom.get("packages", [])
        qwen = [p for p in packages if "Qwen" in p.get("name", "")]
        assert qwen, "complete bundle SBOM must include Qwen model package"

    def test_runtime_sbom_excludes_model(self, tmp_path, artifacts):
        sbom = self._sbom_for(tmp_path, artifacts, "runtime")
        packages = sbom.get("packages", [])
        qwen = [p for p in packages if "Qwen" in p.get("name", "")]
        assert not qwen, "runtime bundle SBOM must not include Qwen model package"


# ── Test 11: Missing required argument ────────────────────────────────────────


class TestMissingRequiredArgs:
    """Test 11: assemble-bundle.sh fails clearly when required arguments are missing."""

    def test_missing_arch_fails(self, tmp_path):
        result = subprocess.run(
            ["bash", str(ASSEMBLE_SH), "--version", "1.0.0"],
            capture_output=True, text=True, env=_base_env(tmp_path),
        )
        assert result.returncode != 0
        assert "arch" in result.stderr.lower()

    def test_missing_version_fails(self, tmp_path):
        result = subprocess.run(
            ["bash", str(ASSEMBLE_SH), "--arch", "amd64"],
            capture_output=True, text=True, env=_base_env(tmp_path),
        )
        assert result.returncode != 0
        assert "version" in result.stderr.lower()

    def test_missing_model_for_complete_fails(self, tmp_path, artifacts):
        result = _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            # No --model
            expect_exit=1,
        )
        assert "model" in result.stderr.lower()

    def test_invalid_arch_fails(self, tmp_path, artifacts):
        result = _run_assemble(
            tmp=tmp_path,
            arch="sparc",
            version=artifacts["version"],
            expect_exit=1,
        )
        assert result.returncode == 1


# ── Test 12: verify-bundle.sh strict mode ─────────────────────────────────────


class TestVerifyBundleStrictMode:
    """Test 12: --strict mode rejects unsigned bundles."""

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path, artifacts):
        self.tmp = tmp_path
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="runtime",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            dist_dir=dist,
        )
        bundle_name = f"exocomp-runtime-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        extract_dir = tmp_path / "extracted"
        extract_dir.mkdir()
        self.bundle_dir = _extract_bundle(archive, extract_dir)

    def test_non_strict_passes_unsigned(self):
        _run_verify(bundle_dir=self.bundle_dir, strict=False, expect_exit=0)

    def test_strict_fails_unsigned(self):
        result = _run_verify(bundle_dir=self.bundle_dir, strict=True, expect_exit=1)
        assert "minisig" in result.stderr.lower() or "signature" in result.stderr.lower()

    def test_signed_bundle_passes_strict_verification(self):
        fake_bin = self.tmp / "bin"
        fake_bin.mkdir()
        fake_minisign = fake_bin / "minisign"
        fake_minisign.write_text(
            """#!/bin/sh
set -eu
mode=""
signature=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -S|-V) mode="$1"; shift ;;
    -x) signature="$2"; shift 2 ;;
    -s|-m|-p|-t) shift 2 ;;
    *) shift ;;
  esac
done
case "${mode}" in
  -S) printf 'trusted comment: fake test signature\\n' > "${signature}" ;;
  -V) test -s "${signature}" ;;
  *) exit 2 ;;
esac
"""
        )
        fake_minisign.chmod(0o755)

        private_key = self.tmp / "minisign.key"
        public_key = self.tmp / "minisign.pub"
        private_key.write_text("fake private key\n")
        public_key.write_text("fake public key\n")
        signature = self.bundle_dir / "bundle.minisig"
        env = {
            **os.environ,
            "PATH": f"{fake_bin}{os.pathsep}{os.environ['PATH']}",
        }

        result = subprocess.run(
            [
                "bash",
                str(SIGN_SH),
                "--manifest",
                str(self.bundle_dir / "manifest.sha256"),
                "--sign-key",
                str(private_key),
                "--output",
                str(signature),
            ],
            capture_output=True,
            text=True,
            env=env,
        )

        assert result.returncode == 0, result.stderr
        assert signature.is_file()
        _run_verify(
            bundle_dir=self.bundle_dir,
            public_key=public_key,
            strict=True,
            expect_exit=0,
            env=env,
        )


# ── Test 13: generate-sbom.sh standalone ─────────────────────────────────────


class TestGenerateSBOMStandalone:
    """Test 13: generate-sbom.sh can be called directly and produces valid JSON."""

    def test_generate_sbom_produces_valid_json(self, tmp_path):
        output = tmp_path / "test-sbom.spdx.json"
        result = subprocess.run(
            [
                "bash", str(GEN_SBOM_SH),
                "--arch", "arm64",
                "--version", "2.0.0",
                "--kind", "runtime",
                "--source-commit", "deadbeef",
                "--builder-image", "hexpm/elixir:test@sha256:abc",
                "--output", str(output),
            ],
            capture_output=True, text=True,
        )
        assert result.returncode == 0, (
            f"generate-sbom.sh failed:\n{result.stderr}"
        )
        assert output.exists(), "SBOM output file not created"
        sbom = json.loads(output.read_text())
        assert sbom.get("spdxVersion") == "SPDX-2.3"

    def test_generate_sbom_arm64_bundle_name(self, tmp_path):
        output = tmp_path / "sbom.spdx.json"
        subprocess.run(
            [
                "bash", str(GEN_SBOM_SH),
                "--arch", "arm64",
                "--version", "1.5.0",
                "--kind", "complete",
                "--output", str(output),
            ],
            capture_output=True, text=True, check=True,
        )
        sbom = json.loads(output.read_text())
        packages = sbom.get("packages", [])
        bundle_pkg = next((p for p in packages if "exocomp-complete" in p.get("name", "")), None)
        assert bundle_pkg is not None, "SBOM must contain the bundle package"
        assert "arm64" in bundle_pkg["name"]


# ── Test 14: generate-provenance.sh standalone ────────────────────────────────


class TestGenerateProvenanceStandalone:
    """Test 14: generate-provenance.sh can be called directly and produces valid JSON."""

    def test_generate_provenance_produces_valid_json(self, tmp_path):
        output = tmp_path / "provenance.json"
        result = subprocess.run(
            [
                "bash", str(GEN_PROV_SH),
                "--arch", "amd64",
                "--version", "1.0.0",
                "--kind", "complete",
                "--source-commit", "feedcafe",
                "--output", str(output),
            ],
            capture_output=True, text=True,
        )
        assert result.returncode == 0, (
            f"generate-provenance.sh failed:\n{result.stderr}"
        )
        assert output.exists()
        prov = json.loads(output.read_text())
        assert "predicateType" in prov
        assert "slsa.dev/provenance" in prov["predicateType"]

    def test_generate_provenance_source_commit_in_materials(self, tmp_path):
        output = tmp_path / "provenance.json"
        source_commit = "abcdef1234567890"
        subprocess.run(
            [
                "bash", str(GEN_PROV_SH),
                "--arch", "amd64",
                "--version", "1.0.0",
                "--kind", "runtime",
                "--source-commit", source_commit,
                "--output", str(output),
            ],
            capture_output=True, text=True, check=True,
        )
        prov = json.loads(output.read_text())
        materials = prov["predicate"]["materials"]
        sha1_values = [
            m.get("digest", {}).get("sha1", "")
            for m in materials
        ]
        assert source_commit in sha1_values, (
            f"source commit {source_commit!r} not found in provenance materials: {sha1_values}"
        )


# ── Test 15: Double-build byte-identity (reproducibility) ─────────────────────


class TestDoubleBuildReproducibility:
    """Test 15: Two complete-bundle assemblies with the same SOURCE_DATE_EPOCH
    must produce byte-identical .tar.gz archives.

    This catches any nondeterministic input: filesystem mtimes, SBOM timestamps,
    provenance build timestamps, manifest.json timestamps, archive metadata.
    """

    def _assemble_once(self, *, tmp: Path, artifacts: dict, epoch: str) -> bytes:
        """Run one assembly and return the archive bytes."""
        dist = tmp / "dist"
        env = {**os.environ, "SOURCE_DATE_EPOCH": epoch}
        result = subprocess.run(
            [
                "bash", str(ASSEMBLE_SH),
                "--arch", artifacts["arch"],
                "--version", artifacts["version"],
                "--kind", "complete",
                "--node-archive", str(artifacts["node_archive"]),
                "--coord-archive", str(artifacts["coord_archive"]),
                "--llama-server", str(artifacts["llama_server"]),
                "--model", str(artifacts["model"]),
                "--model-sha256", artifacts["model_sha256"],
                "--source-commit", "abc1234def5678",
                "--builder-image", "docker.io/hexpm/elixir:test@sha256:000",
                "--dist-dir", str(dist),
            ],
            capture_output=True, text=True, env=env,
        )
        assert result.returncode == 0, (
            f"assemble-bundle.sh failed:\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        assert archive.exists(), f"archive not found: {archive}"
        return archive.read_bytes()

    def test_identical_inputs_produce_byte_identical_archive(self, tmp_path, artifacts):
        """Two assemblies from identical inputs must be byte-identical."""
        epoch = "1700000000"
        tmp1 = tmp_path / "build1"
        tmp2 = tmp_path / "build2"
        tmp1.mkdir()
        tmp2.mkdir()

        bytes1 = self._assemble_once(tmp=tmp1, artifacts=artifacts, epoch=epoch)
        bytes2 = self._assemble_once(tmp=tmp2, artifacts=artifacts, epoch=epoch)

        assert bytes1 == bytes2, (
            f"Double build produced non-identical archives: "
            f"size1={len(bytes1)}, size2={len(bytes2)}"
        )

    def test_different_epoch_produces_different_archive(self, tmp_path, artifacts):
        """Bundles built with different SOURCE_DATE_EPOCH values must differ."""
        tmp1 = tmp_path / "build1"
        tmp2 = tmp_path / "build2"
        tmp1.mkdir()
        tmp2.mkdir()

        bytes1 = self._assemble_once(tmp=tmp1, artifacts=artifacts, epoch="1700000000")
        bytes2 = self._assemble_once(tmp=tmp2, artifacts=artifacts, epoch="1800000000")

        assert bytes1 != bytes2, "Different SOURCE_DATE_EPOCH must produce different archives"

    def test_sbom_timestamp_is_deterministic(self, tmp_path, artifacts):
        """SBOM creationInfo.created must match the SOURCE_DATE_EPOCH, not wall-clock time."""
        epoch = "1700000000"
        dist = tmp_path / "dist"
        env = {**os.environ, "SOURCE_DATE_EPOCH": epoch}
        subprocess.run(
            [
                "bash", str(ASSEMBLE_SH),
                "--arch", artifacts["arch"],
                "--version", artifacts["version"],
                "--kind", "complete",
                "--node-archive", str(artifacts["node_archive"]),
                "--coord-archive", str(artifacts["coord_archive"]),
                "--llama-server", str(artifacts["llama_server"]),
                "--model", str(artifacts["model"]),
                "--model-sha256", artifacts["model_sha256"],
                "--source-commit", "abc1234",
                "--dist-dir", str(dist),
            ],
            capture_output=True, text=True, env=env, check=True,
        )
        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        extract_dir = tmp_path / "extracted"
        extract_dir.mkdir()
        bundle_dir = _extract_bundle(archive, extract_dir)

        sbom = json.loads((bundle_dir / "sbom.spdx.json").read_text())
        created = sbom["creationInfo"]["created"]
        # Must be exactly the ISO-8601 representation of epoch 1700000000
        assert created == "2023-11-14T22:13:20Z", (
            f"SBOM creation timestamp {created!r} does not match SOURCE_DATE_EPOCH={epoch}"
        )

    def test_sbom_namespace_stable_across_builds(self, tmp_path, artifacts):
        """SBOM documentNamespace must not embed a per-build timestamp."""
        epoch = "1700000000"
        dist1 = tmp_path / "dist1"
        dist2 = tmp_path / "dist2"
        env = {**os.environ, "SOURCE_DATE_EPOCH": epoch}

        for dist in (dist1, dist2):
            subprocess.run(
                [
                    "bash", str(ASSEMBLE_SH),
                    "--arch", artifacts["arch"],
                    "--version", artifacts["version"],
                    "--kind", "complete",
                    "--node-archive", str(artifacts["node_archive"]),
                    "--coord-archive", str(artifacts["coord_archive"]),
                    "--llama-server", str(artifacts["llama_server"]),
                    "--model", str(artifacts["model"]),
                    "--model-sha256", artifacts["model_sha256"],
                    "--source-commit", "abc1234",
                    "--dist-dir", str(dist),
                ],
                capture_output=True, text=True, env=env, check=True,
            )

        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"

        e1 = tmp_path / "e1"
        e2 = tmp_path / "e2"
        e1.mkdir()
        e2.mkdir()
        sbom1 = json.loads(_extract_bundle(dist1 / f"{bundle_name}.tar.gz", e1).joinpath("sbom.spdx.json").read_text())
        sbom2 = json.loads(_extract_bundle(dist2 / f"{bundle_name}.tar.gz", e2).joinpath("sbom.spdx.json").read_text())

        assert sbom1["documentNamespace"] == sbom2["documentNamespace"], (
            f"SBOM documentNamespace differs between builds:\n"
            f"  build1: {sbom1['documentNamespace']}\n"
            f"  build2: {sbom2['documentNamespace']}"
        )


# ── Test 16: Signed-metadata tamper detection ─────────────────────────────────


class TestSignedMetadataTamperDetection:
    """Test 16: verify-bundle.sh must reject tampering of manifest.json,
    sbom.spdx.json, and provenance.json because those files are now listed
    in manifest.sha256 (and the signature covers manifest.sha256).
    """

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path, artifacts):
        self.tmp = tmp_path
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=artifacts["model_sha256"],
            dist_dir=dist,
        )
        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        extract_dir = tmp_path / "extracted"
        extract_dir.mkdir()
        self.bundle_dir = _extract_bundle(archive, extract_dir)

    def _tamper_and_verify(self, rel_path: str) -> subprocess.CompletedProcess:
        """Append a byte to `rel_path` inside the bundle and run verify-bundle."""
        target = self.bundle_dir / rel_path
        assert target.exists(), f"Expected file not found in bundle: {rel_path}"
        target.write_bytes(target.read_bytes() + b"\n# TAMPERED\n")
        return _run_verify(bundle_dir=self.bundle_dir, expect_exit=1)

    def test_tampered_manifest_json_fails_verification(self):
        """Tampering manifest.json must cause verify-bundle.sh to fail."""
        result = self._tamper_and_verify("manifest.json")
        combined = result.stdout + result.stderr
        assert "TAMPERED" in combined or "tampered" in combined.lower() or "mismatch" in combined.lower(), (
            f"Expected tamper message; got:\n{combined}"
        )

    def test_tampered_sbom_fails_verification(self):
        """Tampering sbom.spdx.json must cause verify-bundle.sh to fail."""
        result = self._tamper_and_verify("sbom.spdx.json")
        assert result.returncode == 1

    def test_tampered_provenance_fails_verification(self):
        """Tampering provenance.json must cause verify-bundle.sh to fail."""
        result = self._tamper_and_verify("provenance.json")
        assert result.returncode == 1

    def test_deleted_manifest_json_fails_verification(self):
        """Deleting manifest.json must cause verify-bundle.sh to fail."""
        (self.bundle_dir / "manifest.json").unlink()
        result = _run_verify(bundle_dir=self.bundle_dir, expect_exit=1)
        assert result.returncode == 1

    def test_deleted_sbom_fails_verification(self):
        """Deleting sbom.spdx.json must cause verify-bundle.sh to fail."""
        (self.bundle_dir / "sbom.spdx.json").unlink()
        result = _run_verify(bundle_dir=self.bundle_dir, expect_exit=1)
        assert result.returncode == 1

    def test_deleted_provenance_fails_verification(self):
        """Deleting provenance.json must cause verify-bundle.sh to fail."""
        (self.bundle_dir / "provenance.json").unlink()
        result = _run_verify(bundle_dir=self.bundle_dir, expect_exit=1)
        assert result.returncode == 1

    def test_metadata_files_listed_in_manifest_sha256(self):
        """manifest.sha256 must list manifest.json, sbom.spdx.json, and provenance.json."""
        manifest_text = (self.bundle_dir / "manifest.sha256").read_text()
        for meta in ("manifest.json", "sbom.spdx.json", "provenance.json"):
            assert meta in manifest_text, (
                f"{meta} must be listed in manifest.sha256 to be covered by the signature"
            )


# ── Test 17: License completeness ─────────────────────────────────────────────


class TestLicenseCompleteness:
    """Test 17: Assembled bundles must contain a populated LICENSES/ directory
    with all required license texts for governed third-party components.
    """

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path, artifacts):
        self.tmp = tmp_path
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=artifacts["model_sha256"],
            dist_dir=dist,
        )
        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        extract_dir = tmp_path / "extracted"
        extract_dir.mkdir()
        self.bundle_dir = _extract_bundle(archive, extract_dir)

    def test_licenses_directory_present(self):
        """LICENSES/ directory must exist in the assembled bundle."""
        licenses_dir = self.bundle_dir / "LICENSES"
        assert licenses_dir.is_dir(), "LICENSES/ directory must be present in bundle"

    def test_licenses_directory_non_empty(self):
        """LICENSES/ directory must contain at least one license file."""
        licenses_dir = self.bundle_dir / "LICENSES"
        files = list(licenses_dir.iterdir())
        assert len(files) > 0, "LICENSES/ directory must not be empty"

    def test_apache_2_license_present(self):
        """Apache-2.0.txt must be present for Erlang/OTP, Elixir, and Hex package components."""
        assert (self.bundle_dir / "LICENSES" / "Apache-2.0.txt").exists(), (
            "LICENSES/Apache-2.0.txt must be present (required by Erlang/OTP, Elixir, and others)"
        )

    def test_mit_license_present(self):
        """MIT.txt must be present for llama.cpp and MIT-licensed Hex packages."""
        assert (self.bundle_dir / "LICENSES" / "MIT.txt").exists(), (
            "LICENSES/MIT.txt must be present (required by llama.cpp, Bandit, etc.)"
        )

    def test_bsd_3_clause_license_present(self):
        """BSD-3-Clause.txt must be present for x509 and other BSD-licensed components."""
        assert (self.bundle_dir / "LICENSES" / "BSD-3-Clause.txt").exists(), (
            "LICENSES/BSD-3-Clause.txt must be present (required by x509)"
        )

    def test_licenses_covered_by_manifest(self):
        """LICENSES/ files must appear in manifest.sha256 to be signature-authenticated."""
        manifest_text = (self.bundle_dir / "manifest.sha256").read_text()
        licenses_dir = self.bundle_dir / "LICENSES"
        for lic_file in sorted(licenses_dir.iterdir()):
            rel = f"LICENSES/{lic_file.name}"
            assert rel in manifest_text, (
                f"{rel} must be listed in manifest.sha256"
            )

    def test_non_strict_verification_passes_with_populated_licenses(self):
        """Non-strict verification must pass when LICENSES/ is populated."""
        _run_verify(bundle_dir=self.bundle_dir, strict=False, expect_exit=0)


# ── Test 18: Assembly fails closed on missing LICENSES ────────────────────────


class TestAssemblyFailsOnMissingLicenses:
    """Test 18: assemble-bundle.sh must fail (not warn) when the LICENSES
    source directory is absent or when required license files are missing.
    """

    def test_assembly_fails_when_licenses_dir_absent(self, tmp_path, artifacts):
        """Assembly must fail when --licenses-dir points to a non-existent path."""
        missing_dir = tmp_path / "nonexistent_licenses"
        result = _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=artifacts["model_sha256"],
            extra_args=["--licenses-dir", str(missing_dir)],
            expect_exit=1,
        )
        combined = result.stdout + result.stderr
        assert "licenses" in combined.lower() or "LICENSES" in combined, (
            f"Expected LICENSES error; got:\n{combined}"
        )

    def test_assembly_fails_when_required_license_file_missing(self, tmp_path, artifacts):
        """Assembly must fail when a required license SPDX file is absent from LICENSES/."""
        # Create a LICENSES dir with only Apache-2.0, omit MIT and BSD-3-Clause.
        incomplete_licenses = tmp_path / "incomplete_licenses"
        incomplete_licenses.mkdir()
        (incomplete_licenses / "Apache-2.0.txt").write_text("Apache License placeholder\n")
        # MIT.txt and BSD-3-Clause.txt are absent — assembly must fail.
        result = _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=artifacts["model_sha256"],
            extra_args=["--licenses-dir", str(incomplete_licenses)],
            expect_exit=1,
        )
        combined = result.stdout + result.stderr
        assert "MIT" in combined or "license" in combined.lower(), (
            f"Expected missing license error; got:\n{combined}"
        )


# ── Test 19: Strict verification rejects unauthenticated metadata ─────────────


class TestStrictVerificationRejectsUnauthenticatedMetadata:
    """Test 19: In strict mode, verify-bundle.sh must reject a bundle where
    metadata files (manifest.json, sbom.spdx.json, provenance.json) are not
    listed in manifest.sha256.
    """

    @pytest.fixture(autouse=True)
    def setup(self, tmp_path, artifacts):
        self.tmp = tmp_path
        # Assemble and extract a normal bundle.
        dist = tmp_path / "dist"
        _run_assemble(
            tmp=tmp_path,
            arch=artifacts["arch"],
            version=artifacts["version"],
            kind="complete",
            node_archive=artifacts["node_archive"],
            coord_archive=artifacts["coord_archive"],
            llama_server=artifacts["llama_server"],
            model=artifacts["model"],
            model_sha256=artifacts["model_sha256"],
            dist_dir=dist,
        )
        bundle_name = f"exocomp-complete-{artifacts['version']}-linux-{artifacts['arch']}"
        archive = dist / f"{bundle_name}.tar.gz"
        extract_dir = tmp_path / "extracted"
        extract_dir.mkdir()
        self.bundle_dir = _extract_bundle(archive, extract_dir)

    def test_metadata_in_manifest_non_strict_passes(self):
        """A correctly assembled bundle has metadata in manifest.sha256; non-strict passes."""
        manifest_text = (self.bundle_dir / "manifest.sha256").read_text()
        for meta in ("manifest.json", "sbom.spdx.json", "provenance.json"):
            assert meta in manifest_text, f"{meta} must be in manifest.sha256 after assembly"
        # non-strict verification does not require a signature
        _run_verify(bundle_dir=self.bundle_dir, strict=False, expect_exit=0)

    def test_strict_fails_when_manifest_json_removed_from_manifest(self):
        """Removing manifest.json's entry from manifest.sha256 and then tampering
        the file must be detectable: the strict verifier rejects uncovered metadata.
        """
        manifest_path = self.bundle_dir / "manifest.sha256"
        lines = manifest_path.read_text().splitlines(keepends=True)
        # Strip the manifest.json entry to simulate an old-style bundle.
        stripped = [l for l in lines if "manifest.json" not in l]
        manifest_path.write_text("".join(stripped))

        # Strict mode must reject because manifest.json is not covered.
        result = _run_verify(bundle_dir=self.bundle_dir, strict=True, expect_exit=1)
        combined = result.stdout + result.stderr
        assert "manifest.json" in combined or "metadata" in combined.lower(), (
            f"Expected manifest.json coverage error; got:\n{combined}"
        )

    def test_strict_fails_when_licenses_dir_empty(self):
        """Strict mode must fail when the LICENSES directory is empty."""
        licenses_dir = self.bundle_dir / "LICENSES"
        # Remove all license files to simulate an old empty-LICENSES bundle.
        for f in list(licenses_dir.iterdir()):
            f.unlink()
        result = _run_verify(bundle_dir=self.bundle_dir, strict=True, expect_exit=1)
        combined = result.stdout + result.stderr
        assert "license" in combined.lower() or "LICENSES" in combined, (
            f"Expected LICENSES error; got:\n{combined}"
        )

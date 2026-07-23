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
    stub.write_text("#!/bin/sh\necho stub\n")
    stub.chmod(0o755)

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
    """Create a stub llama-server binary."""
    p = dest_dir / "llama-server-stub"
    p.write_bytes(b"#!/bin/sh\necho llama-server-stub\n")
    p.chmod(0o755)
    return p


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
    llama_server: Path | None = None,
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
    if llama_server:
        cmd += ["--llama-server", str(llama_server)]
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

    def test_provenance_present(self):
        assert (self.bundle_dir / "provenance.json").exists()

    def test_install_sh_present(self):
        assert (self.bundle_dir / "scripts" / "install.sh").exists()

    def test_uninstall_sh_present(self):
        assert (self.bundle_dir / "scripts" / "uninstall.sh").exists()

    def test_verify_bundle_sh_present(self):
        assert (self.bundle_dir / "scripts" / "verify-bundle.sh").exists()

    def test_llama_server_present(self):
        assert (self.bundle_dir / "llama-server").exists()

    def test_llama_server_is_executable(self):
        ls = self.bundle_dir / "llama-server"
        assert ls.stat().st_mode & stat.S_IXUSR, "llama-server must be executable"

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

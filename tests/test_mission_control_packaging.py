# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Offline tests for the Mission Control OCI packaging contract."""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
CONTAINERFILE = REPO_ROOT / "release" / "mission_control" / "Containerfile"
ENTRYPOINT = REPO_ROOT / "release" / "mission_control" / "entrypoint.sh"
PACKAGER = REPO_ROOT / "scripts" / "package-mission-control.sh"
PACKAGER_PYTHON = REPO_ROOT / "scripts" / "package_mission_control.py"
IMAGE_BUILDER = (
    "docker.io/hexpm/elixir:1.20.2-erlang-28.5.0.3-debian-bookworm-20260713-slim@sha256:"
    + "b" * 64
)
IMAGE_DIGEST = "sha256:" + "c" * 64


class MissionControlPackagingTest(unittest.TestCase):
    def run_packager(self, output: Path, lock: Path | None = None) -> None:
        command = [
            str(PACKAGER),
            "--image-ref",
            "registry.example.invalid/exocomp/mission-control:1.2.3-amd64",
            "--image-digest",
            IMAGE_DIGEST,
            "--version",
            "1.2.3",
            "--arch",
            "amd64",
            "--source-commit",
            "a" * 40,
            "--source-epoch",
            "1700000000",
            "--builder-image",
            IMAGE_BUILDER,
            "--output-dir",
            str(output),
            "--build-command",
            "scripts/build-mission-control-image.sh amd64",
        ]
        if lock is not None:
            command.extend(["--dependency-lock", str(lock)])
        subprocess.run(command, cwd=REPO_ROOT, check=True, capture_output=True, text=True)

    def test_packager_emits_required_supply_chain_artifacts(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / "metadata"
            self.run_packager(output)
            self.assertEqual(len(list(output.glob("*.manifest.json"))), 1)
            self.assertEqual(len(list(output.glob("*.sha256"))), 1)
            self.assertEqual(len(list(output.glob("*.sbom.spdx.json"))), 1)
            self.assertEqual(len(list(output.glob("*.provenance.json"))), 1)
            self.assertEqual(len(list(output.glob("*.licenses.json"))), 1)

            manifest = json.loads(next(output.glob("*.manifest.json")).read_text())
            self.assertEqual(manifest["artifact"]["type"], "oci-image")
            self.assertEqual(manifest["artifact"]["digest"], IMAGE_DIGEST)
            self.assertTrue(manifest["runtime"]["read_only_rootfs"])
            self.assertEqual(manifest["runtime"]["user"], "10001:10001")
            self.assertEqual(
                manifest["runtime"]["commands"]["migrate"].split()[0],
                "bin/mission_control",
            )

            checksum_file = next(output.glob("*.sha256"))
            for line in checksum_file.read_text().splitlines():
                digest, filename = line.split("  ", 1)
                self.assertEqual(
                    digest, hashlib.sha256((output / filename).read_bytes()).hexdigest()
                )

            licenses = json.loads(next(output.glob("*.licenses.json")).read_text())
            self.assertEqual(licenses["uncovered_dependencies"], [])
            self.assertIn("LICENSE", licenses["required_notice_files"])

    def test_metadata_is_reproducible_for_identical_inputs(self):
        with tempfile.TemporaryDirectory() as temp:
            first = Path(temp) / "first"
            second = Path(temp) / "second"
            self.run_packager(first)
            self.run_packager(second)
            self.assertEqual(
                {path.name: path.read_bytes() for path in first.iterdir()},
                {path.name: path.read_bytes() for path in second.iterdir()},
            )

    def test_packager_rejects_uncovered_dependency(self):
        with tempfile.TemporaryDirectory() as temp:
            lock = Path(temp) / "mix.lock"
            lock.write_text(
                '%{\n  "not_in_registry": {:hex, :not_in_registry, "1.0.0", ""}\n}\n'
            )
            result = subprocess.run(
                [
                    sys.executable,
                    str(PACKAGER_PYTHON),
                    "--image-ref",
                    "example.invalid/mission-control:dev",
                    "--image-digest",
                    IMAGE_DIGEST,
                    "--version",
                    "dev",
                    "--arch",
                    "amd64",
                    "--source-commit",
                    "a" * 40,
                    "--source-epoch",
                    "1700000000",
                    "--builder-image",
                    IMAGE_BUILDER,
                    "--containerfile",
                    str(CONTAINERFILE),
                    "--dependency-lock",
                    str(lock),
                    "--license-registry",
                    str(REPO_ROOT / "licenses" / "components.toml"),
                    "--output-dir",
                    str(Path(temp) / "out"),
                    "--build-command",
                    "test",
                ],
                cwd=REPO_ROOT,
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("license registry", result.stderr)

    def test_containerfile_has_pinned_multistage_runtime_boundary(self):
        content = CONTAINERFILE.read_text()
        builder, runtime = content.split("FROM ${TARGET_IMAGE}", 1)
        self.assertIn("FROM ${BUILDER_IMAGE} AS builder", builder)
        self.assertIn("COPY . .", builder)
        self.assertNotIn("COPY . .", runtime)
        self.assertIn("COPY --from=builder", runtime)
        self.assertIn("COPY LICENSE NOTICE THIRD_PARTY_NOTICES.md", runtime)
        self.assertIn("USER 10001:10001", runtime)
        self.assertIn('VOLUME ["/var/lib/exocomp/mission-control"', runtime)
        self.assertIn("--read-only", content)
        self.assertNotIn("latest", content.lower())
        self.assertNotIn("test/fixtures", runtime)

    def test_entrypoint_has_explicit_commands_and_rejects_missing_secrets(self):
        subprocess.run(["sh", "-n", str(ENTRYPOINT)], check=True)
        with tempfile.TemporaryDirectory() as temp:
            release = Path(temp) / "release"
            (release / "bin").mkdir(parents=True)
            invoked = Path(temp) / "invoked"
            (release / "bin" / "mission_control").write_text(
                f"#!/bin/sh\nprintf '%s\\n' \"$*\" > '{invoked}'\n"
            )
            (release / "bin" / "mission_control").chmod(0o755)
            missing = subprocess.run(
                [str(ENTRYPOINT), "server"],
                env={"MISSION_CONTROL_RELEASE_DIR": str(release)},
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(missing.returncode, 0)
            self.assertIn("DATABASE_URL", missing.stderr)
            self.assertNotIn("SECRET_SENTINEL", missing.stderr)

            environment = os.environ.copy()
            environment.update(
                {
                    "MISSION_CONTROL_RELEASE_DIR": str(release),
                    "DATABASE_URL": "ecto://example.invalid/db",
                    "SECRET_KEY_BASE": "SECRET_SENTINEL",
                    "RELEASE_COOKIE": "cookie",
                }
            )
            subprocess.run([str(ENTRYPOINT), "migrate"], env=environment, check=True)
            self.assertEqual(
                invoked.read_text().strip(),
                "eval Exocomp.MissionControl.Release.migrate()",
            )

    def test_build_and_integration_scripts_require_explicit_pinned_inputs(self):
        build_script = (REPO_ROOT / "scripts" / "build-mission-control-image.sh").read_text()
        integration_script = (REPO_ROOT / "scripts" / "test-mission-control-image.sh").read_text()
        self.assertIn("--pull=never", build_script)
        self.assertIn("BUILDER_AMD64_DIGEST", build_script)
        self.assertIn("CLEAN_TARGET_AMD64_DIGEST", build_script)
        self.assertIn("POSTGRES_IMAGE must include a complete", integration_script)
        self.assertIn("--read-only", integration_script)
        self.assertIn("migrate", integration_script)
        self.assertIn("restart", integration_script)


if __name__ == "__main__":
    unittest.main()

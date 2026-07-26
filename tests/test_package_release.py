# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Tests for deterministic OTP release archive packaging."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
PACKAGER = REPO_ROOT / "scripts" / "package_release.py"
NORMALIZER = REPO_ROOT / "scripts" / "prepare-release-deps.sh"
PACKAGE_RELEASES = REPO_ROOT / "scripts" / "package-releases.sh"
BUILDERS_LOCK = REPO_ROOT / "release" / "builders.lock"


class PackageReleaseTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.release = self.root / "release"
        (self.release / "bin").mkdir(parents=True)
        (self.release / "erts-28.5.0").mkdir()
        (self.release / "lib" / "example-1.0").mkdir(parents=True)
        (self.release / "releases").mkdir()
        (self.release / "bin" / "exocomp_node").write_text("#!/bin/sh\nexit 0\n")
        (self.release / "bin" / "exocomp_node").chmod(0o755)
        (self.release / "erts-28.5.0" / "beam.smp").write_bytes(b"\x7fELFfake")
        (self.release / "lib" / "example-1.0" / "example.beam").write_bytes(b"BEAM")
        (self.release / "releases" / "COOKIE").write_text("do-not-publish-this-cookie")
        self.lock = self.root / "mix.lock"
        self.lock.write_text("%{}\n")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def package(self, output: Path, product: str = "exocomp_node", arch: str = "amd64"):
        subprocess.run(
            [
                sys.executable,
                str(PACKAGER),
                "--release-dir",
                str(self.release),
                "--product",
                product,
                "--version",
                "1.2.3",
                "--arch",
                arch,
                "--output-dir",
                str(output),
                "--source-commit",
                "a" * 40,
                "--source-tag",
                "v1.2.3",
                "--source-epoch",
                "1700000000",
                "--builder-digest",
                "sha256:" + "b" * 64,
                "--elixir-version",
                "1.20.2",
                "--otp-version",
                "28.5.0.3",
                "--dependency-lock",
                str(self.lock),
                "--release-input-normalizer",
                str(NORMALIZER),
                "--build-command",
                f"make build-{arch}",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        slug = product.replace("_", "-")
        base = f"{slug}-1.2.3-linux-{arch}"
        return output / f"{base}.tar.gz", output / f"{base}.manifest.json"

    def test_equivalent_inputs_produce_byte_identical_archives(self):
        archive1, _ = self.package(self.root / "out1")
        self.assertEqual(
            (self.release / "releases" / "COOKIE").read_text(),
            "do-not-publish-this-cookie",
        )
        (self.release / "releases" / "COOKIE").write_text("a-different-build-cookie")
        for path in self.release.rglob("*"):
            os.utime(path, (1800000000, 1800000000), follow_symlinks=False)
        archive2, _ = self.package(self.root / "out2")

        self.assertEqual(archive1.read_bytes(), archive2.read_bytes())
        self.assertEqual(
            (self.release / "releases" / "COOKIE").read_text(),
            "a-different-build-cookie",
        )

    def test_archive_omits_cookie_and_embeds_identity(self):
        archive, _ = self.package(self.root / "out")

        self.assertNotIn(b"do-not-publish-this-cookie", archive.read_bytes())
        with tarfile.open(archive, "r:gz") as packaged:
            names = packaged.getnames()
            self.assertFalse(any(name.endswith("releases/COOKIE") for name in names))
            self.assertTrue(any(name.endswith("erts-28.5.0") for name in names))
            identity_name = next(name for name in names if name.endswith("build-identity.json"))
            identity = json.load(packaged.extractfile(identity_name))

        self.assertFalse(identity["cookie_policy"]["embedded"])
        self.assertEqual(
            identity["cookie_policy"]["provisioning"],
            "installer-generated RELEASE_COOKIE",
        )

    def test_manifest_records_identity_archive_hash_and_complete_payload(self):
        archive, manifest_path = self.package(self.root / "out")
        manifest = json.loads(manifest_path.read_text())

        self.assertEqual(manifest["artifact"]["filename"], archive.name)
        self.assertEqual(len(manifest["artifact"]["sha256"]), 64)
        self.assertEqual(manifest["identity"]["source_tag"], "v1.2.3")
        self.assertEqual(manifest["identity"]["erts_version"], "28.5.0")
        self.assertEqual(manifest["identity"]["architecture"], "amd64")
        self.assertEqual(manifest["identity"]["build_command"], "make build-amd64")
        self.assertEqual(
            len(manifest["identity"]["release_input_normalizer_sha256"]), 64
        )
        paths = {item["path"] for item in manifest["file_inventory"]}
        self.assertIn("bin/exocomp_node", paths)
        self.assertIn("erts-28.5.0", paths)
        self.assertIn("erts-28.5.0/beam.smp", paths)
        self.assertIn("build-identity.json", paths)
        self.assertNotIn("releases/COOKIE", paths)

    def test_archive_metadata_is_normalized_to_source_epoch(self):
        archive, _ = self.package(self.root / "out")
        with tarfile.open(archive, "r:gz") as packaged:
            for member in packaged.getmembers():
                self.assertEqual(member.mtime, 1700000000)
                self.assertEqual(member.uid, 0)
                self.assertEqual(member.gid, 0)
                self.assertEqual(member.uname, "root")
                self.assertEqual(member.gname, "root")

    def test_product_and_architecture_naming_matrix(self):
        expected = set()
        for product in ("exocomp_node", "exocomp_coordinator"):
            for arch in ("amd64", "arm64"):
                archive, manifest = self.package(
                    self.root / f"{product}-{arch}", product=product, arch=arch
                )
                expected.add(archive.name)
                self.assertTrue(manifest.exists())

        self.assertEqual(
            expected,
            {
                "exocomp-node-1.2.3-linux-amd64.tar.gz",
                "exocomp-node-1.2.3-linux-arm64.tar.gz",
                "exocomp-coordinator-1.2.3-linux-amd64.tar.gz",
                "exocomp-coordinator-1.2.3-linux-arm64.tar.gz",
            },
        )


class PackageReleasesScriptTest(unittest.TestCase):
    def test_annotated_tag_uses_peeled_commit_timestamp(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            scripts = root / "scripts"
            release = root / "release"
            scripts.mkdir()
            release.mkdir()
            shutil.copy2(PACKAGE_RELEASES, scripts / "package-releases.sh")
            shutil.copy2(BUILDERS_LOCK, release / "builders.lock")
            (scripts / "prepare-release-deps.sh").write_text("#!/bin/sh\n")
            (scripts / "prepare-release-deps.sh").chmod(0o755)
            (root / "mix.exs").write_text('def project, do: [version: "0.1.0",]\n')
            (root / "mix.lock").write_text("%{}\n")
            for product in ("exocomp_node", "exocomp_coordinator"):
                (root / "_build" / "release" / "amd64" / "rel" / product).mkdir(
                    parents=True
                )

            capture = root / "source-epochs"
            (scripts / "package_release.py").write_text(
                """#!/usr/bin/env python3
import pathlib
import sys

value = sys.argv[sys.argv.index("--source-epoch") + 1]
if not value.isdigit():
    raise SystemExit(f"source epoch is not an integer: {value!r}")
with pathlib.Path("source-epochs").open("a") as output:
    output.write(value + "\\n")
"""
            )
            (scripts / "package_release.py").chmod(0o755)

            def git(*args: str) -> subprocess.CompletedProcess[str]:
                return subprocess.run(
                    ["git", *args],
                    cwd=root,
                    check=True,
                    capture_output=True,
                    text=True,
                )

            git("init", "-q")
            git("config", "user.name", "Release Test")
            git("config", "user.email", "release-test@example.invalid")
            git("add", ".")
            git("commit", "-qm", "fixture")
            git("tag", "-a", "v0.1.0-rc.1", "-m", "annotated candidate")
            expected_epoch = git("show", "-s", "--format=%ct", "HEAD").stdout.strip()

            subprocess.run(
                [str(scripts / "package-releases.sh"), "amd64"],
                cwd=root,
                check=True,
                capture_output=True,
                text=True,
            )

            self.assertEqual(capture.read_text().splitlines(), [expected_epoch] * 2)


if __name__ == "__main__":
    unittest.main()

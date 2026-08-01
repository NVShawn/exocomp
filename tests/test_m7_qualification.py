#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Tests for the fail-closed M7 qualification evidence contract."""

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
SCRIPTS = REPO_ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS))

import finalize_m7_evidence  # noqa: E402
import m7_qualification  # noqa: E402


COMMIT = "a" * 40
TAG = "v0.1.0-rc.99"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class M7QualificationInputTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.model = self.root / "model.gguf"
        self.model.write_bytes(b"verified model")
        self.redacted_config = self.root / "redacted-config.json"
        self.redacted_config.write_text(
            json.dumps({"database_url": "[REDACTED]", "oidc": {"issuer": "https://idp.example.invalid"}})
        )
        self.node_archive = self.root / "node.tar.gz"
        self.node_archive.write_bytes(b"node artifact")
        self.coordinator_archive = self.root / "coordinator.tar.gz"
        self.coordinator_archive.write_bytes(b"coordinator artifact")
        self.node_manifest = self.root / "node.manifest.json"
        self.coordinator_manifest = self.root / "coordinator.manifest.json"
        self.mission_control_manifest = self.root / "mission-control.manifest.json"
        self.write_release_manifest(self.node_manifest, self.node_archive, "exocomp_node")
        self.write_release_manifest(
            self.coordinator_manifest, self.coordinator_archive, "exocomp_coordinator"
        )
        self.mission_control_manifest.write_text(
            json.dumps(
                {
                    "artifact": {
                        "type": "oci-image",
                        "architecture": "amd64",
                        "digest": "sha256:" + "b" * 64,
                    },
                    "identity": {"source_commit": COMMIT},
                }
            )
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write_release_manifest(self, path: Path, archive: Path, product: str) -> None:
        path.write_text(
            json.dumps(
                {
                    "artifact": {"sha256": sha256(archive)},
                    "identity": {
                        "product": product,
                        "architecture": "amd64",
                        "source_tag": TAG,
                        "source_commit": COMMIT,
                    },
                }
            )
        )

    def arguments(self) -> list[str]:
        return [
            "verify-inputs",
            "--architecture",
            "amd64",
            "--candidate-tag",
            TAG,
            "--candidate-commit",
            COMMIT,
            "--operator",
            "qualification@example.invalid",
            "--node-archive",
            str(self.node_archive),
            "--node-manifest",
            str(self.node_manifest),
            "--coordinator-archive",
            str(self.coordinator_archive),
            "--coordinator-manifest",
            str(self.coordinator_manifest),
            "--mission-control-image",
            "registry.example.invalid/exocomp/mission-control@sha256:" + "b" * 64,
            "--mission-control-manifest",
            str(self.mission_control_manifest),
            "--postgres-image",
            "registry.example.invalid/postgres@sha256:" + "c" * 64,
            "--model-path",
            str(self.model),
            "--model-sha256",
            sha256(self.model),
            "--mission-control-service-url",
            "https://mission-control.example.invalid",
            "--redacted-config",
            str(self.redacted_config),
            "--output",
            str(self.root / "identity.json"),
        ]

    def test_verifies_matching_frozen_artifacts_and_model(self) -> None:
        args = m7_qualification.parser().parse_args(self.arguments())
        m7_qualification.verify_inputs(args)

        identity = json.loads((self.root / "identity.json").read_text())
        self.assertEqual(identity["candidate"], {"tag": TAG, "commit": COMMIT})
        self.assertEqual(identity["artifacts"]["node"]["sha256"], sha256(self.node_archive))
        self.assertEqual(identity["artifacts"]["mission_control"]["digest"], "sha256:" + "b" * 64)
        self.assertEqual(identity["configuration"]["redacted_config_sha256"], sha256(self.redacted_config))

    def test_rejects_an_archive_that_does_not_match_its_manifest(self) -> None:
        self.node_archive.write_bytes(b"tampered node artifact")
        args = m7_qualification.parser().parse_args(self.arguments())

        with self.assertRaisesRegex(ValueError, "sha256 does not match"):
            m7_qualification.verify_inputs(args)

    def test_rejects_mission_control_digest_or_architecture_mismatch(self) -> None:
        manifest = json.loads(self.mission_control_manifest.read_text())
        manifest["artifact"]["architecture"] = "arm64"
        self.mission_control_manifest.write_text(json.dumps(manifest))
        args = m7_qualification.parser().parse_args(self.arguments())

        with self.assertRaisesRegex(ValueError, "architecture does not match"):
            m7_qualification.verify_inputs(args)

    def test_rejects_an_unredacted_secret_in_effective_configuration(self) -> None:
        self.redacted_config.write_text(json.dumps({"database_url": "ecto://leaked.example.invalid/db"}))
        args = m7_qualification.parser().parse_args(self.arguments())

        with self.assertRaisesRegex(ValueError, "exposes sensitive value"):
            m7_qualification.verify_inputs(args)


class M7EvidenceResultTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.evidence = self.root / "raw" / "amd64"
        for relative in (
            "candidate/tag-verification.txt",
            "host/guest-runtime.txt",
            "artifacts/identity.json",
        ):
            path = self.evidence / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("evidence")
        (self.evidence / "artifacts" / "identity.json").write_text(
            json.dumps({"candidate": {"tag": TAG, "commit": COMMIT}})
        )
        for relative in {
            path for paths in m7_qualification.REQUIRED_EVIDENCE.values() for path in paths
        }:
            path = self.evidence / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps({"status": "pass"}))

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_writes_all_criteria_only_after_all_phase_evidence_passes(self) -> None:
        args = m7_qualification.parser().parse_args(
            [
                "write-result",
                "--evidence-dir",
                str(self.evidence),
                "--candidate-tag",
                TAG,
                "--candidate-commit",
                COMMIT,
                "--architecture",
                "amd64",
                "--operator",
                "qualification@example.invalid",
            ]
        )
        m7_qualification.write_result(args)

        result = json.loads((self.evidence / "qualification-result.json").read_text())
        self.assertEqual(result["decision"], "pass")
        self.assertEqual(set(result["criteria"]), set(m7_qualification.CRITERIA))

    def test_rejects_a_non_passing_phase_status(self) -> None:
        path = self.evidence / "security/security.json"
        path.write_text(json.dumps({"status": "fail"}))
        args = m7_qualification.parser().parse_args(
            [
                "write-result",
                "--evidence-dir",
                str(self.evidence),
                "--candidate-tag",
                TAG,
                "--candidate-commit",
                COMMIT,
                "--architecture",
                "amd64",
                "--operator",
                "qualification@example.invalid",
            ]
        )

        with self.assertRaisesRegex(ValueError, "did not pass"):
            m7_qualification.write_result(args)


class M7EvidenceFinalizationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        for architecture in m7_qualification.ARCHITECTURES:
            evidence_file = self.root / "raw" / architecture / "candidate" / "identity.txt"
            evidence_file.parent.mkdir(parents=True, exist_ok=True)
            evidence_file.write_text(f"{architecture} evidence")
            result = {
                "architecture": architecture,
                "decision": "pass",
                "tag_signature_verified": True,
                "candidate": {"tag": TAG, "commit": COMMIT},
                "operator": "qualification@example.invalid",
                "criteria": {
                    criterion: {"status": "pass"} for criterion in m7_qualification.CRITERIA
                },
                "required_evidence": ["candidate/identity.txt"],
            }
            (self.root / "raw" / architecture / "qualification-result.json").write_text(
                json.dumps(result)
            )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_requires_symmetric_passing_results_and_indexes_all_files(self) -> None:
        result = finalize_m7_evidence.validate_evidence_root(self.root)
        self.assertEqual(result["decision"], "pass")
        self.assertEqual(set(result["criteria"]), set(m7_qualification.CRITERIA))
        index = finalize_m7_evidence.write_index(self.root)
        indexed = index.read_text()
        self.assertIn("./raw/amd64/qualification-result.json", indexed)
        self.assertIn("./raw/arm64/qualification-result.json", indexed)

    def test_rejects_mismatched_architecture_candidates(self) -> None:
        path = self.root / "raw" / "arm64" / "qualification-result.json"
        value = json.loads(path.read_text())
        value["candidate"]["commit"] = "b" * 40
        path.write_text(json.dumps(value))

        with self.assertRaisesRegex(ValueError, "same signed candidate"):
            finalize_m7_evidence.validate_evidence_root(self.root)

    def test_refuses_to_index_a_symbolic_link(self) -> None:
        target = self.root / "raw" / "amd64" / "candidate" / "identity.txt"
        link = self.root / "raw" / "arm64" / "candidate" / "unsafe-link.txt"
        link.symlink_to(target)

        with self.assertRaisesRegex(ValueError, "symbolic links"):
            finalize_m7_evidence.write_index(self.root)

    def test_failed_signing_removes_only_the_new_partial_result_and_index(self) -> None:
        (self.root / "allowed-signers").write_text("qualification@example.invalid ssh-ed25519 AAAA\n")
        fake_bin = self.root / "bin"
        fake_bin.mkdir()
        signer = fake_bin / "ssh-keygen"
        signer.write_text("#!/bin/sh\nexit 1\n")
        signer.chmod(0o755)
        environment = os.environ | {
            "M7_EVIDENCE_ROOT": str(self.root),
            "M7_EVIDENCE_SIGNING_KEY": str(self.root / "qualification.key"),
            "M7_QUALIFICATION_SIGNER": "qualification@example.invalid",
            "PATH": f"{fake_bin}{os.pathsep}{os.environ['PATH']}",
        }

        completed = subprocess.run(
            [sys.executable, str(SCRIPTS / "finalize_m7_evidence.py")],
            env=environment,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("finalization failed", completed.stderr)
        for name in ("qualification-results.json", "evidence-index.sha256", "evidence-index.sha256.sig"):
            self.assertFalse((self.root / name).exists(), name)


class M7MakeContractTest(unittest.TestCase):
    def test_make_target_requires_explicit_frozen_inputs_and_finalizer(self) -> None:
        makefile = (REPO_ROOT / "Makefile").read_text(encoding="utf-8")
        for fragment in (
            "test-m7-qualification-contract",
            "test-m7-qualification: test-m7-qualification-contract",
            "M7_CANDIDATE_TAG",
            "M7_MISSION_CONTROL_IMAGE",
            "finalize-m7-evidence",
        ):
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, makefile)

    def test_live_wrapper_refuses_missing_targets_and_never_uses_latest_images(self) -> None:
        wrapper = (SCRIPTS / "test-m7-qualification.sh").read_text(encoding="utf-8")
        for fragment in (
            "git -C \"${repo_root}\" verify-tag",
            "refusing to reuse M7_EVIDENCE_DIR",
            "test-mission-control-scenario",
            "mc-scale-full",
            "test-mission-control-lifecycle",
            "M7 qualification requires a full systemd guest",
        ):
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, wrapper)
        self.assertNotIn(":latest", wrapper)


if __name__ == "__main__":
    unittest.main()

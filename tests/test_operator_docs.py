# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Command and coverage checks for the operator documentation."""

from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = {
    "installation": ROOT / "docs" / "installation.md",
    "pki": ROOT / "docs" / "pki-operations.md",
    "policy": ROOT / "docs" / "policy-operations.md",
    "lifecycle": ROOT / "docs" / "lifecycle.md",
    "qualification": ROOT / "docs" / "clean-host-qualification.md",
    "mission_control": ROOT / "docs" / "mission-control.md",
    "service_management": ROOT / "docs" / "service-management.md",
}


class OperatorDocumentationTest(unittest.TestCase):
    def test_required_guides_are_linked_from_index(self):
        index = (ROOT / "docs" / "README.md").read_text()
        for path in DOCS.values():
            self.assertTrue(path.is_file())
            self.assertIn(f"({path.name})", index)

    def test_guides_cover_required_safety_and_lifecycle_topics(self):
        text = "\n".join(path.read_text().lower() for path in DOCS.values())
        required = (
            "amd64",
            "arm64",
            "offline",
            "root fingerprint",
            "enrollment",
            "renewal",
            "revocation",
            "rotation",
            "inventory",
            "diagnostics",
            "allow-list",
            "sudoers",
            "approval",
            "data classification",
            "user data",
            "audit",
            "retention",
            "upgrade",
            "rollback",
            "backup",
            "restore",
            "removal",
            "oidc",
            "webhook",
            "postgresql",
            "kubernetes",
            "ceph",
            "monitoring",
        )
        for topic in required:
            self.assertIn(topic, text, f"operator guides do not cover {topic!r}")
        self.assertRegex(text, r"unknown\s+paths")
        self.assertIn("never", text)

    def test_all_shell_command_blocks_parse(self):
        for name, path in DOCS.items():
            blocks = re.findall(r"```sh\n(.*?)```", path.read_text(), re.DOTALL)
            self.assertTrue(blocks, f"{name} guide has no validated shell commands")
            for index, block in enumerate(blocks, start=1):
                result = subprocess.run(
                    ["bash", "-n"],
                    input=block,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(
                    result.returncode,
                    0,
                    f"{path.name} shell block {index} is invalid:\n{result.stderr}",
                )

    def test_documented_lifecycle_flags_exist_in_shipped_scripts(self):
        install = (ROOT / "scripts" / "install.sh").read_text()
        uninstall = (ROOT / "scripts" / "uninstall.sh").read_text()
        backup = (ROOT / "scripts" / "state-backup.sh").read_text()
        verify = (ROOT / "scripts" / "verify-bundle.sh").read_text()

        for flag in ("--component", "--bundle", "--checksums", "--version", "--allow-list"):
            self.assertIn(flag, install)
        for flag in ("--component", "--purge", "--dry-run", "--non-interactive"):
            self.assertIn(flag, uninstall)
        for token in ("create", "restore", "--component", "--output", "--archive"):
            self.assertIn(token, backup)
        self.assertIn("--bundle-dir", verify)

    def test_install_commands_match_the_delivered_bundle_layout(self):
        installation = DOCS["installation"].read_text()
        lifecycle = DOCS["lifecycle"].read_text()

        for token in (
            "exocomp-complete-0.1.0-linux-amd64.tar.gz.sha256",
            "cd exocomp-complete-0.1.0-linux-amd64",
            "./releases/exocomp-coordinator-0.1.0-linux-amd64.tar.gz",
            "./releases/exocomp-node-0.1.0-linux-amd64.tar.gz",
            "--checksums ./manifest.sha256",
        ):
            self.assertIn(token, installation)
        self.assertNotIn("checksums.sha256", installation)
        self.assertIn(
            "/opt/exocomp/node/current/bin/exocomp-state-backup",
            lifecycle,
        )
        self.assertNotIn("checksums.sha256", lifecycle)

    def test_pki_ceremony_uses_installed_working_directory_and_cookie(self):
        pki = DOCS["pki"].read_text()

        self.assertIn("cd /opt/exocomp/coordinator", pki)
        self.assertIn(". ./config/release-cookie.env", pki)
        self.assertIn(
            'exec ./current/bin/exocomp_coordinator eval "$1"',
            pki,
        )

    def test_qualification_accepts_full_system_vms_and_discloses_emulation(self):
        qualification = " ".join(DOCS["qualification"].read_text().lower().split())

        for phrase in (
            "bare metal is not required",
            "full-system virtual machines",
            "uname -m",
            "cpu emulation",
            "performance-only failure under emulation is inconclusive",
        ):
            self.assertIn(phrase, qualification)

    def test_mission_control_guide_matches_the_shipped_image_contract(self):
        guide = DOCS["mission_control"].read_text()
        entrypoint = (ROOT / "release" / "mission_control" / "entrypoint.sh").read_text()
        containerfile = (ROOT / "release" / "mission_control" / "Containerfile").read_text()

        for command in ("migrate", "server", "healthcheck"):
            self.assertIn(command, entrypoint)
            self.assertIn(command, guide)
        for variable in ("DATABASE_URL", "SECRET_KEY_BASE", "RELEASE_COOKIE"):
            self.assertIn(variable, entrypoint)
            self.assertIn(variable, guide)
        for path in (
            "/var/lib/exocomp/mission-control",
            "/var/log/exocomp/mission-control",
        ):
            self.assertIn(path, containerfile)
            self.assertIn(path, guide)
        for endpoint in ("/health/live", "/health/ready", "/metrics"):
            self.assertIn(endpoint, guide)

    def test_mission_control_guide_is_source_tree_independent(self):
        guide = DOCS["mission_control"].read_text()

        self.assertIn("not require a source checkout", guide)
        self.assertNotIn("./scripts/", guide)
        self.assertNotIn("make build-mission-control", guide)
        self.assertIn("immutable Mission Control image reference", guide)

    def test_mission_control_kubernetes_example_preserves_runtime_boundaries(self):
        guide = DOCS["mission_control"].read_text()
        manifests = re.findall(r"```yaml\n(.*?)```", guide, re.DOTALL)

        self.assertEqual(len(manifests), 2)
        migration, workload = manifests
        for manifest in manifests:
            self.assertNotIn("\t", manifest)
            for document in manifest.split("\n---\n"):
                self.assertRegex(document, r"(?m)^apiVersion: \S+$")
                self.assertRegex(document, r"(?m)^kind: \S+$")

        for token in (
            "kind: PersistentVolumeClaim",
            "kind: Job",
            'args: ["migrate"]',
            "mission-control-state",
            "ReadWriteOnce",
        ):
            self.assertIn(token, migration)
        self.assertNotIn("kind: Deployment", migration)

        for token in (
            "kind: Deployment",
            "kind: Service",
            'args: ["server"]',
            "runAsNonRoot: true",
            "readOnlyRootFilesystem: true",
            "drop: [\"ALL\"]",
            "/usr/local/bin/mission-control-entrypoint",
            "- healthcheck",
            "/var/lib/exocomp/mission-control",
            "/var/log/exocomp/mission-control",
        ):
            self.assertIn(token, workload)
        self.assertNotIn("kind: Job", workload)
        self.assertNotIn("supplied-by-a-probe-secret", workload)

        self.assertLess(
            guide.index("kubectl apply -f /secure/input/mission-control-migrate.yaml"),
            guide.index("kubectl apply -f /secure/input/mission-control-workload.yaml"),
        )

    def test_mission_control_auth_and_webhook_examples_match_versioned_contracts(self):
        guide = DOCS["mission_control"].read_text()

        for variable in (
            "OIDC_PROVIDER_URL",
            "OIDC_CLIENT_ID",
            "OIDC_CLIENT_SECRET",
            "OIDC_REDIRECT_URI",
            "EXOCOMP_READINESS_TOKEN",
        ):
            self.assertIn(variable, guide)
        for header in (
            "X-Exocomp-Event-Id",
            "X-Exocomp-Delivery-Timestamp",
            "X-Exocomp-Event-Type",
            "X-Exocomp-Signature",
        ):
            self.assertIn(header, guide)
        for verifier_token in (
            'f"{event_id}.{timestamp}.".encode("utf-8") + body',
            "hmac.new(",
            "hmac.compare_digest(expected, signature)",
            "datetime.now(timezone.utc)",
        ):
            self.assertIn(verifier_token, guide)

    def test_mission_control_enrollment_walkthrough_keeps_invitation_off_command_line(self):
        guide = DOCS["mission_control"].read_text()

        for token in (
            "POST /api/v1/clusters/enroll",
            "ec_paramgen_curve:P-256",
            "extendedKeyUsage = clientAuth",
            '"invitation": invitation',
            '--data-binary "@$REQUEST_FILE"',
            "cleanup_enrollment_files",
            "cluster-chain.pem",
            "spiffe://exocomp/organizations/$ORGANIZATION_ID/clusters/$CLUSTER_ID",
        ):
            self.assertIn(token, guide)
        self.assertNotRegex(guide, r"curl[^\n]*(INVITATION|invitation)")

    def test_mission_control_restore_rotation_and_uninstall_are_reversible(self):
        guide = DOCS["mission_control"].read_text()

        for token in (
            "--no-owner --no-privileges",
            "mission_control_restore",
            "mission-control-restore-test",
            "mission-control-pre-restore",
            "mission-control-failed-restore",
            "old-token `401`",
            "kubectl -n \"$MC_NAMESPACE\" delete deployment mission-control",
            "kubectl -n \"$MC_NAMESPACE\" get pvc mission-control-state",
        ):
            self.assertIn(token, guide)
        self.assertIn("production is unchanged", guide)
        self.assertIn("matching image, state/schema compatibility, and whole secret revision", guide)

    def test_service_management_documents_all_monitoring_authority_boundaries(self):
        guide = DOCS["service_management"].read_text().lower()

        for phrase in (
            "inventory v2",
            "manual service list",
            "enabled-service discovery",
            "ceph profile",
            "client.exocomp",
            "coverage is degraded",
            "monitoring is not recovery",
            "fresh evidence",
            "approval flow",
        ):
            self.assertIn(phrase, guide)


if __name__ == "__main__":
    unittest.main()

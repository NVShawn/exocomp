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


if __name__ == "__main__":
    unittest.main()

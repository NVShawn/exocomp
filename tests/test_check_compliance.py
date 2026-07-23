# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Failure-path tests for the open-source compliance gate."""

from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPOSITORY_ROOT))

from scripts import check_compliance  # noqa: E402


class ComplianceChecksTest(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name) / "repository"
        shutil.copytree(
            REPOSITORY_ROOT,
            self.root,
            ignore=shutil.ignore_patterns(
                ".git",
                ".oompah-no-hooks",
                "__pycache__",
                "_build",
                "deps",
            ),
        )

    def tearDown(self):
        self.temporary_directory.cleanup()

    def findings(self, selection="all"):
        return check_compliance.run_checks(self.root, selection)

    def replace_manifest_component(self, component_id, old, new):
        path = self.root / "licenses/components.toml"
        text = path.read_text(encoding="utf-8")
        marker = f'id = "{component_id}"'
        start = text.index(marker)
        end = text.find("\n[[components]]", start)
        if end == -1:
            end = len(text)
        block = text[start:end]
        self.assertIn(old, block)
        path.write_text(
            text[:start] + block.replace(old, new, 1) + text[end:],
            encoding="utf-8",
        )

    def test_repository_passes_all_checks(self):
        self.assertEqual([], self.findings())

    def test_missing_governance_file_is_rejected(self):
        (self.root / "SECURITY.md").unlink()

        self.assertIn("missing required file: SECURITY.md", self.findings("files"))

    def test_modified_apache_license_is_rejected(self):
        license_path = self.root / "LICENSE"
        text = license_path.read_text(encoding="utf-8")
        license_path.write_text(
            text.replace("Apache License", "Altered License", 1),
            encoding="utf-8",
        )

        self.assertIn(
            "LICENSE is not the complete canonical Apache-2.0 text",
            self.findings("licenses"),
        )

    def test_missing_notice_inventory_entry_is_rejected(self):
        path = self.root / "licenses/components.toml"
        text = path.read_text(encoding="utf-8")
        start = text.index('[[components]]\nid = "llama-cpp"')
        end = text.index("\n[[components]]", start + 1)
        path.write_text(text[:start] + text[end + 1 :], encoding="utf-8")

        self.assertIn(
            "missing required notice inventory entry: llama-cpp",
            self.findings("licenses"),
        )

    def test_incompatible_license_is_rejected(self):
        self.replace_manifest_component(
            "llama-cpp", 'license = "MIT"', 'license = "GPL-3.0-only"'
        )

        self.assertIn(
            "llama-cpp: incompatible or unapproved license: GPL-3.0-only",
            self.findings("licenses"),
        )

    def test_missing_human_notice_is_rejected(self):
        notice = self.root / "THIRD_PARTY_NOTICES.md"
        text = notice.read_text(encoding="utf-8")
        notice.write_text(
            text.replace("### llama.cpp", "### Removed runtime", 1),
            encoding="utf-8",
        )

        self.assertTrue(
            any("llama-cpp: notice heading missing" in item for item in self.findings())
        )

    def test_uninventoried_locked_dependency_is_rejected(self):
        (self.root / "mix.lock").write_text(
            '%{"bandit": {:hex, :bandit, "1.0.0", "checksum", [], [], "hexpm"}}\n',
            encoding="utf-8",
        )

        self.assertIn(
            "mix.lock dependency missing from license inventory: bandit",
            self.findings("licenses"),
        )

    def test_broken_documentation_link_is_rejected(self):
        readme = self.root / "README.md"
        with readme.open("a", encoding="utf-8") as stream:
            stream.write("\n[Missing guide](docs/does-not-exist.md)\n")

        self.assertIn(
            "README.md: broken local link: docs/does-not-exist.md",
            self.findings("links"),
        )

    def test_missing_source_header_is_rejected(self):
        source = self.root / "lib/example.py"
        source.parent.mkdir()
        source.write_text("print('missing SPDX')\n", encoding="utf-8")

        self.assertIn(
            "missing Apache-2.0 SPDX header: lib/example.py",
            self.findings("headers"),
        )


if __name__ == "__main__":
    unittest.main()

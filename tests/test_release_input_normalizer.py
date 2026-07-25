# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Tests for fail-closed release dependency input normalization."""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NORMALIZER = ROOT / "scripts" / "prepare-release-deps.sh"
LOCK = (
    '%{\n  "bandit": {:hex, :bandit, "1.12.1", '
    '"ce002ed50689de7a7444340495d08ef44e883d211788691070d2ba71bba9f966", '
    "[:mix], [], \"hexpm\", \"fixture\"},\n}\n"
)
SOURCE = """defmodule Bandit do
  @thousand_island_keys ThousandIsland.ServerConfig.__struct__()
                        |> Map.from_struct()
                        |> Map.keys()
end
"""


class ReleaseInputNormalizerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        source = self.root / "deps" / "bandit" / "lib" / "bandit.ex"
        source.parent.mkdir(parents=True)
        source.write_text(SOURCE)
        (self.root / "mix.lock").write_text(LOCK)
        self.source = source

    def tearDown(self) -> None:
        self.temp.cleanup()

    def run_normalizer(self, *, check: bool = True) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["sh", str(NORMALIZER), str(self.root)],
            capture_output=True,
            text=True,
            check=check,
        )

    def test_adds_stable_sort_and_is_idempotent(self):
        self.run_normalizer()
        once = self.source.read_text()
        self.assertEqual(once.count("|> Enum.sort()"), 1)

        self.run_normalizer()
        self.assertEqual(self.source.read_text(), once)

    def test_changed_lock_identity_fails_closed_without_editing_source(self):
        (self.root / "mix.lock").write_text(LOCK.replace("1.12.1", "1.12.2"))
        result = self.run_normalizer(check=False)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("lock identity changed", result.stderr)
        self.assertEqual(self.source.read_text(), SOURCE)

    def test_changed_source_shape_fails_closed(self):
        self.source.write_text(SOURCE.replace("|> Map.keys()", "|> Map.values()"))
        result = self.run_normalizer(check=False)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected one exact", result.stderr)
        self.assertNotIn("|> Enum.sort()", self.source.read_text())


if __name__ == "__main__":
    unittest.main()

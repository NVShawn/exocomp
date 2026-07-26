# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Static qualification checks for the M5 operational surface."""

from __future__ import annotations

import re
import tomllib
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = REPO_ROOT / ".github" / "workflows" / "m5-harness.yml"
BASELINES = REPO_ROOT / "apps" / "bench" / "priv" / "bench" / "baselines"


class M5QualificationWorkflowTest(unittest.TestCase):
    def test_checked_in_baselines_pin_identity_and_both_hard_gates(self) -> None:
        paths = sorted(BASELINES.glob("v*/*.toml"))
        self.assertEqual(6, len(paths))

        expected_metrics = {
            "beam_cpu_percent": "beam.cpu.node_plus_coordinator.mean_percent",
            "beam_ram_percent": "beam.memory.node_plus_coordinator.peak_percent",
        }

        for path in paths:
            with self.subTest(path=path.relative_to(REPO_ROOT)):
                with path.open("rb") as baseline_file:
                    baseline = tomllib.load(baseline_file)

                architecture = path.stem
                version = path.parent.name.removeprefix("v")
                self.assertEqual(version, baseline["artifact_version"])
                self.assertEqual(architecture, baseline["architecture"])
                self.assertEqual(f"{architecture}-ci", baseline["host_profile"])

                gates = baseline["gates"]
                self.assertEqual(set(expected_metrics), set(gates))

                for name, metric in expected_metrics.items():
                    self.assertEqual(metric, gates[name]["metric"])
                    self.assertLessEqual(gates[name]["budget"], 5.0)
                    self.assertEqual("percent", gates[name]["unit"])
                    self.assertEqual("lower_is_better", gates[name]["direction"])

    def test_workflow_runs_the_real_short_gate_for_an_exact_candidate(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")

        required_fragments = (
            "workflow_dispatch:",
            "bundle_url:",
            "bundle_sha256:",
            "sha256sum --check",
            'bash "${bundle_root}/scripts/verify-bundle.sh"',
            '.source_commit == $commit',
            "make bench-llama-short-shipped",
            "BENCH_EVIDENCE_DIR=",
            "actions/upload-artifact@",
        )

        for fragment in required_fragments:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, workflow)

    def test_workflow_actions_are_commit_pinned(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")
        actions = re.findall(r"^\s*uses:\s*([^#\s]+)", workflow, flags=re.MULTILINE)

        self.assertGreaterEqual(len(actions), 3)

        for action in actions:
            with self.subTest(action=action):
                self.assertRegex(action, r"^[^@]+@[0-9a-f]{40}$")


if __name__ == "__main__":
    unittest.main()

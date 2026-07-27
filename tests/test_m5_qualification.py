# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Static qualification checks for the M5 operational surface."""

from __future__ import annotations

import re
import unittest
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    # Python <3.11 compatibility: provide a minimal TOML subset loader that
    # handles the simple key-value + [section.subsection] format used by the
    # baseline files in this project.  No external dependencies required.
    import re as _re

    class _TomllibCompat:
        """Minimal TOML subset loader (Python <3.11 fallback)."""

        @staticmethod
        def load(fp: "IO[bytes]") -> dict:
            """Load TOML from a binary file object."""
            return _TomllibCompat._parse(fp.read().decode("utf-8"))

        @staticmethod
        def _parse(text: str) -> dict:
            result: dict = {}
            current = result
            for raw_line in text.splitlines():
                # Strip inline comments (safe: none of our values contain '#')
                line = raw_line.split("#", 1)[0].strip()
                if not line:
                    continue
                # Section header: [a] or [a.b.c]
                m = _re.match(r"^\[([A-Za-z0-9_.]+)\]$", line)
                if m:
                    current = result
                    for part in m.group(1).split("."):
                        current = current.setdefault(part, {})
                    continue
                # Key = value
                m = _re.match(r"^([A-Za-z0-9_]+)\s*=\s*(.+)$", line)
                if m:
                    key, raw_val = m.group(1), m.group(2).strip()
                    if raw_val.startswith('"') and raw_val.endswith('"'):
                        current[key] = raw_val[1:-1]
                    elif raw_val in ("true", "false"):
                        current[key] = raw_val == "true"
                    else:
                        try:
                            current[key] = int(raw_val)
                        except ValueError:
                            try:
                                current[key] = float(raw_val)
                            except ValueError:
                                current[key] = raw_val
            return result

    tomllib = _TomllibCompat()  # type: ignore[assignment]


REPO_ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = REPO_ROOT / ".github" / "workflows" / "m5-harness.yml"
BASELINES = REPO_ROOT / "apps" / "bench" / "priv" / "bench" / "baselines"
WORKLOAD_SCRIPT = REPO_ROOT / "scripts" / "qualify-m5-workloads.sh"


class M5QualificationWorkflowTest(unittest.TestCase):
    def test_checked_in_baselines_pin_identity_and_both_hard_gates(self) -> None:
        paths = sorted(BASELINES.glob("v*/*.toml"))
        self.assertEqual(46, len(paths))

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

    def test_full_workload_qualification_is_bounded_reproducible_and_reversible(
        self,
    ) -> None:
        script = WORKLOAD_SCRIPT.read_text(encoding="utf-8")

        required_fragments = (
            "M5_DEDICATED_GUEST",
            "status --porcelain=v1 --untracked-files=all",
            "release/builders.lock",
            "make bench-llama-full",
            "BENCH_RESTART_TIMEOUT_MS",
            "qualification-live-preflight.sh",
            "exocomp-state.tar.gz",
            "umask 022",
            "source_tag=untagged",
            '"soak.pass"',
            "QUALIFICATION_STATUS=pass",
        )

        for fragment in required_fragments:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, script)

        self.assertNotIn(":latest", script)
        self.assertIn('summary["config"]["run_seconds"] >= 7200', script)


if __name__ == "__main__":
    unittest.main()

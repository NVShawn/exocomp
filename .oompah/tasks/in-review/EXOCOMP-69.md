---
id: EXOCOMP-69
type: task
status: In Review
priority: null
title: Create crashable fixture service script with health endpoint and state controls
parent: EXOCOMP-29
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:06:29.970644Z'
updated_at: '2026-07-23T21:24:54.382303Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 35fb83c8-dbf7-4c39-96ce-869fe1ae86c7
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 456541
  total_output_tokens: 22578
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 456541
      output_tokens: 22578
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 456504
    output_tokens: 2775
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:13:11.742479+00:00'
  - profile: default
    model: unknown
    input_tokens: 37
    output_tokens: 19803
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:22:44.929228+00:00'
---
## Summary

Implement the fixture service daemon (bash or Python) for the M4 systemd recovery fixture. The service must:

- Run as a long-lived daemon suitable for use as a systemd ExecStart target
- Serve a minimal HTTP health endpoint on a configurable localhost port (e.g. 127.0.0.1:8877) that returns JSON {"status": "ok"} or {"status": "degraded"} independently of the systemd process state
- Write and maintain a harmless workload marker file (e.g. /run/exocomp-fixture/workload.marker) that proves the service is actively running
- Accept a control signal or file-based trigger to enter one of these modes: active (healthy, normal), failed (exits nonzero), degraded (running but health endpoint returns unhealthy), flapping (restarts repeatedly), restart-failure (ExecStart exits immediately each time, exhausting StartLimitBurst)
- Health endpoint must be able to report unhealthy while the systemd unit is still active (process alive but health bad), satisfying the acceptance criterion that health can disagree with systemd active state

Place the service under test/fixtures/exocomp_fixture/bin/exocomp-fixture (executable script).

Reference: plans/milestone-4-service-recovery.md, section 'Reference Fixture'. This is a prerequisite for the unit file / installer task and the ExUnit test task.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:11
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:11
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:12
---
Understanding (duplicate screening): EXOCOMP-69 is the daemon-script slice of parent feature EXOCOMP-29. I will compare its full scope and comments with the parent and sibling M4 fixture tasks, then either archive a confirmed duplicate or hand off to feature implementation without changing code.
---
author: oompah
created: 2026-07-23 21:12
---
Focus handoff: duplicate_detector

Outcome: No duplicate found. EXOCOMP-69 is a distinct implementation child of EXOCOMP-29 and should proceed.

Evidence: Searched the full current tracker state and M4 plans for fixture-service, exocomp-fixture, health endpoint, workload marker, flapping, and restart-failure terms. Read EXOCOMP-29, EXOCOMP-69, EXOCOMP-70, and EXOCOMP-71 in full, including comments. EXOCOMP-29 explicitly decomposes its broad fixture scope into EXOCOMP-69 (daemon), EXOCOMP-70 (unit/installer/cleanup), EXOCOMP-71 (integration tests), and EXOCOMP-72 (documentation). EXOCOMP-70 and EXOCOMP-71 depend on EXOCOMP-69, confirming complementary rather than duplicate scope. Relevant design files are plans/milestone-4-service-recovery.md and plans/fixture-design.md on epic-EXOCOMP-4. Commands used: git grep against origin/oompah/state/proj-c260b117 and git show for the four task records.

Remaining work/risks: Implement the executable Python or Bash daemon at test/fixtures/exocomp_fixture/bin/exocomp-fixture with configurable localhost health port, maintained workload marker, file-controlled active/degraded/failed/flapping/restart-failure modes, and focused tests. Preserve degraded mode as a live process returning unhealthy status. The current shell is unexpectedly on epic-EXOCOMP-29 while the task metadata targets epic-EXOCOMP-4; the feature agent should verify it is operating in the intended shared epic worktree before edits.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-23 21:13
---
Agent completed successfully in 90s (459279 tokens)
---
author: oompah
created: 2026-07-23 21:13
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 9
- Tokens: 456.5K in / 2.8K out [459.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 30s
- Log: EXOCOMP-69__20260723T211147Z.jsonl
---
author: oompah
created: 2026-07-23 21:13
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:15
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:15
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-23 21:16
---
Understanding: Implementing the exocomp-fixture daemon script at test/fixtures/exocomp_fixture/bin/exocomp-fixture. This is a Python-based long-lived service that: (1) serves a health HTTP endpoint on a configurable localhost port returning JSON status, (2) maintains a workload marker file, (3) accepts file-based control triggers to switch between modes: active/healthy, degraded (process alive but health bad), failed (exits nonzero), flapping (rapid restarts), restart-failure (immediate exit to exhaust StartLimitBurst). Will also add focused tests. Reading plan files first to align with design.
---
author: oompah
created: 2026-07-23 21:17
---
Discovery: The project is an Elixir umbrella app under apps/. The fixture service is a new, standalone artifact outside the Elixir build: a Python daemon at test/fixtures/exocomp_fixture/bin/exocomp-fixture. The plans/milestone-4-service-recovery.md confirms the 5 required modes (active, degraded, failed, flapping, restart-failure). No fixture-design.md exists yet on this branch. Will implement: (1) Python daemon with stdlib http.server, file-based mode control, workload marker, SIGTERM handling; (2) Python unittest tests exercising all modes via subprocess. The state dir defaults to /run/exocomp-fixture and is configurable via env var or CLI flag.
---
author: oompah
created: 2026-07-23 21:20
---
Implementation: Created test/fixtures/exocomp_fixture/bin/exocomp-fixture (executable Python 3 daemon) with:
- HTTP health endpoint (configurable addr/port, default 127.0.0.1:8877) returning {"status":"ok"} (200) or {"status":"degraded"} (503)
- Workload marker file updated atomically on every poll cycle; removed on clean shutdown
- File-based mode control ($STATE_DIR/mode): active, degraded (process alive but health bad), failed/flapping/restart-failure (immediate exit code 1) — readable both at startup and dynamically while running
- SIGTERM/SIGINT graceful shutdown
- Poll interval configurable (default 1s, tests use 0.1s)
Also added:
- test/fixtures/exocomp_fixture/test/test_fixture.py — 22 Python unittest tests covering all modes, transitions, HTTP contract, and CLI flags
- test/fixtures/exocomp_fixture/README.md — operator/developer usage guide
- Makefile target test-fixture-service
---
author: oompah
created: 2026-07-23 21:20
---
Verification: 22/22 Python unit tests pass (8.3s). Tests cover: active mode health returns ok, degraded mode health returns degraded while process stays alive (key acceptance criterion), exit-mode startup (failed/flapping/restart-failure all exit immediately with code 1), runtime mode transitions (active→degraded→active, active→failed), workload marker creation and cleanup, SIGTERM clean shutdown (exit 0), HTTP contract (correct status codes and 404 for unknown paths), CLI flags and env vars. Ran via: python3 -m pytest test/fixtures/exocomp_fixture/test/test_fixture.py -v
---
author: oompah
created: 2026-07-23 21:22
---
Completion: Delivered test/fixtures/exocomp_fixture/bin/exocomp-fixture — a Python 3 daemon (no third-party deps) with:
- HTTP /health endpoint (127.0.0.1:8877, configurable) returning {"status":"ok"}|{"status":"degraded"}
- Atomic workload marker file updated each poll cycle, removed on shutdown
- File-based mode control: active, degraded (process stays alive, health unhealthy), failed/flapping/restart-failure (exit code 1)
- SIGTERM/SIGINT graceful shutdown
Also delivered: 22-test Python test suite (all pass, 8.3s), README, and Makefile target test-fixture-service. Branch EXOCOMP-69 pushed. Prerequisite for EXOCOMP-70 and EXOCOMP-71.
---
author: oompah
created: 2026-07-23 21:22
---
Delivered crashable fixture service at test/fixtures/exocomp_fixture/bin/exocomp-fixture with health endpoint, workload marker, file-based mode control (active/degraded/failed/flapping/restart-failure), and 22-test Python test suite (all passing). Makefile target test-fixture-service added.
---
author: oompah
created: 2026-07-23 21:22
---
Agent completed successfully in 420s (19840 tokens)
---
author: oompah
created: 2026-07-23 21:22
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 49, Tool calls: 34
- Tokens: 37 in / 19.8K out [19.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 7m 0s
- Log: EXOCOMP-69__20260723T211547Z.jsonl
---
author: oompah
created: 2026-07-23 21:22
---
Close refused by orchestrator: branch `epic-EXOCOMP-4` has 1 commit not on `main` and no open PR targets `main` from this branch.

Diagnostic:
  Unmerged commits: 1
    5096f79 EXOCOMP-29: Add fixture design document and decompose into child tasks
  Open PRs from this branch: 0
  Merged PRs from this branch: 0

Required: open a PR before closing.
  gh pr create --base main --head epic-EXOCOMP-4 --title "EXOCOMP-69: Create crashable fixture service script with health endpoint and state controls" --body "..."

Task reopened. Re-dispatch on the next tick will see this comment in its prompt context.
---
author: oompah
created: 2026-07-23 21:22
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:22
---
Focus: Software Engineer
---
<!-- COMMENTS:END -->

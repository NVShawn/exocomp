---
id: EXOCOMP-69
type: task
status: In Progress
priority: null
title: Create crashable fixture service script with health endpoint and state controls
parent: EXOCOMP-29
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:06:29.970644Z'
updated_at: '2026-07-23T21:16:00.382636Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 1927a265-5bd0-427d-8561-a965f1de713a
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 456504
  total_output_tokens: 2775
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 456504
      output_tokens: 2775
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 456504
    output_tokens: 2775
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:13:11.742479+00:00'
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
<!-- COMMENTS:END -->

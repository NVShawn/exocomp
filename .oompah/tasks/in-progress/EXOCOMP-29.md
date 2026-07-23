---
id: EXOCOMP-29
type: feature
status: In Progress
priority: 1
title: Create the isolated systemd recovery fixture
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-7
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:45.456680Z'
updated_at: '2026-07-23T21:04:18.158346Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 6c1977cf-187d-494f-8b57-90ad0e3fd69e
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 2022317
  total_output_tokens: 23307
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 2022317
      output_tokens: 23307
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 542271
    output_tokens: 4809
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:35:59.035047+00:00'
  - profile: standard
    model: unknown
    input_tokens: 1011513
    output_tokens: 8336
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:40:57.716174+00:00'
  - profile: default
    model: unknown
    input_tokens: 52
    output_tokens: 1884
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:51:58.540368+00:00'
  - profile: standard
    model: unknown
    input_tokens: 20
    output_tokens: 5268
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:02:07.969348+00:00'
  - profile: standard
    model: unknown
    input_tokens: 468461
    output_tokens: 3010
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:03:52.287393+00:00'
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Create the isolated systemd recovery fixture.

Implementation
Add an intentionally crashable fixture systemd service with an application health endpoint, harmless workload marker, active/failed/degraded/flapping/restart-failure controls, disposable installer, and cleanup limited to fixture resources; document VM or privileged-container requirements.

Testing
Test install/start/stop/crash/degrade/flap/restart-failure/cleanup, health versus systemd state, repeated fixture setup, and proof that non-fixture services/files are untouched.

Acceptance Criteria
- [ ] Every required service state is reproducible.
- [ ] Health can disagree with systemd active state.
- [ ] Fixture setup and cleanup are idempotent and scoped.
- [ ] Focused fixture tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:33
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:35
---
Agent completed successfully in 132s (547080 tokens)
---
author: oompah
created: 2026-07-23 20:36
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 11
- Tokens: 542.3K in / 4.8K out [547.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 12s
- Log: EXOCOMP-29__20260723T203348Z.jsonl
---
author: oompah
created: 2026-07-23 20:36
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-4`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 20:37
---
Retrying (attempt #3, agent: standard)
---
author: oompah
created: 2026-07-23 20:37
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:40
---
Agent completed successfully in 217s (1019849 tokens)
---
author: oompah
created: 2026-07-23 20:40
---
Run #4 [attempt=4, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 33
- Tokens: 1.0M in / 8.3K out [1.0M total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 37s
- Log: EXOCOMP-29__20260723T203722Z.jsonl
---
author: oompah
created: 2026-07-23 20:41
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-4`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 20:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:49
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:51
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 33
- Tokens: 52 in / 1.9K out [1.9K total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 3s
- Log: EXOCOMP-29__20260723T204957Z.jsonl
---
author: oompah
created: 2026-07-23 20:52
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 20:52
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:53
---
Understanding: EXOCOMP-29 asks for a self-contained, intentionally crashable systemd fixture service to support M4 integration testing. It needs: a health HTTP endpoint independent of systemd process state, a harmless workload marker, controls for active/failed/degraded/flapping/restart-failure modes, a disposable installer, scoped cleanup, and documentation of VM/privileged-container requirements. The blocker EXOCOMP-7 is now Done.
---
author: oompah
created: 2026-07-23 20:57
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-29 is a unique, foundational fixture task.

**Evidence reviewed:**
- All tasks in the oompah/state/proj-c260b117 branch surveyed (done, in-progress, open, archived)
- EXOCOMP-29 is child of epic EXOCOMP-4 (M4: Minimal-impact systemd service recovery)
- Sibling tasks EXOCOMP-30 (state machine), EXOCOMP-31 (automatic recovery), EXOCOMP-32 (approval-required recovery), EXOCOMP-33 (idempotency tests), EXOCOMP-34 (milestone verification) all cover distinct scopes
- No other task in the full tracker covers creating an intentionally crashable systemd test fixture with health endpoint, workload marker, state controls, installer, and scoped cleanup
- EXOCOMP-7 (blocker: Scaffold the Elixir umbrella) is Done; EXOCOMP-29 can proceed

**Relevant files:**
- plans/milestone-4-service-recovery.md — M4 design doc; Section 'Reference Fixture' describes exactly what EXOCOMP-29 must implement
- The fixture should live under tests/ or a fixture/ subdirectory alongside the Elixir apps

**Remaining work:**
- Create a bash or Python-based systemd fixture service (crashable, with health endpoint on localhost, harmless workload marker file)
- Install/cleanup scripts scoped to fixture resources only (e.g., /run/exocomp-fixture/)
- Controls to set service mode: active, failed, degraded, flapping, restart-failure
- systemd unit file for the fixture
- Focused ExUnit/integration tests covering all required states plus health-vs-systemd divergence and idempotent setup/cleanup
- Documentation of VM or privileged-container requirement

**Risks:**
- This is the prerequisite for EXOCOMP-31 and EXOCOMP-33; delays cascade
- Tests require systemd access; must run in a VM or privileged container
- Health endpoint must be able to disagree with systemd active state (health unhealthy while systemd shows active)

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-23 21:02
---
Agent completed successfully in 597s (5288 tokens)
---
author: oompah
created: 2026-07-23 21:02
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 41, Tool calls: 28
- Tokens: 20 in / 5.3K out [5.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 9m 57s
- Log: EXOCOMP-29__20260723T205213Z.jsonl
---
author: oompah
created: 2026-07-23 21:02
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:02
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:02
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 21:03
---
Agent completed successfully in 91s (471471 tokens)
---
author: oompah
created: 2026-07-23 21:03
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 7
- Tokens: 468.5K in / 3.0K out [471.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-29__20260723T210227Z.jsonl
---
author: oompah
created: 2026-07-23 21:03
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-4`. Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:04
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-23 21:04
---
Focus: Epic Planner
---
<!-- COMMENTS:END -->

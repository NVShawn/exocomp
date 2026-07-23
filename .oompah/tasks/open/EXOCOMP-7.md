---
id: EXOCOMP-7
type: feature
status: Open
priority: 1
title: Scaffold the Elixir umbrella and quality gates
parent: EXOCOMP-1
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:08:52.964005Z'
updated_at: '2026-07-23T20:19:13.192515Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 204304b5-bc22-4159-bb50-28e8e830a6d1
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 14946783
  total_output_tokens: 85867
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 14946783
      output_tokens: 85867
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 26
    output_tokens: 5590
    cost_usd: 0.0
    recorded_at: '2026-07-23T19:25:22.635193+00:00'
  - profile: standard
    model: unknown
    input_tokens: 4233032
    output_tokens: 28029
    cost_usd: 0.0
    recorded_at: '2026-07-23T19:37:22.165367+00:00'
  - profile: deep
    model: unknown
    input_tokens: 4306684
    output_tokens: 21984
    cost_usd: 0.0
    recorded_at: '2026-07-23T19:46:33.878297+00:00'
  - profile: default
    model: unknown
    input_tokens: 6407041
    output_tokens: 30264
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:00:41.395867+00:00'
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Scaffold the Elixir umbrella and quality gates.

Implementation
Create the Elixir 1.20/OTP 28 umbrella with shared core/protocol, node, and coordinator applications; configure separate node and coordinator releases with ERTS; pin exact toolchain and builder versions; replace placeholder Make targets with non-interactive build, test, lint, format, and format-check targets.

Testing
Run every Make target from a clean checkout; add ExUnit smoke tests that start each application in test mode and build both releases.

Acceptance Criteria
- [ ] Clean checkout builds without host Elixir when using the pinned builder.
- [ ] Both releases contain ERTS and start in test mode.
- [ ] make build, make test, make lint, and make fmt-check pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 19:20
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 19:20
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 19:23
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 19:23
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 19:25
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-7 is a unique, foundational task.

**Evidence reviewed:**
- Searched all 47 tasks across .oompah/tasks (in-progress, open) via the oompah/state branch
- EXOCOMP-7 is a child of EXOCOMP-1 (epic: M1 Prototype Elixir node agent)
- Other M1 children (EXOCOMP-8 through EXOCOMP-13) all depend on EXOCOMP-7 being completed first; none overlap with umbrella scaffold scope
- M2-M6 tasks (EXOCOMP-14 through EXOCOMP-47) cover coordinator, safety, recovery, performance, and release work — none involve creating the initial Elixir umbrella or make targets
- Closest candidates reviewed: EXOCOMP-42 (Build reproducible OTP release artifacts, M6) and EXOCOMP-1 (parent epic) — neither covers the same implementation scope

**Remaining work:**
- Create the Elixir 1.20/OTP 28 umbrella with core/protocol, node, and coordinator apps
- Configure node and coordinator releases with ERTS included
- Pin toolchain and builder image digests
- Replace placeholder Makefile targets with working build, test, lint, format, and fmt-check targets
- Add ExUnit smoke tests for each app starting in test mode and releasing both builds

**Risks:**
- This is the blocker for EXOCOMP-8 and EXOCOMP-9 (and transitively all other M1 tasks); delays cascade
- Builder image pinning requires Docker/container registry access at implementation time
- Elixir/OTP version availability in environment needs to be confirmed

**Recommended next focus:** feature (or devops) — this is a scaffolding/build infrastructure task that creates the Elixir umbrella, configures Mix releases, and sets up Make quality gates
---
author: oompah
created: 2026-07-23 19:25
---
Agent completed successfully in 143s (5616 tokens)
---
author: oompah
created: 2026-07-23 19:25
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 46, Tool calls: 35
- Tokens: 26 in / 5.6K out [5.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 23s
- Log: EXOCOMP-7__20260723T192301Z.jsonl
---
author: oompah
created: 2026-07-23 19:25
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 19:25
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 19:25
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 19:37
---
Agent completed successfully in 708s (4261061 tokens)
---
author: oompah
created: 2026-07-23 19:37
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 37
- Tokens: 4.2M in / 28.0K out [4.3M total]
- Cost: $0.0000
- Exit: normal, Duration: 11m 48s
- Log: EXOCOMP-7__20260723T192537Z.jsonl
---
author: oompah
created: 2026-07-23 19:37
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-1`. Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 19:37
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-23 19:37
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 19:46
---
Agent completed successfully in 535s (4328668 tokens)
---
author: oompah
created: 2026-07-23 19:46
---
Run #2 [attempt=2, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 30
- Tokens: 4.3M in / 22.0K out [4.3M total]
- Cost: $0.0000
- Exit: normal, Duration: 8m 55s
- Log: EXOCOMP-7__20260723T193740Z.jsonl
---
author: oompah
created: 2026-07-23 19:46
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 19:46
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 20:00
---
Agent completed successfully in 839s (6437305 tokens)
---
author: oompah
created: 2026-07-23 20:00
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 106
- Tokens: 6.4M in / 30.3K out [6.4M total]
- Cost: $0.0000
- Exit: normal, Duration: 13m 59s
- Log: EXOCOMP-7__20260723T194643Z.jsonl
---
author: oompah
created: 2026-07-23 20:00
---
Agent completed 3 times without closing this issue. Human action required: review the agent run history and task state, then either close the task if the work is done or add specific guidance and move it back to Open.
---
author: oompah
created: 2026-07-23 20:12
---
[watchdog:stalled_task] Stalled-task watchdog audit (run #4)

**State audited:** `Needs Human`
**Classification:** `actionable`
**Action:** `reopen`
**Evidence:** Last agent comment signals completion without a human question; the Needs Human transition appears accidental.

*This comment is posted automatically by the oompah stalled-task watchdog. No human action required unless the classification above is incorrect.*
---
author: oompah
created: 2026-07-23 20:14
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:14
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 20:19
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 0, Tool calls: 43
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 5m 2s
- Log: EXOCOMP-7__20260723T201411Z.jsonl
---
<!-- COMMENTS:END -->

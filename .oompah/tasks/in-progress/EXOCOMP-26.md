---
id: EXOCOMP-26
type: feature
status: In Progress
priority: 1
title: Implement bounded system-log cleanup action
parent: EXOCOMP-3
children:
- EXOCOMP-84
- EXOCOMP-85
blocked_by:
- EXOCOMP-22
- EXOCOMP-25
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:12.273742Z'
updated_at: '2026-07-24T02:44:34.882967Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 6be41d6a-1493-4cbc-8f9f-e9508bff74c8
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 438179
  total_output_tokens: 4709
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 438179
      output_tokens: 4709
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 438106
    output_tokens: 2375
    cost_usd: 0.0
    recorded_at: '2026-07-24T01:36:46.806960+00:00'
  - profile: default
    model: unknown
    input_tokens: 73
    output_tokens: 2334
    cost_usd: 0.0
    recorded_at: '2026-07-24T01:41:36.160374+00:00'
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Implement bounded system-log cleanup action.

Implementation
Implement system.logs.vacuum using a supported maintenance interface and installed fixed limits for source, minimum retention, maximum bytes, free-space target, cooldown, and retries; require deterministic disk pressure and prove lower-impact options insufficient; audit pre/post usage.

Testing
Test below/above threshold, exact boundary, caller attempts to change paths/limits, user/unknown paths, maximum reclaim, cooldown, maintenance failure, concurrent cleanup, and audit failure.

Acceptance Criteria
- [ ] Cleanup is ineligible without validated disk pressure.
- [ ] Only configured system logs are targeted.
- [ ] Installed retention/byte bounds cannot be widened by callers or the model.
- [ ] User and unknown data are never touched.
- [ ] Focused cleanup tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 01:35
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:35
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 01:35
---
Understanding: Screening EXOCOMP-26 for duplication before any implementation. I will search existing tasks and project design material for system.logs.vacuum/system-log cleanup work, inspect plausible candidates in full, and either archive this issue as a confirmed duplicate or leave a duplicate-detector handoff for implementation.
---
author: oompah
created: 2026-07-24 01:36
---
Discovery: No duplicate confirmed. The closest completed tasks are EXOCOMP-22 (generic deterministic least-impact policy selection) and EXOCOMP-25 (restricted executor/sudoers infrastructure, with a fixed vacuum action catalog entry). Their full descriptions and comments show they do not implement EXOCOMP-26's cleanup-specific disk-pressure validation, installed source/retention/reclaim/free-space bounds, pre/post usage audit, cooldown/retry behavior, or focused cleanup tests. Parent EXOCOMP-3 explicitly lists EXOCOMP-26 as the separate bounded system-log cleanup child.
---
author: oompah
created: 2026-07-24 01:36
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-26 remains a unique implementation task.

Evidence and decisions:
- Searched the tracker state branch and plans for system.logs.vacuum, system-log cleanup, journald, disk pressure, retention, reclaim, and vacuum terms.
- Reviewed EXOCOMP-22 in full: it implements generic eligibility filtering and risk ordering, not the cleanup action.
- Reviewed EXOCOMP-25 in full: it implements restricted executor/sudoers infrastructure and includes a fixed vacuum catalog entry, but explicitly identifies EXOCOMP-26 as the separate cleanup action. Reuse its ActionCatalog, Executor, ExecutorLock, OsCommander, and SudoersPolicy rather than duplicating them.
- Reviewed parent EXOCOMP-3: bounded system-log cleanup is explicitly assigned to EXOCOMP-26 as its own child.
- Relevant design: plans/milestone-3-safety-validation.md, especially System-Data Cleanup and M3-CRIT-4.

Remaining work and risks: Implement disk-pressure and lower-impact eligibility proof, installed immutable source/retention/byte/free-space/cooldown/retry limits, supported maintenance invocation, pre/post usage auditing, fail-closed audit and maintenance behavior, and the requested boundary/concurrency/data-safety tests. Preserve the separation from generic executor and policy-engine responsibilities already delivered by EXOCOMP-25 and EXOCOMP-22.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 01:36
---
Agent completed successfully in 94s (440481 tokens)
---
author: oompah
created: 2026-07-24 01:36
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 13
- Tokens: 438.1K in / 2.4K out [440.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 34s
- Log: EXOCOMP-26__20260724T013515Z.jsonl
---
author: oompah
created: 2026-07-24 01:36
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 01:36
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:36
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-24 01:40
---
Understanding (Epic Planner): EXOCOMP-26 implements bounded system-log cleanup on top of prerequisites EXOCOMP-22 (PolicyEngine/Safety types, Done on origin/EXOCOMP-73 and origin/EXOCOMP-74) and EXOCOMP-25 (ActionCatalog/Executor/SudoersPolicy, Done on origin/EXOCOMP-25). Neither prerequisite implements: disk-pressure detection, installed immutable vacuum bounds, source/path restriction, pre/post usage audit, or the eligibility gate. The current branch (epic-EXOCOMP-3) has no vacuum-specific code. I will decompose into three focused child tasks: (A) Disk-pressure evidence collector - deterministic filesystem measurement producing typed Evidence records; (B) Installed vacuum bounds and eligibility gate - immutable config limits with source restriction and cooldown/retry enforcement; (C) Vacuum action execution with pre/post audit - wires eligibility + executor + audit trail, fail-closed. Each task is independently testable in a single session.
---
author: oompah
created: 2026-07-24 01:41
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 48
- Tokens: 73 in / 2.3K out [2.4K total]
- Cost: $0.0000
- Exit: terminated, Duration: 4m 39s
- Log: EXOCOMP-26__20260724T013658Z.jsonl
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-31
type: feature
status: Needs Rebase
priority: 0
title: Implement automatic recovery of an already-failed service
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-25
- EXOCOMP-27
- EXOCOMP-29
- EXOCOMP-30
labels:
- focus-complete:duplicate_detector
- merge-conflict
assignee: null
created_at: '2026-07-23T19:10:47.061070Z'
updated_at: '2026-07-25T02:06:09.469008Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 9e2cfa48-3bca-44db-8fbb-5a0ce1de57bd
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 577810
  total_output_tokens: 3291
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 577810
      output_tokens: 3291
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 577810
    output_tokens: 3291
    cost_usd: 0.0
    recorded_at: '2026-07-25T02:04:23.281584+00:00'
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Implement automatic recovery of an already-failed service.

Implementation
Connect fresh service evidence, structured restart proposal, deterministic policy, audit-before-action, exact executor, systemd verification, application health check, stability window, terminal artifact, and one-attempt cooldown for a failed allow-listed service.

Testing
Test happy path, service self-recovers before execution, state changes to active/degraded, restart command failure, active-but-unhealthy result, health timeout, audit failure, and stable completion.

Acceptance Criteria
- [ ] Only a currently inactive/failed allow-listed service restarts automatically.
- [ ] Exactly one restart occurs per recovery episode.
- [ ] Success requires systemd plus application health stability.
- [ ] Failure enters cooldown/escalation with complete audit.
- [ ] Focused recovery tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 02:02
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 02:02
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-25 02:02
---
Understanding: duplicate-detector screening only. I will search existing tasks and Milestone 4 design material for service-recovery/restart work, inspect the full descriptions and comments of plausible matches, and either archive EXOCOMP-31 as a confirmed duplicate or hand it off for implementation if no duplicate is established. No code changes will be made in this focus.
---
author: oompah
created: 2026-07-25 02:03
---
Discovery: Duplicate screening found no confirmed duplicate. The closest reviewed tasks are EXOCOMP-30 (generic M4 recovery state machine and invariants), EXOCOMP-32 (approval-required active/degraded service flow), EXOCOMP-27 (generic remediation/A2A lifecycle), and EXOCOMP-33 (fault/idempotency test coverage). Their full descriptions and comments establish prerequisite or sibling boundaries: none implements the automatic orchestration for a currently inactive/failed allow-listed service, including fresh evidence, deterministic allow decision, audit-before-restart, exact execution, systemd plus application-health stability verification, terminal artifact, and one-attempt cooldown.
---
author: oompah
created: 2026-07-25 02:04
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-31 is the distinct Milestone 4 automatic recovery flow for an already-failed service and should proceed to implementation.

Evidence and decisions: The checkout has no .oompah/tasks directory, so I searched plans/docs locally and searched tracker Markdown on origin/oompah/state/proj-c260b117. I then read the full tracker records for EXOCOMP-30, EXOCOMP-32, EXOCOMP-27, EXOCOMP-33, and parent EXOCOMP-4. EXOCOMP-30 provides the pure recovery state machine; EXOCOMP-27 provides generic proposal/policy/audit lifecycle infrastructure; EXOCOMP-32 implements only approval-required active/degraded recovery and explicitly escalates without action when evidence becomes failed; EXOCOMP-33 owns broader failure/idempotency testing; EXOCOMP-4 intentionally lists EXOCOMP-31 as a separate child. Relevant specification and fixture expectations are in plans/milestone-4-service-recovery.md and docs/testing-systemd-fixture.md.

Remaining work and risks: Implement the service-specific automatic path for currently inactive/failed allow-listed evidence, reuse the existing state machine/policy/executor/audit boundaries, refresh evidence immediately before the one permitted restart, require both systemd and application-health stability, emit complete terminal audit/artifacts, and enter cooldown/escalation on every failure without retry. Cover happy path, self-recovery/state drift before execution, command failure, unhealthy/timeout verification, audit failure, and stable completion.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-25 02:04
---
Agent completed successfully in 113s (581101 tokens)
---
author: oompah
created: 2026-07-25 02:04
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 17
- Tokens: 577.8K in / 3.3K out [581.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 53s
- Log: EXOCOMP-31__20260725T020234Z.jsonl
---
author: oompah
created: 2026-07-25 02:04
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-25 02:05
---
YOLO: Merge conflict detected on MR #10. Rebase onto main and resolve conflicts.
---
author: oompah
created: 2026-07-25 02:05
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-25 02:05
---
Focus: Merge Conflict Resolver
---
<!-- COMMENTS:END -->

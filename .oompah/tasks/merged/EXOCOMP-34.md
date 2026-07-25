---
id: EXOCOMP-34
type: chore
status: Merged
priority: 1
title: Verify the M4 minimal-impact recovery milestone
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-28
- EXOCOMP-33
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:49.457512Z'
updated_at: '2026-07-25T02:26:15.100063Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: ee29a420-044e-4927-9066-1293784b6ab4
oompah.work_branch: epic-EXOCOMP-4
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Verify the M4 minimal-impact recovery milestone.

Implementation
Run the full release-like coordinator/node/fixture flow for failed-service automatic recovery and active/degraded approval behavior; collect correlated audit and host-state evidence for every M4 criterion.

Testing
Run unit, integration, fault-injection, and end-to-end Make targets; compare user-data and non-fixture host state before/after; inspect action count and stability window.

Acceptance Criteria
- [ ] Every M4-CRIT-* item has recorded pass/fail evidence.
- [ ] Failed fixture service recovers exactly once and remains healthy.
- [ ] Approval gates disruptive running-service restarts.
- [ ] No user data or non-fixture resource changes.
- [ ] All quality gates pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 02:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 02:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-25 02:25
---
Understanding: This run is limited to duplicate screening. I will search the native task corpus and M4 recovery plan for prior tasks covering the same release-like milestone verification, inspect full descriptions/comments for plausible matches, then either archive EXOCOMP-34 as a confirmed duplicate or leave a duplicate-detector handoff for implementation.
---
author: oompah
created: 2026-07-25 02:25
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 0, Tool calls: 3
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 29s
- Log: EXOCOMP-34__20260725T022449Z.jsonl
---
author: oompah
created: 2026-07-25 02:26
---
Discovery: Duplicate screening found no confirmed duplicate. I searched the git-backed tracker state and plans/docs for M4, minimal-impact recovery, failed-service recovery, approval gates, M4-CRIT, and recovery qualification, then reviewed full tracker records for EXOCOMP-4, EXOCOMP-28, EXOCOMP-31, EXOCOMP-32, EXOCOMP-33, EXOCOMP-39, and EXOCOMP-47. EXOCOMP-31/32 are implementation flows, EXOCOMP-33 is fault/idempotency coverage, EXOCOMP-39 is M5 soak/load testing, and EXOCOMP-47 is downstream M6 clean-host release qualification. Parent EXOCOMP-4 intentionally retains EXOCOMP-34 as its distinct end-to-end M4 acceptance-evidence child; EXOCOMP-28 is only the analogous M3 verifier.
---
author: oompah
created: 2026-07-25 02:26
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-34 uniquely owns cross-cutting Milestone 4 acceptance verification and should proceed.

Evidence and decisions: Searched origin/oompah/state/proj-c260b117 plus plans/docs because this worktree has no .oompah/tasks directory. Reviewed EXOCOMP-4, EXOCOMP-28, EXOCOMP-31, EXOCOMP-32, EXOCOMP-33, EXOCOMP-39, and EXOCOMP-47 in full. The parent epic deliberately lists EXOCOMP-34 separately from automatic recovery, approval-required recovery, and fault testing. Relevant specifications are plans/milestone-4-service-recovery.md (M4-CRIT-1..8) and docs/testing-systemd-fixture.md.

Remaining work and risks: Run the release-like coordinator/node/fixture path; record pass/fail evidence for every M4 criterion; prove one failed-service restart plus stability, approval gating for active/degraded restarts, correlated audit, and unchanged user/non-fixture host state; run affected Make gates. Important prerequisite risk: EXOCOMP-31's final tracker handoff says the automatic recovery feature remained unimplemented despite its Merged state, while EXOCOMP-33 history reports the same missing execution/reconciliation contract. Also preserve the pre-existing untracked apps/exocomp_node/test/exocomp/node/recovery/fault_injection_test.exs; this screening made no repository changes.

Recommended next focus: test.
---
<!-- COMMENTS:END -->

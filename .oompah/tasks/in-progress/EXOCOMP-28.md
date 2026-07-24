---
id: EXOCOMP-28
type: chore
status: In Progress
priority: 1
title: Verify M3 safety and remediation controls
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-20
- EXOCOMP-26
- EXOCOMP-27
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:14.600547Z'
updated_at: '2026-07-24T19:30:17.106137Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: af8b338f-98db-45df-b855-ec6ac3391cfa
oompah.work_branch: epic-EXOCOMP-3
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Verify M3 safety and remediation controls.

Implementation
Run adversarial and integration suites across policy ordering, approvals, replay, privilege separation, failed-service authorization, active-service approval, bounded system cleanup, audit, and data classification; record evidence for every M3 criterion.

Testing
Run all focused tests and repository Make gates; include explicit negative tests for arbitrary commands, paths, services, unknown data, user data, token tampering, and restart replay.

Acceptance Criteria
- [ ] Every M3-CRIT-* item has recorded pass/fail evidence.
- [ ] No test path permits user-data deletion or arbitrary commands.
- [ ] System cleanup stays within fixed bounds under proved need.
- [ ] Automatic versus approval-required service behavior matches policy.
- [ ] All quality gates pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 19:28
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 19:29
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 19:29
---
Understanding: duplicate-screening only. I will search existing tasks and M3 safety-validation materials for overlapping verification/remediation work, inspect the full descriptions and comments of plausible candidates, then either archive EXOCOMP-28 as a confirmed duplicate or record a duplicate-detector handoff without implementing.
---
author: oompah
created: 2026-07-24 19:30
---
Discovery: duplicate screening found no duplicate. The worktree lacks .oompah/tasks, so I searched the git-backed tracker state plus plans/docs, then reviewed full tracker records for EXOCOMP-3, EXOCOMP-20, EXOCOMP-27, EXOCOMP-34, and EXOCOMP-98. EXOCOMP-98 owns the focused approval/replay gate suite; EXOCOMP-27 owns remediation lifecycle/A2A integration tests; both explicitly identify EXOCOMP-28 as separate broad M3 acceptance verification. EXOCOMP-3 lists EXOCOMP-28 as the final security-acceptance child. EXOCOMP-20 and EXOCOMP-34 are analogous verification tasks for M2 and M4, not M3 duplicates.
---
author: oompah
created: 2026-07-24 19:30
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-28 is the unique cross-cutting Milestone 3 acceptance-verification task.

Evidence and decisions: Repository search covered M3, safety validation, remediation, policy ordering, approvals/replay, privilege separation, bounded cleanup, audit, and data classification in plans/docs and the git-backed tracker state. Full records reviewed: EXOCOMP-3, EXOCOMP-20, EXOCOMP-27, EXOCOMP-34, and EXOCOMP-98. EXOCOMP-27 implements lifecycle/A2A/audit behavior and EXOCOMP-98 implements the focused 15-scenario approval/replay gate; neither records pass/fail evidence for every M3-CRIT item. EXOCOMP-3 deliberately retains EXOCOMP-28 as its security-acceptance child. EXOCOMP-20 and EXOCOMP-34 verify different milestones. Relevant specification: plans/milestone-3-safety-validation.md, especially Test Strategy and M3-CRIT-1 through M3-CRIT-8.

Remaining work and risks: Integrate the completed M3 prerequisite branches into epic-EXOCOMP-3 as needed; build the cross-component adversarial/integration acceptance suite; explicitly cover arbitrary commands/paths/services, unknown and user data, approval tampering, concurrent/sequential/restart replay, failed versus active/degraded services, bounded cleanup, privilege rules, and correlated audit; record criterion-by-criterion evidence and run affected Make gates. Existing task history indicates the epic worktree may lag completed child branches, so confirm integration state first.

Recommended next focus: test. No repository files were changed; quality gates were not applicable to this read-only duplicate screening.
---
<!-- COMMENTS:END -->

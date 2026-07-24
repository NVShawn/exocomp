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
labels: []
assignee: null
created_at: '2026-07-23T19:10:14.600547Z'
updated_at: '2026-07-24T19:29:00.042043Z'
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
<!-- COMMENTS:END -->

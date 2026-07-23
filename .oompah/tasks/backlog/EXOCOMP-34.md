---
id: EXOCOMP-34
type: chore
status: Backlog
priority: 1
title: Verify the M4 minimal-impact recovery milestone
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-28
- EXOCOMP-33
labels: []
assignee: null
created_at: '2026-07-23T19:10:49.457512Z'
updated_at: '2026-07-23T19:13:36.014211Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


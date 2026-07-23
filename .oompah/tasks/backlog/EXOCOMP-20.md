---
id: EXOCOMP-20
type: chore
status: Backlog
priority: 1
title: Verify the M2 coordinator milestone
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-13
- EXOCOMP-15
- EXOCOMP-17
- EXOCOMP-18
- EXOCOMP-19
labels: []
assignee: null
created_at: '2026-07-23T19:09:33.364917Z'
updated_at: '2026-07-23T19:12:53.812380Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Verify the M2 coordinator milestone.

Implementation
Build a disposable coordinator plus at least three node fixtures; exercise inventory, DNS, polling, enrollment, renewal, cluster diagnostics, partial failure, cancellation, audit, and coordinator restart; record evidence for every M2 criterion.

Testing
Run all unit/integration tests and relevant Make gates, including token replay, wrong-root, slow node, unreachable node, and restart scenarios.

Acceptance Criteria
- [ ] Every M2-CRIT-* item has recorded pass/fail evidence.
- [ ] Multi-node discovery and diagnostics work after enrollment.
- [ ] Restart reconstructs state without losing durable audit.
- [ ] No M2 path invokes remediation.
- [ ] All quality gates pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


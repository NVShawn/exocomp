---
id: EXOCOMP-32
type: feature
status: Backlog
priority: 1
title: Implement approval-required active and degraded recovery
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-24
- EXOCOMP-27
- EXOCOMP-30
labels: []
assignee: null
created_at: '2026-07-23T19:10:47.855632Z'
updated_at: '2026-07-23T19:13:32.720641Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Implement approval-required active and degraded recovery.

Implementation
When current evidence shows an active or degraded service, move the task to input-required; display exact impact and evidence; accept only a valid bound approval; refresh preconditions before execution; cancel or re-diagnose when state changes.

Testing
Test approve, deny, expiry, timeout, wrong approver/token, changed evidence, service becomes healthy/failed, cancellation, and duplicate approval.

Acceptance Criteria
- [ ] No active/degraded service restarts before valid approval.
- [ ] Approval is invalid after relevant state changes.
- [ ] Denial/timeout performs no action and leaves an auditable terminal/escalated result.
- [ ] Focused approval-flow tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


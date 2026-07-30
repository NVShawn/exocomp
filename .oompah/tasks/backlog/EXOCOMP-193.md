---
id: EXOCOMP-193
type: task
status: Backlog
priority: 1
title: Reconcile desired services and health transitions
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:37:03.188337Z'
updated_at: '2026-07-30T21:37:03.188337Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, desired-state reconciliation.

Deliverable: Maintain the coordinator current view of effective service expectations and their latest health.

Acceptance criteria:
- Union manual, automatic, and profile-derived expectations using the shared resolver.
- Require every applicable configured probe to pass.
- Preserve stale or unreachable states explicitly when observation fails.
- Mark removed expectations retired and emit desired_state_removed rather than treating them as failures.
- Confirm unhealthy and recovered state only after two consecutive observations.
- Every transition is correlated and auditable.

Tests: Cover source addition/removal, enable/disable changes, conflicting observations, probe failure, stale nodes, retirement, and two-observation hysteresis; run make test.

Out of scope: Mission Control database writes, UI, incident workflow, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


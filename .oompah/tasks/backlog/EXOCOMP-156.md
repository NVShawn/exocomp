---
id: EXOCOMP-156
type: task
status: Backlog
priority: 2
title: Add incident acknowledgement, assignment, snooze, and resolution
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-141
- EXOCOMP-155
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:41.639331Z'
updated_at: '2026-07-30T14:21:08.115620Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add authorized context functions to acknowledge, assign/unassign, snooze/unsnooze, and manually resolve an incident.
- Require and store a reason for manual resolution.
- Record operator subject, organization, timestamp, and correlation ID for every mutation.

Acceptance:
- Role-matrix tests cover viewer denial and operator/admin success.
- Tests cover invalid transitions, snooze expiry, reassignment, concurrent mutation, and cross-organization IDs.
- New unhealthy evidence still reopens a manually resolved incident.

Out of scope: LiveView controls and notifications.
Quality gate: focused workflow tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


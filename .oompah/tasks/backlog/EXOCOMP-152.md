---
id: EXOCOMP-152
type: task
status: Backlog
priority: 1
title: Persist current cluster and node status
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-149
start_blocked_by: &id001
- EXOCOMP-194
labels: []
assignee: null
created_at: '2026-07-30T14:15:36.397265Z'
updated_at: '2026-07-30T21:40:35.868576Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add organization-scoped cluster and node current-state schemas for connectivity, health, versions, capabilities, labels, node counts, and last contact.
- Reduce cluster.hello, heartbeat, and status.snapshot events into the materialized current view transactionally.
- Reject stale snapshots using sequence/observation ordering.

Acceptance:
- Reducer tests cover initial state, partial update, stale update, node removal/tombstone, reconnect, duplicate event, and organization isolation.
- Current state can be queried without scanning event history.

Out of scope: history checkpoints, incidents, and UI.
Quality gate: focused context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


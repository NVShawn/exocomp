---
id: EXOCOMP-153
type: task
status: Backlog
priority: 2
title: Record bounded cluster and node status history
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-152
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:37.552915Z'
updated_at: '2026-07-30T14:20:55.334835Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add partition-ready status-history storage scoped to organization and source identity.
- Record cluster checkpoints every five minutes.
- Record node state changes immediately and unchanged-node checkpoints hourly.
- Preserve observation time separately from ingestion time.

Acceptance:
- Clock-controlled tests cover change detection, checkpoint cadence, duplicate snapshots, late events, and bounded batch writes.
- History writes do not block or replace the current-state transaction.

Out of scope: retention deletion and charts.
Quality gate: focused history tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


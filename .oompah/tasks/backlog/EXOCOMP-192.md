---
id: EXOCOMP-192
type: task
status: Backlog
priority: 2
title: Schedule service discovery and observations in the coordinator
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:37:02.009432Z'
updated_at: '2026-07-30T21:37:02.009432Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, desired-state polling.

Deliverable: Add coordinator scheduling that discovers automatic services on startup and every five minutes and observes effective services on the existing 30-second health cadence.

Acceptance criteria:
- Use jitter, bounded concurrency, per-node timeouts, and the existing backoff/isolation patterns.
- Cache the newest successful discovery without replacing it with a failed scan.
- Inventory replacement triggers prompt reconciliation.
- One slow or unreachable node cannot block peers.
- Scheduling uses an injectable clock for deterministic tests.

Tests: Cover startup, periodic refresh, jitter, cache preservation, inventory reload, timeout isolation, and cancellation; run make test.

Out of scope: Merge rules, status event schemas, incidents, and recovery.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


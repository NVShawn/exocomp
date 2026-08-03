---
id: EXOCOMP-223
type: task
status: Backlog
priority: 1
title: Renew policy leases and fall back to observe on expiry
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-222
labels: []
assignee: null
created_at: '2026-08-03T14:25:17.678179Z'
updated_at: '2026-08-03T14:30:50.386688Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add Mission Control renewal and coordinator lease-timer behavior with a five-minute default and validated configuration.

Acceptance criteria:
- Lease configuration accepts 60 through 3600 seconds; renewal defaults to 60 seconds and must be below half the lease.
- Mission Control issues fresh signed bundles without changing policy version when only the lease changes.
- Coordinator timers use monotonic time while running and validated wall time after restart.
- Expiry atomically switches all effective policy to observe, invalidates pending execution, and writes durable audit state.
- Reconnect requires a fresh bundle before manage resumes.

Tests: Use injectable clocks for bounds, renewal, delayed delivery, disconnect, clock movement, restart before/after expiry, invalid configuration, pending-work invalidation, and reconnection; run make test, make fmt-check, and make lint.

Out of scope: Action execution and LiveView rendering.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


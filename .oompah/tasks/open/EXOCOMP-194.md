---
id: EXOCOMP-194
type: task
status: Open
priority: 2
title: Define desired-service status events and contract fixtures
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-139
- EXOCOMP-193
labels: []
assignee: null
created_at: '2026-07-30T21:37:04.090360Z'
updated_at: '2026-08-01T11:52:32.165772Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, connection protocol and fleet status.

Deliverable: Extend the versioned Mission Control protocol with bounded desired-state changes, service-status changes, profile coverage, and periodic service summary snapshots.

Acceptance criteria:
- Events carry node, unit, source set, health depth, recovery authority, observation time, evidence references, and correlation ID.
- Initial snapshot plus deltas reconstruct the current view idempotently.
- Payloads are size-bounded, redacted, and forward-version checked.
- Duplicate and out-of-order fixtures define deterministic behavior.
- Shared fixtures are consumable by coordinator and Mission Control tests.

Tests: Add encode/decode, schema rejection, bounds, redaction, duplicate, ordering, and reconstruction tests; run make test.

Out of scope: Database migrations, incident reduction, LiveView rendering, and Ceph collection.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


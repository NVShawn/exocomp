---
id: EXOCOMP-18
type: feature
status: Backlog
priority: 1
title: Implement coordinator diagnostic task orchestration and audit
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-14
- EXOCOMP-15
labels: []
assignee: null
created_at: '2026-07-23T19:09:31.642631Z'
updated_at: '2026-07-23T19:12:46.775440Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Implement coordinator diagnostic task orchestration and audit.

Implementation
Create correlation IDs and idempotency keys; dispatch diagnostic A2A tasks; collect partial results; propagate cancellation when possible; bound concurrency/history/output; write goal, downstream state, result, and failure audit events; rebuild live state after restart without a database.

Testing
Test duplicate submissions, partial node failure, timeout, cancellation, task eviction, restart loss and safe resubmission, audit redaction, and unavailable audit sink.

Acceptance Criteria
- [ ] Cluster diagnostics return explicit success and failure per node.
- [ ] Duplicate submissions do not create duplicate downstream work.
- [ ] Volatile restart behavior is documented and safely resubmittable.
- [ ] Every task transition is correlated in durable audit.
- [ ] Focused tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


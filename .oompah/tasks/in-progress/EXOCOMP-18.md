---
id: EXOCOMP-18
type: feature
status: In Progress
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
updated_at: '2026-07-24T04:26:40.794868Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: f33add38-27ec-4e2d-bf50-3b407c9d4025
oompah.work_branch: epic-EXOCOMP-2
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 04:26
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 04:26
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

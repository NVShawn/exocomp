---
id: EXOCOMP-19
type: feature
status: Backlog
priority: 1
title: Expose coordinator cluster A2A service
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-15
- EXOCOMP-18
labels: []
assignee: null
created_at: '2026-07-23T19:09:32.508992Z'
updated_at: '2026-07-23T19:14:29.542341Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Expose coordinator cluster A2A service.

Implementation
Publish a coordinator Agent Card with exocomp.cluster.health and exocomp.cluster.diagnose; support A2A send/get/list/cancel using shared types; authorize inventory selections; aggregate bounded partial results; declare streaming/push unsupported; expose no remediation execution.

Testing
Run shared protocol fixtures plus tests for selection authorization, partial results, cancellation, mTLS, unsupported capabilities, version negotiation, and concurrent callers.

Acceptance Criteria
- [ ] Agent Card and endpoints conform to pinned A2A 1.0 fixtures.
- [ ] Authenticated callers receive correlated cluster results.
- [ ] Unauthorized node selection is rejected.
- [ ] No execution/remediation skill is reachable.
- [ ] Focused tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


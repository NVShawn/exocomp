---
id: EXOCOMP-2
type: epic
status: Open
priority: 1
title: 'M2: Coordinator, discovery, and node enrollment'
parent: null
children:
- EXOCOMP-14
- EXOCOMP-15
- EXOCOMP-16
- EXOCOMP-17
- EXOCOMP-18
- EXOCOMP-19
- EXOCOMP-20
blocked_by: []
labels:
- epic:stale
assignee: null
created_at: '2026-07-23T19:08:09.243476Z'
updated_at: '2026-07-24T02:40:30.941541Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Deliver coordinator discovery, node enrollment, polling, diagnostic orchestration, and A2A service capabilities.

Scope
Coordinate child tasks for coordinator state and inventory, health polling, bootstrap PKI, node enrollment and renewal, task orchestration, the coordinator A2A surface, and milestone acceptance. Remediation execution remains disabled.

Testing
All child-task tests, PKI scenarios, and the multi-node integration suite must pass through repository Make targets.

Acceptance Criteria
- [ ] Every child task is complete and focused tests pass.
- [ ] Every M2-CRIT-* criterion in the linked plan has recorded evidence.
- [ ] Enrollment, discovery, polling, and diagnostic dispatch work across multiple nodes.
- [ ] No Milestone 2 path invokes remediation.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


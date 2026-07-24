---
id: EXOCOMP-2
type: epic
status: Merged
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
updated_at: '2026-07-24T18:47:04.122262Z'
work_branch: epic-EXOCOMP-2
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/9
review_number: '9'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/9
oompah.review_number: '9'
oompah.work_branch: epic-EXOCOMP-2
oompah.target_branch: main
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:47
---
YOLO: merged PR #9.
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-4
type: epic
status: Merged
priority: 1
title: 'M4: Minimal-impact systemd service recovery'
parent: null
children:
- EXOCOMP-29
- EXOCOMP-30
- EXOCOMP-31
- EXOCOMP-32
- EXOCOMP-33
- EXOCOMP-34
- EXOCOMP-106
- EXOCOMP-109
blocked_by: []
labels:
- epic:rebasing
assignee: null
created_at: '2026-07-23T19:08:10.789340Z'
updated_at: '2026-07-25T19:28:55.873915Z'
work_branch: epic-EXOCOMP-4
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/10
review_number: '10'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/10
oompah.review_number: '10'
oompah.work_branch: epic-EXOCOMP-4
oompah.target_branch: main
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Prove the complete control loop by recovering an already-failed allow-listed systemd service with the least disruptive eligible action.

Scope
Coordinate the recovery fixture, state machine, automatic failed-service flow, approval-required active/degraded flow, failure-mode testing, and end-to-end acceptance. Recovery permits one restart before cooldown and never mutates user data.

Testing
State-machine, fixture, idempotency, fault-injection, and end-to-end tests must pass through repository Make targets.

Acceptance Criteria
- [ ] Every child task is complete and focused tests pass.
- [ ] Every M4-CRIT-* criterion in the linked plan has recorded evidence.
- [ ] The failed fixture service recovers exactly once and passes stability verification.
- [ ] Audit evidence proves least-impact selection and no user-data mutation.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


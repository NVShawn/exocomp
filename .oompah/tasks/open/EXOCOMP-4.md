---
id: EXOCOMP-4
type: epic
status: Open
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
blocked_by: []
labels:
- epic:stale
assignee: null
created_at: '2026-07-23T19:08:10.789340Z'
updated_at: '2026-07-23T21:50:53.075342Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


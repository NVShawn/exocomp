---
id: EXOCOMP-30
type: feature
status: Open
priority: 1
title: Implement the service-recovery state machine
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-18
- EXOCOMP-22
labels: []
assignee: null
created_at: '2026-07-23T19:10:46.278084Z'
updated_at: '2026-07-23T19:17:18.201696Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Implement the service-recovery state machine.

Implementation
Implement observe, diagnose, propose, validate, await approval, execute, verify, cooldown, complete, and escalate states with legal transitions, correlation, cancellation, deadlines, fresh-evidence requirements, one-attempt limit, and durable transition audit.

Testing
Use exhaustive state-transition tests for all legal/illegal events, stale/out-of-order messages, cancellation, timeout, duplicate events, restart restoration, cooldown, and escalation.

Acceptance Criteria
- [ ] Illegal or stale transitions fail without action.
- [ ] Each transition has one correlated audit event.
- [ ] Only validated paths can reach execution.
- [ ] A failed verification cannot autonomously loop to execution.
- [ ] Focused state-machine tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-33
type: chore
status: Backlog
priority: 1
title: Test recovery idempotency and failure modes
parent: EXOCOMP-4
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T19:10:48.671360Z'
updated_at: '2026-07-23T19:10:48.671360Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Test recovery idempotency and failure modes.

Implementation
Add fault-injection coverage for network partitions before/after execution, coordinator restart, node restart during action, duplicate/concurrent tasks, replay, audit sink failures, restart failure, health failure, flapping, and cooldown reconciliation.

Testing
Run each failure at the execution boundary and assert action count, durable execution record, task state, audit state, reconciliation result, and absence of restart loops.

Acceptance Criteria
- [ ] No scenario causes more than one execution for an execution ID.
- [ ] Post-action partitions reconcile without blind retry.
- [ ] Pre-action audit failure prevents execution.
- [ ] Flapping/repeated failure escalates after one attempt.
- [ ] All fault tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


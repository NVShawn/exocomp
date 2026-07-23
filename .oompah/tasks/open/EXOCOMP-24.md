---
id: EXOCOMP-24
type: feature
status: Open
priority: 1
title: Verify approvals and prevent replay on nodes
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-17
- EXOCOMP-23
labels: []
assignee: null
created_at: '2026-07-23T19:10:10.424356Z'
updated_at: '2026-07-23T19:17:13.857252Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Verify approvals and prevent replay on nodes.

Implementation
Verify signatures and every token binding at the node; re-check current preconditions; durably record consumed execution IDs before action; serialize concurrent verification; reconcile incomplete records after restart; fail closed on corrupt/unavailable replay state.

Testing
Test first use, concurrent duplicate, replay, replay after restart, wrong node/task/action/parameters/evidence, expiry, changed precondition, storage corruption, and interrupted persistence.

Acceptance Criteria
- [ ] A valid token executes at most once across restarts.
- [ ] Stale or mismatched approvals never reach an executor.
- [ ] Durable-state failure blocks approved action.
- [ ] Concurrent duplicates return one authoritative outcome.
- [ ] Focused replay tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


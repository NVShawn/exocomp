---
id: EXOCOMP-189
type: task
status: Backlog
priority: 1
title: Define desired-service types and deterministic merge rules
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-188
labels: []
assignee: null
created_at: '2026-07-30T21:36:59.020887Z'
updated_at: '2026-07-30T21:39:43.492754Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, three-path desired-state extension.

Deliverable: Add shared data types and a pure resolver that combines manual, automatic, and cluster-profile expectations for one node and service.

Acceptance criteria:
- The result records node, unit, sorted source set, required probes, expected state, profile context, and recovery-authority source.
- Duplicate services become one effective expectation.
- Automatic discovery alone never grants recovery authority.
- Manual allow-list and shipped-profile authority remain distinguishable.
- Output ordering is deterministic.

Tests: Add table-driven unit tests for each source alone, all source combinations, duplicate probes, stable ordering, and authority merging; run make test.

Out of scope: I/O, polling, incident creation, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


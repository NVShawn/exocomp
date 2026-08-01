---
id: EXOCOMP-189
type: task
status: Open
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
updated_at: '2026-08-01T13:41:02.526515Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 6d5af8d008d883ef9e3cf0c6756e1516e15bef843eea0d9378bdf7f813142c14
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 6f4e4e2b-f8aa-466e-8ba9-cd645f7f7e33
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:41:01.778212+00:00'
  claim_expires_at: '2026-08-01T14:11:01.778212+00:00'
  retry_count: 0
  retry_after: null
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


---
id: EXOCOMP-100
type: feature
status: Backlog
priority: 1
title: Implement volatile diagnostic task store and idempotency
parent: EXOCOMP-18
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T04:29:30.794767Z'
updated_at: '2026-07-24T04:29:30.794767Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Create the coordinator orchestration state model and public internal API for accepting diagnostic goals. Generate UUIDv4 correlation IDs, derive or retain stable downstream idempotency keys, and deduplicate repeated caller submissions so concurrent/retried submissions cannot create duplicate downstream work. Store live and terminal task state without a database, with configurable bounds for active concurrency, retained task history, per-task artifacts/output, and deterministic oldest-terminal eviction. Define states and per-node outcome shapes suitable for EXOCOMP-19 handlers. Add focused tests for duplicate submissions, concurrent duplicate races, bounds, eviction, output truncation, and lookup/list semantics.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


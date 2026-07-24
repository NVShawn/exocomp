---
id: EXOCOMP-100
type: feature
status: In Progress
priority: 1
title: Implement volatile diagnostic task store and idempotency
parent: EXOCOMP-18
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T04:29:30.794767Z'
updated_at: '2026-07-24T15:56:25.897231Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 516222c7-5b1a-47ff-9bcf-7ce2cbbe3630
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Create the coordinator orchestration state model and public internal API for accepting diagnostic goals. Generate UUIDv4 correlation IDs, derive or retain stable downstream idempotency keys, and deduplicate repeated caller submissions so concurrent/retried submissions cannot create duplicate downstream work. Store live and terminal task state without a database, with configurable bounds for active concurrency, retained task history, per-task artifacts/output, and deterministic oldest-terminal eviction. Define states and per-node outcome shapes suitable for EXOCOMP-19 handlers. Add focused tests for duplicate submissions, concurrent duplicate races, bounds, eviction, output truncation, and lookup/list semantics.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 15:55
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 15:55
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 15:55
---
Understanding: duplicate-detector pass only. I will search task records and project decisions for existing work covering the volatile diagnostic task store, UUID correlation/idempotency, concurrent submission deduplication, bounded retention/eviction, output truncation, and lookup/list semantics; then inspect full candidate task descriptions/comments before deciding duplicate versus implementation handoff.
---
author: oompah
created: 2026-07-24 15:56
---
Discovery: duplicate screening found no confirmed duplicate. Closest match EXOCOMP-79 is the already-merged node-side A2A TaskRegistry (generic submitted/working lifecycle, worker cancellation, TTL/count eviction); EXOCOMP-100 is coordinator-side goal acceptance with caller deduplication, stable downstream idempotency keys, correlation IDs, per-node outcome shapes, artifact/output truncation, and EXOCOMP-19-facing lookup/list semantics. EXOCOMP-18 is its intentional parent decomposition; EXOCOMP-101 consumes this store for fan-out; EXOCOMP-19 is the external HTTP/A2A surface; EXOCOMP-99 is the downstream client adapter. These scopes are complementary, not duplicates.
---
<!-- COMMENTS:END -->

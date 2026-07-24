---
id: EXOCOMP-100
type: feature
status: Open
priority: 1
title: Implement volatile diagnostic task store and idempotency
parent: EXOCOMP-18
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T04:29:30.794767Z'
updated_at: '2026-07-24T16:10:19.522172Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 09784ef6-1e57-435c-a337-c422d1f6e928
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 606414
  total_output_tokens: 5945
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 606414
      output_tokens: 5945
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 606360
    output_tokens: 3429
    cost_usd: 0.0
    recorded_at: '2026-07-24T15:56:50.871923+00:00'
  - profile: default
    model: unknown
    input_tokens: 54
    output_tokens: 2516
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:04:03.622518+00:00'
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
author: oompah
created: 2026-07-24 15:56
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-100 remains a distinct implementation task. No repository files were changed.

Evidence: The requested rg scan found no materialized .oompah/tasks directory on this checkout/default branch, but repository plans identify the coordinator contract in plans/milestone-2-coordinator.md: volatile/reconstructible state, correlation/idempotency, bounded history, and get/list/cancel support. Full tracker records reviewed: EXOCOMP-18 (parent epic intentionally created EXOCOMP-100 as the state/idempotency foundation), EXOCOMP-79 and EXOCOMP-12 (merged node-side task registry/service), EXOCOMP-99 (diagnostic client adapter), EXOCOMP-101 (fan-out consumer), and EXOCOMP-19 (external coordinator A2A handlers). EXOCOMP-79 is the closest reusable precedent, but it does not cover caller submission keys, concurrent duplicate races, stable per-node downstream idempotency, coordinator per-node outcomes, or artifact/output truncation.

Relevant files/decisions: plans/milestone-2-coordinator.md; apps/exocomp_coordinator/ is the implementation surface; apps/exocomp_core/lib/exocomp/a2a/ supplies shared task shapes when prerequisite branches are present. Preserve a public internal API suitable for EXOCOMP-19 and state updates suitable for EXOCOMP-101. The current checkout reports branch epic-EXOCOMP-18 despite the dispatch text naming epic-EXOCOMP-2, so the next agent should verify prerequisite branch content before editing.

Remaining work/risks: implement atomic acceptance/deduplication, UUIDv4 correlation IDs, caller-key derivation/retention, stable downstream keys, bounded active/history/artifact/output storage, deterministic oldest-terminal eviction, state/outcome types, and focused concurrency/bounds/truncation/lookup/list tests. Reuse node registry concepts only where semantics match; do not alias coordinator goals to node tasks.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 15:56
---
Agent completed successfully in 111s (609789 tokens)
---
author: oompah
created: 2026-07-24 15:56
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 31
- Tokens: 606.4K in / 3.4K out [609.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 51s
- Log: EXOCOMP-100__20260724T155504Z.jsonl
---
author: oompah
created: 2026-07-24 15:56
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 16:01
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:01
---
Focus: Feature Developer
---
author: oompah
created: 2026-07-24 16:04
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 43
- Tokens: 54 in / 2.5K out [2.6K total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 25s
- Log: EXOCOMP-100__20260724T160140Z.jsonl
---
author: oompah
created: 2026-07-24 16:04
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 16:04
---
Focus: Feature Developer
---
author: oompah
created: 2026-07-24 16:07
---
Understanding: Implementing coordinator-side volatile diagnostic goal store (GoalStore) in apps/exocomp_coordinator/. Key design: (1) DiagnosticGoal struct with UUIDv4 correlation ID, caller idempotency key, goal states (:accepted/:dispatching/:running/:completed/:failed/:canceled), per-node outcomes, bounded artifacts and output; (2) NodeOutcome struct for per-node results (:pending/:running/:succeeded/:failed/:unreachable/:canceled); (3) GoalStore GenServer with atomic accept/dedup by caller_key, configurable max_active/max_history/max_artifacts/max_output_bytes, oldest-terminal TTL+count eviction, and downstream_key/2 pure function; (4) focused tests for duplicate submissions, concurrent races, bounds, eviction, output truncation, and lookup/list semantics. Following patterns from apps/exocomp_node/lib/exocomp/node/task_registry.ex.
---
<!-- COMMENTS:END -->

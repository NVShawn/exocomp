---
id: EXOCOMP-100
type: feature
status: Needs Human
priority: 1
title: Implement volatile diagnostic task store and idempotency
parent: EXOCOMP-18
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T04:29:30.794767Z'
updated_at: '2026-08-01T00:59:04.820421Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: b848852b-7a3f-4af0-8040-8551e3be745c
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 606463
  total_output_tokens: 43511
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 606463
      output_tokens: 43511
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
  - profile: default
    model: unknown
    input_tokens: 49
    output_tokens: 37566
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:28:54.974766+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    no-auditor-audit-84dd878d6ea3-3: '2026-07-31T21:16:07.138357+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-100
    target_state: Archived
    evidence_fingerprint: 73c4d75ef3c0aa77d8940cf4cffaf962a743e0a6ffc7ea1a327a1ca18f629b51
    audit_ids:
    - audit-84dd878d6ea3
    kind: result
    applied: true
    retired_at: '2026-07-31T21:16:07.138371+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-100
    audit_id: audit-84dd878d6ea3
    attempt_id: no-auditor-audit-84dd878d6ea3-3
    target_state: Archived
    evidence_fingerprint: 73c4d75ef3c0aa77d8940cf4cffaf962a743e0a6ffc7ea1a327a1ca18f629b51
    status: Needs Human
    audit_ids:
    - audit-84dd878d6ea3
    applied: true
    created_at: '2026-07-31T21:16:07.138390+00:00'
    applied_at: '2026-07-31T21:16:10.174385+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-84dd878d6ea3
    project_id: proj-c260b117
    task_id: EXOCOMP-100
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 73c4d75ef3c0aa77d8940cf4cffaf962a743e0a6ffc7ea1a327a1ca18f629b51
    attempts:
    - version: 1
      attempt_id: attempt-5eec6bdb4ca5
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 73c4d75ef3c0aa77d8940cf4cffaf962a743e0a6ffc7ea1a327a1ca18f629b51
      created_at: '2026-07-31T21:12:27.689612+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T21:12:27.689612+00:00'
      branch_key: epic-EXOCOMP-2
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:12:33.188679+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:12:43.188653+00:00'
    - version: 1
      attempt_id: attempt-136b37307ed6
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 73c4d75ef3c0aa77d8940cf4cffaf962a743e0a6ffc7ea1a327a1ca18f629b51
      created_at: '2026-07-31T21:13:51.176667+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-07-31T21:13:51.176667+00:00'
      branch_key: epic-EXOCOMP-2
      candidate_rotation_count: 1
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:13:57.525860+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:14:17.525820+00:00'
    - version: 1
      attempt_id: attempt-1d180c188796
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 73c4d75ef3c0aa77d8940cf4cffaf962a743e0a6ffc7ea1a327a1ca18f629b51
      created_at: '2026-07-31T21:14:58.192858+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-07-31T21:14:58.192858+00:00'
      branch_key: epic-EXOCOMP-2
      candidate_rotation_count: 2
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:15:04.048135+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:15:44.048108+00:00'
    - version: 1
      attempt_id: no-auditor-audit-84dd878d6ea3-3
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 73c4d75ef3c0aa77d8940cf4cffaf962a743e0a6ffc7ea1a327a1ca18f629b51
      verdict: fail
      failure_classification: no_auditor
      created_at: '2026-07-31T21:16:07.138175+00:00'
      completed_at: '2026-07-31T21:16:07.138175+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-31T20:45:58.129943+00:00'
    updated_at: '2026-07-31T21:16:07.138175+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-5eec6bdb4ca5
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 73c4d75ef3c0aa77d8940cf4cffaf962a743e0a6ffc7ea1a327a1ca18f629b51
    created_at: '2026-07-31T21:12:27.689612+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T21:12:27.689612+00:00'
    branch_key: epic-EXOCOMP-2
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:12:33.188679+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:12:43.188653+00:00'
  - version: 1
    attempt_id: attempt-136b37307ed6
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 73c4d75ef3c0aa77d8940cf4cffaf962a743e0a6ffc7ea1a327a1ca18f629b51
    created_at: '2026-07-31T21:13:51.176667+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-07-31T21:13:51.176667+00:00'
    branch_key: epic-EXOCOMP-2
    candidate_rotation_count: 1
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:13:57.525860+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:14:17.525820+00:00'
  - version: 1
    attempt_id: attempt-1d180c188796
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 73c4d75ef3c0aa77d8940cf4cffaf962a743e0a6ffc7ea1a327a1ca18f629b51
    created_at: '2026-07-31T21:14:58.192858+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-07-31T21:14:58.192858+00:00'
    branch_key: epic-EXOCOMP-2
    candidate_rotation_count: 2
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:15:04.048135+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:15:44.048108+00:00'
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
author: oompah
created: 2026-07-24 16:15
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:15
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-24 16:15
---
Understanding: Implementing coordinator-side volatile diagnostic goal store. Plan: (1) Explore codebase structure, existing patterns from node task_registry.ex, and plans/milestone-2-coordinator.md; (2) Implement GoalStore GenServer in apps/exocomp_coordinator/ with DiagnosticGoal/NodeOutcome structs, UUIDv4 correlation IDs, caller-key deduplication, configurable bounds, deterministic oldest-terminal eviction, output/artifact truncation; (3) Implement public internal API for EXOCOMP-19 consumers; (4) Write focused tests for all requirements; (5) Verify with mix test.
---
author: oompah
created: 2026-07-24 16:18
---
Discovery: DiagnosticGoal and NodeOutcome structs already exist in apps/exocomp_coordinator/lib/exocomp/coordinator/. The node-side TaskRegistry (apps/exocomp_node/lib/exocomp/node/task_registry.ex) provides the eviction/GenServer patterns to follow. Need to implement GoalStore GenServer with: atomic dedup by caller_key, UUIDv4 correlation IDs, configurable max_active/max_history/max_artifacts/max_output_bytes bounds, oldest-terminal eviction, front-truncated output, per-node outcome management, downstream_key/2 pure function, and comprehensive tests.
---
author: oompah
created: 2026-07-24 16:28
---
Implementation: Created GoalStore GenServer in apps/exocomp_coordinator/lib/exocomp/coordinator/goal_store.ex. Key design decisions: (1) UUIDv4 correlation IDs via :crypto; (2) atomic caller_key deduplication in GenServer handle_call — concurrent calls serialised, one goal created; (3) sequence counter (not monotonic_ms) for stable insertion-order list semantics; (4) configurable max_active/max_history/max_artifacts/max_output_bytes with oldest-terminal eviction on every accept via make_room, plus periodic :evict message; (5) front-truncation on output overflow with sticky output_truncated flag; (6) caller_key index cleaned up at eviction time so re-submissions after eviction get fresh IDs; (7) downstream_key/2 pure function (SHA-256 hex of goal_id:node_id). Tests in goal_store_test.exs cover all required scenarios: duplicates, concurrent races, bounds, eviction, output truncation, and lookup/list semantics. All 153 coordinator tests pass.
---
author: oompah
created: 2026-07-24 16:28
---
Verification: All 153 coordinator tests pass (55 exocomp_core + 66 exocomp_node + 153 exocomp_coordinator — total 274 coordinator-side). The 36 new goal_store_test.exs cases exercise: duplicate acceptance, concurrent race dedup, max_active and max_history bounds, deterministic oldest-terminal eviction, caller_key index cleanup, output truncation, artifact caps, cancel, transition state machine, downstream_key format/determinism, and terminal? helper coverage. Zero failures.
---
author: oompah
created: 2026-07-24 16:28
---
Completion: Delivered GoalStore GenServer (apps/exocomp_coordinator/lib/exocomp/coordinator/goal_store.ex) and test suite (apps/exocomp_coordinator/test/exocomp/coordinator/goal_store_test.exs). The store provides the full coordinator orchestration state model and public internal API required by EXOCOMP-100: UUIDv4 correlation IDs, atomic caller_key deduplication (concurrent/retry-safe), stable downstream_key/2 idempotency, bounded active/history/artifact/output storage, deterministic oldest-terminal eviction, output front-truncation, and EXOCOMP-19/EXOCOMP-101-compatible get/list/cancel/transition API. DiagnosticGoal and NodeOutcome structs (already present) define all required state and outcome shapes. Branch EXOCOMP-99 pushed; all tests green.
---
author: oompah
created: 2026-07-24 16:28
---
Implemented GoalStore volatile diagnostic task store with UUIDv4 correlation IDs, atomic caller_key deduplication, configurable bounds (max_active/max_history/max_artifacts/max_output_bytes), deterministic oldest-terminal eviction, output front-truncation, downstream_key/2 pure function, and public internal API (accept/get/list/transition/put_node_outcome/append_output/put_artifact/cancel). 36 focused tests cover all required scenarios. All 153 coordinator tests pass.
---
author: oompah
created: 2026-07-24 16:28
---
Agent completed successfully in 817s (37615 tokens)
---
author: oompah
created: 2026-07-24 16:28
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 79, Tool calls: 54
- Tokens: 49 in / 37.6K out [37.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 13m 37s
- Log: EXOCOMP-100__20260724T161521Z.jsonl
---
author: oompah
created: 2026-07-31 20:46
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-07-31 21:12
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 21:12
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-07-31 21:12
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 21:13
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-07-31 21:13
---
Run #2 [attempt=2, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 4s
---
author: oompah
created: 2026-07-31 21:13
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 21:14
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-07-31 21:15
---
Run #3 [attempt=3, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 4s
---
author: oompah
created: 2026-07-31 21:15
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 21:16
---
Needs Human — Archived audit requires operator input.

No independent auditor candidate is available for this audit (Audit reached the maximum of 3 attempts.). Configure the `auditor` role with at least one healthy provider/model that is independent of the task contributors, then move the task back to Open to retry.
---
author: oompah
created: 2026-08-01 00:59
---
Direct operator recovery claimed at the project owner's request. This is a failed Archived audit caused by deleted historical branch checkout, not incomplete implementation. Keep Needs Human as a scheduler hold until OOMPAH-671 is deployed; I will rearm and oversee the existing archive audit without reopening implementation.
---
<!-- COMMENTS:END -->

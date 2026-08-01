---
id: EXOCOMP-102
type: feature
status: Needs Human
priority: 1
title: Propagate coordinator diagnostic cancellation
parent: EXOCOMP-18
children: []
blocked_by:
- EXOCOMP-101
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T04:29:44.242098Z'
updated_at: '2026-08-01T00:59:07.043270Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 886e94ea-b999-4505-a0eb-4e3a63e0f022
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 508474
  total_output_tokens: 66864
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 508474
      output_tokens: 66864
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 508441
    output_tokens: 3890
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:57:24.503536+00:00'
  - profile: default
    model: unknown
    input_tokens: 33
    output_tokens: 62974
    cost_usd: 0.0
    recorded_at: '2026-07-24T17:33:40.568730+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    no-auditor-audit-a04fdbdb74c9-3: '2026-07-31T21:15:12.734310+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-102
    target_state: Archived
    evidence_fingerprint: 3939a7130e9bad948b1ba216061de1694657191d5c2e8f46eaf1faa95a875e15
    audit_ids:
    - audit-a04fdbdb74c9
    kind: result
    applied: true
    retired_at: '2026-07-31T21:15:12.734319+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-102
    audit_id: audit-a04fdbdb74c9
    attempt_id: no-auditor-audit-a04fdbdb74c9-3
    target_state: Archived
    evidence_fingerprint: 3939a7130e9bad948b1ba216061de1694657191d5c2e8f46eaf1faa95a875e15
    status: Needs Human
    audit_ids:
    - audit-a04fdbdb74c9
    applied: true
    created_at: '2026-07-31T21:15:12.734333+00:00'
    applied_at: '2026-07-31T21:15:15.346318+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-a04fdbdb74c9
    project_id: proj-c260b117
    task_id: EXOCOMP-102
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 3939a7130e9bad948b1ba216061de1694657191d5c2e8f46eaf1faa95a875e15
    attempts:
    - version: 1
      attempt_id: attempt-3451e031b572
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 3939a7130e9bad948b1ba216061de1694657191d5c2e8f46eaf1faa95a875e15
      created_at: '2026-07-31T21:12:54.638604+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T21:12:54.638604+00:00'
      branch_key: epic-EXOCOMP-2
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:13:01.160349+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:13:11.160317+00:00'
    - version: 1
      attempt_id: attempt-e9b608ea4768
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 3939a7130e9bad948b1ba216061de1694657191d5c2e8f46eaf1faa95a875e15
      created_at: '2026-07-31T21:13:23.575893+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-07-31T21:13:23.575893+00:00'
      branch_key: epic-EXOCOMP-2
      candidate_rotation_count: 1
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:13:31.086021+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:13:51.085994+00:00'
    - version: 1
      attempt_id: attempt-976c3e6f82c5
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 3939a7130e9bad948b1ba216061de1694657191d5c2e8f46eaf1faa95a875e15
      created_at: '2026-07-31T21:14:17.824397+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-07-31T21:14:17.824397+00:00'
      branch_key: epic-EXOCOMP-2
      candidate_rotation_count: 2
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:14:22.651890+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:15:02.651859+00:00'
    - version: 1
      attempt_id: no-auditor-audit-a04fdbdb74c9-3
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 3939a7130e9bad948b1ba216061de1694657191d5c2e8f46eaf1faa95a875e15
      verdict: fail
      failure_classification: no_auditor
      created_at: '2026-07-31T21:15:12.734184+00:00'
      completed_at: '2026-07-31T21:15:12.734184+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-31T20:46:08.667667+00:00'
    updated_at: '2026-07-31T21:15:12.734184+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-3451e031b572
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 3939a7130e9bad948b1ba216061de1694657191d5c2e8f46eaf1faa95a875e15
    created_at: '2026-07-31T21:12:54.638604+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T21:12:54.638604+00:00'
    branch_key: epic-EXOCOMP-2
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:13:01.160349+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:13:11.160317+00:00'
  - version: 1
    attempt_id: attempt-e9b608ea4768
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 3939a7130e9bad948b1ba216061de1694657191d5c2e8f46eaf1faa95a875e15
    created_at: '2026-07-31T21:13:23.575893+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-07-31T21:13:23.575893+00:00'
    branch_key: epic-EXOCOMP-2
    candidate_rotation_count: 1
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:13:31.086021+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:13:51.085994+00:00'
  - version: 1
    attempt_id: attempt-976c3e6f82c5
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 3939a7130e9bad948b1ba216061de1694657191d5c2e8f46eaf1faa95a875e15
    created_at: '2026-07-31T21:14:17.824397+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-07-31T21:14:17.824397+00:00'
    branch_key: epic-EXOCOMP-2
    candidate_rotation_count: 2
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:14:22.651890+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:15:02.651859+00:00'
---
## Summary

Implement cancellation for accepted and running cluster diagnostic tasks. Atomically mark the cluster task cancellation request, stop undispatched work, attempt A2A cancellation for every active downstream task that supports it, record explicit per-node cancelled/completed/cancel-failed outcomes, and make repeated cancellation idempotent. Resolve races with node completion and ensure orchestration workers terminate without leaking tasks. Add focused tests for cancellation before dispatch, during fan-out, unsupported downstream cancellation, partial cancellation failure, repeated cancel, and completion/cancel races.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 16:55
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:55
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 16:55
---
Understanding: Duplicate-screening only. I will search coordinator/cluster-diagnostic cancellation tasks and planning records, inspect full descriptions/comments for plausible matches, and either archive EXOCOMP-102 as a confirmed duplicate or hand it off for implementation. The current checkout lacks .oompah/tasks and is branch epic-EXOCOMP-18, so I will use tracker/default-branch read-only evidence while remaining in this worktree.
---
author: oompah
created: 2026-07-24 16:56
---
Discovery: No confirmed duplicate. EXOCOMP-18 explicitly decomposed cancellation into this child after EXOCOMP-99/100/101. EXOCOMP-99 only supplies the outbound DiagnosticClient.cancel operation and unsupported/not-cancelable normalization; EXOCOMP-100 only atomically transitions coordinator goal state and rejects terminal cancellation; EXOCOMP-101 supplies bounded fan-out/result aggregation but no cluster cancel API or downstream cancellation propagation. EXOCOMP-79 is node-side local task/worker cancellation, EXOCOMP-19 owns the future external HTTP/A2A cancel endpoint, and EXOCOMP-105 only verifies integration. These are prerequisites/consumers or reusable precedents, not the same deliverable.
---
author: oompah
created: 2026-07-24 16:57
---
Focus handoff: duplicate_detector\n\nOutcome: Duplicate screening found no duplicate; EXOCOMP-102 should proceed to feature implementation. No repository files were changed.\n\nEvidence and decisions: Searched the complete tracker state branch and repository docs/plans for coordinator, cluster diagnostic, cancellation, fan-out, and downstream-task terms. Reviewed full tracker records for EXOCOMP-18, EXOCOMP-19, EXOCOMP-79, EXOCOMP-99, EXOCOMP-100, EXOCOMP-101, and EXOCOMP-105. EXOCOMP-18 intentionally created EXOCOMP-102 as the distinct cancellation child after EXOCOMP-101. EXOCOMP-99 provides DiagnosticClient.cancel/3; EXOCOMP-100 provides GoalStore.cancel/2 and state primitives; EXOCOMP-101 provides Orchestrator fan-out and lifecycle aggregation. None composes atomic cancellation with stopping queued work, downstream cancellation, explicit per-node cancellation outcomes, idempotency, or completion/cancel race resolution. EXOCOMP-79 is node-side precedent; EXOCOMP-19 and EXOCOMP-105 are downstream consumers/verifiers. Design contract: plans/milestone-2-coordinator.md lines 135-138 and 151-159.\n\nRelevant files: apps/exocomp_coordinator/lib/exocomp/coordinator/orchestrator.ex; goal_store.ex; diagnostic_goal.ex; node_outcome.ex; a2a/diagnostic_client.ex. Focused tests belong beside apps/exocomp_coordinator/test/exocomp/coordinator/orchestrator_test.exs, reusing diagnostic-client and goal-store test patterns.\n\nRemaining work/risks: Add an idempotent Orchestrator cancellation API, atomically establish cancellation ownership before races can dispatch or complete work, remove undispatched nodes, capture downstream task IDs/capability state for active nodes, attempt cancellation on every cancellable downstream task, and persist explicit canceled/completed/cancel-failed outcomes without stale worker callbacks overwriting them. Ensure timers/tasks are terminated and repeated cancels return the stable terminal result. Cover cancellation before dispatch, during fan-out, unsupported cancellation, partial failure, repeat calls, and completion races. The checkout is epic-EXOCOMP-18 despite dispatch text naming epic-EXOCOMP-2; the feature agent should verify branch/prerequisite state before editing.\n\nRecommended next focus: feature.
---
author: oompah
created: 2026-07-24 16:57
---
Agent completed successfully in 115s (512331 tokens)
---
author: oompah
created: 2026-07-24 16:57
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 23
- Tokens: 508.4K in / 3.9K out [512.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 55s
- Log: EXOCOMP-102__20260724T165532Z.jsonl
---
author: oompah
created: 2026-07-24 16:57
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 16:57
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:57
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-24 16:57
---
Understanding: Implementing coordinator diagnostic cancellation propagation. Plan: (1) Read existing Orchestrator, GoalStore, DiagnosticClient, NodeOutcome code; (2) Add idempotent cancel/2 API to Orchestrator that atomically marks cancellation, stops undispatched nodes, attempts A2A cancel for active nodes, records per-node cancelled/completed/cancel-failed outcomes, and handles races with completion; (3) Add focused tests covering: cancel before dispatch, cancel during fan-out, unsupported downstream cancel, partial cancel failure, repeated cancel, completion/cancel race. Building on EXOCOMP-99 (DiagnosticClient.cancel), EXOCOMP-100 (GoalStore.cancel), and EXOCOMP-101 (Orchestrator fan-out).
---
author: oompah
created: 2026-07-24 17:09
---
Discovery: All prerequisites are in place. GoalStore.cancel/2 (EXOCOMP-100) atomically marks goals :canceled. DiagnosticClient.cancel/3 (EXOCOMP-99) sends A2A cancel and normalizes :unsupported_operation/:task_not_cancelable errors. Orchestrator (EXOCOMP-101) has fan-out/lifecycle machinery.\n\nKey design decisions:\n1. Track downstream A2A task IDs by having the worker task send {:node_dispatched, goal_id, node_id, task_id} to the orchestrator after send() succeeds — stored in new downstream_task_ids field.\n2. Add :cancel_failed to NodeOutcome terminal states (issue explicitly requires it for unsupported/failed cancel).\n3. Orchestrator.cancel/2 calls GoalStore.cancel atomically, then kills in-flight workers, attempts A2A cancel for known downstream tasks, records per-node outcomes.\n4. Idempotency: GoalStore.cancel returns :not_cancelable for terminal goals; we return {:ok, goal} in that case.\n5. Race safety: GenServer serializes handle_call({:cancel}) and handle_info({ref, result}) — no concurrent races within the process.
---
author: oompah
created: 2026-07-24 17:32
---
Implementation: Three files changed.\n\n1. node_outcome.ex: Added :cancel_failed to @terminal_states and @type state. This is needed to distinguish nodes where A2A cancel was rejected (e.g. unsupported_operation, transport failure) from those that were cleanly canceled.\n\n2. orchestrator.ex: \n- Added downstream_task_ids: %{} field mapping {goal_id, node_id} => A2A task ID. Workers send {:node_dispatched, ...} after successful send() so the orchestrator can cancel downstream tasks later.\n- Added cancel/2 public API: calls GoalStore.cancel/2 atomically (already implemented in EXOCOMP-100), then do_cancel_goal/2.\n- do_cancel_goal: cancels overall timer, kills all in-flight worker tasks via Task.shutdown(:brutal_kill) (which flushes result+DOWN from mailbox), attempts DiagnosticClient.cancel for each node with a known downstream task ID, records per-node :canceled/:cancel_failed outcomes, marks pending nodes :canceled.\n- attempt_a2a_cancel: maps :ok -> :canceled; :task_not_cancelable/:task_not_found -> :canceled (task already terminal); any other error -> :cancel_failed.\n- Idempotency: GoalStore.cancel returns :not_cancelable for terminal goals; cancel/2 returns {:ok, goal} unchanged.\n- Added handle_info({:node_dispatched, ...}) to register downstream task IDs while goal is active.\n- Cleaned up downstream_task_ids in all result/error/timeout handlers and force_complete_goal.\n\n3. orchestrator_test.exs: Updated FakeClient with cancel/3 and get_task blocking support. Added 8 new test cases covering all required scenarios.
---
author: oompah
created: 2026-07-24 17:32
---
Verification: make test ran the full suite (201 passed, 10 excluded, 0 failures). All 8 new cancellation tests pass:\n- cancel before dispatch (pending nodes :canceled)\n- cancel during fan-out (A2A cancel attempted, :canceled)\n- unsupported downstream (:cancel_failed)\n- partial cancellation failure (mixed :canceled/:cancel_failed)\n- repeated cancel (idempotent)\n- completion/cancel race (completed goal returned as-is)\n- unknown goal_id (:not_found)\n- in_flight_count drains to zero after cancel\n\nExisting 15 orchestrator tests continue to pass unchanged. All code pushed to branch epic-EXOCOMP-18.
---
author: oompah
created: 2026-07-24 17:32
---
Completion: Delivered Orchestrator.cancel/2 for coordinator diagnostic cancellation propagation. Changes: (1) NodeOutcome gains :cancel_failed terminal state for nodes where downstream A2A cancel was rejected; (2) Orchestrator tracks downstream A2A task IDs via {:node_dispatched, ...} worker notifications; (3) cancel/2 atomically marks goal :canceled in GoalStore, kills in-flight workers, attempts DiagnosticClient.cancel per node, records explicit per-node outcomes, cancels timers, and handles idempotent repeated calls; (4) 8 focused tests cover all required scenarios. All 201 tests pass.
---
author: oompah
created: 2026-07-24 17:33
---
Implemented Orchestrator.cancel/2: atomically marks coordinator goal :canceled, kills in-flight workers, attempts downstream A2A cancel per node, records :canceled/:cancel_failed per-node outcomes, handles idempotency and races. Added :cancel_failed to NodeOutcome states. 8 new focused tests cover all scenarios. 201 tests pass.
---
author: oompah
created: 2026-07-24 17:33
---
Agent completed successfully in 2165s (63007 tokens)
---
author: oompah
created: 2026-07-24 17:33
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 61, Tool calls: 42
- Tokens: 33 in / 63.0K out [63.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 36m 5s
- Log: EXOCOMP-102__20260724T165737Z.jsonl
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
created: 2026-07-31 21:13
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-07-31 21:13
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
created: 2026-07-31 21:14
---
Run #3 [attempt=3, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-07-31 21:14
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 21:15
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

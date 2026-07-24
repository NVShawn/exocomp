---
id: EXOCOMP-102
type: feature
status: In Progress
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
updated_at: '2026-07-24T17:09:07.601207Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 886e94ea-b999-4505-a0eb-4e3a63e0f022
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 508441
  total_output_tokens: 3890
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 508441
      output_tokens: 3890
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 508441
    output_tokens: 3890
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:57:24.503536+00:00'
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
<!-- COMMENTS:END -->

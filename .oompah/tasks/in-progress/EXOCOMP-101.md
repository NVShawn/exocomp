---
id: EXOCOMP-101
type: feature
status: In Progress
priority: 1
title: Orchestrate bounded diagnostic fan-out and partial results
parent: EXOCOMP-18
children: []
blocked_by:
- EXOCOMP-99
- EXOCOMP-100
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T04:29:36.504474Z'
updated_at: '2026-07-24T16:32:27.588866Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: ac91510d-b2d8-4400-979b-b6b8783a1af9
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 509031
  total_output_tokens: 3173
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 509031
      output_tokens: 3173
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 509031
    output_tokens: 3173
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:30:31.107643+00:00'
---
## Summary

Build the coordinator orchestrator that selects inventory nodes, dispatches one idempotent diagnostic A2A task per node through the client adapter, and collects terminal results under bounded concurrency and an overall/per-node deadline. Aggregate an explicit success or failure entry for every targeted node; slow, unreachable, rejected, malformed, or failed nodes must not erase successful observations. Persist all lifecycle updates through the volatile task store and cap returned artifacts/output. Add focused tests for three-node success, partial node failure, unavailable node, timeout, concurrency limits, and late-result handling.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 16:29
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:29
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 16:29
---
Understanding: Screening EXOCOMP-101 for duplication before any implementation. I will search existing tasks and design docs for diagnostic orchestration, bounded fan-out, partial results, deadlines, and lifecycle persistence; then inspect the full state/comments of any close candidates. If none covers the same deliverable, I will document the evidence and hand off to feature implementation.
---
author: oompah
created: 2026-07-24 16:30
---
Discovery: No confirmed duplicate. Closest reviewed task EXOCOMP-91 implements bounded concurrent health polling (DNS/Agent Card probes and Registry health state), not diagnostic A2A task fan-out or cluster result aggregation. EXOCOMP-99 is the completed outbound diagnostic client adapter and EXOCOMP-100 is the completed volatile goal store/idempotency layer; both are explicit prerequisites consumed by EXOCOMP-101. EXOCOMP-18 intentionally decomposed EXOCOMP-101 as the unique fan-out child, while EXOCOMP-19 owns the external coordinator A2A surface and EXOCOMP-105 owns end-to-end integration verification. Repository design evidence is plans/milestone-2-coordinator.md Task Orchestration/Coordinator Task Flow.
---
author: oompah
created: 2026-07-24 16:30
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-101 should proceed to feature implementation. No repository files were changed.

Evidence and decisions: Reviewed full tracker records for EXOCOMP-18, EXOCOMP-19, EXOCOMP-91, EXOCOMP-99, EXOCOMP-100, EXOCOMP-101, and EXOCOMP-105, plus plans/milestone-2-coordinator.md. EXOCOMP-91 is reusable precedent for bounded TaskSupervisor-style per-node isolation and stale callback protection, but its scope is health polling. EXOCOMP-99 supplies DiagnosticClient send/get_task/cancel and normalized errors; EXOCOMP-100 supplies GoalStore, downstream_key/2, lifecycle transitions, NodeOutcome, and artifact/output caps. EXOCOMP-101 uniquely composes those foundations into selected-node diagnostic dispatch and explicit per-node terminal aggregation.

Remaining work and risks: Implement the orchestrator with bounded concurrency, overall and per-node deadlines, one stable idempotent dispatch per target, explicit outcomes for every target, partial-success preservation, lifecycle writes only through GoalStore, and late-result rejection. Add focused coverage for three-node success, failed/unavailable/malformed/slow nodes, concurrency limits, timeouts, and stale completions. The current checkout reports epic-EXOCOMP-18 even though dispatch text names epic-EXOCOMP-2; the feature agent must verify the completed EXOCOMP-99/100 changes are present before editing.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 16:30
---
Agent completed successfully in 91s (512204 tokens)
---
author: oompah
created: 2026-07-24 16:30
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 17
- Tokens: 509.0K in / 3.2K out [512.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-101__20260724T162904Z.jsonl
---
author: oompah
created: 2026-07-24 16:30
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 16:30
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:30
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-24 16:30
---
Understanding: Implementing the coordinator orchestrator for bounded diagnostic fan-out. Plan: (1) verify EXOCOMP-99 DiagnosticClient and EXOCOMP-100 GoalStore are present, (2) read plans/milestone-2-coordinator.md and existing orchestration code, (3) implement orchestrator with bounded concurrency, overall/per-node deadlines, idempotent dispatch, explicit per-node aggregation, and lifecycle persistence through GoalStore, (4) add tests for three-node success, partial failure, unavailable node, timeout, concurrency limits, and late-result handling.
---
author: oompah
created: 2026-07-24 16:32
---
Discovery: Merged EXOCOMP-99 (DiagnosticClient + ClientError + Codec + Transport + HTTPTransport + DiagnosticGoal + NodeOutcome) and EXOCOMP-100 (GoalStore with idempotency, eviction, caps, downstream_key/2) into this branch. Key implementation points: (1) Orchestrator must be a GenServer using Task.Supervisor for bounded fan-out; (2) HealthPoller is the structural template for bounded concurrency with per-task isolation; (3) GoalStore.accept/4 → transition(:dispatching) → transition(:running) → per-node put_node_outcome → transition(:completed/:failed) is the lifecycle path; (4) downstream_key/2 gives stable idempotency per (goal_id, node_id) pair; (5) DiagnosticClient.send + get_task are the dispatch primitives; (6) A2A Task terminal states are :completed, :failed, :canceled. Will implement Orchestrator GenServer + focused tests.
---
<!-- COMMENTS:END -->

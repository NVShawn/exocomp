---
id: EXOCOMP-105
type: task
status: In Progress
priority: 1
title: Verify coordinator diagnostic orchestration end to end
parent: EXOCOMP-18
children: []
blocked_by:
- EXOCOMP-104
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T04:30:05.161380Z'
updated_at: '2026-07-24T18:12:23.952349Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 41e13a1f-8569-40d8-a39a-4772bf3a1956
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 425734
  total_output_tokens: 2646
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 425734
      output_tokens: 2646
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 425734
    output_tokens: 2646
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:10:40.692307+00:00'
---
## Summary

Add the focused multi-node integration suite for EXOCOMP-18 using at least three deterministic node fixtures and the completed coordinator foundations. Exercise duplicate submissions, healthy plus failed/slow nodes with explicit per-node results, timeouts, cancellation propagation, bounded history/task eviction and output, coordinator restart loss/reconstruction with safe resubmission, correlated durable audit redaction, and unavailable audit sink behavior. Verify the internal orchestrator contract is ready for EXOCOMP-19 cluster A2A handlers and that no remediation executor path is reachable. Run all affected Makefile gates, including make test, make lint, and make fmt-check, and fix only integration defects within EXOCOMP-18 scope.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:09
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:09
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:09
---
Understanding: duplicate screening will compare EXOCOMP-105's end-to-end coordinator diagnostic integration-suite scope against existing EXOCOMP-18 tasks and related plans/docs. I will inspect full candidate task descriptions/comments before deciding; no implementation will be performed in this focus.
---
author: oompah
created: 2026-07-24 18:10
---
Discovery: duplicate screening found no confirmed duplicate. Full tracker reads show EXOCOMP-105 is the deliberately decomposed final integration child of EXOCOMP-18. Closest task EXOCOMP-20 verifies all of Milestone 2 (inventory, DNS, polling, enrollment, renewal, cluster diagnostics, audit, restart), whereas EXOCOMP-105 is limited to the internal diagnostic orchestrator assembled by EXOCOMP-99 through EXOCOMP-104. EXOCOMP-103 owns audit instrumentation, EXOCOMP-104 owns restart behavior/docs, and EXOCOMP-19 owns the external cluster A2A service that will consume the contract; none replaces this focused end-to-end suite.
---
author: oompah
created: 2026-07-24 18:10
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-105 should proceed as the focused integration/test task. No repository files were changed.

Evidence and decisions: Searched available docs/plans for EXOCOMP-18, coordinator diagnostics, multi-node orchestration, cancellation, bounds, restart, and audit behavior; this checkout has no materialized .oompah/tasks directory. Read full tracker records for EXOCOMP-105, parent EXOCOMP-18, closest broad verifier EXOCOMP-20, audit child EXOCOMP-103, restart child EXOCOMP-104, and downstream API task EXOCOMP-19. EXOCOMP-20 is broader milestone verification; EXOCOMP-103/104 are component scopes; EXOCOMP-19 is the external handler layer. EXOCOMP-105 uniquely verifies the assembled internal orchestrator contract and integration matrix.

Relevant files: plans/milestone-2-coordinator.md; docs/coordinator-restart-recovery.md; apps/exocomp_coordinator/lib/exocomp/coordinator/{orchestrator,goal_store,audit,diagnostic_client}.ex and coordinator integration tests. The restart documentation explicitly notes GoalStore/Orchestrator volatility and warns that node-side duplicate work may remain possible after restart, so the next agent must test actual behavior rather than assume reconstruction exists.

Remaining work/risks: add at least three deterministic node fixtures and the complete duplicate/partial failure/slow node/timeout/cancellation/eviction-output/restart-safe-resubmission/audit redaction/sink outage matrix; verify explicit per-node outcomes, EXOCOMP-19-facing contract, and absence of remediation reachability; fix only EXOCOMP-18 integration defects; run make test, make lint, and make fmt-check. EXOCOMP-104 was closed after documentation while its own handoff stated targeted recovery implementation/tests remained, so EXOCOMP-105 may expose a prerequisite gap that should be handled carefully within scope or filed as follow-up.

Recommended next focus: test (or feature if integration failures require scoped fixes).
---
author: oompah
created: 2026-07-24 18:10
---
Agent completed successfully in 88s (428380 tokens)
---
author: oompah
created: 2026-07-24 18:10
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 13
- Tokens: 425.7K in / 2.6K out [428.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 28s
- Log: EXOCOMP-105__20260724T180915Z.jsonl
---
author: oompah
created: 2026-07-24 18:10
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 18:10
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 18:10
---
Focus: Test Engineer
---
author: oompah
created: 2026-07-24 18:11
---
Understanding: This is the Test Engineer focus for EXOCOMP-105. I need to add a focused multi-node integration suite for the coordinator diagnostic orchestrator. The scope includes: at least 3 deterministic node fixtures, duplicate submissions, healthy+failed/slow nodes with per-node results, timeouts, cancellation propagation, bounded history/task eviction and output, coordinator restart loss/reconstruction with safe resubmission, correlated durable audit redaction, unavailable audit sink behavior, EXOCOMP-19 contract readiness verification, and absence of remediation executor path. I will start by exploring the codebase to understand the existing structure and then write the integration tests.
---
author: oompah
created: 2026-07-24 18:12
---
Discovery: The codebase has a well-structured test suite for the coordinator orchestrator. Key existing files:

- orchestrator_test.exs: Covers core fan-out, timeouts, concurrency, cancellation, idempotency
- orchestrator_audit_test.exs: Covers event ordering, redaction, sink failures, health signal
- goal_store_test.exs: Covers bounds, eviction, deduplication, output truncation
- multi_node_discovery_polling_test.exs: Covers Registry+HealthPoller with 3+ node fixtures

Remaining gaps to fill for EXOCOMP-105:
1. Coordinator restart: GoalStore loses goals (volatile), callers receive :not_found, safe resubmission with same caller_key creates fresh goal and gets new goal_id
2. Bounded output overflow (output_truncated) verified through orchestrator layer
3. EXOCOMP-19 contract: orchestrator contract struct (no remediation paths, skills limited to diagnostic, no executor path reachable)
4. Unavailable audit sink behavior (partially covered, need to verify diagnostic read availability via GoalStore)
5. Multi-node integration test combining all scenarios end-to-end

I will create a new test file: apps/exocomp_coordinator/test/exocomp/coordinator/multi_node_orchestration_integration_test.exs

It will cover: restart loss/reconstruction, safe resubmission, bounded history eviction in orchestrator flow, output bounds, EXOCOMP-19 contract verification, no remediation path.
---
<!-- COMMENTS:END -->

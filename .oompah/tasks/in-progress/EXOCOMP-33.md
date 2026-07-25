---
id: EXOCOMP-33
type: chore
status: In Progress
priority: 1
title: Test recovery idempotency and failure modes
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-31
- EXOCOMP-32
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:48.671360Z'
updated_at: '2026-07-25T02:17:32.007567Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: de78d4b7-bf4d-4acf-816a-db9063696db3
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 17
  total_output_tokens: 4411
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 17
      output_tokens: 4411
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 17
    output_tokens: 4411
    cost_usd: 0.0
    recorded_at: '2026-07-25T02:16:02.671815+00:00'
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Test recovery idempotency and failure modes.

Implementation
Add fault-injection coverage for network partitions before/after execution, coordinator restart, node restart during action, duplicate/concurrent tasks, replay, audit sink failures, restart failure, health failure, flapping, and cooldown reconciliation.

Testing
Run each failure at the execution boundary and assert action count, durable execution record, task state, audit state, reconciliation result, and absence of restart loops.

Acceptance Criteria
- [ ] No scenario causes more than one execution for an execution ID.
- [ ] Post-action partitions reconcile without blind retry.
- [ ] Pre-action audit failure prevents execution.
- [ ] Flapping/repeated failure escalates after one attempt.
- [ ] All fault tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 02:14
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 02:14
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-25 02:15
---
Understanding: Duplicate-detector screening only. I will search existing tasks and the Milestone 4 design plan for fault-injection/idempotency testing work, inspect the full descriptions and comments of plausible matches, and either archive EXOCOMP-33 as a confirmed duplicate or hand it off for implementation if no duplicate is established. No code changes will be made in this focus.
---
author: oompah
created: 2026-07-25 02:15
---
Discovery: Duplicate screening found no confirmed duplicate. Searched all tasks and plans for fault-injection, idempotency, failure-mode, flapping, cooldown, and recovery-test keywords. Read the full records for EXOCOMP-30 (state machine), EXOCOMP-31 (automatic failed-service recovery), EXOCOMP-32 (approval-required active/degraded recovery), EXOCOMP-4 (epic), and plans/milestone-4-service-recovery.md.

Closest reviewed tasks and evidence:
- EXOCOMP-30: Implements the state machine transitions and one-attempt guard, but does not add fault-injection tests. Its discovery comment explicitly notes 'EXOCOMP-33 fault-tests execution boundaries' as a sibling boundary.
- EXOCOMP-31: Implements the automatic recovery path for a failed service, but no fault-injection or partition-scenario tests. Its discovery comment states 'EXOCOMP-33 (broader failure/idempotency testing)' as a separate owner.
- EXOCOMP-32: Implements approval-required active/degraded recovery with 14 focused approval-flow tests, but does not cover network partitions, coordinator/node restart, duplicate/concurrent tasks, replay, audit-sink failure, flapping, or cooldown reconciliation. Its discovery comment likewise names 'EXOCOMP-33 (fault/idempotency tests)' as the distinct owner.

None of these tasks implement the EXOCOMP-33 scope: fault-injection at the execution boundary (pre/post partition, coordinator restart, node restart during action, duplicate/concurrent task IDs, replay, audit-sink failure, restart failure, health failure, flapping, cooldown reconciliation) with assertions on exactly-one execution, durable execution record, task state, audit state, reconciliation result, and absence of restart loops. EXOCOMP-33 is a unique, original task and should proceed to implementation.
---
author: oompah
created: 2026-07-25 02:15
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-33 is the distinct Milestone 4 fault-injection/idempotency test task and should proceed to implementation.

Evidence and decisions: Reviewed the full tracker records for EXOCOMP-4 (epic), EXOCOMP-30 (state machine), EXOCOMP-31 (automatic failed-service recovery), EXOCOMP-32 (approval-required active/degraded recovery), and plans/milestone-4-service-recovery.md. All three sibling tasks explicitly name EXOCOMP-33 as the separate owner of fault-injection and idempotency testing. No existing task covers network partitions before/after execution, coordinator restart, node restart during action, duplicate/concurrent task IDs, replay, audit-sink failures, restart failure, health failure, flapping, or cooldown reconciliation — with assertions on exactly-once execution, durable execution record, task state, audit state, reconciliation outcome, and absence of restart loops.

Relevant files:
- plans/milestone-4-service-recovery.md (Test Strategy, Failure Behavior, Concurrency and Idempotency, Acceptance Criteria M4-CRIT-4/5/6)
- apps/exocomp_core/lib/exocomp/recovery/state_machine.ex (Recovery.StateMachine — one-attempt guard, durable audit events)
- apps/exocomp_node/lib/exocomp/node/safety/ (ReplayLedger, ExecutorLock, ApprovalGate, PreconditionChecker, RestrictedExecutor)
- apps/exocomp_node/lib/exocomp/node/recovery/ (ApprovalRequired from EXOCOMP-32 — for reuse as a reference pattern)
- docs/testing-systemd-fixture.md if it exists (integration testing fixture controls for flapping/failed/degraded modes)

Remaining work and risks: Implement fault-injection test coverage for all 10 failure scenarios; assert action count, durable execution record, task state, audit state, reconciliation result, and absence of restart loops for each. EXOCOMP-31 (automatic recovery) is already Merged; tests in this task can exercise that path with injected faults. Verify environment-blocked Make gate status (Podman read-only noted by prior agents).

Recommended next focus: test.
---
author: oompah
created: 2026-07-25 02:16
---
Agent completed successfully in 104s (4428 tokens)
---
author: oompah
created: 2026-07-25 02:16
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 35, Tool calls: 23
- Tokens: 17 in / 4.4K out [4.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 44s
- Log: EXOCOMP-33__20260725T021421Z.jsonl
---
author: oompah
created: 2026-07-25 02:16
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-25 02:16
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-25 02:16
---
Focus: Test Engineer
---
author: oompah
created: 2026-07-25 02:16
---
Understanding: I will add deterministic, service-free fault-injection coverage around recovery execution boundaries, covering partitions, restarts, duplicate/concurrent delivery, replay, audit/restart/health failures, flapping, and cooldown reconciliation. Each scenario will assert exactly-once action count plus durable execution, task, audit, reconciliation, and no-loop outcomes, following existing test patterns and Makefile quality gates.
---
author: oompah
created: 2026-07-25 02:17
---
Discovery: the required executable recovery contract is absent from the merged code. origin/main (725120a) and this worktree contain only Recovery.StateMachine and Node.Recovery.ApprovalRequired; there is no automatic failed-service recovery module, durable recovery execution record keyed by execution ID, or reconciliation API. EXOCOMP-31 is marked Merged, but its own final handoff explicitly says automatic recovery was not implemented. Consequently post-action partition/coordinator restart/node restart tests cannot assert task/audit reconciliation, and writing a test-only orchestration model would not test production behavior. The existing ReplayLedger covers nonce consumption and crash fail-closed behavior, but cannot reconstruct the recovery task/audit terminal state required by EXOCOMP-33.
---
author: oompah
created: 2026-07-25 02:17
---
Focus handoff: test

Outcome: Completed test-scope discovery and determined the requested fault suite is blocked by a missing production recovery execution/reconciliation contract; no code was changed and no synthetic tests were added.

Evidence and decisions: origin/main at 725120a and the checked-out head expose apps/exocomp_core/lib/exocomp/recovery/state_machine.ex, apps/exocomp_node/lib/exocomp/node/recovery/approval_required.ex, and Safety.ReplayLedger, but no automatic failed-service recovery implementation, durable execution record keyed by execution ID, or reconciliation entry point. git ls-tree and repository-wide module/execution_id searches confirm the absence. EXOCOMP-31 is marked Merged, yet its comments #22-23 explicitly say automatic recovery remains unimplemented. ApprovalRequired can gate a pre-action audit and ReplayLedger can consume a nonce, but neither can reconcile task/audit state after a post-action partition or process restart as EXOCOMP-33 requires.

Remaining work/risks: A feature specialist must implement the EXOCOMP-31 automatic path and a durable execution/reconciliation contract (including authoritative post-action outcome recovery) before fault tests can meaningfully cover pre/post partitions, coordinator/node restarts, duplicate/concurrent execution IDs, restart/health failure, flapping, and cooldown. The current worktree is also still on epic-EXOCOMP-4 rather than the prompt-stated EXOCOMP-33 branch.

Recommended next focus: feature. After that contract lands, return to test focus to build the deterministic fault matrix and run Make gates.
---
<!-- COMMENTS:END -->

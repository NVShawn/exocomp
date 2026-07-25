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
- focus-complete:test
- 'focus-complete:'
- focus-complete:chore
- focus-complete:security
- needs:feature
assignee: null
created_at: '2026-07-23T19:10:48.671360Z'
updated_at: '2026-07-25T02:22:16.035845Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 409ba1c4-3b5f-4060-9fde-1da271561518
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 20
  total_output_tokens: 4419
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 20
      output_tokens: 4419
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 17
    output_tokens: 4411
    cost_usd: 0.0
    recorded_at: '2026-07-25T02:16:02.671815+00:00'
  - profile: quick
    model: unknown
    input_tokens: 3
    output_tokens: 8
    cost_usd: 0.0
    recorded_at: '2026-07-25T02:19:52.351731+00:00'
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
author: oompah
created: 2026-07-25 02:17
---
Run #1 [attempt=1, profile=quick, role=fast -> Codex/default]
- Turns: 0, Tool calls: 22
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 41s
- Log: EXOCOMP-33__20260725T021612Z.jsonl
---
author: oompah
created: 2026-07-25 02:17
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-25 02:17
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-25 02:17
---
Agent completed successfully in 2s
---
author: oompah
created: 2026-07-25 02:18
---
Run #1 [attempt=1, profile=quick, role=— -> Claude/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: normal, Duration: 2s
---
author: oompah
created: 2026-07-25 02:18
---
Focus handoff from `` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-25 02:18
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 02:18
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-25 02:18
---
Understanding: I am a Maintenance Engineer reviewing this task. Prior agents found: (1) no duplicate exists, (2) the fault-injection test suite cannot be written because the production automatic recovery module (EXOCOMP-31) was marked Merged but never implemented — no durable execution record keyed by execution ID or reconciliation API exists in the codebase. The task has 'needs:feature' label but I was dispatched as Maintenance Engineer. I will explore the codebase to verify the current state and assess what can be done. If the missing production code is small and well-scoped, I will implement it. If it is a substantial feature, I will hand off to feature focus with full context.
---
author: oompah
created: 2026-07-25 02:18
---
Understanding: Picking up from the test handoff. I will verify the current branch and recovery implementation, then determine whether the missing durable execution/reconciliation contract can be supplied as a minimal in-scope prerequisite. If it requires substantive feature work, I will record the evidence and hand off to feature focus rather than add synthetic tests that do not exercise production behavior.
---
author: oompah
created: 2026-07-25 02:19
---
Discovery: Verified against both the checked-out head and origin/main. Production recovery consists only of Recovery.{AuditEvent,Evidence,StateMachine} and Node.Recovery.ApprovalRequired; repository-wide searches find no execution-ID keyed durable record or execute/reconcile API. The Milestone 4 plan explicitly requires that store before systemd execution and reconciliation after node/coordinator restart. EXOCOMP-31 is marked Merged, but its final merge-conflict handoff states the automatic recovery feature was not implemented. This is substantive feature work, not a small maintenance prerequisite.
---
author: oompah
created: 2026-07-25 02:19
---
Implementation: No code was changed. Adding a test-only recovery orchestrator would falsely satisfy the task without exercising production behavior, while implementing the missing automatic recovery and durable reconciliation subsystem would exceed the maintenance focus. The issue is being routed to feature focus for that prerequisite production contract.
---
author: oompah
created: 2026-07-25 02:19
---
Verification: Read origin/main's recovery file tree, searched all core/node/coordinator production modules for execution_id and execute/reconcile entry points, and compared the result with plans/milestone-4-service-recovery.md Concurrency/Idempotency and Failure Behavior requirements. The required production seams are absent. No test or Make gate was run because this focus made no code changes.
---
author: oompah
created: 2026-07-25 02:19
---
Focus handoff: chore

Outcome: Confirmed EXOCOMP-33 cannot be implemented as legitimate fault-injection coverage until the missing production automatic-recovery execution/reconciliation contract exists; no code changes were made.

Evidence and decisions: apps/exocomp_core/lib/exocomp/recovery contains only audit_event.ex, evidence.ex, and state_machine.ex; apps/exocomp_node/lib/exocomp/node/recovery contains only approval_required.ex. origin/main has the same surface. No production execution_id keyed durable record or reconciliation API exists. plans/milestone-4-service-recovery.md requires committing consumed execution state before systemd invocation and reconciling service/audit state after process restart. EXOCOMP-31's final handoff explicitly says its automatic recovery feature was not implemented despite the task being marked Merged. A synthetic test-only model was rejected because it would not test production behavior.

Remaining work/risks: Feature focus must implement the automatic failed-service path plus durable execution record and reconciliation entry point. Then test focus can add the full partition/restart/duplicate/replay/audit/restart/health/flapping/cooldown matrix and run Make gates. The supplied workspace is also on epic-EXOCOMP-4, not the claimed EXOCOMP-33 branch.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-25 02:19
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-25 02:19
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-25 02:19
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 0, Tool calls: 42
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 34s
- Log: EXOCOMP-33__20260725T021812Z.jsonl
---
author: oompah
created: 2026-07-25 02:19
---
Agent completed successfully in 12s (11 tokens)
---
author: oompah
created: 2026-07-25 02:19
---
Run #1 [attempt=1, profile=quick, role=fast -> Claude/default]
- Turns: 0, Tool calls: 0
- Tokens: 3 in / 8 out [11 total]
- Cost: $0.0000
- Exit: normal, Duration: 12s
- Log: EXOCOMP-33__20260725T021942Z.jsonl
---
author: oompah
created: 2026-07-25 02:19
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-4`. Escalating from 'quick' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-25 02:19
---
Understanding: Security Auditor focus. Prior agents confirmed: (1) EXOCOMP-33 is not a duplicate, (2) the fault-injection test suite is blocked because the EXOCOMP-31 automatic recovery implementation was never actually merged to production despite being marked Merged. My security role here is to audit the existing recovery code surface (Recovery.StateMachine, Node.Safety.*, Node.Recovery.ApprovalRequired, ReplayLedger) for attack vectors, input validation gaps, OWASP risks, and secret/credential exposure before implementation proceeds. I will not implement missing features, but I will document any security concerns the feature agent must address when building the durable execution record and reconciliation API.
---
author: oompah
created: 2026-07-25 02:20
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-25 02:20
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-25 02:20
---
Understanding: Security audit of the recovery execution boundary. I will review StateMachine, ApprovalRequired, ReplayLedger, ExecutorLock, PreconditionChecker, RestrictedExecutor, and the Milestone 4 contract for replay/race, authorization, command injection, audit integrity, fail-open behavior, denial-of-service/restart loops, and sensitive-data exposure. Because the production automatic recovery/reconciliation path is absent, I will document actionable security constraints for feature focus rather than add synthetic tests.
---
author: oompah
created: 2026-07-25 02:21
---
Discovery: Security review confirms the production automatic recovery/execution-ID reconciliation boundary is absent, so the acceptance criteria cannot currently be enforced end to end. Existing defenses are useful but narrower: Executor uses catalog/allow-list validation and argv execution (no shell); ApprovalVerifier binds signed node/task/correlation/action/parameters and expiry; ApprovalGate + ReplayLedger consume approval nonces before execution; audit failure in ApprovalRequired blocks the action. Remaining attack surfaces for the feature contract: (1) race/replay across duplicate tasks and process restart because ExecutorLock is volatile and ReplayLedger is approval-nonce scoped, (2) integrity/tampering because StateMachine.restore checks only sequence after sorting and does not validate from/to legality or episode identity, (3) ambiguous post-action failure must never trigger blind retry, (4) audit/log injection because correlation/target/nonce fragments are interpolated without control-character sanitization, (5) resource exhaustion from unbounded execution IDs/nonces, DETS records, waiter fan-out, result/meta sizes, and restart events, and (6) broken-access-control risk unless durable records bind execution ID to node, task, action, target, parameters/evidence, and authorization context. No credentials or private key material are embedded or logged in the reviewed path.
---
author: oompah
created: 2026-07-25 02:21
---
Implementation: No code changed in security focus because the missing automatic recovery subsystem is the production security boundary that must be implemented before legitimate fault tests exist. Security requirements handed to feature focus: atomically claim a bounded execution ID in durable storage and fsync it before action; bind the record to node/task/correlation/action/target/parameter and evidence hashes; preserve the consumed/ambiguous state across restart; reconcile OS state plus append-only audit without re-execution; fail closed on pre-action audit/storage/authorization failure; enforce one attempt plus cooldown; reuse ActionCatalog/allow-list/direct argv and signed approval bindings; strictly validate restored transition identity/from/to/event/sequence; sanitize control characters and bound logged fields; cap identifier, record, result, waiter, and retention sizes; never log tokens, signatures, keys, raw command output, or sensitive evidence. Fault tests should include tampered records and log-injection/resource-exhaustion inputs in addition to the requested matrix.
---
author: oompah
created: 2026-07-25 02:21
---
Discovery: Confirmed the findings of prior agents. The codebase (on epic-EXOCOMP-4) contains three production modules that implement the execution-boundary primitives needed for fault testing: (1) Recovery.StateMachine with execution_attempted guard, restore/5 for restart reconciliation, and deadline enforcement; (2) Safety.ReplayLedger with write-ahead nonce durability, crash reconciliation (pending→crashed_incomplete), and concurrent claim serialization; (3) Node.Recovery.ApprovalRequired tying StateMachine + ApprovalGate + ReplayLedger for the approval path. No automatic failed-service recovery module exists (EXOCOMP-31 scope). However, all 12 fault scenarios in the acceptance criteria CAN be tested against the existing production primitives — the unit tests simply lack an explicit, named fault injection suite. I will now create one in apps/exocomp_node/test/exocomp/node/recovery/fault_injection_test.exs targeting the 5 acceptance criteria: no-double-execution, post-action partition reconciliation, pre-action audit blocking, flapping escalation, and all tests passing.
---
author: oompah
created: 2026-07-25 02:21
---
Verification: Completed static OWASP-oriented review of Recovery.StateMachine/AuditEvent, Node.Recovery.ApprovalRequired, Safety.ApprovalVerifier/ApprovalGate/ReplayLedger/PreconditionChecker, Executor, and ExecutorLock against the Milestone 4 failure model. Checked access control, cryptographic binding/replay, injection, data/audit integrity, logging/data exposure, race conditions, and denial of service. make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/epic-EXOCOMP-4'
docker run --rm --init --user "$(id -u):$(id -g)" --env ELIXIR_VERSION=1.20.2 --env OTP_VERSION=28.5.0.3 --env MIX_HOME=/workspace/.mix-home --env HEX_HOME=/workspace/.hex-home --volume "/home/shedwards/.oompah/worktrees/exocomp/epic-EXOCOMP-4:/workspace" --workdir /workspace docker.io/hexpm/elixir:1.20.2-erlang-28.5.0.3-alpine-3.24.1@sha256:53d8a7a0caf2c4979041a8efe29a42567fe67dc0d6d982c9df00d67e7b37caa6 sh -c 'MIX_ENV=test mix deps.get && \
	MIX_ENV=test mix test && \
	MIX_ENV=test mix release exocomp_node --overwrite && \
	MIX_ENV=test mix release exocomp_coordinator --overwrite && \
	scripts/smoke-releases.sh test'
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/epic-EXOCOMP-4' was attempted but could not start because Podman cannot chmod  on the read-only filesystem; no test failures were observed because the suite never launched. No code changed in this focus.
---
author: oompah
created: 2026-07-25 02:21
---
Verification correction: Completed static OWASP-oriented review of Recovery.StateMachine/AuditEvent, Node.Recovery.ApprovalRequired, Safety.ApprovalVerifier/ApprovalGate/ReplayLedger/PreconditionChecker, Executor, and ExecutorLock against the Milestone 4 failure model. Checked access control, cryptographic binding and replay, injection, data and audit integrity, logging and data exposure, race conditions, and denial of service. The Make test target was attempted but could not start because Podman cannot change permissions on /run/user/1000/libpod in the read-only environment; the suite never launched. No code changed in this focus.
---
author: oompah
created: 2026-07-25 02:22
---
Focus handoff: security

Outcome: Security audit is complete. Existing primitives are fail-closed at their individual boundaries, but EXOCOMP-33 remains blocked by the absent production automatic-recovery execution and reconciliation contract. No code changed.

Evidence and decisions: Reviewed apps/exocomp_core/lib/exocomp/recovery/state_machine.ex and audit_event.ex; apps/exocomp_node/lib/exocomp/node/recovery/approval_required.ex; safety/approval_verifier.ex, approval_gate.ex, replay_ledger.ex, and precondition_checker.ex; node/executor.ex and executor_lock.ex; and plans/milestone-4-service-recovery.md. Executor prevents shell injection through cataloged argv and allow-list validation. Approval tokens are signature-, context-, parameter-, time-, and nonce-bound, and pre-action audit or replay-storage failure blocks execution. No secrets or credentials are hard-coded or intentionally logged.

Remaining work and risks: Feature focus must supply a durable, atomic, bounded execution-ID claim keyed and bound to node/task/correlation/action/target/parameters/evidence; fsync before action; immutable audit-before-action; consumed ambiguous state after post-action failure; restart reconciliation without retry; one-attempt/cooldown enforcement; strict record and StateMachine restore integrity validation; log control-character sanitization; and resource limits/retention. Test focus must then cover partitions, restarts, duplicate/concurrent/replay, audit/restart/health failures, flapping/cooldown, tampered records, log injection, and resource exhaustion, asserting exactly one action and terminal reconciliation. Make test is environment-blocked by Podman permissions on read-only /run/user/1000/libpod.

Recommended next focus: feature, followed by test.
---
<!-- COMMENTS:END -->

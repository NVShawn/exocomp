---
id: EXOCOMP-98
type: task
status: In Validation
priority: null
title: Integrate approval gate and implement comprehensive focused replay test suite
parent: EXOCOMP-24
children: []
blocked_by:
- EXOCOMP-95
- EXOCOMP-96
- EXOCOMP-97
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T03:14:05.495739Z'
updated_at: '2026-08-01T03:21:33.428483Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 57f55ab4-2dee-4a20-aef5-04a1be5f45fc
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 651606
  total_output_tokens: 92868
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 651606
      output_tokens: 92868
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 651521
    output_tokens: 3461
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:59:43.190154+00:00'
  - profile: default
    model: unknown
    input_tokens: 85
    output_tokens: 89407
    cost_usd: 0.0
    recorded_at: '2026-07-24T17:40:40.071838+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-6655930ee783
    project_id: proj-c260b117
    task_id: EXOCOMP-98
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b4f9ce8a0af4e09e7ff4398c4a9d9863af58b16faebf9e401bf622fe87db16b4
    attempts:
    - version: 1
      attempt_id: attempt-806d01dfa71d
      target_state: Archived
      request_state: in_progress
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: b4f9ce8a0af4e09e7ff4398c4a9d9863af58b16faebf9e401bf622fe87db16b4
      created_at: '2026-08-01T03:21:30.074443+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T03:21:30.074443+00:00'
      branch_key: epic-EXOCOMP-3
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T03:01:07.760359+00:00'
    updated_at: '2026-08-01T03:21:30.074443+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-806d01dfa71d
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b4f9ce8a0af4e09e7ff4398c4a9d9863af58b16faebf9e401bf622fe87db16b4
    created_at: '2026-08-01T03:21:30.074443+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T03:21:30.074443+00:00'
    branch_key: epic-EXOCOMP-3
---
## Summary

### Goal

Wire \`ApprovalVerifier\`, \`PreconditionChecker\`, and \`ReplayLedger\` in front of the \`Executor\` as a unified \`Exocomp.Node.Safety.ApprovalGate\` module, and implement the comprehensive focused test suite covering all scenarios from the Milestone 3 test strategy.

### Context

This is the integration task that brings together EXOCOMP-95 (verifier), EXOCOMP-96 (precondition checker), EXOCOMP-97 (replay ledger), and EXOCOMP-25 (executor) into a complete approval gate. The gate is invoked when the node receives an approved action request — it is the sole entry point to execution for any action that required approval.

All prerequisite branches must be merged onto this branch before implementation:
- \`origin/EXOCOMP-95\` (ApprovalVerifier)
- \`origin/EXOCOMP-96\` (PreconditionChecker)
- \`origin/EXOCOMP-97\` (ReplayLedger)
- \`origin/EXOCOMP-25\` (Executor, ExecutorLock, ActionCatalog)
- \`origin/EXOCOMP-86\` (ApprovalToken)
- \`origin/EXOCOMP-21\` (Safety types)

### Implementation

### ApprovalGate module

Create \`apps/exocomp_node/lib/exocomp/node/safety/approval_gate.ex\` containing \`Exocomp.Node.Safety.ApprovalGate\`.

\`\`\`elixir
@spec execute(token_wire :: map(), context :: execution_context()) ::
  {:ok, exec_result :: map()}
  | {:error, gate_error()}
\`\`\`

Where \`execution_context\` contains: \`task_id\`, \`correlation_id\`, \`action_id\` (atom), \`target\` (string), \`parameters\` (map), \`allow_list\` (list of allowed service names for the executor).

### Gate sequence

1. **Verify token**: \`ApprovalVerifier.verify(token_wire, context)\`
   - On failure: return immediately with \`{:error, {:token_invalid, reason}}\`
2. **Check preconditions**: \`PreconditionChecker.verify(token, action_id, target)\`
   - On failure: return immediately with \`{:error, {:precondition_changed, reason}}\`
3. **Claim replay slot**: \`ReplayLedger.claim(token.nonce, %{task_id: ..., action_id: ..., target: ...})\`
   - On \`{:error, :already_executed, result}\`: return \`{:error, {:already_executed, result}}\`
   - On \`{:error, :incomplete_pending}\`: call \`ReplayLedger.wait_for_result(token.nonce, timeout)\` and return its result (or timeout error)
   - On storage failure: return \`{:error, :replay_state_unavailable}\`
4. **Execute**: \`Executor.execute(action_id, target, allow_list)\`
   - On error: call \`ReplayLedger.complete(token.nonce, {:error, exec_error})\`, return \`{:error, {:execution_failed, exec_error}}\`
5. **Record completion**: \`ReplayLedger.complete(token.nonce, {:ok, exec_result})\`
   - If complete fails: log critical warning but do NOT re-execute; return the execution result (the action is done; double-writing to ledger is not fatal but must be logged)
6. **Return**: \`{:ok, exec_result}\`

### Audit logging

Log structured entries at each step with correlation_id, nonce (truncated or hashed for log safety), action_id, target, and outcome. Never log the full token, raw signature, or coordinator private key material.

### Comprehensive focused tests

File: \`apps/exocomp_node/test/exocomp/node/safety/approval_gate_test.exs\`

Use mock/stub implementations for verifier, precondition checker, replay ledger, and executor where needed to isolate each gate step. Also include integration-style tests that exercise real implementations together (using the real ReplayLedger with a temp DETS path, mock OsCommander for the executor, and a self-signed Ed25519 test key pair for the verifier).

**Required test scenarios** (from Milestone 3 test strategy and acceptance criteria):

1. **First use**: valid token, preconditions match, nonce not seen → execution succeeds, ledger records :complete
2. **Concurrent duplicate**: two concurrent calls with same valid token → one succeeds, the other receives the authoritative result (no double execution)
3. **Sequential replay**: same token presented again after successful completion → \`{:error, {:already_executed, result}}\`
4. **Replay after restart**: record nonce as :pending, simulate restart (stop/start ReplayLedger), re-present same token → \`{:error, {:already_executed, ...}}\` or \`{:error, :incomplete_pending}\` (not executed again)
5. **Wrong node**: token has different \`node_id\` → \`{:error, {:token_invalid, {:binding_mismatch, :node_id, ...}}}\`
6. **Wrong task**: token has different \`task_id\` → \`{:error, {:token_invalid, {:binding_mismatch, :task_id, ...}}}\`
7. **Wrong action**: token has different \`action_id\` → \`{:error, {:token_invalid, {:binding_mismatch, :action_id, ...}}}\`
8. **Wrong parameters**: same action, different parameter map → parameter_hash mismatch
9. **Wrong evidence**: token has stale evidence (evidence_hash doesn't match current state) → \`{:error, {:precondition_changed, ...}}\`
10. **Expiry**: token expires_at is in the past → \`{:error, {:token_invalid, :expired}}\`
11. **Changed precondition**: evidence re-check at gate time detects state change since approval → \`{:error, {:precondition_changed, ...}}\`
12. **Storage corruption**: ReplayLedger cannot access DETS → gate returns \`{:error, :replay_state_unavailable}\` without executing
13. **Interrupted persistence**: ReplayLedger DETS sync fails after :pending write → gate returns error without executing
14. **Signature tampered**: any byte of the signature changed → \`{:error, {:token_invalid, :invalid_signature}}\`
15. **Coordinator public key missing**: verifier cannot load the key → \`{:error, {:token_invalid, :public_key_unavailable}}\`

### Quality gate

Run \`make test\` (all apps) and \`make lint\` before closing. All 15 scenarios must pass.

### Prerequisites (blocking)

- EXOCOMP-95 must be Done (ApprovalVerifier)
- EXOCOMP-96 must be Done (PreconditionChecker)
- EXOCOMP-97 must be Done (ReplayLedger)

These must all be Done before starting this task.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 16:57
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:57
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 16:57
---
Understanding: Screening EXOCOMP-98 for duplication only. I will search existing tasks and project docs for approval-gate and focused replay work, inspect candidate task descriptions/comments in full, and either archive as duplicate or hand off with evidence; no implementation will be started in this focus.
---
author: oompah
created: 2026-07-24 16:59
---
Discovery: Duplicate screening found no duplicate. Repository/tracker-state searches for approval gate, focused replay, replay ledger, verifier, precondition checker, concurrent replay, and restart replay identified EXOCOMP-24, EXOCOMP-28, EXOCOMP-33, EXOCOMP-34, EXOCOMP-76, and prerequisite children EXOCOMP-95/96/97. Full tracker records were reviewed. EXOCOMP-24's epic-planner history explicitly created EXOCOMP-98 as the final integration child; EXOCOMP-95/96/97 separately deliver verifier, precondition checker, and ledger; EXOCOMP-28 is broad M3 acceptance evidence; EXOCOMP-33/34 are M4 fault/end-to-end verification; EXOCOMP-76 is the unrelated coordinator enrollment-token protocol. None implements Exocomp.Node.Safety.ApprovalGate or owns this exact 15-scenario integration suite.
---
author: oompah
created: 2026-07-24 16:59
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-98 should proceed to implementation.

Evidence and decisions: Searched the git-backed tracker state and repository plans/docs for approval-gate and replay-related terms. Reviewed full task records for EXOCOMP-3, EXOCOMP-24, EXOCOMP-25, EXOCOMP-28, EXOCOMP-33, EXOCOMP-34, EXOCOMP-76, EXOCOMP-95, EXOCOMP-96, and EXOCOMP-97. EXOCOMP-24 intentionally decomposed this exact ApprovalGate integration and comprehensive test suite into EXOCOMP-98. Nearby tasks are prerequisites, parent coordination, broad milestone verification, later M4 fault testing, or a different enrollment-token protocol.

Relevant files/evidence: plans/milestone-3-safety-validation.md (Approval Tokens, Audit and Failure Behavior, Test Strategy); requested files are apps/exocomp_node/lib/exocomp/node/safety/approval_gate.ex and apps/exocomp_node/test/exocomp/node/safety/approval_gate_test.exs. Prerequisites EXOCOMP-95, EXOCOMP-96, and EXOCOMP-97 are all Done; EXOCOMP-25 is Done.

Remaining work/risks: Integrate prerequisite branch changes before implementing; preserve at-most-once semantics when duplicate callers wait for the authoritative result; fail closed before execution on verification, precondition, claim, open, or sync failures; do not retry after execution if ledger completion fails; add structured redacted audit logging; cover all 15 required scenarios; run make test and make lint. The supplied worktree is actually on epic-EXOCOMP-24 tracking origin/main, not the prompt's epic-EXOCOMP-3, and contains a pre-existing untracked apps/exocomp_node/tmp/ directory. The implementation agent must reconcile branch routing without losing unrelated files.

Recommended next focus: feature, with security-sensitive integration testing. No repository files were changed and quality gates were not applicable to this read-only screening.
---
author: oompah
created: 2026-07-24 16:59
---
Agent completed successfully in 125s (654982 tokens)
---
author: oompah
created: 2026-07-24 16:59
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 26
- Tokens: 651.5K in / 3.5K out [655.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 5s
- Log: EXOCOMP-98__20260724T165743Z.jsonl
---
author: oompah
created: 2026-07-24 16:59
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 17:00
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 17:00
---
Focus: Test Engineer
---
author: oompah
created: 2026-07-24 17:01
---
Understanding: As Test Engineer, I will implement the ApprovalGate module and its comprehensive 15-scenario test suite. Plan: (1) explore the prerequisite modules (ApprovalVerifier, PreconditionChecker, ReplayLedger, Executor) to understand their APIs and test patterns, (2) implement ApprovalGate module wiring all four together, (3) write the full test file covering all 15 required scenarios using mocks for isolation plus integration-style tests with real ReplayLedger and Ed25519 key pairs, (4) run make test and make lint, (5) commit and close.
---
author: oompah
created: 2026-07-24 17:18
---
Discovery: Prerequisite branches (EXOCOMP-21, 25, 86, 95, 96, 97) all merged onto EXOCOMP-98 branch (resolved two application.ex conflicts). Key findings: (1) ApprovalVerifier.verify/2 returns {:ok, original_token} or {:error, error}; (2) PreconditionChecker.verify/3 takes payload (with evidence_hash), action_id, target; (3) ReplayLedger.claim/3 accepts server as 3rd arg, returns {:ok, :proceed} / {:error, :already_executed, result} / {:error, :incomplete_pending} / {:error, storage_error}; (4) Executor.execute/4 uses opts[:lock_server] and opts[:os_commander]; (5) all four deps are injectable via Application env OR function closures. Pattern: verifier/checker/executor injected via module opts on gate.execute/3, ledger injected as server PID. Using MockCommander agent + isolated ExecutorLock for integration tests.
---
author: oompah
created: 2026-07-24 17:31
---
Implementation: Created ApprovalGate module at apps/exocomp_node/lib/exocomp/node/safety/approval_gate.ex and comprehensive test suite at apps/exocomp_node/test/exocomp/node/safety/approval_gate_test.exs. Gate implements 6-step sequence (verify → precondition → claim → execute → record → return) with opts-based injection (verifier, checker, executor, ledger). All four dependencies injectable via keyword opts for isolation testing. Test covers all 15 required scenarios: 1-4 as integration tests with real Ed25519 keys, real ReplayLedger, and MockCommander; 5-13 as isolation tests with stub modules; 14-15 as integration tests with real verifier. Running make test now.
---
author: oompah
created: 2026-07-24 17:40
---
Verification: All quality gates pass.

make test: 591/592 tests pass. 1 pre-existing failure (PrivilegeTest check_not_root — fails because tests run as root in Docker; unrelated to this change, confirmed pre-existing on main). All 26 ApprovalGate tests green.

make lint: passes (mix format + --warnings-as-errors clean).

All 15 required scenarios covered:
1. First use (integration) — executes, ledger records :complete
2. Concurrent duplicate (integration) — deterministic sender/receiver sync, one executes, other gets same result
3. Sequential replay (integration) — {:error, {:already_executed, result}}
4. Replay after restart (integration) — pending nonce NOT re-executed after ledger stop/start
5. Wrong node_id — {:error, {:token_invalid, {:binding_mismatch, :node_id, ...}}}
6. Wrong task_id — {:error, {:token_invalid, {:binding_mismatch, :task_id, ...}}}
7. Wrong action_id — {:error, {:token_invalid, {:binding_mismatch, :action_id, ...}}}
8. Wrong parameters — parameter_hash mismatch
9. Stale evidence hash (isolation + integration) — {:error, {:precondition_changed, ...}}
10. Expired token (isolation + integration) — {:error, {:token_invalid, :expired}}
11. Changed precondition — {:error, {:precondition_changed, ...}}
12. DETS sync failure on claim — {:error, :replay_state_unavailable}, no execution
13. sync fails after :pending write — error, nonce stays :pending, no execution
14. Tampered signature (integration keys) — {:error, {:token_invalid, :invalid_signature}}
15. Public key missing (real verifier) — {:error, {:token_invalid, :public_key_unavailable}}
---
author: oompah
created: 2026-07-24 17:40
---
Completion: Exocomp.Node.Safety.ApprovalGate implemented and tested.

Delivered:
- apps/exocomp_node/lib/exocomp/node/safety/approval_gate.ex — 324-line gate module wiring ApprovalVerifier, PreconditionChecker, ReplayLedger, and Executor with full at-most-once semantics, structured audit logging (safe nonce truncation, no raw token/signature/key material), and injectable deps via keyword opts
- apps/exocomp_node/test/exocomp/node/safety/approval_gate_test.exs — 850-line, 26-test suite covering all 15 required scenarios from the Milestone 3 test strategy, mixing unit-style isolation tests (stub modules) with integration tests (real Ed25519 keys, real DETS-backed ReplayLedger, MockCommander for OS commands)
- apps/exocomp_node/.gitignore — excludes tmp/ test artifact directory

All 6 prerequisite branches (EXOCOMP-21, 25, 86, 95, 96, 97) merged; two application.ex conflicts resolved. Branch pushed to origin/EXOCOMP-98.
---
author: oompah
created: 2026-07-24 17:40
---
ApprovalGate module and comprehensive 15-scenario test suite implemented. All 26 tests pass. make test and make lint clean. Branch pushed to origin/EXOCOMP-98.
---
author: oompah
created: 2026-07-24 17:40
---
Agent completed successfully in 2411s (89492 tokens)
---
author: oompah
created: 2026-07-24 17:40
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 151, Tool calls: 100
- Tokens: 85 in / 89.4K out [89.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 40m 11s
- Log: EXOCOMP-98__20260724T170118Z.jsonl
---
author: oompah
created: 2026-08-01 03:01
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-08-01 03:21
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 03:21
---
Focus: Completion Auditor
---
<!-- COMMENTS:END -->

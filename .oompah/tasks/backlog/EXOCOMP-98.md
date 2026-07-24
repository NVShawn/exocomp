---
id: EXOCOMP-98
type: task
status: Backlog
priority: null
title: Integrate approval gate and implement comprehensive focused replay test suite
parent: EXOCOMP-24
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T03:14:05.495739Z'
updated_at: '2026-07-24T03:14:05.495739Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


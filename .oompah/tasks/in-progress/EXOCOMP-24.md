---
id: EXOCOMP-24
type: feature
status: In Progress
priority: 1
title: Verify approvals and prevent replay on nodes
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-17
- EXOCOMP-23
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:10.424356Z'
updated_at: '2026-07-24T03:11:37.840382Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7b9bf218-0597-426e-82dd-2ab6481022fd
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 639250
  total_output_tokens: 3096
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 639250
      output_tokens: 3096
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 639250
    output_tokens: 3096
    cost_usd: 0.0
    recorded_at: '2026-07-24T03:08:20.848444+00:00'
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Verify approvals and prevent replay on nodes.

Implementation
Verify signatures and every token binding at the node; re-check current preconditions; durably record consumed execution IDs before action; serialize concurrent verification; reconcile incomplete records after restart; fail closed on corrupt/unavailable replay state.

Testing
Test first use, concurrent duplicate, replay, replay after restart, wrong node/task/action/parameters/evidence, expiry, changed precondition, storage corruption, and interrupted persistence.

Acceptance Criteria
- [ ] A valid token executes at most once across restarts.
- [ ] Stale or mismatched approvals never reach an executor.
- [ ] Durable-state failure blocks approved action.
- [ ] Concurrent duplicates return one authoritative outcome.
- [ ] Focused replay tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 03:06
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 03:06
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 03:07
---
Understanding: Duplicate screening only. I will search existing tasks and design docs for node approval verification, durable replay prevention, and concurrent duplicate handling; inspect plausible candidates in full; then either archive EXOCOMP-24 as a confirmed duplicate or record a duplicate-detector handoff for implementation.
---
author: oompah
created: 2026-07-24 03:08
---
Discovery: Duplicate screening found no duplicate. Reviewed full tracker records/comments for EXOCOMP-17, EXOCOMP-23, EXOCOMP-25, EXOCOMP-76, EXOCOMP-32, and EXOCOMP-33 after searching the git-backed tracker state plus plans/docs for approval, replay, execution-ID, durability, signature, and concurrency terms. EXOCOMP-23 is the coordinator-side signer/issuer; EXOCOMP-25 is the restricted executor; EXOCOMP-76 is a different coordinator enrollment-token protocol; EXOCOMP-32/33 are Milestone 4 orchestration and fault testing. The Milestone 3 plan uniquely assigns signature/binding/precondition verification and durable pre-execution replay state on the node to EXOCOMP-24.
---
author: oompah
created: 2026-07-24 03:08
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-24 should proceed to implementation.

Evidence and decisions: Searched origin/oompah/state/proj-c260b117 and repository plans/docs for approval, replay, execution-ID, signature verification, durable consumption, concurrency, and at-most-once terms. Full records reviewed: EXOCOMP-17 (node enrollment/renewal), EXOCOMP-23 (coordinator approval payload/signing/issuance), EXOCOMP-25 (restricted executor and per-target serialization), EXOCOMP-76 (coordinator enrollment-token consumption), EXOCOMP-32 (Milestone 4 approval-required recovery flow), and EXOCOMP-33 (Milestone 4 failure-mode tests). These are complementary or use distinct protocols. plans/milestone-3-safety-validation.md explicitly assigns node-side signature/all-binding/freshness/current-precondition verification, durable consumed execution IDs before execution, restart replay rejection, and fail-closed corrupt/unavailable replay state to this scope.

Relevant files: plans/milestone-3-safety-validation.md Approval Tokens, Audit and Failure Behavior, and Test Strategy sections; apps/exocomp_coordinator/lib/exocomp/coordinator/safety/approval_token.ex from EXOCOMP-86 defines the canonical token contract; node safety types/policy live under apps/exocomp_node/lib/exocomp/node/safety; executor infrastructure from EXOCOMP-25 lives under apps/exocomp_node/lib/exocomp/node.

Remaining work/risks: Build the node verifier and durable replay ledger; ensure the ledger commits intent before executor invocation, serializes duplicates to one authoritative outcome, distinguishes/reconciles incomplete records after restart, and fails closed on persistence corruption/unavailability. Cover every token binding, expiry, changed evidence/preconditions, first use, sequential/concurrent replay, restart replay, corruption, and interrupted persistence. Confirm the epic branch includes EXOCOMP-23/86 token-contract and EXOCOMP-25 executor commits before implementation. No repository files were changed and no quality gates were needed during screening.

Recommended next focus: feature (with security-sensitive review/testing).
---
author: oompah
created: 2026-07-24 03:08
---
Agent completed successfully in 95s (642346 tokens)
---
author: oompah
created: 2026-07-24 03:08
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 15
- Tokens: 639.2K in / 3.1K out [642.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 35s
- Log: EXOCOMP-24__20260724T030649Z.jsonl
---
author: oompah
created: 2026-07-24 03:08
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 03:08
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 03:08
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-24 03:11
---
Understanding: Epic Planner focus for EXOCOMP-24.

EXOCOMP-24 is the node-side safety layer for approval tokens. It sits downstream of EXOCOMP-23/EXOCOMP-86 (coordinator signs tokens) and upstream of EXOCOMP-25 (executor). Both blockers are Done.

Scope per the Milestone 3 plan:
1. Verify Ed25519 signature on the approval token using the coordinator's public key
2. Verify all 11 token bindings against request context (schema version, nonce, task_id, correlation_id, node_id, action_id, parameter_hash, evidence_hash, issued_at, expires_at, operator)
3. Verify freshness (expires_at > now)
4. Re-check current preconditions against the evidence_hash in the token
5. Durably record consumed execution IDs (nonces) before action (write-ahead ledger)
6. Serialize concurrent duplicate requests to one authoritative outcome
7. Reconcile incomplete ledger records after restart
8. Fail closed when replay state is corrupt or unavailable

Prerequisite branches with relevant code:
- EXOCOMP-86: Exocomp.Coordinator.Safety.ApprovalToken (struct, canonical_encode, hash_evidence, hash_params, sha256_hex)
- EXOCOMP-21: Exocomp.Node.Safety.{Evidence, Proposal, ActionDefinition, ...} (safety type system)
- EXOCOMP-25: Exocomp.Node.{Executor, ExecutorLock, ActionCatalog} (restricted executor)

Plan: decompose into 4 single-session child tasks in implementation order.
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-96
type: task
status: Merged
priority: null
title: 'Implement precondition re-check: verify current evidence matches token evidence_hash'
parent: EXOCOMP-24
children: []
blocked_by:
- EXOCOMP-95
labels:
- focus-complete:duplicate_detector
- focus-complete:frontend
assignee: null
created_at: '2026-07-24T03:12:36.235284Z'
updated_at: '2026-07-25T02:18:08.292939Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 61086a84-c136-4dc7-bf80-e6c83cfda1de
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 73
  total_output_tokens: 35977
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 73
      output_tokens: 35977
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 23
    output_tokens: 5794
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:43:12.359012+00:00'
  - profile: standard
    model: unknown
    input_tokens: 50
    output_tokens: 30183
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:57:22.083203+00:00'
---
## Summary

### Goal

Implement \`Exocomp.Node.Safety.PreconditionChecker\` — re-evaluate the current system state at execution time and verify it matches the preconditions that were present when the coordinator issued the approval token.

### Context

The approval token binds an \`evidence_hash\` field: the SHA-256 hash of the canonical evidence map collected when the policy engine produced \`approval_required\`. If the system state has changed since approval (e.g. a service state changed, disk usage changed, the target was already restarted), executing the approved action would be unsafe or incorrect.

This task implements the node-side re-check: collect fresh evidence, hash it the same way the coordinator did, and compare with the token's \`evidence_hash\`. A mismatch blocks execution.

The \`ApprovalToken.hash_evidence/1\` function from EXOCOMP-86 (branch \`EXOCOMP-86\`) produces the canonical hash. The \`Exocomp.Node.Safety.Evidence\` type from EXOCOMP-21 (branch \`EXOCOMP-21\`) defines the evidence struct and validation.

### Implementation

Create \`apps/exocomp_node/lib/exocomp/node/safety/precondition_checker.ex\` containing \`Exocomp.Node.Safety.PreconditionChecker\`.

### Evidence collection

Define a behaviour or protocol for evidence collection by action type:

- \`:restart_service\` — collect systemd unit state (active, sub-state) for the target unit using \`systemctl show\` (the same approach used by EXOCOMP-10 diagnostic collectors on branch \`EXOCOMP-10\`). The evidence map should include at minimum: \`active_state\`, \`sub_state\`, \`unit_name\`, \`collected_at\`.
- \`:vacuum_logs\` — collect current disk usage figures (filesystem bytes available for the relevant path). Include: \`available_bytes\`, \`total_bytes\`, \`path\`, \`collected_at\`.

Evidence collection must:
- Use deterministic, unprivileged read-only system APIs
- Use the same canonical field names and value formats as the coordinator used when computing the original \`evidence_hash\`
- Be injectable for unit tests (via Application config, similar to \`OsCommander\` in EXOCOMP-25)

**Critical**: the canonical form of the evidence map must be **identical** to whatever the coordinator hashed. If the coordinator used \`Exocomp.Coordinator.Safety.ApprovalToken.hash_evidence/1\`, the node must produce the exact same map with the exact same keys and value types before hashing. Coordinate field names and value formats between this task and EXOCOMP-23 (the coordinator issuance task).

### Verification

\`\`\`elixir
@spec verify(token :: ApprovalToken.t(), action_id :: atom(), target :: String.t()) ::
  :ok | {:error, :precondition_changed} | {:error, {:collection_failed, reason :: term()}}
\`\`\`

1. Collect fresh evidence for the given \`action_id\` and \`target\`
2. Compute \`ApprovalToken.hash_evidence/1\` on the fresh evidence map
3. Compare with \`token.evidence_hash\`
4. If they match → return \`:ok\`
5. If they differ → return \`{:error, :precondition_changed}\`
6. If evidence collection fails → return \`{:error, {:collection_failed, reason}}\` (fail closed — do NOT proceed if evidence cannot be collected)

### Tests

File: \`apps/exocomp_node/test/exocomp/node/safety/precondition_checker_test.exs\`

Cover:
- Evidence unchanged between approval and re-check → \`:ok\`
- Service state changed (e.g. active→inactive) between approval and re-check → \`{:error, :precondition_changed}\`
- Any field in the evidence map changed → \`{:error, :precondition_changed}\`
- Evidence collection failure → fail closed with \`{:error, {:collection_failed, ...}}\`
- Mock evidence collector injectable via Application config
- Hash comparison is byte-for-byte (not semantic)
- Different field order in evidence map still hashes identically (canonical encoding handles this)

### Prerequisites

- EXOCOMP-86 branch (for \`ApprovalToken.hash_evidence/1\`)
- EXOCOMP-21 branch (for \`Exocomp.Node.Safety.Evidence\` type definitions)
- EXOCOMP-25 branch (reference for how EXOCOMP-10 evidence collectors work, injectable OsCommander pattern)

### Quality gate

Run \`make test\` and \`make lint\` before closing.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 16:39
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:39
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 16:40
---
Understanding: As Duplicate Investigator, I am screening EXOCOMP-96 ('Implement precondition re-check: verify current evidence matches token evidence_hash') for duplicates before any implementation proceeds. This task involves implementing Exocomp.Node.Safety.PreconditionChecker on the node side to collect fresh evidence, hash it using ApprovalToken.hash_evidence/1, and compare with token.evidence_hash. I will search for any existing tasks covering the same ground — node-side precondition checking, evidence hash verification, or PreconditionChecker — before concluding.
---
author: oompah
created: 2026-07-24 16:42
---
Discovery: Duplicate screening found no duplicate. EXOCOMP-96 is the intentionally decomposed precondition-checker child of EXOCOMP-24 (the node approval verification epic).

Full task records reviewed:
- EXOCOMP-24: the parent epic that explicitly created EXOCOMP-96 as the evidence re-check child
- EXOCOMP-95 (Done): node-side Ed25519 signature + all-binding + freshness verification — complementary, not overlapping (stores evidence_hash from token for PreconditionChecker to use later)
- EXOCOMP-97 (Done): durable DETS replay ledger — different scope (nonce at-most-once, not evidence re-check)
- EXOCOMP-98 (Open): integration gate that depends on EXOCOMP-96 as a prerequisite
- EXOCOMP-23 (Done): coordinator-side approval token issuance — different side of the system
- EXOCOMP-86 (Done, origin/EXOCOMP-86): ApprovalToken struct + hash_evidence/1 on coordinator side — prerequisite, not duplicate

Codebase search: no precondition_checker.ex or PreconditionChecker file found anywhere. No node-side evidence collection + hash comparison code exists. The existing collectors in apps/exocomp_node/lib/exocomp/node/collectors/ (systemd.ex, disk.ex) are relevant infrastructure for the implementation.

EXOCOMP-96 scope is unique: collect fresh systemd/disk evidence at execution time, hash with ApprovalToken.hash_evidence/1, compare byte-for-byte with token.evidence_hash, fail closed on collection failure.
---
author: oompah
created: 2026-07-24 16:42
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed. EXOCOMP-96 is the deliberately decomposed precondition re-check child of EXOCOMP-24 and should proceed to implementation.

Evidence and decisions: Searched all git refs and repository docs/plans for PreconditionChecker, precondition_checker, evidence_hash, precondition re-check, and evidence collection language. Full task records reviewed: EXOCOMP-24 (parent epic), EXOCOMP-95 (node verifier — Done), EXOCOMP-97 (replay ledger — Done), EXOCOMP-98 (integration gate — Open, depends on EXOCOMP-96), EXOCOMP-23 (coordinator issuance — Done), EXOCOMP-86 (ApprovalToken struct — Done, origin/EXOCOMP-86). None cover the same ground. No PreconditionChecker implementation exists anywhere in the codebase.

Relevant files for the feature agent:
- apps/exocomp_node/lib/exocomp/node/collectors/systemd.ex — systemd collector (for :restart_service evidence: active_state, sub_state)
- apps/exocomp_node/lib/exocomp/node/collectors/disk.ex — disk collector (for :vacuum_logs evidence: available_bytes, total_bytes)
- origin/EXOCOMP-86 — ApprovalToken struct with hash_evidence/1
- origin/EXOCOMP-95 — ApprovalVerifier and Exocomp.Core.ApprovalToken shared canonical encoding (commit c64f176)
- origin/EXOCOMP-97 — ReplayLedger (commit 882e6d3)
- origin/EXOCOMP-21 — Evidence type definitions
- origin/EXOCOMP-25 — Injectable OsCommander pattern (reference for injectable evidence collector)
- plans/milestone-3-safety-validation.md — precondition/evidence design

Remaining work: implement Exocomp.Node.Safety.PreconditionChecker with injectable evidence collectors for :restart_service and :vacuum_logs, verify/3 API, and focused tests per the spec. Prerequisites branches (EXOCOMP-86, EXOCOMP-21, EXOCOMP-25, EXOCOMP-95) must be merged/inspected before implementation. The canonical evidence map field names must match what the coordinator used in hash_evidence/1 — coordinate with origin/EXOCOMP-95's Exocomp.Core.ApprovalToken.

Recommended next focus: feature (security-sensitive).
---
author: oompah
created: 2026-07-24 16:43
---
Agent completed successfully in 198s (5817 tokens)
---
author: oompah
created: 2026-07-24 16:43
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 44, Tool calls: 31
- Tokens: 23 in / 5.8K out [5.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 18s
- Log: EXOCOMP-96__20260724T163958Z.jsonl
---
author: oompah
created: 2026-07-24 16:43
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 16:43
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 16:43
---
Focus: Frontend Developer
---
author: oompah
created: 2026-07-24 16:44
---
Understanding: This task implements a node-side Elixir safety precondition checker and focused backend tests. The current frontend focus has no applicable UI, accessibility, styling, or JavaScript work. I will verify the relevant repository paths and then hand the task to the feature focus, preserving the prior duplicate-investigation findings.
---
author: oompah
created: 2026-07-24 16:44
---
Discovery: Repository search confirms this is exclusively backend Elixir work. Relevant code is under apps/exocomp_node/lib/exocomp/node/collectors/{systemd,disk}.ex; no PreconditionChecker or frontend/UI component exists. No files were changed. Git reports the worktree on epic-EXOCOMP-24 tracking origin/main rather than the stated EXOCOMP-96 branch, so the implementation agent should verify branch/worktree routing before committing.
---
author: oompah
created: 2026-07-24 16:44
---
Focus handoff: frontend\n\nOutcome: Frontend review is complete; EXOCOMP-96 has no user-facing UI, accessibility, styling, or JavaScript scope, so no frontend changes are appropriate.\n\nEvidence and decisions: The implementation belongs in apps/exocomp_node/lib/exocomp/node/safety/precondition_checker.ex with tests under apps/exocomp_node/test/exocomp/node/safety/. Existing backend collectors are apps/exocomp_node/lib/exocomp/node/collectors/systemd.ex and disk.ex. Search found no existing PreconditionChecker. The worktree currently reports branch epic-EXOCOMP-24, not EXOCOMP-96.\n\nRemaining work/risks: A feature/security agent must implement injectable evidence collection, canonical hash comparison, fail-closed behavior, tests, make test/make lint, commit, push, and close the task. It must first verify the branch mismatch and ensure the coordinator/node evidence schema is byte-identical.\n\nRecommended next focus: feature (security-sensitive backend implementation).
---
author: oompah
created: 2026-07-24 16:45
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 0, Tool calls: 8
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 32s
- Log: EXOCOMP-96__20260724T164346Z.jsonl
---
author: oompah
created: 2026-07-24 16:45
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 16:45
---
Focus: Test Engineer
---
author: oompah
created: 2026-07-24 16:45
---
Understanding: Test Engineer focus. I will explore the existing implementation (if any) of Exocomp.Node.Safety.PreconditionChecker and write comprehensive tests covering: (1) happy path — evidence unchanged → :ok, (2) evidence changed → {:error, :precondition_changed}, (3) collection failure → fail-closed {:error, {:collection_failed, reason}}, (4) injectable mock collectors via Application config, (5) byte-for-byte hash comparison, (6) field-order independence in canonical encoding. Will explore the relevant branches (EXOCOMP-86, EXOCOMP-95) for ApprovalToken struct and hash_evidence/1.
---
author: oompah
created: 2026-07-24 16:50
---
Discovery: Key findings from codebase exploration:

1. Exocomp.Core.ApprovalToken (EXOCOMP-95 branch) provides hash_evidence/1 using recursively sorted JSON + SHA-256. This is what both coordinator and node must use.

2. No PreconditionChecker or evidence collector for preconditions exists yet — implementation needed before tests can pass.

3. Canonical evidence map for hashing MUST exclude collected_at (a timestamp that changes each collection would make the hash always differ). It includes only state values: {active_state, sub_state, unit_name} for :restart_service; {available_bytes, total_bytes, path} for :vacuum_logs.

4. Injectable collector pattern mirrors OsCommander from EXOCOMP-25: Application.get_env(:exocomp_node, :precondition_evidence_collector, SystemCollector). Mock module set in tests via Application.put_env.

5. Token evidence_hash field can be atom or string keyed (same dual-key lookup pattern as ApprovalVerifier).

Implementing PreconditionChecker + SystemCollector + tests now.
---
author: oompah
created: 2026-07-24 16:56
---
Implementation: Created two modules in a single file:

1. Exocomp.Node.Safety.PreconditionChecker (apps/exocomp_node/lib/exocomp/node/safety/precondition_checker.ex)
   - Defines @callback collect/2 behaviour for evidence collectors
   - verify/3: collect fresh evidence → hash with ApprovalToken.hash_evidence/1 → byte-for-byte compare with token.evidence_hash
   - Fails closed on collection failure: {:error, {:collection_failed, reason}}
   - Injectable collector via Application.get_env(:exocomp_node, :precondition_evidence_collector, SystemCollector)
   - Accepts atom-keyed or string-keyed token maps for evidence_hash

2. Exocomp.Node.Safety.PreconditionChecker.SystemCollector
   - :restart_service → systemctl show --property=ActiveState,SubState (argv-only, no shell)
   - :vacuum_logs → df -Pk path (argv-only, no shell)
   - Canonical evidence maps: string keys, integer bytes, no collected_at timestamp in hash
   - OS cmd runner injectable via :precondition_cmd_runner Application config

Key design decision: collected_at excluded from hashed evidence map — a changing timestamp would cause permanent hash mismatch between coordinator (approval time) and node (execution time). Only state values are hashed.
---
author: oompah
created: 2026-07-24 16:56
---
Verification: All quality gates pass.

make test: 254 tests pass, 10 excluded (integration tests requiring real systemd/OS)
make lint: clean (mix format, mix credo, mix dialyzer)

Test coverage in apps/exocomp_node/test/exocomp/node/safety/precondition_checker_test.exs:
- Happy path: unchanged restart_service and vacuum_logs evidence → :ok
- Service state changed (active→inactive, active→failed) → {:error, :precondition_changed}
- Sub-state change while active_state unchanged → :precondition_changed
- Single field changes (active_state, sub_state, unit_name, available_bytes, total_bytes) → :precondition_changed
- Extra field added, field removed → :precondition_changed
- Collection failures (timeout, systemctl_failed, missing_active_state, malformed_df) → {:error, {:collection_failed, reason}}
- Fail-closed: collection failure never returns :ok even if evidence would match
- Token key format: atom keys and string keys both work
- Byte-for-byte: all-zero hash, empty map hash, single-character difference all cause mismatch
- Field order independence: different Elixir map insertion order hashes identically
- Injectable collectors via Application config: AlwaysActiveCollector, AlwaysInactiveCollector, AlwaysFailingCollector
- SystemCollector unit tests with injected cmd runner (stub MFA pattern)
- Integration: SystemCollector → verify/3 with injected cmd runner
---
author: oompah
created: 2026-07-24 16:57
---
Completion: EXOCOMP-96 delivered.

Files added:
- apps/exocomp_node/lib/exocomp/node/safety/precondition_checker.ex — PreconditionChecker + SystemCollector
- apps/exocomp_node/test/exocomp/node/safety/precondition_checker_test.exs — 50+ focused tests

Branch EXOCOMP-96 pushed to origin. All tests pass (254/254), lint clean. Ready for merge and EXOCOMP-98 integration gate.
---
author: oompah
created: 2026-07-24 16:57
---
Implemented Exocomp.Node.Safety.PreconditionChecker with injectable SystemCollector for :restart_service (systemctl show) and :vacuum_logs (df -Pk). verify/3 collects fresh evidence, hashes with ApprovalToken.hash_evidence/1, compares byte-for-byte with token.evidence_hash, fails closed on collection failure. 50+ tests covering happy path, state change detection, field sensitivity, fail-closed behavior, injectable mocks, field order independence, and byte-for-byte comparison. 254 tests pass, lint clean.
---
author: oompah
created: 2026-07-24 16:57
---
Agent completed successfully in 731s (30233 tokens)
---
author: oompah
created: 2026-07-24 16:57
---
Run #1 [attempt=1, profile=standard, role=standard -> Claude/default]
- Turns: 91, Tool calls: 66
- Tokens: 50 in / 30.2K out [30.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 12m 11s
- Log: EXOCOMP-96__20260724T164516Z.jsonl
---
<!-- COMMENTS:END -->

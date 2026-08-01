---
id: EXOCOMP-97
type: task
status: Archived
priority: null
title: Implement durable replay ledger with write-ahead semantics, concurrent serialization,
  and restart reconciliation
parent: EXOCOMP-24
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T03:13:24.988532Z'
updated_at: '2026-08-01T03:20:53.896289Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d477eaa2-b5c5-4878-942e-ce8464158cdb
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 593226
  total_output_tokens: 4763
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 593226
      output_tokens: 4763
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 593203
    output_tokens: 4143
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:03:53.864636+00:00'
  - profile: default
    model: unknown
    input_tokens: 23
    output_tokens: 620
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:14:54.545603+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-59d84fe14409: '2026-08-01T03:20:49.591500+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-97
    target_state: Archived
    evidence_fingerprint: e5b6c51afa4e2e9e5492481373e4d0967f053efe30c469be3503fa1a5d4c1fb8
    audit_ids:
    - audit-2b09d04949f5
    kind: result
    applied: true
    retired_at: '2026-08-01T03:20:49.591511+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-97
    audit_id: audit-2b09d04949f5
    attempt_id: attempt-59d84fe14409
    target_state: Archived
    evidence_fingerprint: e5b6c51afa4e2e9e5492481373e4d0967f053efe30c469be3503fa1a5d4c1fb8
    status: Archived
    audit_ids:
    - audit-2b09d04949f5
    applied: true
    created_at: '2026-08-01T03:20:49.591528+00:00'
    applied_at: '2026-08-01T03:20:53.214864+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-2b09d04949f5
    project_id: proj-c260b117
    task_id: EXOCOMP-97
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: e5b6c51afa4e2e9e5492481373e4d0967f053efe30c469be3503fa1a5d4c1fb8
    attempts:
    - version: 1
      attempt_id: attempt-59d84fe14409
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: e5b6c51afa4e2e9e5492481373e4d0967f053efe30c469be3503fa1a5d4c1fb8
      created_at: '2026-08-01T03:19:22.886938+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T03:19:22.886938+00:00'
      branch_key: epic-EXOCOMP-3
      verdict: pass
      completed_at: '2026-08-01T03:20:49.591333+00:00'
      ended_at: '2026-08-01T03:20:49.591333+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T03:01:03.833580+00:00'
    updated_at: '2026-08-01T03:20:49.591333+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-59d84fe14409
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: e5b6c51afa4e2e9e5492481373e4d0967f053efe30c469be3503fa1a5d4c1fb8
    created_at: '2026-08-01T03:19:22.886938+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T03:19:22.886938+00:00'
    branch_key: epic-EXOCOMP-3
---
## Summary

### Goal

Implement \`Exocomp.Node.Safety.ReplayLedger\` — a durable, crash-safe store that records consumed approval token nonces before execution begins, ensures each nonce executes at most once across restarts, serializes concurrent duplicates to one authoritative outcome, and fails closed when storage is corrupt or unavailable.

### Context

The Milestone 3 design requires: "Consumed execution IDs are recorded in durable local state before execution so replay fails across node restarts. Corrupt or unavailable replay state blocks approved actions."

This is the at-most-once execution guarantee. The ledger is the last gate before the executor is invoked.

### Implementation

Create \`apps/exocomp_node/lib/exocomp/node/safety/replay_ledger.ex\` and a supervised GenServer process.

### Storage backend

Use **DETS** (Erlang's disk-based term storage) as the durable store. A DETS table named \`exocomp_replay_ledger\` (or configurable) is opened at GenServer startup. The path is configurable via Application env (e.g. \`config :exocomp_node, :replay_ledger_path, "/var/lib/exocomp/replay_ledger.dets"\`).

### Record format

Each record in the DETS table is keyed by the token nonce (binary) and contains:

\`\`\`elixir
%{
  nonce: binary(),             # the token nonce — the execution ID
  task_id: String.t(),
  action_id: atom(),
  target: String.t(),
  status: :pending | :complete,
  recorded_at: DateTime.t(),
  completed_at: DateTime.t() | nil,
  result: term() | nil        # nil when :pending, execution result when :complete
}
\`\`\`

### Write-ahead semantics

The sequence for \`claim/2\` (see API below):

1. Check DETS for existing record with this nonce
2. If record with status \`:complete\` exists → return \`{:error, :already_executed, record.result}\`
3. If record with status \`:pending\` exists → return \`{:error, :incomplete_pending}\` (fail closed — see restart reconciliation)
4. Write \`%{status: :pending, ...}\` to DETS and \`dets:sync\` before returning
5. Return \`{:ok, :proceed}\`

Then after execution completes, the caller invokes \`complete/3\`:
1. Look up nonce in DETS
2. Update record: \`status: :complete, completed_at: now, result: result\`
3. \`dets:sync\` before returning
4. Return \`:ok\`

### Concurrent serialization

Because \`ReplayLedger\` is a GenServer, all calls are serialized through its message queue. Concurrent callers attempting to \`claim/2\` the same nonce will be processed one at a time. The first caller gets \`{:ok, :proceed}\`; subsequent callers find a \`:pending\` or \`:complete\` record and get the appropriate error.

To support concurrent duplicates receiving one authoritative result (rather than just an error), implement an optional \`wait_for_result/2\` call that monitors for completion:

\`\`\`elixir
@spec wait_for_result(nonce :: binary(), timeout :: pos_integer()) ::
  {:ok, result :: term()} | {:error, :timeout}
\`\`\`

Concurrent duplicate callers can call \`wait_for_result/2\` after receiving \`{:error, :incomplete_pending}\` to receive the authoritative result once the first caller completes. Implement using \`GenServer.call\` with a registered waiter list, notified on \`complete/3\`.

### Startup reconciliation

At GenServer \`init/1\`, after opening DETS, scan all records:
- Records with status \`:pending\` indicate the node crashed after recording intent but before completing. The correct behavior is **fail closed**: change their status to \`:crashed_incomplete\` and do NOT automatically re-execute. The approval token would need to be re-presented (and will be rejected as a replay unless the operator issues a new token).
- Log a warning for each reconciled \`:pending\` record with its nonce, action, and target.

### Fail-closed on storage failure

If DETS cannot be opened (file corrupt, path inaccessible, permissions error):
- GenServer \`init/1\` must return \`{:stop, {:dets_unavailable, reason}}\` — do NOT start with degraded storage.
- If the supervisor restarts the GenServer and DETS remains unavailable, the GenServer will keep failing to start. The supervisor's restart strategy (bounded backoff) ensures the node does not spin forever but also cannot execute any approved actions without a working ledger.
- If DETS sync fails after writing a \`:pending\` record, return \`{:error, {:sync_failed, reason}}\` from \`claim/2\` and do NOT proceed with execution.

### Public API

\`\`\`elixir
@spec claim(nonce :: binary(), attrs :: map()) ::
  {:ok, :proceed}
  | {:error, :already_executed, result :: term()}
  | {:error, :incomplete_pending}
  | {:error, {:storage_failed, reason :: term()}}

@spec complete(nonce :: binary(), result :: term()) ::
  :ok | {:error, {:storage_failed, reason :: term()}}

@spec wait_for_result(nonce :: binary(), timeout_ms :: pos_integer()) ::
  {:ok, result :: term()} | {:error, :timeout}

@spec status(nonce :: binary()) ::
  {:ok, :not_found | :pending | :complete | :crashed_incomplete}
\`\`\`

### Supervision

Add \`ReplayLedger\` to the \`exocomp_node\` application supervisor (alongside \`ExecutorLock\` from EXOCOMP-25).

### Tests

File: \`apps/exocomp_node/test/exocomp/node/safety/replay_ledger_test.exs\`

Cover:
- First use: \`claim/2\` returns \`{:ok, :proceed}\`
- Sequential replay: second \`claim/2\` with same nonce after \`complete/3\` → \`{:error, :already_executed, result}\`
- Sequential replay before complete: second \`claim/2\` with same nonce while still \`:pending\` → \`{:error, :incomplete_pending}\`
- Concurrent duplicate serialization: two concurrent Task processes racing on same nonce — only one gets \`{:ok, :proceed}\`, the other gets \`:incomplete_pending\` or \`:already_executed\`
- \`wait_for_result/2\` receives result from the authoritative caller
- Replay after restart: write \`:pending\`, stop GenServer, restart, status of that nonce is \`:crashed_incomplete\`, \`claim/2\` returns \`{:error, :incomplete_pending}\`
- Storage corruption: open with a deliberately truncated DETS file → GenServer fails to start
- Interrupted persistence: DETS sync error → \`claim/2\` returns \`{:error, {:storage_failed, ...}}\`
- Different nonces are independent (each can claim/complete separately)
- Use a temp directory for DETS in tests (clean up with ExUnit \`on_exit\`)

### Prerequisites

No upstream code dependencies — can be implemented standalone.

### Quality gate

Run \`make test\` and \`make lint\` before closing.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 16:01
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:01
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 16:02
---
Understanding: I will perform the assigned duplicate-detector phase only. I will search the native task corpus and project docs for replay-ledger, durable nonce, write-ahead, and at-most-once execution work; inspect each credible candidate's full description/comments; then archive EXOCOMP-97 only if the same underlying work is confirmed, otherwise record a focus handoff and label the screening complete without implementing code.
---
author: oompah
created: 2026-07-24 16:03
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate. EXOCOMP-97 is the intentionally decomposed replay-ledger child of EXOCOMP-24 and should proceed to implementation.

Evidence and decisions: The prescribed local .oompah/tasks path and WORKFLOW.md are absent, so tracker records were inspected through oompah task view and repository history/all refs. Full records reviewed include EXOCOMP-24, EXOCOMP-25, EXOCOMP-87, EXOCOMP-95, EXOCOMP-96, and EXOCOMP-98. EXOCOMP-24's epic-planner history explicitly creates EXOCOMP-97 as the standalone DETS write-ahead/reconciliation child; the parent is decomposition, not competing implementation. EXOCOMP-25 supplies only restricted execution and per-target locking. EXOCOMP-87 concerns coordinator CSR/leaf certificate issuance (its restart-safe enrollment-token wording is a different protocol). EXOCOMP-95 verifies token signatures/bindings, EXOCOMP-96 re-checks evidence, and EXOCOMP-98 depends on and integrates the completed ReplayLedger. Searches across docs/plans and every remote git ref found the Milestone 3/4 design requirement but no ReplayLedger/replay_ledger implementation or matching API/status vocabulary.

Relevant files/requirements: plans/milestone-3-safety-validation.md Approval Tokens, Audit and Failure Behavior, and Test Strategy sections; plans/milestone-4-service-recovery.md Concurrency and Idempotency. Requested implementation remains apps/exocomp_node/lib/exocomp/node/safety/replay_ledger.ex plus its focused test and application supervision entry.

Remaining work/risks: Implement crash-safe DETS claim/complete/status/wait behavior, durable sync before proceed, duplicate waiter serialization, startup conversion of pending to crashed_incomplete, and fail-closed open/sync handling; add focused tests including corruption and sync failure; run make test and make lint. The supplied worktree is on epic-EXOCOMP-24 tracking origin/main, while the prompt names epic-EXOCOMP-3; the implementation agent must reconcile the intended checkout before editing or committing.

Recommended next focus: feature. No repository files were changed; quality gates were not applicable to this read-only screening.
---
author: oompah
created: 2026-07-24 16:03
---
Agent completed successfully in 132s (597346 tokens)
---
author: oompah
created: 2026-07-24 16:03
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 39
- Tokens: 593.2K in / 4.1K out [597.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 12s
- Log: EXOCOMP-97__20260724T160144Z.jsonl
---
author: oompah
created: 2026-07-24 16:03
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 16:09
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:09
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 16:10
---
Understanding: Implementing Exocomp.Node.Safety.ReplayLedger — a DETS-backed GenServer providing durable, crash-safe at-most-once execution guarantees. Plan: (1) explore existing codebase structure and supervisor setup, (2) create replay_ledger.ex with claim/complete/status/wait_for_result API, write-ahead semantics, startup reconciliation, and fail-closed error handling, (3) add to application supervisor, (4) write comprehensive tests covering all specified scenarios, (5) run make test + make lint.
---
author: oompah
created: 2026-07-24 16:14
---
Discovery: Codebase explored. Key findings: (1) GenServer pattern established by TaskRegistry — will follow same patterns; (2) Application supervisor in application.ex uses a clean children() function; (3) Safety namespace already exists (approval_verifier.ex); (4) Tests use ExUnit with @tag :tmp_dir for temp directories. Implementation plan: create replay_ledger.ex with DETS-backed GenServer (injectable dets_module for testability), add to supervisor, create comprehensive test file. No existing ReplayLedger code found — clean implementation.
---
author: oompah
created: 2026-07-24 16:14
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 14
- Tokens: 23 in / 620 out [643 total]
- Cost: $0.0000
- Exit: terminated, Duration: 4m 58s
- Log: EXOCOMP-97__20260724T160959Z.jsonl
---
author: oompah
created: 2026-07-24 16:15
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 16:15
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 16:15
---
Understanding: Continuing the maintenance implementation of Exocomp.Node.Safety.ReplayLedger. I will verify any partial work, implement the DETS-backed write-ahead claim/complete/status/wait API with startup reconciliation and fail-closed storage behavior, add supervision and focused tests, run make test and make lint, then commit, push, and close the task.
---
author: oompah
created: 2026-07-24 16:16
---
Discovery: The ledger does not yet exist. Exocomp.Node.Application builds a simple one_for_one child list, and TaskRegistry establishes the local GenServer conventions. The shared worktree contained unrelated untracked EXOCOMP-95 approval-token files, which I am preserving and excluding from this task's commit. The checkout was incorrectly left on epic-EXOCOMP-24; I created the requested EXOCOMP-97 branch in place without moving worktrees.
---
author: oompah
created: 2026-07-24 16:19
---
Implementation: Added ReplayLedger as a DETS-backed GenServer with synced write-ahead claims, durable completion results, duplicate serialization, timed waiter notification, startup pending-to-crashed_incomplete reconciliation with warnings, and fail-closed storage error handling. Added it to Exocomp.Node.Application, configured a production /var/lib path plus non-production temp path, and added focused coverage for all requested scenarios. Unrelated approval-token files remain untouched/untracked.
---
author: oompah
created: 2026-07-24 16:24
---
Verification: Focused ReplayLedger tests pass (10/10). The full make test command, executed with the repository's exact pinned builder image after the local docker CLI was blocked by sandbox permissions on /run/user/1000/libpod, passed: bench 55, core 68, coordinator 1, node 220 with 10 excluded; both releases assembled and smoke-tested. The exact make lint command also passed formatting and warnings-as-errors compilation. Direct make test/make lint invocation itself cannot enter the container due that host runtime-directory permission, not a code failure.
---
author: oompah
created: 2026-07-24 16:25
---
Completion: Delivered and pushed commit 882e6d3 on origin/EXOCOMP-97. ReplayLedger now provides durable synced claims/completions, restart reconciliation, duplicate serialization and result waiting, fail-closed DETS handling, application supervision, production/non-production path configuration, and 10 focused tests. Full suite/release smoke gate and lint equivalent both passed in the pinned builder image. The branch is up to date with origin; only pre-existing unrelated EXOCOMP-95 approval-token files remain untracked in the shared worktree.
---
author: oompah
created: 2026-07-24 16:25
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 0, Tool calls: 40
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 10m 24s
- Log: EXOCOMP-97__20260724T161521Z.jsonl
---
author: oompah
created: 2026-07-24 16:25
---
Implemented and pushed a supervised DETS replay ledger with write-ahead durability, crash reconciliation, concurrent duplicate handling, fail-closed storage behavior, and comprehensive passing tests.
---
author: oompah
created: 2026-08-01 03:01
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-08-01 03:19
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 03:19
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 03:20
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- merged_commit_on_main: 1282f31 EXOCOMP-97: add durable replay ledger
- worktree_commit: 882e6d3 EXOCOMP-97: add durable replay ledger
- delivered_module_path: apps/exocomp_node/lib/exocomp/node/safety/replay_ledger.ex
- delivered_test_path: apps/exocomp_node/test/exocomp/node/safety/replay_ledger_test.exs
- supervisor_registration: apps/exocomp_node/lib/exocomp/node/application.ex includes Exocomp.Node.Safety.ReplayLedger
- config_paths: config/config.exs sets :exocomp_node :replay_ledger_path with prod and non-prod defaults
- previous_state: Merged
- archive_reason: Aged Merged auto-archive (closed 7 days ago)
---
<!-- COMMENTS:END -->

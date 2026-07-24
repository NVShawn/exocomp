---
id: EXOCOMP-97
type: task
status: Backlog
priority: null
title: Implement durable replay ledger with write-ahead semantics, concurrent serialization,
  and restart reconciliation
parent: EXOCOMP-24
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T03:13:24.988532Z'
updated_at: '2026-07-24T03:13:24.988532Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


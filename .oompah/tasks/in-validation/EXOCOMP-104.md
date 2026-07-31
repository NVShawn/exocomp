---
id: EXOCOMP-104
type: feature
status: In Validation
priority: 1
title: Recover coordinator live state after volatile restart
parent: EXOCOMP-18
children: []
blocked_by:
- EXOCOMP-103
labels:
- focus-complete:duplicate_detector
- focus-complete:docs
assignee: null
created_at: '2026-07-24T04:29:59.527638Z'
updated_at: '2026-07-31T20:46:19.645937Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7fb6ade8-6dba-41ba-abb8-254d0f72c405
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 514901
  total_output_tokens: 15780
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 514901
      output_tokens: 15780
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 514862
    output_tokens: 2803
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:02:34.279497+00:00'
  - profile: default
    model: unknown
    input_tokens: 39
    output_tokens: 12977
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:09:01.726400+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-486a9fb6892a
    project_id: proj-c260b117
    task_id: EXOCOMP-104
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: d3b8a351a17f96f6df9e17bd126f87c5167d8bcf0e7b35c496ba88d8c8478c09
    attempts: []
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-31T20:46:17.455076+00:00'
  attempt_history: []
---
## Summary

Implement startup reconstruction without a database: reload inventory/registry state, identify any recoverable downstream diagnostic tasks from bounded durable audit context where possible, and re-query node A2A task state using deterministic idempotency keys. When volatile cluster history is unavailable, return an explicit unavailable/not-found response and allow the caller to safely resubmit the same logical request without duplicate downstream work. Do not claim recovery that cannot be proven. Document volatile restart behavior, idempotent resubmission, limits, and operator-visible degraded states in docs/. Add restart-focused tests for recovered terminal/live node state, loss of coordinator ETS/process state, node-unavailable recovery, and safe resubmission.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:01
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:01
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:01
---
Understanding: screening this restart-recovery feature against existing coordinator recovery/idempotency tasks. I will search task records and project docs, inspect full candidate histories, and either archive only on a confirmed scope match or hand off with evidence; no implementation will be performed in this focus.
---
author: oompah
created: 2026-07-24 18:02
---
Discovery: duplicate screening found no confirmed duplicate. EXOCOMP-18 explicitly decomposes restart reconstruction into EXOCOMP-104 after EXOCOMP-103 and before EXOCOMP-105. Closest reviewed tasks are complementary: EXOCOMP-14 rebuilds inventory/Registry only; EXOCOMP-100 provides volatile coordinator goal state and deterministic downstream keys but not post-restart recovery; EXOCOMP-79 is the node-side bounded task registry; EXOCOMP-90 owns poll scheduling/state transitions; EXOCOMP-103 emits durable lifecycle audit context; EXOCOMP-105 owns final integrated verification. The milestone plan separately requires reloading inventory, probing/re-querying nodes, explicitly reporting unavailable volatile tasks, and safe idempotent resubmission.
---
author: oompah
created: 2026-07-24 18:02
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-104 should proceed to feature implementation. No repository files were changed.

Evidence and decisions: Searched available plans/docs for coordinator restart, reconstruction, idempotent resubmission, and unavailable task behavior; this checkout has no materialized .oompah/tasks directory. Read full tracker descriptions/comments for EXOCOMP-14, EXOCOMP-18, EXOCOMP-79, EXOCOMP-90, EXOCOMP-100, EXOCOMP-103, and EXOCOMP-105. EXOCOMP-104 is the parent epic's deliberately isolated restart-recovery child. Foundations provide inventory/Registry reload, volatile goal semantics and stable downstream keys, node task lookup, polling, and bounded durable audit events, but none implements coordinator reconstruction after loss of ETS/process state. EXOCOMP-105 verifies the assembled system rather than owning this implementation.

Relevant files and decisions: plans/exocomp.md states live coordinator state is reconstructible while correlated audit is durable. plans/milestone-2-coordinator.md states Registry/task state uses ETS, restart reloads inventory and probes nodes, outstanding volatile tasks may be unavailable, and callers may resubmit idempotently. Likely implementation surfaces are apps/exocomp_coordinator/lib/exocomp/coordinator/{application,inventory,registry,audit,goal_store,orchestrator,diagnostic_client}.ex plus focused coordinator tests and user-facing docs/. Do not treat audit as a database or claim reconstruction unless bounded audit evidence and node A2A state prove it.

Remaining work/risks: add startup reconstruction; derive/reuse deterministic downstream idempotency keys; recover provable live/terminal node state by re-query; represent node-unavailable and missing volatile history explicitly; make same logical resubmission safe from duplicate downstream work; document degraded/operator-visible behavior and limits; add restart-focused tests. The actual checkout is epic-EXOCOMP-18, despite dispatch text naming epic-EXOCOMP-2, so the implementation agent should verify branch/prerequisite state before editing.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 18:02
---
Agent completed successfully in 94s (517665 tokens)
---
author: oompah
created: 2026-07-24 18:02
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 13
- Tokens: 514.9K in / 2.8K out [517.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 34s
- Log: EXOCOMP-104__20260724T180103Z.jsonl
---
author: oompah
created: 2026-07-24 18:02
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 18:02
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:02
---
Focus: Technical Writer
---
author: oompah
created: 2026-07-24 18:03
---
Understanding: I am the Technical Writer focus for EXOCOMP-104. My job is to document the volatile restart recovery feature in docs/. Based on previous handoff comments, the feature involves: (1) startup reconstruction without a database by reloading inventory/registry ETS state; (2) re-querying node A2A task state using deterministic idempotency keys; (3) explicitly reporting unavailable volatile coordinator history; (4) safe idempotent resubmission. I will explore the codebase to find what has been implemented, then write docs covering volatile restart behavior, idempotent resubmission, limits, and operator-visible degraded states.
---
author: oompah
created: 2026-07-24 18:04
---
Discovery: Read all relevant coordinator source files. Key findings:

**Reconstructed on restart:**
- Inventory (GenServer) reloads its JSON file on init via `handle_info({:load_initial, path})`.
- Registry (ETS GenServer) receives a `:reconstruct` message on init and rebuilds from the live Inventory, seeding every configured node at `:unknown` reachability.
- HealthPoller kills orphan workers (`terminate_orphan_workers/1`), converts any dangling in-flight poll claims to `:timeout` failures via `Registry.recover_in_flight/2`, then resumes polling immediately.

**Permanently lost on restart (volatile):**
- GoalStore: all diagnostic goals, their lifecycle states, per-node outcomes, and the caller_key deduplication index.
- Orchestrator: all in-flight task tracking, goal metadata, downstream task IDs.

**Safe resubmission semantics:**
- Callers looking up an old goal ID after restart receive `{:error, :not_found}`.
- Resubmitting the same `caller_key` creates a NEW goal with a new UUIDv4 correlation ID and new downstream idempotency keys (SHA-256 of new goal_id:node_id). The coordinator-level deduplication is safe, but node A2A tasks may re-run if the original dispatch already completed a node-side task.
- The audit trail (journald or JSON-lines) is durable and correlated; it is NOT a recovery database and cannot prove task state on node side after restart.

**Operator-visible degraded states:**
- `Health.check/0` reports `:degraded` if Inventory, Registry, or Audit are unavailable.
- An unreachable audit sink blocks enrollment and state-changing operations (but not diagnostic polling).
- Registry node states reset to `:unknown` after restart and transition to accurate states as polls complete.

Will now write docs/coordinator-restart-recovery.md covering all of the above.
---
author: oompah
created: 2026-07-24 18:08
---
Implementation: Added docs/coordinator-restart-recovery.md with the following sections:

1. **What restarts?** — clarifies OTP process restarts vs. full coordinator restart
2. **What is reconstructed** — Inventory (reads file on init), Registry (seeds from inventory via :reconstruct message), HealthPoller (kills orphans, recovers in-flight tokens, resumes polling), DNS Resolver, Audit
3. **What is permanently lost** — GoalStore goals, Orchestrator in-flight state, caller-key deduplication index
4. **Restart sequence** — Mermaid diagram showing the supervisor start order and reconstruction flow
5. **Explicit unavailable responses** — table of {:error, :not_found} and other explicit responses with recommended caller actions
6. **Safe idempotent resubmission** — how to use caller_key, warning not to reuse goal_id, note that node-side duplicate work is possible for pre-restart dispatches
7. **Operator-visible degraded states** — Health.check/0 output structure, common causes table, audit event types emitted around restart
8. **Limits table** — all configurable bounds with correct config keys verified against source
9. **Audit trail is and is not** — explicit statement that it is a compliance record, not a recovery database
10. **Testing** — pointers to specific test names (verified against test files)

Also updated docs/README.md to list the new document.

All 201 tests pass (10 excluded). All defaults and test names verified against source code.
---
author: oompah
created: 2026-07-24 18:08
---
Focus handoff: docs

Outcome: Documentation complete. Added docs/coordinator-restart-recovery.md — a comprehensive operator and developer reference for volatile restart behavior, covering the full reconstruction sequence, permanent losses, safe resubmission, operator-visible degraded states, limits, and the audit trail boundary. Updated docs/README.md to include the new document. All 201 tests pass.

Relevant files and decisions:
- docs/coordinator-restart-recovery.md (new)
- docs/README.md (updated Contents section)
- All module docstrings and test names in the document verified against live source files
- Defaults in limits table verified against @default_* module attributes
- Config key names verified against GenServer init opts

Remaining work/risks:
- The feature implementation (EXOCOMP-103 foundations + coordinator reconstruction code) and restart-focused tests described in the issue description are not yet implemented. The docs written here accurately describe the EXISTING partial behavior (Registry reconstruct, HealthPoller orphan recovery) and the MISSING behavior (GoalStore and Orchestrator are volatile with no reconstruction). The test focus should add targeted restart-scenario tests per the issue's acceptance criteria.

Recommended next focus: feature (to implement GoalStore/Orchestrator post-restart query via deterministic keys and node A2A re-query) and test (to add restart-focused test coverage per the issue description).
---
author: oompah
created: 2026-07-24 18:08
---
Added docs/coordinator-restart-recovery.md documenting volatile restart behavior, reconstruction sequence, explicit unavailable responses, safe idempotent resubmission, operator-visible degraded states, limits, and audit trail boundaries. Updated docs/README.md. All defaults, config keys, and test names verified against source. All 201 tests pass.
---
author: oompah
created: 2026-07-24 18:09
---
Agent completed successfully in 372s (13016 tokens)
---
author: oompah
created: 2026-07-24 18:09
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 72, Tool calls: 55
- Tokens: 39 in / 13.0K out [13.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 6m 12s
- Log: EXOCOMP-104__20260724T180252Z.jsonl
---
author: oompah
created: 2026-07-31 20:46
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
<!-- COMMENTS:END -->

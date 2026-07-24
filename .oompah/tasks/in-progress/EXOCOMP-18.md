---
id: EXOCOMP-18
type: feature
status: In Progress
priority: 1
title: Implement coordinator diagnostic task orchestration and audit
parent: EXOCOMP-2
children:
- EXOCOMP-99
- EXOCOMP-100
- EXOCOMP-101
- EXOCOMP-102
blocked_by:
- EXOCOMP-14
- EXOCOMP-15
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:09:31.642631Z'
updated_at: '2026-07-24T04:29:44.294880Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7c9652ee-3c12-4c6e-990e-d9cc42870a22
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 12
  total_output_tokens: 4118
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 12
      output_tokens: 4118
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 12
    output_tokens: 4118
    cost_usd: 0.0
    recorded_at: '2026-07-24T04:28:09.200736+00:00'
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Implement coordinator diagnostic task orchestration and audit.

Implementation
Create correlation IDs and idempotency keys; dispatch diagnostic A2A tasks; collect partial results; propagate cancellation when possible; bound concurrency/history/output; write goal, downstream state, result, and failure audit events; rebuild live state after restart without a database.

Testing
Test duplicate submissions, partial node failure, timeout, cancellation, task eviction, restart loss and safe resubmission, audit redaction, and unavailable audit sink.

Acceptance Criteria
- [ ] Cluster diagnostics return explicit success and failure per node.
- [ ] Duplicate submissions do not create duplicate downstream work.
- [ ] Volatile restart behavior is documented and safely resubmittable.
- [ ] Every task transition is correlated in durable audit.
- [ ] Focused tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 04:26
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 04:26
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 04:27
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-18 is a unique task covering coordinator diagnostic task orchestration — distinct from every other task in the EXOCOMP-2 epic.

**Evidence reviewed (all candidates with full tracker reads):**
- EXOCOMP-14 (Done): Scaffolds coordinator Inventory/Registry/ETS Audit sink infrastructure — foundational plumbing only; no A2A task dispatch, no correlation IDs, no idempotency keys.
- EXOCOMP-15 (Done): DNS hostname resolution and concurrent health polling — polls Agent Card health only; does NOT dispatch diagnostic tasks or collect diagnostic results.
- EXOCOMP-16 (Done): Coordinator CA initialization and enrollment tokens — PKI-only scope; zero overlap with diagnostic orchestration.
- EXOCOMP-17 (Done): Node enrollment and certificate renewal — node-side identity only; no orchestration or audit events of the type EXOCOMP-18 requires.
- EXOCOMP-19 (Open): Exposes the coordinator cluster A2A HTTP endpoints (Agent Card, send/get/list/cancel handlers, authorization) — the *external surface*; EXOCOMP-18 is the *internal orchestration logic* that EXOCOMP-19's handlers will delegate to.
- EXOCOMP-20 (Open): Milestone verification only; no implementation.
- EXOCOMP-88–92 (children of EXOCOMP-15, all Done): DNS resolver, mTLS address adoption, poll scheduling, concurrency, integration — none touch diagnostic task dispatch.
- Prior duplicate_detector agents on EXOCOMP-14, EXOCOMP-15, EXOCOMP-16, EXOCOMP-17, and EXOCOMP-88 each explicitly listed EXOCOMP-18 as a *distinct* sibling task with no overlap.

**Relevant files for feature agent:**
- plans/milestone-2-coordinator.md — §Task Orchestration (correlation IDs/idempotency keys, partial results, cancellation, audit events, restart rebuilding), §Test Strategy (M2-CRIT-3 through M2-CRIT-6), §Audit
- apps/exocomp_coordinator/ — implementation surface (EXOCOMP-14 supplies Inventory, Registry, Audit, Health foundation)
- apps/exocomp_core/ — shared A2A protocol types (from EXOCOMP-8)
- Makefile — `make test`, `make lint`, `make fmt-check` quality gates

**Remaining work (for feature agent):**
1. Implement `Exocomp.Coordinator.Orchestrator` (or similar) — creates UUIDv4 correlation IDs and idempotency keys per goal
2. Dispatch diagnostic A2A tasks to nodes via A2A 1.0 client; collect partial results; propagate cancellation
3. Bound concurrency, task history, and output per M2 spec
4. Write correlated audit events: goal accepted, downstream task dispatched, result received, failure recorded
5. Rebuild live orchestrator state after coordinator restart without a database (from Inventory + re-querying node A2A state)
6. Tests covering: duplicate submissions (idempotency), partial node failure, timeout, cancellation, task eviction, restart loss and safe resubmission, audit redaction, unavailable audit sink
7. Run `make test && make lint && make fmt-check`

**Risks:**
- This task is blocked by EXOCOMP-14 (Done) and EXOCOMP-15 (Done) — both blockers cleared; feature agent should verify epic-EXOCOMP-2 branch includes their work
- EXOCOMP-19 (cluster A2A HTTP service) will depend on the Orchestrator interface produced here; the interface contract matters
- Idempotency key design must survive coordinator restart (stateless re-derivation or durable key store)
- Audit sink from EXOCOMP-14 is JSON-lines only; orchestration events must be compatible with that sink

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-24 04:28
---
Agent completed successfully in 92s (4130 tokens)
---
author: oompah
created: 2026-07-24 04:28
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 25, Tool calls: 16
- Tokens: 12 in / 4.1K out [4.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 32s
- Log: EXOCOMP-18__20260724T042640Z.jsonl
---
author: oompah
created: 2026-07-24 04:28
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 04:28
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 04:28
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-24 04:28
---
Understanding: This focus will decompose EXOCOMP-18 into concrete, single-session child tasks covering orchestration, dispatch/result handling, bounded state and restart recovery, correlated audit, documentation, and focused verification. I will inspect existing children first, avoid duplicates, set child dependencies, then return the epic to Backlog with an epic_planner handoff; no code will be implemented in this focus.
---
author: oompah
created: 2026-07-24 04:29
---
Discovery: The milestone contract is concentrated in plans/milestone-2-coordinator.md (Coordinator Task Flow, A2A Interface, Audit, M2-CRIT-5/6). The displayed tracker state contains no existing children. Current checkout is the epic branch behind the completed foundation branches: coordinator currently has only its empty supervisor, while EXOCOMP-14/15 implementations are visible in git history on their epic branches. Decomposition therefore separates stable protocol/client and in-memory task primitives from fan-out aggregation, cancellation, audit, restart recovery/docs, and final integration verification; implementation children must begin from a branch containing the completed EXOCOMP-14/15 foundations.
---
<!-- COMMENTS:END -->

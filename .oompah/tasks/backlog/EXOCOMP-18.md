---
id: EXOCOMP-18
type: feature
status: Backlog
priority: 1
title: Implement coordinator diagnostic task orchestration and audit
parent: EXOCOMP-2
children:
- EXOCOMP-99
- EXOCOMP-100
- EXOCOMP-101
- EXOCOMP-102
- EXOCOMP-103
- EXOCOMP-104
- EXOCOMP-105
blocked_by:
- EXOCOMP-14
- EXOCOMP-15
labels:
- focus-complete:duplicate_detector
- focus-complete:epic_planner
assignee: null
created_at: '2026-07-23T19:09:31.642631Z'
updated_at: '2026-07-24T04:31:14.240640Z'
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
author: oompah
created: 2026-07-24 04:30
---
Implementation (planning): Created seven explicit children: EXOCOMP-99 A2A client adapter; EXOCOMP-100 volatile store/idempotency/bounds; EXOCOMP-101 fan-out and partial results; EXOCOMP-102 cancellation; EXOCOMP-103 correlated durable audit; EXOCOMP-104 restart reconstruction and operator docs; EXOCOMP-105 end-to-end verification. Set the graph so 99 and 100 unblock 101, followed by 102 -> 103 -> 104 -> 105. Each child includes focused test expectations and a single coherent ownership boundary.
---
author: oompah
created: 2026-07-24 04:30
---
Verification: Re-read EXOCOMP-18 and confirmed all seven children are attached in Backlog; tracker accepted every dependency edge (101<-99/100, 102<-101, 103<-102, 104<-103, 105<-104). Coverage maps to every stated implementation/testing item and acceptance criterion, including explicit per-node failures, duplicate suppression, bounds/eviction, cancellation, restart-safe resubmission documentation, correlated redacted audit, sink outage, and affected Make gates. No repository files were changed in this planning-only focus, so code quality gates were not applicable.
---
author: oompah
created: 2026-07-24 04:30
---
Focus handoff: epic_planner

Completion outcome: EXOCOMP-18 is fully decomposed into EXOCOMP-99 through EXOCOMP-105, with independent client/state foundations and an ordered implementation/integration path. No code was changed.

Evidence and decisions: plans/milestone-2-coordinator.md Coordinator Task Flow, A2A Interface, Audit, and M2-CRIT-5/6 define the split. EXOCOMP-99 and EXOCOMP-100 may run in parallel; dependencies then serialize EXOCOMP-101 -> 102 -> 103 -> 104 -> 105. The final child owns the complete focused matrix and make test/lint/fmt-check gates.

Risks and remaining work: the current epic checkout is behind completed EXOCOMP-14/15 branches and contains only the coordinator supervisor, so child branches must include those foundations before implementation. Preserve the EXOCOMP-19-facing orchestrator API, deterministic restart-safe idempotency, explicit uncertainty after volatile loss, and the audit-outage diagnostic availability policy. Existing untracked coordinator tmp fixtures were observed and left untouched.

Recommended next focus: feature agents should execute ready children EXOCOMP-99 and EXOCOMP-100; keep the parent epic in Backlog until all children complete.
---
author: oompah
created: 2026-07-24 04:31
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 0, Tool calls: 31
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 57s
- Log: EXOCOMP-18__20260724T042817Z.jsonl
---
<!-- COMMENTS:END -->

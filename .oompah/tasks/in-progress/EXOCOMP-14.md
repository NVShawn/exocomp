---
id: EXOCOMP-14
type: feature
status: In Progress
priority: 1
title: Scaffold coordinator inventory, registry, and audit
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-7
- EXOCOMP-8
labels:
- focus-complete:duplicate_detector
- focus-complete:epic_planner
assignee: null
created_at: '2026-07-23T19:09:28.257166Z'
updated_at: '2026-07-23T22:19:28.627821Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 39ffb9b1-df50-493f-9c36-9c4afcbb0541
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 5643395
  total_output_tokens: 52323
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 5643395
      output_tokens: 52323
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 566847
    output_tokens: 3085
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:53:03.192207+00:00'
  - profile: standard
    model: unknown
    input_tokens: 21
    output_tokens: 4194
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:55:07.587833+00:00'
  - profile: standard
    model: unknown
    input_tokens: 448032
    output_tokens: 3518
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:56:55.605606+00:00'
  - profile: deep
    model: unknown
    input_tokens: 615499
    output_tokens: 3982
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:59:19.547888+00:00'
  - profile: standard
    model: unknown
    input_tokens: 23
    output_tokens: 7585
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:06:58.855501+00:00'
  - profile: standard
    model: unknown
    input_tokens: 4012973
    output_tokens: 29959
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:19:09.221222+00:00'
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Scaffold coordinator inventory, registry, and audit.

Implementation
Implement coordinator supervision; versioned JSON inventory parsing; atomic inventory replacement; ETS node registry; configured journald or bounded JSON-lines audit sink; structured health and error reporting.

Testing
Test malformed inventory, duplicate IDs and certificate identities, failed replacement retaining prior state, registry reconstruction, sink redaction, and audit outage behavior.

Acceptance Criteria
- [ ] Valid inventory loads atomically.
- [ ] Invalid replacement leaves prior inventory active.
- [ ] Registry is reconstructible after restart.
- [ ] Audit output is correlated and redacted.
- [ ] Focused tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:51
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:51
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:53
---
Agent completed successfully in 95s (569932 tokens)
---
author: oompah
created: 2026-07-23 21:53
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 9
- Tokens: 566.8K in / 3.1K out [569.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 35s
- Log: EXOCOMP-14__20260723T215131Z.jsonl
---
author: oompah
created: 2026-07-23 21:53
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-2`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:53
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:54
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-14 is a unique foundational task with no overlap in the existing task graph.

**Evidence reviewed:**
- Searched plans/, docs/, and README.md for coordinator, inventory, registry, audit keywords
- Reviewed all EXOCOMP-2 children: EXOCOMP-15 (DNS polling), EXOCOMP-16 (CA/enrollment tokens), EXOCOMP-17 (enrollment/renewal), EXOCOMP-18 (orchestration audit), EXOCOMP-19 (A2A service), EXOCOMP-20 (verification)
- Closest candidate was EXOCOMP-18 (Implement coordinator diagnostic task orchestration and audit) — but EXOCOMP-18 covers task-orchestration-specific audit events (correlation IDs, goal/result events) while EXOCOMP-14 creates the underlying audit sink infrastructure (journald/JSON-lines sink, ETS registry, OTP supervisor tree, inventory parser). These are complementary, not duplicates.
- EXOCOMP-7 (Done): Elixir umbrella scaffold — provides apps/exocomp_coordinator but no coordinator logic
- EXOCOMP-8 (Done): A2A 1.0 protocol types — provides shared protocol layer that the coordinator will use

**Relevant files:**
- plans/milestone-2-coordinator.md — Inventory and Discovery section, Node State section, Audit section; acceptance criteria M2-CRIT-1 and M2-CRIT-6
- apps/exocomp_coordinator/ — existing stub app from EXOCOMP-7 (OTP app structure, no coordinator logic)
- apps/exocomp_core/ — shared A2A types from EXOCOMP-8

**Remaining work (for feature agent):**
1. Coordinator OTP supervisor tree (Exocomp.Coordinator.Application with sub-supervisors for inventory, registry, audit)
2. Versioned JSON inventory parser: validate schema, reject duplicate node IDs/identities, atomic replacement (keep prior state on failure)
3. ETS-backed node registry: load from inventory, reconstructible after restart
4. Audit sink: journald adapter + bounded JSON-lines file sink, with redaction and structured events
5. Structured health and error reporting modules
6. Tests: malformed inventory, duplicate IDs/cert identities, failed replacement retaining prior state, registry reconstruction, sink redaction, audit outage behavior
7. Run make test, make lint, make fmt-check

**Risks:**
- EXOCOMP-7 and EXOCOMP-8 are both Done (blockers cleared). Branch EXOCOMP-14 should be based on the merged work from those branches.
- The feature agent should check which branch to base EXOCOMP-14 off (main vs the M2 epic branch epic-EXOCOMP-2)
- Journald integration requires systemd_journal Erlang dependency — may need to add to mix.exs

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-23 21:55
---
Agent completed successfully in 102s (4215 tokens)
---
author: oompah
created: 2026-07-23 21:55
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 37, Tool calls: 28
- Tokens: 21 in / 4.2K out [4.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 42s
- Log: EXOCOMP-14__20260723T215328Z.jsonl
---
author: oompah
created: 2026-07-23 21:55
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:55
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:55
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 21:56
---
Agent completed successfully in 98s (451550 tokens)
---
author: oompah
created: 2026-07-23 21:56
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 8
- Tokens: 448.0K in / 3.5K out [451.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 38s
- Log: EXOCOMP-14__20260723T215519Z.jsonl
---
author: oompah
created: 2026-07-23 21:56
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-2`. Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:57
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-23 21:57
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 21:59
---
Agent completed successfully in 122s (619481 tokens)
---
author: oompah
created: 2026-07-23 21:59
---
Run #2 [attempt=2, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 9
- Tokens: 615.5K in / 4.0K out [619.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 2s
- Log: EXOCOMP-14__20260723T215721Z.jsonl
---
author: oompah
created: 2026-07-23 21:59
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-2`. No stronger profile is configured; retrying with 'deep' in 20s (2/3).
---
author: oompah
created: 2026-07-23 21:59
---
Retrying (attempt #2, agent: standard)
---
author: oompah
created: 2026-07-23 21:59
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 22:01
---
Understanding: EXOCOMP-14 is a leaf feature task (child of EXOCOMP-2 epic), not a sub-epic itself. The scope covers: (1) coordinator OTP supervisor tree, (2) versioned JSON inventory parser with atomic replacement, (3) ETS-backed node registry, (4) journald/JSON-lines audit sink with redaction, (5) structured health/error reporting, and (6) focused tests for all of the above. Blockers EXOCOMP-7 (umbrella scaffold) and EXOCOMP-8 (A2A types) are both Done. The codebase currently has only an empty coordinator Application stub. No child tasks are needed — this is a single-session feature implementation task. Will hand off to feature agent.
---
author: oompah
created: 2026-07-23 22:06
---
Focus handoff: epic_planner

**Outcome:** EXOCOMP-14 is a leaf feature task — not a sub-epic — and does NOT require child task decomposition. It should be implemented directly by a feature agent. No children were created.

**Evidence reviewed:**
- EXOCOMP-2 already has 7 well-scoped children (EXOCOMP-14 through EXOCOMP-20), each sized for a single agent session. EXOCOMP-14 is one of them.
- Existing codebase: `apps/exocomp_coordinator/` has only an empty OTP Application stub (no logic). `apps/exocomp_core/` has only `Exocomp.Protocol.version/0` and an empty supervisor. Blockers EXOCOMP-7 and EXOCOMP-8 are Done.
- Branch `EXOCOMP-14` is based on main (last commit 1db1135, includes EXOCOMP-7 and EXOCOMP-8 work).
- plans/milestone-2-coordinator.md §§ Inventory and Discovery, Node State, Audit are the authoritative spec.

**Key files for feature agent:**
- `apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex` — empty OTP Application (start here)
- `apps/exocomp_coordinator/mix.exs` — add deps here (Jason for JSON parsing; journald dep if available)
- `apps/exocomp_coordinator/test/exocomp/coordinator/application_test.exs` — existing test pattern
- `apps/exocomp_core/lib/exocomp/protocol.ex` — protocol version constant
- `Makefile` — use `make test`, `make lint`, `make fmt-check` for quality gates
- `plans/milestone-2-coordinator.md` — full design spec

**Work required (feature agent):**
1. Add Jason (JSON parsing) dependency to apps/exocomp_coordinator/mix.exs
2. Implement `Exocomp.Coordinator.Inventory` GenServer: versioned JSON parsing, schema validation, duplicate node ID/identity rejection, atomic replacement (retain prior state on failure)
3. Implement `Exocomp.Coordinator.Registry` module: ETS-backed node registry, load from inventory, support registry reconstruction after restart
4. Implement `Exocomp.Coordinator.Audit` GenServer: journald adapter OR bounded JSON-lines file sink, structured/correlated events, redaction of sensitive fields, graceful degradation on outage
5. Wire all three into `Exocomp.Coordinator.Application` supervisor tree with appropriate restart strategies
6. Implement `Exocomp.Coordinator.Health` for structured health/error reporting
7. Write focused tests: malformed inventory, duplicate IDs, duplicate cert identities, failed replacement retaining prior inventory, registry reconstruction, sink redaction, audit outage behavior
8. Run `make test && make lint && make fmt-check`; commit and push

**Risks:**
- Journald integration may require `systemd_journal` Erlang dep; if unavailable in the container image, fall back to JSON-lines only and note it
- The container build uses Alpine Linux — journald may not be available; JSON-lines sink is the safe default
- Jason is not yet in mix.lock; it will need to be fetched inside the container
- The coordinator release is already defined in root mix.exs; no release config changes needed

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-23 22:06
---
Agent completed successfully in 432s (7608 tokens)
---
author: oompah
created: 2026-07-23 22:07
---
Run #3 [attempt=3, profile=standard, role=standard -> Claude/default]
- Turns: 47, Tool calls: 35
- Tokens: 23 in / 7.6K out [7.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 7m 12s
- Log: EXOCOMP-14__20260723T215948Z.jsonl
---
author: oompah
created: 2026-07-23 22:07
---
Focus handoff from `epic_planner` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 22:07
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:07
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-23 22:19
---
Agent completed successfully in 720s (4042932 tokens)
---
author: oompah
created: 2026-07-23 22:19
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 42
- Tokens: 4.0M in / 30.0K out [4.0M total]
- Cost: $0.0000
- Exit: normal, Duration: 12m 0s
- Log: EXOCOMP-14__20260723T220711Z.jsonl
---
author: oompah
created: 2026-07-23 22:19
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-2`. Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 22:19
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-23 22:19
---
Focus: Software Engineer
---
<!-- COMMENTS:END -->

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
assignee: null
created_at: '2026-07-23T19:09:28.257166Z'
updated_at: '2026-07-23T21:57:21.050278Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 9773fe7b-f5a2-4a85-b264-e771508b2d44
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 1014900
  total_output_tokens: 10797
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1014900
      output_tokens: 10797
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
<!-- COMMENTS:END -->

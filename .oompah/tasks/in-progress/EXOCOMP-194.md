---
id: EXOCOMP-194
type: task
status: In Progress
priority: 2
title: Define desired-service status events and contract fixtures
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-139
- EXOCOMP-193
labels: []
assignee: null
created_at: '2026-07-30T21:37:04.090360Z'
updated_at: '2026-08-01T17:28:53.004379Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-194
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 326449b4ff80a5a30ebd03bc178761927d5a1837f71ab3b9353cba3547843a04
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T16:05:02.166080+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-179, EXOCOMP-152, EXOCOMP-193, EXOCOMP-192,
    and EXOCOMP-149. EXOCOMP-179 explicitly depends on EXOCOMP-194 and consumes its
    fixtures; the others own reconciliation, persistence, scheduling, or ingestion.
    Terminal EXOCOMP-139 and EXOCOMP-189 were excluded. No active duplicate claims
    the desired-service event schema.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 9f0948b4-6486-4478-95ca-c4d1622bd1b3
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-194
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-194
  base_branch: epic-EXOCOMP-185
  base_sha: ce0330d8cb83c6467cdfd072f125dc46b04bbff5
  updated_at: '2026-08-01T17:10:37.951595+00:00'
oompah.task_costs:
  total_input_tokens: 874472
  total_output_tokens: 5054
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 874472
      output_tokens: 5054
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 874472
    output_tokens: 5054
    cost_usd: 0.0
    recorded_at: '2026-08-01T16:05:02.164613+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-194__20260801T160259Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-185--task-EXOCOMP-194
    source_sha: 7b3ff4a831259ec5555de09214348b3da5eb554e
    completed_at: '2026-08-01T16:05:02.173946+00:00'
---
## Summary

Plan: plans/mission-control.md, connection protocol and fleet status.

Deliverable: Extend the versioned Mission Control protocol with bounded desired-state changes, service-status changes, profile coverage, and periodic service summary snapshots.

Acceptance criteria:
- Events carry node, unit, source set, health depth, recovery authority, observation time, evidence references, and correlation ID.
- Initial snapshot plus deltas reconstruct the current view idempotently.
- Payloads are size-bounded, redacted, and forward-version checked.
- Duplicate and out-of-order fixtures define deterministic behavior.
- Shared fixtures are consumable by coordinator and Mission Control tests.

Tests: Add encode/decode, schema rejection, bounds, redaction, duplicate, ordering, and reconstruction tests; run make test.

Out of scope: Database migrations, incident reduction, LiveView rendering, and Ceph collection.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 16:02
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 16:02
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 16:05
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 15
- Tokens: 874.5K in / 5.1K out [879.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 10s
- Log: EXOCOMP-194__20260801T160259Z.jsonl
---
author: oompah
created: 2026-08-01 17:10
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 17:10
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 17:10
---
Understanding: extend the versioned Mission Control protocol with bounded desired-state and service-status events plus periodic summaries and shared fixtures. I will first map the existing protocol and adjacent coordinator/reconciliation contracts, then implement focused encode/decode, schema, bounds, redaction, duplicate/order, and reconstruction coverage before running make test.
---
author: oompah
created: 2026-08-01 17:14
---
Discovery: the scheduler now exposes resolver-backed expectations, profile context, recovery authority, per-service health/hysteresis, observation timestamps, and correlated transitions. The earlier generic Mission Control envelope is on a separate sibling branch, so this task needs a shared core contract. I will model strict desired_state.added/changed/removed, service_status.changed, and service_summary.snapshot payloads, plus deterministic replay and shared JSON fixtures.
---
author: oompah
created: 2026-08-01 17:27
---
Implementation: added exocomp_core Mission Control status event/codec/reducer modules, strict v1 payloads for desired-state deltas, service-status deltas, profile coverage, and summary snapshots; added coordinator facades; added root shared JSON fixtures for valid events, duplicate delivery, and out-of-order delivery; documented replay and bounds in plans/mission-control.md. Focused suite passes 13/13 in a local Jason-compatible compile smoke.
---
author: oompah
created: 2026-08-01 17:28
---
Verification: focused shared-core plus coordinator-facade contract tests pass 13/13 using compiled Elixir/Jason sources; warning-as-error compile passes for all new production modules; all seven JSON fixtures parse and git diff --check passes. make test passes offline builder/package checks but cannot enter the pinned Elixir container because Podman reports its runtime filesystem is read-only. make compliance-check is blocked by 12 pre-existing trailing-whitespace errors in unrelated inventory tests.
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-154
type: task
status: In Progress
priority: 1
title: Add incident records and deterministic fingerprints
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-152
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:38.872090Z'
updated_at: '2026-08-01T12:35:03.790443Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-154
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 9f0e14f810f08751a854544e673bffb6d609bfe4ab68b5aecaedc771e40bc3b1
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:32:12.111347+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active task records including EXOCOMP-131,\
    \ 149, 152, 155, 156, and 157. They are parent, ingestion, state, transition,\
    \ workflow, and grouping work respectively; several explicitly depend on or exclude\
    \ EXOCOMP-154\u2019s incident-record scope."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: d6ac0ad4-a998-41c0-a65a-75022192d02d
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-154
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-154
  base_branch: epic-EXOCOMP-131
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:32:30.223926+00:00'
oompah.task_costs:
  total_input_tokens: 614786
  total_output_tokens: 3786
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 614786
      output_tokens: 3786
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 614786
    output_tokens: 3786
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:32:12.110141+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-154__20260801T123039Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-131--task-EXOCOMP-154
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:32:12.116665+00:00'
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add organization-scoped incident and incident-event schemas with open, acknowledged, and resolved states.
- Implement the fingerprint from organization, cluster, alert type, source, target type, and target identity.
- Upsert repeated evidence into one incident and preserve a correlated timeline.

Acceptance:
- Tests cover identical alerts, distinct targets, distinct organizations, concurrent opens, resolved recurrence, and event ordering.
- Fingerprints are stable and contain no secret/raw-log data.

Out of scope: health thresholds and operator workflow mutations.
Quality gate: focused incident tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:30
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:30
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:32
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 13
- Tokens: 614.8K in / 3.8K out [618.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 40s
- Log: EXOCOMP-154__20260801T123039Z.jsonl
---
author: oompah
created: 2026-08-01 12:32
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:32
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 12:32
---
Understanding: I will inspect the existing model, storage, and migration/test patterns plus plans/mission-control.md; implement organization-scoped incidents/events, deterministic secret-free fingerprints, atomic repeated-evidence upsert, and correlated event ordering; then run focused tests and all required quality gates before committing, pushing, and submitting.
---
author: oompah
created: 2026-08-01 12:35
---
Discovery: the current base has no Mission Control app, Ecto schemas, Repo, or database migration infrastructure; the roadmap is the only incident contract. Existing coordinator stores use isolated GenServers and immutable structs, with serialization/redaction patterns already established. I will add a dependency-free Mission Control incident domain/context that can be adopted by the later persistence foundation: explicit Incident and IncidentEvent records, canonical length-prefixed fingerprinting, atomic GenServer upsert, and timeline sorting by occurred_at plus stable insertion sequence.
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-156
type: task
status: In Progress
priority: 2
title: Add incident acknowledgement, assignment, snooze, and resolution
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-141
- EXOCOMP-155
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:41.639331Z'
updated_at: '2026-08-01T14:56:15.108956Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-156
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: ae6f531a3ba8cde371b450e3f714c337113882ff9519d65691008ea01894d380
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:55:55.435690+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-154, 155, 157, 167, 141, 171, 152, and 153.
    Their scopes are incident records, health transitions, grouping, UI consumption,
    authorization, audit storage, fleet state, and history. EXOCOMP-167 explicitly
    depends on EXOCOMP-156; no active task duplicates its backend workflow mutations.
    Terminal tasks were excluded.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: a969e83e-f2d7-49e3-9803-5fcdb63ee8a0
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-156
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-156
  base_branch: epic-EXOCOMP-131
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:56:13.199785+00:00'
oompah.task_costs:
  total_input_tokens: 1352093
  total_output_tokens: 5941
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1352093
      output_tokens: 5941
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 1352093
    output_tokens: 5941
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:55:55.430459+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-156__20260801T145319Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-131--task-EXOCOMP-156
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:55:55.444875+00:00'
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add authorized context functions to acknowledge, assign/unassign, snooze/unsnooze, and manually resolve an incident.
- Require and store a reason for manual resolution.
- Record operator subject, organization, timestamp, and correlation ID for every mutation.

Acceptance:
- Role-matrix tests cover viewer denial and operator/admin success.
- Tests cover invalid transitions, snooze expiry, reassignment, concurrent mutation, and cross-organization IDs.
- New unhealthy evidence still reopens a manually resolved incident.

Out of scope: LiveView controls and notifications.
Quality gate: focused workflow tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:53
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:55
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 21
- Tokens: 1.4M in / 5.9K out [1.4M total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 46s
- Log: EXOCOMP-156__20260801T145319Z.jsonl
---
author: oompah
created: 2026-08-01 14:56
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:56
---
Focus: Maintenance Engineer
---
<!-- COMMENTS:END -->

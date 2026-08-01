---
id: EXOCOMP-155
type: task
status: In Progress
priority: 1
title: Implement incident health-transition rules
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-154
start_blocked_by: &id001
- EXOCOMP-193
- EXOCOMP-200
labels: []
assignee: null
created_at: '2026-07-30T14:15:39.771394Z'
updated_at: '2026-08-01T23:01:47.531662Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-155
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: c8126b3670c097f541a336f7e8c0209296b74c91fda5460a1f77314b54d0ff7e
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:34:33.230839+00:00'
  matched_identifiers: []
  evidence: 'Acknowledged. The coordination message confirms that EXOCOMP-154 (a dependency
    and epic-sibling) has started implementation. This reinforces that EXOCOMP-155
    is a distinct task blocked by EXOCOMP-154''s completion, not a duplicate of it.


    My investigation conclusion remains unchanged:


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** Comprehensive search across the codebase found no existing incident
    reducer implementation, incident state management, or parallel health-transition
    logic. The mission-control.md plan documents the requirements for EXOCOMP-155,
    but no code exists. The coordinator has foundational health monitoring (health_poller,
    node_prober) for node-level observations, but not the Mission Control incident
    reduction rules (two consecutive degraded/healthy observations, explicit alert
    severity mapping, manual/auto resolution). EXOCOMP-154 is a dependency (currently
    starting implementation), not a duplicate. EXOCOMP-155 is original implementation
    work that will begin once EXOCOMP-154 completes.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 10ce6f6e-c973-4eec-9134-985e0e901af0
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-155
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-155
  base_branch: epic-EXOCOMP-131
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T23:01:44.694357+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 561
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 561
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 561
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:34:33.230105+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-155__20260801T123225Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-131--task-EXOCOMP-155
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:34:33.259918+00:00'
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Open health incidents after two consecutive degraded observations.
- Open immediately for stale/unreachable state and identity, authentication, audit, policy, or remediation failures.
- Open explicit cluster alerts and apply deterministic severity mapping.
- Auto-resolve health incidents after two consecutive healthy observations; reopen on new matching unhealthy evidence.

Acceptance:
- Table-driven reducer tests cover every rule, threshold boundary, interleaved target, duplicate observation, manual-resolution recurrence, and explicit resolve event.
- No model is used for opening, grouping, or resolving incidents.

Out of scope: operator acknowledgement and UI.
Quality gate: focused reducer tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: reduce service and profile health into incidents. Use two observations for unhealthy/WARN transitions, immediate critical alerts for Ceph HEALTH_ERR, explicit coverage incidents, and desired_state_removed resolution without creating a false recovery observation.
---
author: oompah
created: 2026-08-01 12:32
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:32
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:34
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 60, Tool calls: 31
- Tokens: 10 in / 561 out [571 total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 16s
- Log: EXOCOMP-155__20260801T123225Z.jsonl
---
author: oompah
created: 2026-08-01 23:01
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 23:01
---
Focus: Callback Auth Validation Specialist
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-155
type: task
status: Open
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
updated_at: '2026-08-01T12:32:24.283435Z'
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
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: cc19945e-072c-4248-a131-edc8c37f2cda
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:32:15.966637+00:00'
  claim_expires_at: '2026-08-01T13:02:15.966637+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: eb7697f1-caed-450e-a8d5-cb2775983fd4
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-155
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-155
  base_branch: epic-EXOCOMP-131
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:32:21.981317+00:00'
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
<!-- COMMENTS:END -->

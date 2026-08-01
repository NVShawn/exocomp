---
id: EXOCOMP-193
type: task
status: Open
priority: 1
title: Reconcile desired services and health transitions
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-189
- EXOCOMP-192
labels: []
assignee: null
created_at: '2026-07-30T21:37:03.188337Z'
updated_at: '2026-08-01T13:54:44.347219Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-193
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: f9dc2fec670abefb1df3a4e266b8cdb2f1162bf79da6db32a7df3a140611ee6c
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: bdb5537a-e015-473b-9632-4116b73b5f2d
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:54:35.437762+00:00'
  claim_expires_at: '2026-08-01T14:24:35.437762+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: eb6a2158-1629-4558-a8bf-57f8bc0b615c
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-193
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-193
  base_branch: epic-EXOCOMP-185
  base_sha: 6742aa13ef4dc7e3dafa1582cebb5e4550ba9a72
  updated_at: '2026-08-01T13:54:42.198529+00:00'
---
## Summary

Plan: plans/mission-control.md, desired-state reconciliation.

Deliverable: Maintain the coordinator current view of effective service expectations and their latest health.

Acceptance criteria:
- Union manual, automatic, and profile-derived expectations using the shared resolver.
- Require every applicable configured probe to pass.
- Preserve stale or unreachable states explicitly when observation fails.
- Mark removed expectations retired and emit desired_state_removed rather than treating them as failures.
- Confirm unhealthy and recovered state only after two consecutive observations.
- Every transition is correlated and auditable.

Tests: Cover source addition/removal, enable/disable changes, conflicting observations, probe failure, stale nodes, retirement, and two-observation hysteresis; run make test.

Out of scope: Mission Control database writes, UI, incident workflow, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:54
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:54
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

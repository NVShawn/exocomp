---
id: EXOCOMP-142
type: task
status: Open
priority: 1
title: Create one-use cluster invitations
parent: EXOCOMP-129
children: []
blocked_by:
- EXOCOMP-141
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:14:24.463171Z'
updated_at: '2026-08-01T11:54:27.131871Z'
work_branch: epic-EXOCOMP-129--task-EXOCOMP-142
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: a878dc9c2770ae74c029518ed160ca9480609de0e2d6c26628971002a325ce17
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: e6afb1f4-561d-40f3-88bd-70a006afec8c
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T11:54:14.952068+00:00'
  claim_expires_at: '2026-08-01T12:24:14.952068+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: e890ac9b-734a-473a-a58f-c040a354fba2
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-142
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-142
  base_branch: epic-EXOCOMP-129
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T11:54:23.718402+00:00'
---
## Summary

Plan: plans/mission-control.md, Cluster Enrollment and Identity.

Deliverables:
- Add cluster and invitation schemas scoped to an organization.
- Add an admin-only POST /api/v1/cluster-invitations endpoint.
- Generate a random invitation, show it once, store only its digest, and bind it to cluster name and optional labels.
- Add expiry and atomic single-use consumption helpers.

Acceptance:
- Tests cover creation, expiry, replay, wrong organization, duplicate cluster names, and concurrent consumption.
- Invitation plaintext is absent from the database and logs.
- Viewer and operator roles receive a forbidden response.

Out of scope: CSR signing and certificate renewal.
Quality gate: focused context/API tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 11:54
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 11:54
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

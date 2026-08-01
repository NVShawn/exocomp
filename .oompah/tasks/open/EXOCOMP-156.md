---
id: EXOCOMP-156
type: task
status: Open
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
updated_at: '2026-08-01T14:53:16.182185Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-156
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: ae6f531a3ba8cde371b450e3f714c337113882ff9519d65691008ea01894d380
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 58e7b4ad-6057-4b7b-afb4-991f790fddea
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:53:06.081128+00:00'
  claim_expires_at: '2026-08-01T15:23:06.081128+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: d341b2f8-f36b-4614-9ad8-5a57168860c0
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-156
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-156
  base_branch: epic-EXOCOMP-131
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:53:13.207098+00:00'
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
<!-- COMMENTS:END -->

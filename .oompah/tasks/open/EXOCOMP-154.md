---
id: EXOCOMP-154
type: task
status: Open
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
updated_at: '2026-08-01T12:30:38.768920Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-154
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 9f0e14f810f08751a854544e673bffb6d609bfe4ab68b5aecaedc771e40bc3b1
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 4e7f6659-b62c-4526-8c4d-d7a6232b65bf
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:30:30.264717+00:00'
  claim_expires_at: '2026-08-01T13:00:30.264717+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 7a1159d4-a13e-4627-81a1-dfcc75084b1a
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-154
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-154
  base_branch: epic-EXOCOMP-131
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:30:36.198540+00:00'
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
<!-- COMMENTS:END -->

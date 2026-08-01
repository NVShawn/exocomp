---
id: EXOCOMP-181
type: task
status: Open
priority: 1
title: Add Mission Control security negative tests
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-144
- EXOCOMP-141
- EXOCOMP-149
- EXOCOMP-151
- EXOCOMP-162
- EXOCOMP-163
- EXOCOMP-173
- EXOCOMP-179
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:42.487515Z'
updated_at: '2026-08-01T13:17:43.084700Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-181
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 646a4ee9e3ac90b68d4a9fe5d53e640c23cd775cb1c36e4331bf7d2229c2fcef
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 11ebaf2b-0b72-4ee7-95ca-a2961c21d922
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:17:35.024623+00:00'
  claim_expires_at: '2026-08-01T13:47:35.024623+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 4698bd48-8e04-4a9c-9041-b67e6e6065a5
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-181
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-181
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:17:40.888753+00:00'
---
## Summary

Plan: plans/mission-control.md, Test Strategy and Acceptance Criteria.

Deliverables:
- Add negative tests for cross-organization identifiers, forged/expired OIDC identity, revoked/wrong cluster certificates, invitation replay, payload identity override, arbitrary actions/paths, stale or replayed approvals, invalid webhook signatures, and secret/redaction boundaries.
- Add a dependency and container scan appropriate to the Phoenix image.
- Document each failed-closed boundary and its expected audit event.

Acceptance:
- Every listed attack is rejected before mutation or execution.
- Security failures are bounded, correlated, and do not expose secrets.
- The suite runs from one Make target.

Out of scope: external penetration testing.
Quality gate: security target plus make compliance-check, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:17
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:17
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

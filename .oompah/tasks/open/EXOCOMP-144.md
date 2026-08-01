---
id: EXOCOMP-144
type: task
status: Open
priority: 1
title: Add cluster certificate renewal and revocation
parent: EXOCOMP-129
children: []
blocked_by:
- EXOCOMP-143
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:14:27.914202Z'
updated_at: '2026-08-01T11:58:21.556986Z'
work_branch: epic-EXOCOMP-129--task-EXOCOMP-144
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 7f788b690fe18007128498a1d78db1652371cfcd3f0f36c0dc220000f7316674
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 7a50c0f6-98a9-4b27-bb63-bc98b382296a
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T11:58:12.883974+00:00'
  claim_expires_at: '2026-08-01T12:28:12.883974+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 72033011-f451-48af-a69f-40df843b0c92
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-144
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-144
  base_branch: epic-EXOCOMP-129
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T11:58:18.674280+00:00'
---
## Summary

Plan: plans/mission-control.md, Cluster Enrollment and Identity.

Deliverables:
- Add authenticated POST /api/v1/clusters/renew certificate renewal.
- Permit renewal after day 20 for a valid non-revoked cluster identity and rotate the certificate serial.
- Add admin context operations to revoke a cluster and its active certificate serials.
- Expose deterministic certificate status lookup for the connection gateway.

Acceptance:
- Tests cover early renewal, valid renewal, expired certificate, revoked cluster, identity mismatch, concurrent renewal, and signing failure.
- Revoked identities cannot renew.
- Private keys remain coordinator-local.

Out of scope: UI and active WebSocket disconnection.
Quality gate: focused PKI tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 11:58
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 11:58
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

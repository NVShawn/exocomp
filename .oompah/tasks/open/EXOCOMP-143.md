---
id: EXOCOMP-143
type: task
status: Open
priority: 1
title: Issue cluster certificates from validated CSRs
parent: EXOCOMP-129
children: []
blocked_by:
- EXOCOMP-142
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:14:25.708004Z'
updated_at: '2026-08-01T11:56:18.139247Z'
work_branch: epic-EXOCOMP-129--task-EXOCOMP-143
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 61c3ed9793b90e51c9ccee4659a410e6fd66b6995ecb7ead785f83d2833424b8
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: d3886fe3-67b4-4eb1-88e3-340e5925da81
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T11:56:10.964204+00:00'
  claim_expires_at: '2026-08-01T12:26:10.964204+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 3afbfa83-cde1-4f47-8641-35dc143500b3
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-143
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-143
  base_branch: epic-EXOCOMP-129
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T11:56:16.426010+00:00'
---
## Summary

Plan: plans/mission-control.md, Cluster Enrollment and Identity.

Deliverables:
- Add the POST /api/v1/clusters/enroll invitation-and-CSR exchange.
- Validate CSR signature and allowed key parameters.
- Issue a 30-day client certificate from the configured online intermediate using the planned SPIFFE URI identity.
- Persist certificate serial and public metadata; never receive or store the coordinator private key.

Acceptance:
- Tests cover a valid CSR, malformed/unsigned CSR, unsupported key, expired/replayed invitation, wrong cluster binding, and signing failure.
- The returned chain validates to the configured Mission Control trust root.
- The certificate organization and cluster IDs match persisted records.

Out of scope: renewal, revocation, and WebSocket authentication.
Quality gate: focused PKI/API tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 11:56
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 11:56
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

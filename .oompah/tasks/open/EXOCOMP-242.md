---
id: EXOCOMP-242
type: bug
status: Open
priority: 1
title: Repair M7B invitation and SPIFFE certificate regressions
parent: null
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T17:14:37.656789Z'
updated_at: '2026-08-03T17:18:35.625075Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 14c1ea8de63462c2e449fce9b670ce773684e978440c72ad92d1146eb5ea31e9
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 2b082f9d-eb67-4178-b67c-3fc44a7c22f6
  claim_owner: 8a58fb27-42d0-40cf-8dc2-70615b9783dc
  claimed_at: '2026-08-03T17:18:21.551445+00:00'
  claim_expires_at: '2026-08-03T17:48:21.551445+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 71ec1c6c-444a-4347-9a66-e1a71c5fb0aa
---
## Summary

Triggered by: EXOCOMP-143

The integrated EXOCOMP-142/143 parent fails the repository make test gate. Repair the cluster invitation and certificate-enrollment regressions in apps/exocomp_coordinator: use the OTP/X509 GeneralName representation accepted by the pinned runtime for SPIFFE URI SANs in both CSR fixtures and production certificate issuance; correct the cluster-invitation test helper's attrs normalization; make its clock fixture lifecycle-safe; and ensure a request with no authentication deterministically returns 401 without leaking async test context. Add or retain regression coverage proving valid CSR issuance, multiple/wrong SPIFFE identity rejection, invitation expiry/replay behavior, plaintext-token non-persistence, and missing-auth rejection. Acceptance: make fmt-check, make test, and make lint pass on the repaired branch, including release smoke tests.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 17:18
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 17:18
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-242
type: bug
status: In Progress
priority: 1
title: Repair M7B invitation and SPIFFE certificate regressions
parent: null
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T17:14:37.656789Z'
updated_at: '2026-08-03T17:14:52.250766Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
---
## Summary

Triggered by: EXOCOMP-143

The integrated EXOCOMP-142/143 parent fails the repository make test gate. Repair the cluster invitation and certificate-enrollment regressions in apps/exocomp_coordinator: use the OTP/X509 GeneralName representation accepted by the pinned runtime for SPIFFE URI SANs in both CSR fixtures and production certificate issuance; correct the cluster-invitation test helper's attrs normalization; make its clock fixture lifecycle-safe; and ensure a request with no authentication deterministically returns 401 without leaking async test context. Add or retain regression coverage proving valid CSR issuance, multiple/wrong SPIFFE identity rejection, invitation expiry/replay behavior, plaintext-token non-persistence, and missing-auth rejection. Acceptance: make fmt-check, make test, and make lint pass on the repaired branch, including release smoke tests.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


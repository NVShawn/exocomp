---
id: EXOCOMP-143
type: task
status: Backlog
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
updated_at: '2026-07-30T14:20:07.353440Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


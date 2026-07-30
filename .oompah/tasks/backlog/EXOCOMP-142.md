---
id: EXOCOMP-142
type: task
status: Backlog
priority: 1
title: Create one-use cluster invitations
parent: EXOCOMP-129
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:14:24.463171Z'
updated_at: '2026-07-30T14:14:24.463171Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


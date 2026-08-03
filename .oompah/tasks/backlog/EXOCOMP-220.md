---
id: EXOCOMP-220
type: task
status: Backlog
priority: 1
title: Manage Mission Control policy-signing keys
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-219
labels: []
assignee: null
created_at: '2026-08-03T14:25:11.140193Z'
updated_at: '2026-08-03T14:30:40.525299Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Provision and rotate the dedicated online Ed25519 policy-signing key and publish its verification chain to enrolled clusters.

Acceptance criteria:
- Private keys use protected runtime secret storage and are never written to audit, logs, fixtures, or API responses.
- Every key has a stable key ID and activation/retirement timestamps.
- Rotation permits the current and immediately previous verification keys during a bounded overlap.
- Missing, corrupt, insecurely permissioned, or mismatched keys make bundle issuance unavailable without affecting read-only Mission Control operation.

Tests: Cover initial provisioning, permission checks, sign/verify, rotation overlap, retired-key rejection, corruption, restart, redaction, and concurrent issuance; run make test, make fmt-check, make lint, and security checks.

Out of scope: Cluster certificate PKI, bundle delivery, and action permits.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


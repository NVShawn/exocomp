---
id: EXOCOMP-220
type: task
status: Open
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
updated_at: '2026-08-03T15:31:30.620282Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 1bf24e81bc6b275b555dec62e5aa1be3707a7ec640488f1f6c3ae2df6b71eba2
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: a2615386-264d-4163-8400-1d1699375d46
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:31:14.608545+00:00'
  claim_expires_at: '2026-08-03T16:01:14.608545+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 496d4278-e1c7-4772-8b3a-7b13055faddc
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


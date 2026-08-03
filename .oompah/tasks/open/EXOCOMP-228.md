---
id: EXOCOMP-228
type: task
status: Open
priority: 1
title: Issue short-lived coordinator action permits
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-213
- EXOCOMP-222
labels: []
assignee: null
created_at: '2026-08-03T14:26:27.555796Z'
updated_at: '2026-08-03T15:41:46.116422Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: aa7f6088de9d3b41fc72858c3b7203b22206808c9ab43cc1a334feb51c692f2e
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: efeb690f-a824-4a61-a246-d9306ec70532
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:41:35.352524+00:00'
  claim_expires_at: '2026-08-03T16:11:35.352524+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 3010693c-5582-4e44-b604-d6cf98f9871a
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add a canonical coordinator-signed permit for one exact broker action after a manage decision passes all coordinator safety gates.

Acceptance criteria:
- Permit binds cluster, node, action ID, exact target, canonical service key, evidence hash, idempotency ID, policy version/hash, issue time, and expiry.
- Expiry is at most 60 seconds and never later than the policy lease.
- Existing approval signing material is domain-separated from permit signatures.
- A permit cannot be issued for observe, stale evidence, unsupported nodes, unknown actions, or expired policy.
- Signing failure prevents dispatch and is audited.

Tests: Add canonical fixture, sign/verify, binding mismatch, replay identity, expiry bounds, policy-expiry cap, domain separation, observe denial, and signing-failure tests; run make test, make fmt-check, and make lint.

Out of scope: Broker policy verification, node transport, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


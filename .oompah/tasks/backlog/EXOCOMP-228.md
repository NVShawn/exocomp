---
id: EXOCOMP-228
type: task
status: Backlog
priority: 1
title: Issue short-lived coordinator action permits
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T14:26:27.555796Z'
updated_at: '2026-08-03T14:26:27.555796Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
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


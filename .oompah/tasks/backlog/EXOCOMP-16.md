---
id: EXOCOMP-16
type: feature
status: Backlog
priority: 1
title: Implement coordinator CA initialization and enrollment tokens
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-9
- EXOCOMP-14
labels: []
assignee: null
created_at: '2026-07-23T19:09:29.953540Z'
updated_at: '2026-07-23T19:14:26.970720Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Implement coordinator CA initialization and enrollment tokens.

Implementation
Add coordinator-local initialization that creates a protected offline root export, online intermediate, coordinator leaf identity, and separate approval-signing key; implement ten-minute one-use enrollment tokens bound to inventory node IDs; enforce key permissions and explicit backup output.

Testing
Test initialization idempotency, secure permissions, missing/corrupt key material, token expiry, node mismatch, token replay, and secrets absent from logs.

Acceptance Criteria
- [ ] PKI initialization produces valid separated root/intermediate material.
- [ ] Online state does not retain an unprotected root key.
- [ ] Enrollment tokens are node-bound, expiring, and single-use.
- [ ] Private material is protected and redacted.
- [ ] Focused PKI tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-23
type: feature
status: Backlog
priority: 1
title: Implement signed task-bound approval issuance
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-16
- EXOCOMP-21
labels: []
assignee: null
created_at: '2026-07-23T19:10:09.330640Z'
updated_at: '2026-07-23T19:12:57.669989Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Implement signed task-bound approval issuance.

Implementation
Implement canonical versioned approval payloads and Ed25519 signatures using the coordinator approval key; bind nonce, task/correlation, node, action, parameter hash, evidence hash, issue/expiry time, and operator identity; add coordinator-local approve/deny commands.

Testing
Test canonical encoding, signature verification vectors, tampering of every binding, expiry, operator audit, missing keys, and approval refusal for forbidden actions.

Acceptance Criteria
- [ ] Approval is short-lived and bound to exact current action/evidence.
- [ ] Changing any bound field invalidates the signature.
- [ ] Approval cannot authorize user-data deletion or unknown actions.
- [ ] Operator and issuance are audited without secrets.
- [ ] Focused crypto/command tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


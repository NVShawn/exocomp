---
id: EXOCOMP-23
type: feature
status: In Progress
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
updated_at: '2026-07-24T02:29:01.330707Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: a24369b8-5e26-4588-a07e-2d4c1cc12528
oompah.work_branch: epic-EXOCOMP-3
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:28
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:29
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

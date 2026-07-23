---
id: EXOCOMP-3
type: epic
status: Open
priority: 1
title: 'M3: Safety validation and controlled remediation'
parent: null
children:
- EXOCOMP-21
- EXOCOMP-22
- EXOCOMP-23
- EXOCOMP-24
- EXOCOMP-25
- EXOCOMP-26
- EXOCOMP-27
- EXOCOMP-28
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T19:08:10.012498Z'
updated_at: '2026-07-23T22:51:24.560557Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Deliver deterministic least-impact policy, approvals, restricted executors, bounded system-data cleanup, and auditable remediation.

Scope
Coordinate child tasks for action schemas, policy selection, approval signing and replay protection, privilege separation, bounded system-log cleanup, A2A remediation integration, and security acceptance. User and unknown data must never be deletion targets.

Testing
All focused policy, crypto, privilege, data-safety, and integration tests must pass through repository Make targets.

Acceptance Criteria
- [ ] Every child task is complete and focused tests pass.
- [ ] Every M3-CRIT-* criterion in the linked plan has recorded evidence.
- [ ] Adversarial tests prove the model cannot bypass deterministic policy.
- [ ] No test path permits user-data deletion or arbitrary command execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


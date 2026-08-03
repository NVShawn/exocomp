---
id: EXOCOMP-216
type: task
status: Open
priority: 1
title: Enforce policy mutation authorization and auditing
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-214
- EXOCOMP-215
labels: []
assignee: null
created_at: '2026-08-03T14:24:17.168394Z'
updated_at: '2026-08-03T15:29:28.941035Z'
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

Deliverable: Add Mission Control context functions that authorize and audit every management-policy mutation.

Acceptance criteria:
- Admins may set either mode and remove overrides.
- Operators may only preserve or reduce effective authority and cannot delete an override when inheritance broadens authority.
- Viewers cannot mutate policy.
- Authorization is evaluated against the post-change effective result within the same transaction.
- Successful and rejected changes record actor, scope, before/after values, version, organization, and correlation ID without secrets.

Tests: Cover every role, every scope, direct and indirect broadening, concurrent stale version, cross-organization IDs, audit failure rollback, and deletion inheritance; run make test, make fmt-check, and make lint.

Out of scope: Web controllers, LiveView, distribution, and execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


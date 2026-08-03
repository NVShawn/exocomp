---
id: EXOCOMP-215
type: task
status: Backlog
priority: 1
title: Persist organization-scoped management policies
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:24:14.313906Z'
updated_at: '2026-08-03T14:29:01.563997Z'
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

Deliverable: Add Mission Control migrations, schemas, and repository functions for management-policy overrides and monotonic organization policy versions.

Acceptance criteria:
- Database checks allow exactly the identity fields required by each scope.
- Unique constraints permit one override per organization and scope identity.
- Organization identity is mandatory on every query and foreign key.
- Create, update, delete, list, and effective-resolution reads are transactional.
- Concurrent version updates cannot lose a committed policy change.

Tests: Add migration and context tests for all scopes, uniqueness, invalid identity combinations, organization isolation, rollback, and concurrent updates; run the focused database Make target plus make test, make fmt-check, and make lint.

Out of scope: RBAC, HTTP endpoints, bundle creation, and UI.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


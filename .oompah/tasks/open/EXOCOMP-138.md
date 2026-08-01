---
id: EXOCOMP-138
type: task
status: Open
priority: 2
title: Add organizations and mandatory organization scoping
parent: EXOCOMP-128
children: []
blocked_by:
- EXOCOMP-137
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:52.527968Z'
updated_at: '2026-08-01T11:51:24.396657Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Organization and Operator Identity.

Deliverables:
- Add the organizations table and schema with a stable generated identifier.
- Add a test/dev seed for the initial organization.
- Add a small reusable scoping helper that requires organization_id for tenant-owned queries and inserts.
- Add foreign-key and unique-constraint examples used by later contexts.

Acceptance:
- Inserts without an organization fail closed.
- Tests prove records from one organization cannot be read, updated, or deleted through another organization scope.
- No global unscoped list function is exposed.

Out of scope: tenant administration UI and billing.
Quality gate: focused Ecto tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


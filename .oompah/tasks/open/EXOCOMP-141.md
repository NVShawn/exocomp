---
id: EXOCOMP-141
type: task
status: Open
priority: 1
title: Enforce viewer, operator, and admin authorization
parent: EXOCOMP-129
children: []
blocked_by:
- EXOCOMP-140
- EXOCOMP-138
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:14:23.272282Z'
updated_at: '2026-08-01T11:48:45.386886Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Organization and Operator Identity.

Deliverables:
- Add operator identity and role-binding schemas scoped to organization_id.
- Map configured OIDC claims/groups to viewer, operator, or admin.
- Add plugs/on_mount hooks and context-level authorization functions for read, operate, and administer actions.
- Add a helper that records the stable OIDC subject and correlation ID for mutations.

Acceptance:
- A role matrix test covers every allowed and denied operation.
- Removing a UI control does not bypass context authorization.
- Cross-organization role bindings fail closed.

Out of scope: feature-specific mutations and admin pages.
Quality gate: focused authorization tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


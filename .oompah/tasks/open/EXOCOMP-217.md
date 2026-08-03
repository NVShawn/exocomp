---
id: EXOCOMP-217
type: task
status: Open
priority: 2
title: Add management-policy HTTP APIs
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-216
labels: []
assignee: null
created_at: '2026-08-03T14:24:19.702752Z'
updated_at: '2026-08-03T15:30:21.115767Z'
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

Deliverable: Add versioned Mission Control endpoints to list, resolve, create, update, and delete policy overrides.

Acceptance criteria:
- Organization comes only from the authenticated session.
- Requests validate scope-specific identifiers, canonical service keys, mode, and expected policy version.
- Responses include configured value, inherited value, effective value, winning scope or conflict, policy version, and lease status where available.
- Stale writes return a deterministic conflict response.
- Authorization failures do not reveal cross-organization resources.

Tests: Add controller tests for success and all validation, role, conflict, not-found, malformed JSON, size-limit, and organization-isolation paths; run make test, make fmt-check, and make lint.

Out of scope: HTML UI, policy distribution, and broker behavior.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


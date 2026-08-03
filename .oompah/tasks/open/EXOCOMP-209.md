---
id: EXOCOMP-209
type: epic
status: Open
priority: 1
title: 'M8A: Policy model, API, authorization, and UI'
parent: EXOCOMP-208
children:
- EXOCOMP-213
- EXOCOMP-214
- EXOCOMP-215
- EXOCOMP-216
- EXOCOMP-217
- EXOCOMP-218
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:23:21.454996Z'
updated_at: '2026-08-03T15:30:30.389798Z'
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

Outcome: Deliver the shared policy types and resolver plus organization-scoped Mission Control persistence, authorization, API, audit, and operator UI.

Acceptance:
- All five scopes, canonical service keys, inheritance, peer conflict, and implicit observe are represented.
- Admin, operator-restriction, and viewer rules are enforced in contexts and UI.
- Every policy mutation is versioned, concurrency-safe, organization-scoped, and audited.

Out of scope: Policy delivery, leases, coordinator/node enforcement, privileged execution, and qualification.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


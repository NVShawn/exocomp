---
id: EXOCOMP-22
type: feature
status: Backlog
priority: 1
title: Implement deterministic least-impact policy selection
parent: EXOCOMP-3
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T19:10:08.344504Z'
updated_at: '2026-07-23T19:10:08.344504Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Implement deterministic least-impact policy selection.

Implementation
Filter unauthorized, unsafe, stale, inapplicable, cooldown, and retry-exhausted actions; produce deny/allow/approval_required decisions; order eligible actions lexicographically by data loss, work loss, disruption, and scope; require proof before escalation.

Testing
Use table/property tests for stable ordering, ties, stale evidence, validator errors, unavailable policy, safer remaining candidates, and deterministic repeated evaluation.

Acceptance Criteria
- [ ] Validator ambiguity or error fails closed.
- [ ] A higher-impact action cannot win while a safer eligible action remains.
- [ ] Decisions include auditable reasons and ordering evidence.
- [ ] Repeated inputs produce the same decision.
- [ ] Focused policy tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


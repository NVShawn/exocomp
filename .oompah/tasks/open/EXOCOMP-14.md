---
id: EXOCOMP-14
type: feature
status: Open
priority: 1
title: Scaffold coordinator inventory, registry, and audit
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-7
- EXOCOMP-8
labels: []
assignee: null
created_at: '2026-07-23T19:09:28.257166Z'
updated_at: '2026-07-23T19:17:06.616843Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Scaffold coordinator inventory, registry, and audit.

Implementation
Implement coordinator supervision; versioned JSON inventory parsing; atomic inventory replacement; ETS node registry; configured journald or bounded JSON-lines audit sink; structured health and error reporting.

Testing
Test malformed inventory, duplicate IDs and certificate identities, failed replacement retaining prior state, registry reconstruction, sink redaction, and audit outage behavior.

Acceptance Criteria
- [ ] Valid inventory loads atomically.
- [ ] Invalid replacement leaves prior inventory active.
- [ ] Registry is reconstructible after restart.
- [ ] Audit output is correlated and redacted.
- [ ] Focused tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-21
type: feature
status: In Progress
priority: 1
title: Define action, evidence, risk, and data-classification types
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-8
labels: []
assignee: null
created_at: '2026-07-23T19:10:07.361533Z'
updated_at: '2026-07-23T21:51:43.319375Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 24c869e4-eddc-4f1e-ad81-4f36d5feef3b
oompah.work_branch: epic-EXOCOMP-3
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Define action, evidence, risk, and data-classification types.

Implementation
Implement versioned types and JSON schemas for action definitions, proposals, evidence, validator results, risk ranks, reversibility, data classification, execution, and verification; reject unknown fields/versions where security-relevant; default unknown data to protected user data.

Testing
Add table/property tests for valid schemas, malformed values, unknown versions, missing evidence, risk ordering primitives, and every data-classification default.

Acceptance Criteria
- [ ] All security-relevant inputs are bounded and schema-versioned.
- [ ] Unknown data is always classified as protected user data.
- [ ] User-data deletion is unrepresentable as an eligible action.
- [ ] Focused type/schema tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:51
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:51
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:51
---
Understanding: Investigating whether EXOCOMP-21 ('Define action, evidence, risk, and data-classification types') is a duplicate of an existing task. Will search for related tasks covering type definitions for actions, evidence, risk ranks, reversibility, data classification, and schema versioning before any implementation proceeds.
---
<!-- COMMENTS:END -->

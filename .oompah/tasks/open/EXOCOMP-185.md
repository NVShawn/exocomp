---
id: EXOCOMP-185
type: epic
status: Open
priority: 1
title: 'M7I: Host service desired state'
parent: EXOCOMP-127
children:
- EXOCOMP-187
- EXOCOMP-188
- EXOCOMP-189
- EXOCOMP-190
- EXOCOMP-191
- EXOCOMP-192
- EXOCOMP-193
- EXOCOMP-194
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:35:54.447822Z'
updated_at: '2026-08-01T11:51:09.953915Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md and the approved three-path service desired-state extension from 2026-07-30.

Outcome: Add coordinator-owned manual and automatic service expectations, merge them deterministically with cluster-profile expectations, observe their health through bounded node skills, and report durable service state to Mission Control.

Required behavior:
- Coordinator inventory v2 remains compatible with v1.
- Manual and automatic paths compose as a union and retain their sources.
- Automatic mode monitors enabled long-running services but does not grant restart authority.
- Desired-state removal, unsupported observations, and unhealthy transitions are explicit and auditable.
- Work is decomposed into focused child tasks suitable for a junior developer.

Out of scope: Ceph-specific topology and remedies, arbitrary commands, and Mission Control-owned desired-state configuration.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


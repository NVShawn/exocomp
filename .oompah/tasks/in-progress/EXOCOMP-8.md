---
id: EXOCOMP-8
type: feature
status: In Progress
priority: 1
title: Implement A2A 1.0 shared protocol types and fixtures
parent: EXOCOMP-1
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T19:08:53.749492Z'
updated_at: '2026-07-23T20:25:28.854961Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 364f519a-253b-4a3c-9946-6b1e85412192
oompah.work_branch: epic-EXOCOMP-1
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Implement A2A 1.0 shared protocol types and fixtures.

Implementation
Pin the official A2A 1.0 schemas used by Exocomp; implement HTTP+JSON codecs for Agent Card, Message, Task, Part, Artifact, task states, standard errors, and A2A-Version handling; keep types in shared umbrella code.

Testing
Add fixture round-trip tests, invalid payload tests, required-field tests, media-type tests, and version negotiation tests.

Acceptance Criteria
- [ ] Official valid fixtures round-trip without semantic loss.
- [ ] Malformed or unsupported input returns the correct bounded A2A error.
- [ ] A2A-Version values other than supported 1.0 fail as designed.
- [ ] All shared protocol tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:25
---
Understanding: Acting as Duplicate Investigator for EXOCOMP-8 (Implement A2A 1.0 shared protocol types and fixtures). Searched .oompah/tasks, plans/, docs/, and README.md for related tasks. Reviewed EXOCOMP-1 (parent epic), EXOCOMP-7 (blocker, now Done), EXOCOMP-9 through EXOCOMP-13 (sibling M1 children). No duplicate found.
---
<!-- COMMENTS:END -->

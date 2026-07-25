---
id: EXOCOMP-34
type: chore
status: Merged
priority: 1
title: Verify the M4 minimal-impact recovery milestone
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-28
- EXOCOMP-33
labels: []
assignee: null
created_at: '2026-07-23T19:10:49.457512Z'
updated_at: '2026-07-25T02:25:04.349741Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: ee29a420-044e-4927-9066-1293784b6ab4
oompah.work_branch: epic-EXOCOMP-4
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Verify the M4 minimal-impact recovery milestone.

Implementation
Run the full release-like coordinator/node/fixture flow for failed-service automatic recovery and active/degraded approval behavior; collect correlated audit and host-state evidence for every M4 criterion.

Testing
Run unit, integration, fault-injection, and end-to-end Make targets; compare user-data and non-fixture host state before/after; inspect action count and stability window.

Acceptance Criteria
- [ ] Every M4-CRIT-* item has recorded pass/fail evidence.
- [ ] Failed fixture service recovers exactly once and remains healthy.
- [ ] Approval gates disruptive running-service restarts.
- [ ] No user data or non-fixture resource changes.
- [ ] All quality gates pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 02:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 02:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-25 02:25
---
Understanding: This run is limited to duplicate screening. I will search the native task corpus and M4 recovery plan for prior tasks covering the same release-like milestone verification, inspect full descriptions/comments for plausible matches, then either archive EXOCOMP-34 as a confirmed duplicate or leave a duplicate-detector handoff for implementation.
---
<!-- COMMENTS:END -->

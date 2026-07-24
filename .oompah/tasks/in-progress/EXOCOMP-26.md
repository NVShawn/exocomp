---
id: EXOCOMP-26
type: feature
status: In Progress
priority: 1
title: Implement bounded system-log cleanup action
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-22
- EXOCOMP-25
labels: []
assignee: null
created_at: '2026-07-23T19:10:12.273742Z'
updated_at: '2026-07-24T01:35:26.182865Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: da3d8ed6-7465-4536-8bdc-16eecbbfbf20
oompah.work_branch: epic-EXOCOMP-3
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Implement bounded system-log cleanup action.

Implementation
Implement system.logs.vacuum using a supported maintenance interface and installed fixed limits for source, minimum retention, maximum bytes, free-space target, cooldown, and retries; require deterministic disk pressure and prove lower-impact options insufficient; audit pre/post usage.

Testing
Test below/above threshold, exact boundary, caller attempts to change paths/limits, user/unknown paths, maximum reclaim, cooldown, maintenance failure, concurrent cleanup, and audit failure.

Acceptance Criteria
- [ ] Cleanup is ineligible without validated disk pressure.
- [ ] Only configured system logs are targeted.
- [ ] Installed retention/byte bounds cannot be widened by callers or the model.
- [ ] User and unknown data are never touched.
- [ ] Focused cleanup tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 01:35
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:35
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 01:35
---
Understanding: Screening EXOCOMP-26 for duplication before any implementation. I will search existing tasks and project design material for system.logs.vacuum/system-log cleanup work, inspect plausible candidates in full, and either archive this issue as a confirmed duplicate or leave a duplicate-detector handoff for implementation.
---
<!-- COMMENTS:END -->

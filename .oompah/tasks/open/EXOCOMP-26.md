---
id: EXOCOMP-26
type: feature
status: Open
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
updated_at: '2026-07-23T19:17:15.350461Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


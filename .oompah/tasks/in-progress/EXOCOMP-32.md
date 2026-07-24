---
id: EXOCOMP-32
type: feature
status: In Progress
priority: 1
title: Implement approval-required active and degraded recovery
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-24
- EXOCOMP-27
- EXOCOMP-30
labels: []
assignee: null
created_at: '2026-07-23T19:10:47.855632Z'
updated_at: '2026-07-24T18:56:05.168769Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 5e30ed94-6ac7-4a07-9603-4659224ba31b
oompah.work_branch: epic-EXOCOMP-4
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Implement approval-required active and degraded recovery.

Implementation
When current evidence shows an active or degraded service, move the task to input-required; display exact impact and evidence; accept only a valid bound approval; refresh preconditions before execution; cancel or re-diagnose when state changes.

Testing
Test approve, deny, expiry, timeout, wrong approver/token, changed evidence, service becomes healthy/failed, cancellation, and duplicate approval.

Acceptance Criteria
- [ ] No active/degraded service restarts before valid approval.
- [ ] Approval is invalid after relevant state changes.
- [ ] Denial/timeout performs no action and leaves an auditable terminal/escalated result.
- [ ] Focused approval-flow tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:55
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:55
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:56
---
Understanding: Screening EXOCOMP-32 for duplication before any implementation. I will search existing tasks and design docs for approval-gated active/degraded recovery, inspect the full state/comments of plausible candidates, then archive only if the same underlying work is already tracked; otherwise I will record a duplicate-detector handoff and label the focus complete.
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-19
type: feature
status: In Progress
priority: 1
title: Expose coordinator cluster A2A service
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-15
- EXOCOMP-18
labels: []
assignee: null
created_at: '2026-07-23T19:09:32.508992Z'
updated_at: '2026-07-24T18:24:36.531717Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 99e3cf5e-5e2a-43c7-9174-d367727fc5aa
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Expose coordinator cluster A2A service.

Implementation
Publish a coordinator Agent Card with exocomp.cluster.health and exocomp.cluster.diagnose; support A2A send/get/list/cancel using shared types; authorize inventory selections; aggregate bounded partial results; declare streaming/push unsupported; expose no remediation execution.

Testing
Run shared protocol fixtures plus tests for selection authorization, partial results, cancellation, mTLS, unsupported capabilities, version negotiation, and concurrent callers.

Acceptance Criteria
- [ ] Agent Card and endpoints conform to pinned A2A 1.0 fixtures.
- [ ] Authenticated callers receive correlated cluster results.
- [ ] Unauthorized node selection is rejected.
- [ ] No execution/remediation skill is reachable.
- [ ] Focused tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:24
---
Understanding: Screening EXOCOMP-19 for duplication before any implementation. I will search native tasks and project design/docs for coordinator cluster A2A scope, then inspect each plausible task's full description/comments and either archive as duplicate or hand off with evidence.
---
<!-- COMMENTS:END -->

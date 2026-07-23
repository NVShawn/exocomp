---
id: EXOCOMP-12
type: feature
status: In Progress
priority: 1
title: Expose diagnostic-only node A2A service
parent: EXOCOMP-1
children: []
blocked_by:
- EXOCOMP-8
- EXOCOMP-9
- EXOCOMP-10
- EXOCOMP-11
labels: []
assignee: null
created_at: '2026-07-23T19:08:57.046675Z'
updated_at: '2026-07-23T22:49:18.837912Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 5b5acbd3-5be2-49bc-8571-0d372747059e
oompah.work_branch: epic-EXOCOMP-1
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Expose diagnostic-only node A2A service.

Implementation
Publish the node Agent Card and diagnostic skills exocomp.system.diagnose, exocomp.service.diagnose, and exocomp.remediation.propose over mTLS; implement send, task get/list/cancel, bounded in-memory task history, body/time limits, and standards-defined unsupported responses; advertise no state-changing capability.

Testing
Add A2A contract tests, mTLS authentication tests, concurrent task tests, cancellation, eviction, request limit, collector failure, inference failure, and unsupported-operation cases.

Acceptance Criteria
- [ ] Authenticated clients receive schema-valid diagnostic artifacts.
- [ ] Unauthenticated clients are rejected before request handling.
- [ ] Task history and concurrency are bounded.
- [ ] The Agent Card exposes no execution skill.
- [ ] All service and protocol tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:49
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

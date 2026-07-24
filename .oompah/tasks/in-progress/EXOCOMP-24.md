---
id: EXOCOMP-24
type: feature
status: In Progress
priority: 1
title: Verify approvals and prevent replay on nodes
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-17
- EXOCOMP-23
labels: []
assignee: null
created_at: '2026-07-23T19:10:10.424356Z'
updated_at: '2026-07-24T03:07:00.183124Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 28da36fe-5172-4eed-84cc-42db1a72f8d2
oompah.work_branch: epic-EXOCOMP-3
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Verify approvals and prevent replay on nodes.

Implementation
Verify signatures and every token binding at the node; re-check current preconditions; durably record consumed execution IDs before action; serialize concurrent verification; reconcile incomplete records after restart; fail closed on corrupt/unavailable replay state.

Testing
Test first use, concurrent duplicate, replay, replay after restart, wrong node/task/action/parameters/evidence, expiry, changed precondition, storage corruption, and interrupted persistence.

Acceptance Criteria
- [ ] A valid token executes at most once across restarts.
- [ ] Stale or mismatched approvals never reach an executor.
- [ ] Durable-state failure blocks approved action.
- [ ] Concurrent duplicates return one authoritative outcome.
- [ ] Focused replay tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 03:06
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 03:06
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 03:07
---
Understanding: Duplicate screening only. I will search existing tasks and design docs for node approval verification, durable replay prevention, and concurrent duplicate handling; inspect plausible candidates in full; then either archive EXOCOMP-24 as a confirmed duplicate or record a duplicate-detector handoff for implementation.
---
<!-- COMMENTS:END -->

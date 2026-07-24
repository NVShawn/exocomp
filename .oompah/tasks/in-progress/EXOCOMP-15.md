---
id: EXOCOMP-15
type: feature
status: In Progress
priority: 1
title: Implement DNS discovery and concurrent node polling
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-12
- EXOCOMP-14
labels: []
assignee: null
created_at: '2026-07-23T19:09:29.099203Z'
updated_at: '2026-07-24T02:31:33.545000Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 304dc270-7184-4769-bff0-6462f5e389b8
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Implement DNS discovery and concurrent node polling.

Implementation
Resolve configured hostnames, track address changes, verify mTLS identity independently of reverse DNS, and poll Agent Cards/health every 30 seconds with jitter, bounded concurrency, per-node timeout, failure states, and backoff.

Testing
Test DNS changes, multiple addresses, wrong identity, healthy/slow/stale/unreachable nodes, concurrent polling, backoff, and recovery without blocking unrelated nodes.

Acceptance Criteria
- [ ] At least three nodes are polled concurrently.
- [ ] One slow or unreachable node cannot delay unrelated polls.
- [ ] Address changes require successful DNS and mTLS checks.
- [ ] Registry states and timestamps are correct.
- [ ] Focused tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:31
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:31
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

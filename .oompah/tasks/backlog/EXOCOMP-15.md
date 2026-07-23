---
id: EXOCOMP-15
type: feature
status: Backlog
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
updated_at: '2026-07-23T19:14:26.034397Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


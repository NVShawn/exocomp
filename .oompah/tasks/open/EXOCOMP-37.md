---
id: EXOCOMP-37
type: chore
status: Open
priority: 2
title: Benchmark coordinator polling and A2A concurrency
parent: EXOCOMP-5
children: []
blocked_by:
- EXOCOMP-20
- EXOCOMP-35
labels: []
assignee: null
created_at: '2026-07-23T19:11:19.549341Z'
updated_at: '2026-07-23T19:17:25.204544Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 5 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-5-performance.md)

Goal
Benchmark coordinator polling and A2A concurrency.

Implementation
Benchmark representative node counts and concurrency with healthy, slow, and unreachable mixtures; measure poll cycles, cluster tasks, DNS changes, partial results, scheduler use, process/mailbox growth, network usage, and latency percentiles.

Testing
Run scaling steps repeatedly; inject slow/unreachable nodes; verify unrelated polling progress and compare steady-state versus failure-state resource use.

Acceptance Criteria
- [ ] Results identify sustainable node/concurrency ranges.
- [ ] Slow/unreachable nodes do not produce unbounded queues or block unrelated work.
- [ ] Latency/error/resource metrics include raw samples and host/build identity.
- [ ] Configured gates pass or fail explicitly.

Quality Gate
Run the focused benchmark tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


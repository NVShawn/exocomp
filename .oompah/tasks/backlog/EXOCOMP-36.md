---
id: EXOCOMP-36
type: chore
status: Backlog
priority: 2
title: Benchmark node idle and diagnostic workloads
parent: EXOCOMP-5
children: []
blocked_by:
- EXOCOMP-12
- EXOCOMP-35
labels: []
assignee: null
created_at: '2026-07-23T19:11:18.592456Z'
updated_at: '2026-07-23T19:13:38.426185Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 5 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-5-performance.md)

Goal
Benchmark node idle and diagnostic workloads.

Implementation
Measure node BEAM control-plane CPU/RAM with model unloaded and loaded; run 30-minute steady idle plus sequential/concurrent system and service diagnostics; retain raw samples and amd64/arm64 summaries; enforce less than 5% of one core and 5% host RAM at idle excluding llama.cpp.

Testing
Repeat runs on both profiles; test malformed/slow collectors during load; inspect RSS, scheduler, processes, mailboxes, descriptors, task history, latency percentiles, and error rate.

Acceptance Criteria
- [ ] Both architectures have reproducible raw and summary results.
- [ ] Idle control-plane gates are automatically evaluated.
- [ ] Diagnostic concurrency stays bounded without growing mailboxes/history.
- [ ] Any failure names workload, metric, baseline, and observed value.

Quality Gate
Run the focused benchmark tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


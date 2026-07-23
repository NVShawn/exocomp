---
id: EXOCOMP-39
type: chore
status: Backlog
priority: 2
title: Run recovery and multi-hour soak benchmarks
parent: EXOCOMP-5
children: []
blocked_by:
- EXOCOMP-34
- EXOCOMP-35
labels: []
assignee: null
created_at: '2026-07-23T19:11:21.493438Z'
updated_at: '2026-07-23T19:13:43.403290Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 5 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-5-performance.md)

Goal
Run recovery and multi-hour soak benchmarks.

Implementation
Run repeated diagnostics, bounded inference, health polling, controlled partitions, service failure/recovery, coordinator/node restart, and at least one llama restart for the documented soak duration; analyze slopes after warm-up.

Testing
Track memory categories, processes, mailboxes, descriptors, tasks, audit backlog, latency, and recovery time; inject M4 recovery under load and confirm safety/action-count invariants.

Acceptance Criteria
- [ ] No sustained unbounded memory/process/mailbox/descriptor/task growth is present.
- [ ] Recovery under load executes at most once and preserves safety.
- [ ] Audit backlog has bounded behavior.
- [ ] Raw soak data and analysis are retained.

Quality Gate
Run the focused benchmark tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


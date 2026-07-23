---
id: EXOCOMP-40
type: chore
status: Open
priority: 2
title: Publish M5 baselines and performance gates
parent: EXOCOMP-5
children: []
blocked_by:
- EXOCOMP-34
- EXOCOMP-36
- EXOCOMP-37
- EXOCOMP-38
- EXOCOMP-39
labels: []
assignee: null
created_at: '2026-07-23T19:11:22.415417Z'
updated_at: '2026-07-23T19:17:27.277381Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 5 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-5-performance.md)

Goal
Publish M5 baselines and performance gates.

Implementation
Consolidate amd64/arm64 node, coordinator, model, recovery, and soak results; check in versioned baselines and gate configuration; document sizing, limitations, reproducibility, and any hardware-only exception with evidence.

Testing
Re-run short CI benchmark and full release benchmark commands; test baseline update/review workflow and intentional regression detection.

Acceptance Criteria
- [ ] Every M5-CRIT-* item has pass/fail evidence.
- [ ] Idle control-plane gates pass on both references.
- [ ] Reports link exact raw data, host, build, and model identity.
- [ ] Exceptions never waive correctness/leak gates.
- [ ] Benchmark Make targets behave as documented.

Quality Gate
Run the focused benchmark tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-35
type: feature
status: Open
priority: 2
title: Build the reproducible benchmark harness
parent: EXOCOMP-5
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T19:11:17.553654Z'
updated_at: '2026-07-23T19:17:23.839616Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 5 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-5-performance.md)

Goal
Build the reproducible benchmark harness.

Implementation
Implement versioned benchmark definitions, pinned amd64/arm64 host profiles, warm-up/run/repetition controls, process/cgroup attribution, BEAM and host sampling, raw sample schema, summary generation, baseline comparison, and short/full Make targets.

Testing
Test configuration validation, synthetic CPU/memory loads, process attribution, missing metrics, percentile calculations, threshold direction, incompatible profiles, deterministic summaries, and non-zero regression exit.

Acceptance Criteria
- [ ] Harness records build, host, model, workload, and raw metadata.
- [ ] Node/coordinator/llama processes are attributed separately.
- [ ] Invalid or incomparable runs are rejected.
- [ ] Regression failures return non-zero with exact metric details.
- [ ] Harness tests pass.

Quality Gate
Run the focused benchmark tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


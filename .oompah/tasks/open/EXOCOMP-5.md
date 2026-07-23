---
id: EXOCOMP-5
type: epic
status: Open
priority: 1
title: 'M5: Performance and resource analysis'
parent: null
children:
- EXOCOMP-35
- EXOCOMP-36
- EXOCOMP-37
- EXOCOMP-38
- EXOCOMP-39
- EXOCOMP-40
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T19:08:11.554597Z'
updated_at: '2026-07-23T19:20:16.208141Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 5 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-5-performance.md)

Goal
Produce reproducible amd64 and arm64 performance baselines and enforce the control-plane resource budget.

Scope
Coordinate benchmark tooling, node and coordinator workloads, model characterization, recovery and soak tests, and the final performance report. Measure BEAM control-plane usage separately from llama.cpp while also reporting total usage.

Testing
Harness self-tests, short CI benchmarks, full architecture benchmarks, and soak/regression gates must pass using the documented Make targets.

Acceptance Criteria
- [ ] Every child task is complete and focused tests pass.
- [ ] Every M5-CRIT-* criterion in the linked plan has recorded evidence.
- [ ] Idle control-plane CPU and RAM gates pass on both reference architectures.
- [ ] Raw data, host profiles, baselines, and exception rationale are reproducible.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


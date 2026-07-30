---
id: EXOCOMP-5
type: epic
status: In Validation
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
labels:
- epic:stale
assignee: null
created_at: '2026-07-23T19:08:11.554597Z'
updated_at: '2026-07-30T23:49:46.007452Z'
work_branch: epic-EXOCOMP-5
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/5
review_number: '5'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/5
oompah.review_number: '5'
oompah.work_branch: epic-EXOCOMP-5
oompah.target_branch: main
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-f5104ce58e4c
    project_id: proj-c260b117
    task_id: EXOCOMP-5
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: d6194da153b89bc288912d1728bb89996f710d779f45d72439e6f9ad8edda6b7
    attempts: []
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-30T23:49:44.179008+00:00'
  attempt_history: []
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 23:06
---
YOLO: merged PR #5.
---
author: oompah
created: 2026-07-30 23:49
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
<!-- COMMENTS:END -->

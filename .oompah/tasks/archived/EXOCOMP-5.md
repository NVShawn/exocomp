---
id: EXOCOMP-5
type: epic
status: Archived
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
updated_at: '2026-07-31T00:11:49.975183Z'
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
  applied_result_attempts:
    attempt-e21e51aa1975: '2026-07-31T00:11:40.565842+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-f5104ce58e4c
    project_id: proj-c260b117
    task_id: EXOCOMP-5
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: d6194da153b89bc288912d1728bb89996f710d779f45d72439e6f9ad8edda6b7
    attempts:
    - version: 1
      attempt_id: attempt-e21e51aa1975
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: d6194da153b89bc288912d1728bb89996f710d779f45d72439e6f9ad8edda6b7
      created_at: '2026-07-31T00:09:51.686153+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T00:09:51.686153+00:00'
      branch_key: epic-EXOCOMP-5
      verdict: pass
      completed_at: '2026-07-31T00:11:40.565734+00:00'
      ended_at: '2026-07-31T00:11:40.565734+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-30T23:49:44.179008+00:00'
    updated_at: '2026-07-31T00:11:40.565734+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-e21e51aa1975
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: d6194da153b89bc288912d1728bb89996f710d779f45d72439e6f9ad8edda6b7
    created_at: '2026-07-31T00:09:51.686153+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T00:09:51.686153+00:00'
    branch_key: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 34
  total_output_tokens: 5514
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 34
      output_tokens: 5514
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 34
    output_tokens: 5514
    cost_usd: 0.0
    recorded_at: '2026-07-31T00:11:48.644034+00:00'
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
author: oompah
created: 2026-07-31 00:09
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 00:09
---
Focus: Completion Auditor
---
author: oompah
created: 2026-07-31 00:11
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- merge_commit: 242ac6363291360969baeb18b73ff10713402e31
- merge_pr: #5 (epic-EXOCOMP-5)
- merge_date: 2026-07-23T18:06:27-05:00
- worktree_head: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
- origin_main_head: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
- children_states: EXOCOMP-35=Merged; EXOCOMP-36,37,38,39,40=Archived
- m5_crit_status: All 8 M5-CRIT-* items checked in plans/milestone-5-performance.md with cited evidence paths
- evidence_dir: docs/release-evidence/v0.1.0-rc.23/raw/amd64/m5-workload-harness/
---
author: oompah
created: 2026-07-31 00:11
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 36, Tool calls: 28
- Tokens: 34 in / 5.5K out [5.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 56s
- Log: EXOCOMP-5__20260731T000954Z.jsonl
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-36
type: chore
status: Archived
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
updated_at: '2026-07-30T23:51:29.030492Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-7f77f29ff575: '2026-07-30T23:51:11.920976+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-6e168b7c5056
    project_id: proj-c260b117
    task_id: EXOCOMP-36
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 8420cb55a70aad5dceab0d7f9e34c491c08d4d2108c8c07a60dbf02b3822089b
    attempts:
    - version: 1
      attempt_id: attempt-7f77f29ff575
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 8420cb55a70aad5dceab0d7f9e34c491c08d4d2108c8c07a60dbf02b3822089b
      created_at: '2026-07-30T23:49:27.394147+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-30T23:49:27.394147+00:00'
      branch_key: EXOCOMP-36
      verdict: pass
      completed_at: '2026-07-30T23:51:11.920882+00:00'
      ended_at: '2026-07-30T23:51:11.920882+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-30T23:49:19.465316+00:00'
    updated_at: '2026-07-30T23:51:11.920882+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-7f77f29ff575
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 8420cb55a70aad5dceab0d7f9e34c491c08d4d2108c8c07a60dbf02b3822089b
    created_at: '2026-07-30T23:49:27.394147+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-30T23:49:27.394147+00:00'
    branch_key: EXOCOMP-36
oompah.task_costs:
  total_input_tokens: 48
  total_output_tokens: 1692
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 48
      output_tokens: 1692
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 48
    output_tokens: 1692
    cost_usd: 0.0
    recorded_at: '2026-07-30T23:51:27.938935+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 23:49
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-07-30 23:49
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-30 23:49
---
Focus: Completion Auditor
---
author: oompah
created: 2026-07-30 23:51
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- task_id: EXOCOMP-36
- issue_type: chore
- previous_state: Merged
- target_state: Archived
- trigger: aged_merged_auto_archive_7d
- bench_harness_present: apps/bench/ with idle-node scenario
- baselines_present: priv/bench/baselines/v0.1.0-rc.23/{amd64,arm64}.toml
- history_note: Task file moved backlog->open->merged->in-validation (in-validation transition is standard terminal-audit staging)
---
author: oompah
created: 2026-07-30 23:51
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 0, Tool calls: 31
- Tokens: 48 in / 1.7K out [1.7K total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 0s
- Log: EXOCOMP-36__20260730T234933Z.jsonl
---
<!-- COMMENTS:END -->

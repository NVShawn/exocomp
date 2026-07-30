---
id: EXOCOMP-37
type: chore
status: Archived
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
updated_at: '2026-07-30T23:53:36.231729Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-21c8a706be14: '2026-07-30T23:53:17.088948+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-f10a6914cdff
    project_id: proj-c260b117
    task_id: EXOCOMP-37
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 3fe69971c518597ee602522cf07c6b4e2416470fa40e08009aa5d17f86463367
    attempts:
    - version: 1
      attempt_id: attempt-21c8a706be14
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 3fe69971c518597ee602522cf07c6b4e2416470fa40e08009aa5d17f86463367
      created_at: '2026-07-30T23:49:29.778093+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-30T23:49:29.778093+00:00'
      branch_key: EXOCOMP-37
      verdict: pass
      completed_at: '2026-07-30T23:53:17.088799+00:00'
      ended_at: '2026-07-30T23:53:17.088799+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-30T23:49:23.790708+00:00'
    updated_at: '2026-07-30T23:53:17.088799+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-21c8a706be14
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 3fe69971c518597ee602522cf07c6b4e2416470fa40e08009aa5d17f86463367
    created_at: '2026-07-30T23:49:29.778093+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-30T23:49:29.778093+00:00'
    branch_key: EXOCOMP-37
oompah.task_costs:
  total_input_tokens: 65
  total_output_tokens: 2320
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 65
      output_tokens: 2320
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 65
    output_tokens: 2320
    cost_usd: 0.0
    recorded_at: '2026-07-30T23:53:34.954685+00:00'
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
created: 2026-07-30 23:53
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- branch_head: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
- main_head: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
- unpushed_commits_from_task_branch: 0
- sibling_task_delivering_m5_polling_work: EXOCOMP-125 via PR #20 merged 2026-07-27
- coordinator_polling_probe_path: apps/exocomp_coordinator/lib/exocomp/coordinator/qualification_probe.ex
- gates_in_summary_module: coordinator_poll_healthy, coordinator_poll_slow, coordinator_poll_unreachable, coordinator_poll_mailbox_growth
- audit_attempt_id: attempt-21c8a706be14
- audit_chain_state: in_progress attempt #1
- task_status_field: In Validation (audit-pending; scheduler previous_state=Merged)
---
author: oompah
created: 2026-07-30 23:53
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 0, Tool calls: 42
- Tokens: 65 in / 2.3K out [2.4K total]
- Cost: $0.0000
- Exit: terminated, Duration: 4m 0s
- Log: EXOCOMP-37__20260730T234940Z.jsonl
---
<!-- COMMENTS:END -->

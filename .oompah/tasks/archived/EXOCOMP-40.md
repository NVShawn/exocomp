---
id: EXOCOMP-40
type: chore
status: Archived
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
updated_at: '2026-07-30T23:54:40.138985Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-3080f4e2af6a: '2026-07-30T23:54:29.790029+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-7ba40c5c7fdb
    project_id: proj-c260b117
    task_id: EXOCOMP-40
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 33452d982c60a33aa967798a656d84c4fc8b7709239a7f73ef70e7e110fb331a
    attempts:
    - version: 1
      attempt_id: attempt-3080f4e2af6a
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 33452d982c60a33aa967798a656d84c4fc8b7709239a7f73ef70e7e110fb331a
      created_at: '2026-07-30T23:50:23.484761+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-30T23:50:23.484761+00:00'
      branch_key: EXOCOMP-40
      verdict: pass
      completed_at: '2026-07-30T23:54:29.789854+00:00'
      ended_at: '2026-07-30T23:54:29.789854+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-30T23:49:40.125897+00:00'
    updated_at: '2026-07-30T23:54:29.789854+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-3080f4e2af6a
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 33452d982c60a33aa967798a656d84c4fc8b7709239a7f73ef70e7e110fb331a
    created_at: '2026-07-30T23:50:23.484761+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-30T23:50:23.484761+00:00'
    branch_key: EXOCOMP-40
oompah.task_costs:
  total_input_tokens: 67
  total_output_tokens: 10743
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 67
      output_tokens: 10743
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 67
    output_tokens: 10743
    cost_usd: 0.0
    recorded_at: '2026-07-30T23:54:38.236570+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 23:49
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-07-30 23:50
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-30 23:50
---
Focus: Completion Auditor
---
author: oompah
created: 2026-07-30 23:54
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- task_id: EXOCOMP-40
- issue_type: chore
- previous_state: Merged
- target_state: Archived
- trigger: aged_merged_auto_archive_7d
- merged_transition_commit: b7e1e08
- merged_at_date: 2026-07-23
- audit_date: 2026-07-30
- aging_days: 7
- baselines_present: apps/bench/priv/bench/baselines/v0.1.0-rc.23/{amd64,arm64}.toml
- profiles_present: apps/bench/priv/bench/profiles/{amd64,arm64}-ci.toml
- release_evidence_present: docs/release-evidence/v0.1.0-rc.23/{README.md,qualification-results.json,evidence-index.sha256,evidence-index.sha256.sig}
- plan_criteria_status: all 8 M5-CRIT-* checked in plans/milestone-5-performance.md
- make_targets: bench-llama-short, bench-harness, bench-llama-short-shipped, bench-llama-full, test-m5-qualification
- dependencies_state: EXOCOMP-34 Merged; EXOCOMP-36 Archived; EXOCOMP-37/38/39 In Validation (audit-staging) or Merged
- parent_epic_status: EXOCOMP-5 Merged via PR #5
- history_note: backlog->open->merged->in-validation transition matches standard terminal-audit workflow
---
author: oompah
created: 2026-07-30 23:54
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 75, Tool calls: 61
- Tokens: 67 in / 10.7K out [10.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 4m 10s
- Log: EXOCOMP-40__20260730T235033Z.jsonl
---
<!-- COMMENTS:END -->

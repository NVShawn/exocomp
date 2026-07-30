---
id: EXOCOMP-39
type: chore
status: Archived
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
updated_at: '2026-07-30T23:52:24.356001Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-616e4068fcaf: '2026-07-30T23:52:22.232689+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-b4a7172b47d0
    project_id: proj-c260b117
    task_id: EXOCOMP-39
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 6eb71a37dd880fc455b37e8b1bad61692082b5cfa1f14f962ea34ad8518ebc17
    attempts:
    - version: 1
      attempt_id: attempt-616e4068fcaf
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 6eb71a37dd880fc455b37e8b1bad61692082b5cfa1f14f962ea34ad8518ebc17
      created_at: '2026-07-30T23:50:22.111244+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-30T23:50:22.111244+00:00'
      branch_key: EXOCOMP-39
      verdict: pass
      completed_at: '2026-07-30T23:52:22.232593+00:00'
      ended_at: '2026-07-30T23:52:22.232593+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-30T23:49:34.640516+00:00'
    updated_at: '2026-07-30T23:52:22.232593+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-616e4068fcaf
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 6eb71a37dd880fc455b37e8b1bad61692082b5cfa1f14f962ea34ad8518ebc17
    created_at: '2026-07-30T23:50:22.111244+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-30T23:50:22.111244+00:00'
    branch_key: EXOCOMP-39
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
created: 2026-07-30 23:52
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- merged_transition_commit: df7b80d
- merged_transition_date: 2026-07-23T23:30:00Z
- audit_queue_comment_date: 2026-07-30T23:49Z
- retention_days_observed: 7
- task_pending_chain_audit_id: audit-b4a7172b47d0
- task_pending_chain_target: Archived
- task_pending_chain_previous_state: Merged
- task_pending_chain_fingerprint: 6eb71a37dd880fc455b37e8b1bad61692082b5cfa1f14f962ea34ad8518ebc17
- task_pending_chain_source: auto_archive
- current_file_path: .oompah/tasks/in-validation/EXOCOMP-39.md
- current_file_commit: 5c21c2d
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-40
type: chore
status: In Validation
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
updated_at: '2026-07-30T23:50:33.172433Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-7ba40c5c7fdb
    project_id: proj-c260b117
    task_id: EXOCOMP-40
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 33452d982c60a33aa967798a656d84c4fc8b7709239a7f73ef70e7e110fb331a
    attempts:
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
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-30T23:49:40.125897+00:00'
    updated_at: '2026-07-30T23:50:23.484761+00:00'
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
<!-- COMMENTS:END -->

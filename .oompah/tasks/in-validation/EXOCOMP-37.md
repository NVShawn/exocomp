---
id: EXOCOMP-37
type: chore
status: In Validation
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
updated_at: '2026-07-30T23:49:40.603410Z'
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
    audit_id: audit-f10a6914cdff
    project_id: proj-c260b117
    task_id: EXOCOMP-37
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 3fe69971c518597ee602522cf07c6b4e2416470fa40e08009aa5d17f86463367
    attempts:
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
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-30T23:49:23.790708+00:00'
    updated_at: '2026-07-30T23:49:29.778093+00:00'
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
<!-- COMMENTS:END -->

---
id: EXOCOMP-2
type: epic
status: In Validation
priority: 1
title: 'M2: Coordinator, discovery, and node enrollment'
parent: null
children:
- EXOCOMP-14
- EXOCOMP-15
- EXOCOMP-16
- EXOCOMP-17
- EXOCOMP-18
- EXOCOMP-19
- EXOCOMP-20
blocked_by: []
labels:
- epic:stale
assignee: null
created_at: '2026-07-23T19:08:09.243476Z'
updated_at: '2026-07-31T20:55:25.158050Z'
work_branch: epic-EXOCOMP-2
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/9
review_number: '9'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/9
oompah.review_number: '9'
oompah.work_branch: epic-EXOCOMP-2
oompah.target_branch: main
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-00e27e4ce78e
    project_id: proj-c260b117
    task_id: EXOCOMP-2
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 72be727f0a023470da368377bbff60e3059ebfbcc9dd6dd6e9fda37d06dc9cab
    attempts:
    - version: 1
      attempt_id: attempt-7ed3dd34d77a
      target_state: Archived
      request_state: in_progress
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 72be727f0a023470da368377bbff60e3059ebfbcc9dd6dd6e9fda37d06dc9cab
      created_at: '2026-07-31T20:55:22.608032+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T20:55:22.608032+00:00'
      branch_key: epic-EXOCOMP-2
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-31T20:46:42.404674+00:00'
    updated_at: '2026-07-31T20:55:22.608032+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-7ed3dd34d77a
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 72be727f0a023470da368377bbff60e3059ebfbcc9dd6dd6e9fda37d06dc9cab
    created_at: '2026-07-31T20:55:22.608032+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T20:55:22.608032+00:00'
    branch_key: epic-EXOCOMP-2
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Deliver coordinator discovery, node enrollment, polling, diagnostic orchestration, and A2A service capabilities.

Scope
Coordinate child tasks for coordinator state and inventory, health polling, bootstrap PKI, node enrollment and renewal, task orchestration, the coordinator A2A surface, and milestone acceptance. Remediation execution remains disabled.

Testing
All child-task tests, PKI scenarios, and the multi-node integration suite must pass through repository Make targets.

Acceptance Criteria
- [ ] Every child task is complete and focused tests pass.
- [ ] Every M2-CRIT-* criterion in the linked plan has recorded evidence.
- [ ] Enrollment, discovery, polling, and diagnostic dispatch work across multiple nodes.
- [ ] No Milestone 2 path invokes remediation.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:47
---
YOLO: merged PR #9.
---
author: oompah
created: 2026-07-31 20:46
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-07-31 20:55
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 20:55
---
Focus: Completion Auditor
---
<!-- COMMENTS:END -->

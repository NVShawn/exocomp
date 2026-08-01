---
id: EXOCOMP-3
type: epic
status: In Validation
priority: 1
title: 'M3: Safety validation and controlled remediation'
parent: null
children:
- EXOCOMP-21
- EXOCOMP-22
- EXOCOMP-23
- EXOCOMP-24
- EXOCOMP-25
- EXOCOMP-26
- EXOCOMP-27
- EXOCOMP-28
- EXOCOMP-108
blocked_by: []
labels:
- epic:rebasing
assignee: null
created_at: '2026-07-23T19:08:10.012498Z'
updated_at: '2026-08-01T21:22:38.100325Z'
work_branch: epic-EXOCOMP-3
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/12
review_number: '12'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/12
oompah.review_number: '12'
oompah.work_branch: epic-EXOCOMP-3
oompah.target_branch: main
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-72983f0fb0f0
    project_id: proj-c260b117
    task_id: EXOCOMP-3
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 5512afa98f25aed5df83c0f51cc11d33396f2cb621041ee8fde12d3a19cd082c
    attempts:
    - version: 1
      attempt_id: attempt-03577dfbb3d4
      target_state: Archived
      request_state: in_progress
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 5512afa98f25aed5df83c0f51cc11d33396f2cb621041ee8fde12d3a19cd082c
      created_at: '2026-08-01T21:19:04.163564+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T21:19:04.163564+00:00'
      branch_key: epic-EXOCOMP-3
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T21:18:54.523492+00:00'
    updated_at: '2026-08-01T21:19:04.163564+00:00'
  - version: 1
    audit_id: audit-0206842bbb7e
    project_id: proj-c260b117
    task_id: EXOCOMP-3
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
    attempts: []
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Validation
    created_at: '2026-08-01T21:22:36.455228+00:00'
  - version: 1
    audit_id: audit-14731edb697d
    project_id: proj-c260b117
    task_id: EXOCOMP-3
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
    attempts: []
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Validation
    created_at: '2026-08-01T21:22:36.455228+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-03577dfbb3d4
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 5512afa98f25aed5df83c0f51cc11d33396f2cb621041ee8fde12d3a19cd082c
    created_at: '2026-08-01T21:19:04.163564+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T21:19:04.163564+00:00'
    branch_key: epic-EXOCOMP-3
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Deliver deterministic least-impact policy, approvals, restricted executors, bounded system-data cleanup, and auditable remediation.

Scope
Coordinate child tasks for action schemas, policy selection, approval signing and replay protection, privilege separation, bounded system-log cleanup, A2A remediation integration, and security acceptance. User and unknown data must never be deletion targets.

Testing
All focused policy, crypto, privilege, data-safety, and integration tests must pass through repository Make targets.

Acceptance Criteria
- [ ] Every child task is complete and focused tests pass.
- [ ] Every M3-CRIT-* criterion in the linked plan has recorded evidence.
- [ ] Adversarial tests prove the model cannot bypass deterministic policy.
- [ ] No test path permits user-data deletion or arbitrary command execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 02:10
---
YOLO: merged PR #12.
---
author: oompah
created: 2026-08-01 21:18
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-08-01 21:19
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 21:19
---
Focus: Completion Auditor
---
<!-- COMMENTS:END -->

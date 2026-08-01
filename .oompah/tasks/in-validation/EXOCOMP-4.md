---
id: EXOCOMP-4
type: epic
status: In Validation
priority: 1
title: 'M4: Minimal-impact systemd service recovery'
parent: null
children:
- EXOCOMP-29
- EXOCOMP-30
- EXOCOMP-31
- EXOCOMP-32
- EXOCOMP-33
- EXOCOMP-34
- EXOCOMP-106
- EXOCOMP-109
blocked_by: []
labels:
- epic:rebasing
assignee: null
created_at: '2026-07-23T19:08:10.789340Z'
updated_at: '2026-08-01T21:24:48.724669Z'
work_branch: epic-EXOCOMP-4
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/10
review_number: '10'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/10
oompah.review_number: '10'
oompah.work_branch: epic-EXOCOMP-4
oompah.target_branch: main
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-5f6fb7566daa
    project_id: proj-c260b117
    task_id: EXOCOMP-4
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: af00412b66a77cdddc18d01772616312cfd6270d6dcaa2526b0b1873470873b3
    attempts:
    - version: 1
      attempt_id: attempt-3a9cec45112b
      target_state: Archived
      request_state: in_progress
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: af00412b66a77cdddc18d01772616312cfd6270d6dcaa2526b0b1873470873b3
      created_at: '2026-08-01T21:24:40.986740+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T21:24:40.986740+00:00'
      branch_key: epic-EXOCOMP-4
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T21:19:12.334799+00:00'
    updated_at: '2026-08-01T21:24:40.986740+00:00'
  - version: 1
    audit_id: audit-62a193b86f6a
    project_id: proj-c260b117
    task_id: EXOCOMP-4
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
    attempts: []
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Validation
    created_at: '2026-08-01T21:22:40.212063+00:00'
  - version: 1
    audit_id: audit-8c5aea60bc95
    project_id: proj-c260b117
    task_id: EXOCOMP-4
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
    attempts: []
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Validation
    created_at: '2026-08-01T21:22:40.212063+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-3a9cec45112b
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: af00412b66a77cdddc18d01772616312cfd6270d6dcaa2526b0b1873470873b3
    created_at: '2026-08-01T21:24:40.986740+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T21:24:40.986740+00:00'
    branch_key: epic-EXOCOMP-4
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Prove the complete control loop by recovering an already-failed allow-listed systemd service with the least disruptive eligible action.

Scope
Coordinate the recovery fixture, state machine, automatic failed-service flow, approval-required active/degraded flow, failure-mode testing, and end-to-end acceptance. Recovery permits one restart before cooldown and never mutates user data.

Testing
State-machine, fixture, idempotency, fault-injection, and end-to-end tests must pass through repository Make targets.

Acceptance Criteria
- [ ] Every child task is complete and focused tests pass.
- [ ] Every M4-CRIT-* criterion in the linked plan has recorded evidence.
- [ ] The failed fixture service recovers exactly once and passes stability verification.
- [ ] Audit evidence proves least-impact selection and no user-data mutation.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 21:19
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-08-01 21:24
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 21:24
---
Focus: Completion Auditor
---
<!-- COMMENTS:END -->

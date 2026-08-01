---
id: EXOCOMP-185
type: epic
status: In Validation
priority: 1
title: 'M7I: Host service desired state'
parent: EXOCOMP-127
children:
- EXOCOMP-187
- EXOCOMP-188
- EXOCOMP-189
- EXOCOMP-190
- EXOCOMP-191
- EXOCOMP-192
- EXOCOMP-193
- EXOCOMP-194
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:35:54.447822Z'
updated_at: '2026-08-01T18:02:41.606503Z'
work_branch: epic-EXOCOMP-185
target_branch: epic-EXOCOMP-127
review_url: https://github.com/NVShawn/exocomp/pull/22
review_number: '22'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/22
oompah.review_number: '22'
oompah.work_branch: epic-EXOCOMP-185
oompah.target_branch: epic-EXOCOMP-127
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-caa43cae56bb
    project_id: proj-c260b117
    task_id: EXOCOMP-185
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
    attempts:
    - version: 1
      attempt_id: attempt-34ade6f49251
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
      created_at: '2026-08-01T18:02:34.874779+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T18:02:34.874779+00:00'
      branch_key: epic-EXOCOMP-185
      failure_classification: infrastructure_error
      ended_at: '2026-08-01T18:02:39.460986+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-185 (tried: origin/epic-EXOCOMP-185, origin/EXOCOMP-185)'
      next_retry_at: '2026-08-01T18:02:49.460963+00:00'
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-01T18:00:19.561927+00:00'
    updated_at: '2026-08-01T18:02:39.460986+00:00'
  - version: 1
    audit_id: audit-2e98cc055e11
    project_id: proj-c260b117
    task_id: EXOCOMP-185
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
    attempts: []
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-01T18:00:19.561927+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-34ade6f49251
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
    created_at: '2026-08-01T18:02:34.874779+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T18:02:34.874779+00:00'
    branch_key: epic-EXOCOMP-185
    failure_classification: infrastructure_error
    ended_at: '2026-08-01T18:02:39.460986+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-185 (tried: origin/epic-EXOCOMP-185, origin/EXOCOMP-185)'
    next_retry_at: '2026-08-01T18:02:49.460963+00:00'
---
## Summary

Plan: plans/mission-control.md and the approved three-path service desired-state extension from 2026-07-30.

Outcome: Add coordinator-owned manual and automatic service expectations, merge them deterministically with cluster-profile expectations, observe their health through bounded node skills, and report durable service state to Mission Control.

Required behavior:
- Coordinator inventory v2 remains compatible with v1.
- Manual and automatic paths compose as a union and retain their sources.
- Automatic mode monitors enabled long-running services but does not grant restart authority.
- Desired-state removal, unsupported observations, and unhealthy transitions are explicit and auditable.
- Work is decomposed into focused child tasks suitable for a junior developer.

Out of scope: Ceph-specific topology and remedies, arbitrary commands, and Mission Control-owned desired-state configuration.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 18:00
---
Queued for terminal transition to Merged. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-01 18:00
---
YOLO: merged PR #22.
---
author: oompah
created: 2026-08-01 18:02
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 18:02
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 2s
---
author: oompah
created: 2026-08-01 18:02
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-185 (tried: origin/epic-EXOCOMP-185, origin/EXOCOMP-185). A different independent auditor will be tried on the next scheduler tick.
---
<!-- COMMENTS:END -->

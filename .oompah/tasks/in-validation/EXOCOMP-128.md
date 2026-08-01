---
id: EXOCOMP-128
type: epic
status: In Validation
priority: 1
title: 'M7A: Mission Control foundation and persistence'
parent: EXOCOMP-127
children:
- EXOCOMP-136
- EXOCOMP-137
- EXOCOMP-138
- EXOCOMP-139
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:12:16.107664Z'
updated_at: '2026-08-01T16:18:30.240557Z'
work_branch: epic-EXOCOMP-128
target_branch: epic-EXOCOMP-127
review_url: https://github.com/NVShawn/exocomp/pull/21
review_number: '21'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/21
oompah.review_number: '21'
oompah.work_branch: epic-EXOCOMP-128
oompah.target_branch: epic-EXOCOMP-127
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-8dacff3cc8f3
    project_id: proj-c260b117
    task_id: EXOCOMP-128
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    attempts:
    - version: 1
      attempt_id: attempt-9e721291b92b
      target_state: Done
      request_state: in_progress
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
      created_at: '2026-08-01T16:18:25.073295+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T16:18:25.073295+00:00'
      branch_key: epic-EXOCOMP-128
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-01T16:17:53.124916+00:00'
    updated_at: '2026-08-01T16:18:25.073295+00:00'
  - version: 1
    audit_id: audit-8bf58132f5c0
    project_id: proj-c260b117
    task_id: EXOCOMP-128
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    attempts: []
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-01T16:17:53.124916+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-9e721291b92b
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    created_at: '2026-08-01T16:18:25.073295+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T16:18:25.073295+00:00'
    branch_key: epic-EXOCOMP-128
---
## Summary

Plan sections: Architecture; Organization and Operator Identity; Persistence and Retention.

Deliver the Phoenix LiveView application skeleton, PostgreSQL/Ecto foundation, mandatory organization scope, and versioned Mission Control event/command protocol types. This epic establishes shared interfaces only; feature-specific fleet, incident, chat, and webhook behavior belongs to later epics.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 16:17
---
Queued for terminal transition to Merged. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-01 16:17
---
YOLO: merged PR #21.
---
author: oompah
created: 2026-08-01 16:18
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 16:18
---
Focus: Completion Auditor
---
<!-- COMMENTS:END -->

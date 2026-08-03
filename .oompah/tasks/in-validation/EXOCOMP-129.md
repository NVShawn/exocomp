---
id: EXOCOMP-129
type: epic
status: In Validation
priority: 1
title: 'M7B: Operator identity and cluster PKI'
parent: EXOCOMP-127
children:
- EXOCOMP-140
- EXOCOMP-141
- EXOCOMP-142
- EXOCOMP-143
- EXOCOMP-144
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:12:17.258642Z'
updated_at: '2026-08-03T17:07:37.218078Z'
work_branch: epic-EXOCOMP-129
target_branch: epic-EXOCOMP-127
review_url: https://github.com/NVShawn/exocomp/pull/23
review_number: '23'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/23
oompah.review_number: '23'
oompah.work_branch: epic-EXOCOMP-129
oompah.target_branch: epic-EXOCOMP-127
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-f0d409f1d24d
    project_id: proj-c260b117
    task_id: EXOCOMP-129
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    attempts: []
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-03T17:07:29.134256+00:00'
  - version: 1
    audit_id: audit-16a474483e07
    project_id: proj-c260b117
    task_id: EXOCOMP-129
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    attempts: []
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-03T17:07:29.134256+00:00'
  attempt_history: []
---
## Summary

Plan sections: Organization and Operator Identity; Cluster Enrollment and Identity.

Deliver OIDC operator authentication and roles plus the separate Mission Control PKI, one-use cluster invitations, CSR enrollment, certificate renewal, and revocation. Identity must always come from the authenticated operator session or validated cluster certificate.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 17:07
---
Queued for terminal transition to Merged. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-03 17:07
---
YOLO: merged PR #23.
---
<!-- COMMENTS:END -->

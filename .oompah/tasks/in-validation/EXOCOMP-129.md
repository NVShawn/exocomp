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
updated_at: '2026-08-03T17:14:00.073007Z'
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
  applied_result_attempts:
    infrastructure-exhausted-audit-f0d409f1d24d-3: '2026-08-03T17:13:42.397125+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-129
    target_state: Done
    evidence_fingerprint: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    audit_ids:
    - audit-f0d409f1d24d
    kind: result
    applied: true
    retired_at: '2026-08-03T17:13:42.397134+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-129
    audit_id: audit-f0d409f1d24d
    attempt_id: infrastructure-exhausted-audit-f0d409f1d24d-3
    target_state: Done
    evidence_fingerprint: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    status: Needs Human
    audit_ids:
    - audit-f0d409f1d24d
    applied: true
    created_at: '2026-08-03T17:13:42.397147+00:00'
    applied_at: '2026-08-03T17:13:46.945888+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-f0d409f1d24d
    project_id: proj-c260b117
    task_id: EXOCOMP-129
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    attempts:
    - version: 1
      attempt_id: attempt-2ca9ceab16f7
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
      created_at: '2026-08-03T17:10:18.527176+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-03T17:10:18.527176+00:00'
      branch_key: epic-EXOCOMP-129
      failure_classification: infrastructure_error
      ended_at: '2026-08-03T17:10:25.874804+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-129 (tried: origin/epic-EXOCOMP-129, origin/EXOCOMP-129)'
      next_retry_at: '2026-08-03T17:10:35.874776+00:00'
    - version: 1
      attempt_id: attempt-b98c55b4cdb4
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
      created_at: '2026-08-03T17:11:22.392063+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-08-03T17:11:22.392063+00:00'
      branch_key: epic-EXOCOMP-129
      candidate_rotation_count: 1
      failure_classification: infrastructure_error
      ended_at: '2026-08-03T17:11:31.089483+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-129 (tried: origin/epic-EXOCOMP-129, origin/EXOCOMP-129)'
      next_retry_at: '2026-08-03T17:11:51.089454+00:00'
    - version: 1
      attempt_id: attempt-56bedf1310b0
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
      created_at: '2026-08-03T17:12:46.398915+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-08-03T17:12:46.398915+00:00'
      branch_key: epic-EXOCOMP-129
      candidate_rotation_count: 2
      failure_classification: infrastructure_error
      ended_at: '2026-08-03T17:12:54.152710+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-129 (tried: origin/epic-EXOCOMP-129, origin/EXOCOMP-129)'
      next_retry_at: '2026-08-03T17:13:34.152676+00:00'
    - version: 1
      attempt_id: infrastructure-exhausted-audit-f0d409f1d24d-3
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
      verdict: needs_human
      failure_classification: infrastructure_error
      created_at: '2026-08-03T17:13:42.397047+00:00'
      completed_at: '2026-08-03T17:13:42.397047+00:00'
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-03T17:07:29.134256+00:00'
    updated_at: '2026-08-03T17:13:42.397047+00:00'
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
  attempt_history:
  - version: 1
    attempt_id: attempt-2ca9ceab16f7
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    created_at: '2026-08-03T17:10:18.527176+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-03T17:10:18.527176+00:00'
    branch_key: epic-EXOCOMP-129
    failure_classification: infrastructure_error
    ended_at: '2026-08-03T17:10:25.874804+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-129 (tried: origin/epic-EXOCOMP-129, origin/EXOCOMP-129)'
    next_retry_at: '2026-08-03T17:10:35.874776+00:00'
  - version: 1
    attempt_id: attempt-b98c55b4cdb4
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    created_at: '2026-08-03T17:11:22.392063+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-08-03T17:11:22.392063+00:00'
    branch_key: epic-EXOCOMP-129
    candidate_rotation_count: 1
    failure_classification: infrastructure_error
    ended_at: '2026-08-03T17:11:31.089483+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-129 (tried: origin/epic-EXOCOMP-129, origin/EXOCOMP-129)'
    next_retry_at: '2026-08-03T17:11:51.089454+00:00'
  - version: 1
    attempt_id: attempt-56bedf1310b0
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    created_at: '2026-08-03T17:12:46.398915+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-08-03T17:12:46.398915+00:00'
    branch_key: epic-EXOCOMP-129
    candidate_rotation_count: 2
    failure_classification: infrastructure_error
    ended_at: '2026-08-03T17:12:54.152710+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-129 (tried: origin/epic-EXOCOMP-129, origin/EXOCOMP-129)'
    next_retry_at: '2026-08-03T17:13:34.152676+00:00'
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
author: oompah
created: 2026-08-03 17:10
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-03 17:10
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 5s
---
author: oompah
created: 2026-08-03 17:10
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-129 (tried: origin/epic-EXOCOMP-129, origin/EXOCOMP-129). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-03 17:11
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-08-03 17:11
---
Run #2 [attempt=2, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-08-03 17:11
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-129 (tried: origin/epic-EXOCOMP-129, origin/EXOCOMP-129). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-03 17:12
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-08-03 17:12
---
Run #3 [attempt=3, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-08-03 17:13
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-129 (tried: origin/epic-EXOCOMP-129, origin/EXOCOMP-129). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-03 17:13
---
Needs Human — Done audit requires operator input.

Independent auditor launches exhausted their retry budget because the audit workspace or transport failed before review began. Restore the audit infrastructure, then have a project owner rearm this terminal audit; do not reopen implementation work.
---
<!-- COMMENTS:END -->

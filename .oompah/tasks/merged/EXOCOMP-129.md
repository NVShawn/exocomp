---
id: EXOCOMP-129
type: epic
status: Merged
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
updated_at: '2026-08-03T17:34:13.618829Z'
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
    attempt-fca3a0ff09ba: '2026-08-03T17:34:09.165934+00:00'
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
  - project_id: proj-c260b117
    task_id: EXOCOMP-129
    target_state: Merged
    evidence_fingerprint: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    audit_ids:
    - audit-16a474483e07
    kind: result
    applied: true
    retired_at: '2026-08-03T17:34:09.165946+00:00'
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
  - project_id: proj-c260b117
    task_id: EXOCOMP-129
    audit_id: audit-16a474483e07
    attempt_id: attempt-fca3a0ff09ba
    target_state: Merged
    evidence_fingerprint: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    status: Merged
    audit_ids:
    - audit-16a474483e07
    applied: false
    created_at: '2026-08-03T17:34:09.165961+00:00'
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
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    attempts:
    - version: 1
      attempt_id: attempt-fca3a0ff09ba
      target_state: Merged
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
      created_at: '2026-08-03T17:15:15.628509+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-03T17:15:15.628509+00:00'
      branch_key: epic-EXOCOMP-129
      verdict: pass
      completed_at: '2026-08-03T17:34:09.165755+00:00'
      ended_at: '2026-08-03T17:34:09.165755+00:00'
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-03T17:07:29.134256+00:00'
    updated_at: '2026-08-03T17:34:09.165755+00:00'
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
  - version: 1
    attempt_id: attempt-fca3a0ff09ba
    target_state: Merged
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 1636c1f6ad745c0d8aaa0ffb7cbc310e2063ec7420c3f9a20d014c65ed81a95f
    created_at: '2026-08-03T17:15:15.628509+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-03T17:15:15.628509+00:00'
    branch_key: epic-EXOCOMP-129
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
author: oompah
created: 2026-08-03 17:15
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-03 17:15
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-03 17:34
---
Audit PASS — Merged

[REDACTED]

Safe evidence:
- merge_commit: 869d7c5a08868c4e9f2dd372e8808ec4ee4edfb0
- merge_commit_message: Merge pull request #23 from NVShawn/epic-EXOCOMP-129
- merge_parent_target: 3377d707470a4dbe27fd9c962c0acb4e95e1289d
- merge_parent_work: 0a82a703f55d97a54f36c87f9d3edec3ffaad25a
- work_branch: epic-EXOCOMP-129
- work_branch_head: 0a82a703f55d97a54f36c87f9d3edec3ffaad25a
- target_branch: epic-EXOCOMP-127
- target_branch_contains_merge: origin/epic-EXOCOMP-127
- review_pr: https://github.com/NVShawn/exocomp/pull/23
- child_tasks_status: EXOCOMP-140,141,142,143,144 all in .oompah/tasks/done/
- child_144_terminal_audit: PASS at 2026-08-03T17:00:12Z (audit-e167a2bfb05b)
- merge_diff_stat: 17 files, +4174 / -31
- deliverables_present: cluster_invitation.ex, cluster_invitation_store.ex, cluster_invitation_handler.ex, cluster_enrollment_handler.ex, renewal_handler.ex (expanded), pki/certificate_registry.ex, pki/cluster_issuer.ex, cluster.ex, cluster_invitations.ex, plus tests
- test_files_added: cluster_invitation_test.exs (206), pki/certificate_registry_test.exs (252), integration/cluster_enrollment_test.exs (279), integration/coordinator_pki_renewal_test.exs (863)
- prior_done_audit_infrastructure_reason: auditor tried origin/epic-EXOCOMP-129 which was never pushed; the merge is on origin/epic-EXOCOMP-127 (the declared target_branch)
---
<!-- COMMENTS:END -->

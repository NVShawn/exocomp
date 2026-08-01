---
id: EXOCOMP-3
type: epic
status: In Review
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
updated_at: '2026-08-01T21:32:43.298701Z'
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
  applied_result_attempts:
    attempt-03577dfbb3d4: '2026-08-01T21:23:51.707962+00:00'
    infrastructure-exhausted-audit-0206842bbb7e-3: '2026-08-01T21:32:11.234669+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-3
    target_state: Archived
    evidence_fingerprint: 5512afa98f25aed5df83c0f51cc11d33396f2cb621041ee8fde12d3a19cd082c
    audit_ids:
    - audit-72983f0fb0f0
    kind: result
    applied: true
    retired_at: '2026-08-01T21:23:51.707974+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-3
    target_state: Done
    evidence_fingerprint: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
    audit_ids:
    - audit-0206842bbb7e
    kind: result
    applied: true
    retired_at: '2026-08-01T21:32:11.234680+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-3
    audit_id: audit-72983f0fb0f0
    attempt_id: attempt-03577dfbb3d4
    target_state: Archived
    evidence_fingerprint: 5512afa98f25aed5df83c0f51cc11d33396f2cb621041ee8fde12d3a19cd082c
    status: In Validation
    audit_ids:
    - audit-72983f0fb0f0
    applied: true
    created_at: '2026-08-01T21:23:51.707990+00:00'
    applied_at: '2026-08-01T21:23:55.669906+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-3
    audit_id: audit-0206842bbb7e
    attempt_id: infrastructure-exhausted-audit-0206842bbb7e-3
    target_state: Done
    evidence_fingerprint: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
    status: Needs Human
    audit_ids:
    - audit-0206842bbb7e
    applied: true
    created_at: '2026-08-01T21:32:11.234694+00:00'
    applied_at: '2026-08-01T21:32:13.575338+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-72983f0fb0f0
    project_id: proj-c260b117
    task_id: EXOCOMP-3
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 5512afa98f25aed5df83c0f51cc11d33396f2cb621041ee8fde12d3a19cd082c
    attempts:
    - version: 1
      attempt_id: attempt-03577dfbb3d4
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 5512afa98f25aed5df83c0f51cc11d33396f2cb621041ee8fde12d3a19cd082c
      created_at: '2026-08-01T21:19:04.163564+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T21:19:04.163564+00:00'
      branch_key: epic-EXOCOMP-3
      verdict: pass
      completed_at: '2026-08-01T21:23:51.707784+00:00'
      ended_at: '2026-08-01T21:23:51.707784+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T21:18:54.523492+00:00'
    updated_at: '2026-08-01T21:23:51.707784+00:00'
  - version: 1
    audit_id: audit-0206842bbb7e
    project_id: proj-c260b117
    task_id: EXOCOMP-3
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
    attempts:
    - version: 1
      attempt_id: attempt-c50fc394be74
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
      created_at: '2026-08-01T21:24:34.181920+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T21:24:34.181920+00:00'
      branch_key: epic-EXOCOMP-3
      failure_classification: infrastructure_error
      ended_at: '2026-08-01T21:24:42.524550+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-3 (tried: origin/epic-EXOCOMP-3, origin/EXOCOMP-3)'
      next_retry_at: '2026-08-01T21:24:52.524520+00:00'
    - version: 1
      attempt_id: attempt-50bfc9ebe086
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
      created_at: '2026-08-01T21:30:21.686787+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-08-01T21:30:21.686787+00:00'
      branch_key: epic-EXOCOMP-3
      candidate_rotation_count: 1
      failure_classification: infrastructure_error
      ended_at: '2026-08-01T21:30:33.951516+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-3 (tried: origin/epic-EXOCOMP-3, origin/EXOCOMP-3)'
      next_retry_at: '2026-08-01T21:30:53.951484+00:00'
    - version: 1
      attempt_id: attempt-5e1230428a13
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
      created_at: '2026-08-01T21:30:56.143117+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-08-01T21:30:56.143117+00:00'
      branch_key: epic-EXOCOMP-3
      candidate_rotation_count: 2
      failure_classification: infrastructure_error
      ended_at: '2026-08-01T21:30:59.416774+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-3 (tried: origin/epic-EXOCOMP-3, origin/EXOCOMP-3)'
      next_retry_at: '2026-08-01T21:31:39.416736+00:00'
    - version: 1
      attempt_id: infrastructure-exhausted-audit-0206842bbb7e-3
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
      verdict: needs_human
      failure_classification: infrastructure_error
      created_at: '2026-08-01T21:32:11.234600+00:00'
      completed_at: '2026-08-01T21:32:11.234600+00:00'
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Validation
    created_at: '2026-08-01T21:22:36.455228+00:00'
    updated_at: '2026-08-01T21:32:11.234600+00:00'
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
  - version: 1
    attempt_id: attempt-c50fc394be74
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
    created_at: '2026-08-01T21:24:34.181920+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T21:24:34.181920+00:00'
    branch_key: epic-EXOCOMP-3
    failure_classification: infrastructure_error
    ended_at: '2026-08-01T21:24:42.524550+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-3 (tried: origin/epic-EXOCOMP-3, origin/EXOCOMP-3)'
    next_retry_at: '2026-08-01T21:24:52.524520+00:00'
  - version: 1
    attempt_id: attempt-50bfc9ebe086
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
    created_at: '2026-08-01T21:30:21.686787+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-08-01T21:30:21.686787+00:00'
    branch_key: epic-EXOCOMP-3
    candidate_rotation_count: 1
    failure_classification: infrastructure_error
    ended_at: '2026-08-01T21:30:33.951516+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-3 (tried: origin/epic-EXOCOMP-3, origin/EXOCOMP-3)'
    next_retry_at: '2026-08-01T21:30:53.951484+00:00'
  - version: 1
    attempt_id: attempt-5e1230428a13
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: dfdd06de43ce7298c9622fd8f22ad3f48a983aabef54b3f7b5f0deb405fe18e2
    created_at: '2026-08-01T21:30:56.143117+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-08-01T21:30:56.143117+00:00'
    branch_key: epic-EXOCOMP-3
    candidate_rotation_count: 2
    failure_classification: infrastructure_error
    ended_at: '2026-08-01T21:30:59.416774+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-3 (tried: origin/epic-EXOCOMP-3, origin/EXOCOMP-3)'
    next_retry_at: '2026-08-01T21:31:39.416736+00:00'
oompah.task_costs:
  total_input_tokens: 33
  total_output_tokens: 4731
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 33
      output_tokens: 4731
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 33
    output_tokens: 4731
    cost_usd: 0.0
    recorded_at: '2026-08-01T21:24:18.293270+00:00'
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
author: oompah
created: 2026-08-01 21:23
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- merge_commit: 7295c338c4ff4505291f412f7476894d42bbda8a
- merge_pr: #12 (NVShawn/epic-EXOCOMP-3)
- merge_date: 2026-07-24
- audit_date: 2026-08-01
- days_since_merge: 8
- merge_on_main: true (git branch --contains lists main)
- files_added_by_merge: 54
- insertions_by_merge: 11196
- acceptance_criteria_checked: M3-CRIT-1..M3-CRIT-8 all [x] in plans/milestone-3-safety-validation.md
- acceptance_test_recovery: EXOCOMP-113 recovered M3 acceptance suites (commit cad1c28b)
- safety_modules_present: apps/exocomp_node/lib/exocomp/node/safety (14 modules) and matching tests
---
author: oompah
created: 2026-08-01 21:24
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 34, Tool calls: 27
- Tokens: 33 in / 4.7K out [4.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 5m 6s
- Log: EXOCOMP-3__20260801T211925Z.jsonl
---
author: oompah
created: 2026-08-01 21:24
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 21:24
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-08-01 21:24
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-3 (tried: origin/epic-EXOCOMP-3, origin/EXOCOMP-3). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-01 21:30
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-08-01 21:30
---
Run #2 [attempt=2, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 8s
---
author: oompah
created: 2026-08-01 21:30
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-3 (tried: origin/epic-EXOCOMP-3, origin/EXOCOMP-3). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-01 21:30
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-08-01 21:31
---
Run #3 [attempt=3, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 2s
---
author: oompah
created: 2026-08-01 21:31
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-3 (tried: origin/epic-EXOCOMP-3, origin/EXOCOMP-3). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-01 21:32
---
Needs Human — Done audit requires operator input.

Independent auditor launches exhausted their retry budget because the audit workspace or transport failed before review began. Restore the audit infrastructure, then have a project owner rearm this terminal audit; do not reopen implementation work.
---
<!-- COMMENTS:END -->

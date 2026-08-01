---
id: EXOCOMP-185
type: epic
status: Merged
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
updated_at: '2026-08-01T18:27:42.044436Z'
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
  applied_result_attempts:
    infrastructure-exhausted-audit-caa43cae56bb-3: '2026-08-01T18:13:55.334690+00:00'
    attempt-2618bf606a0d: '2026-08-01T18:27:22.347010+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-185
    target_state: Done
    evidence_fingerprint: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
    audit_ids:
    - audit-caa43cae56bb
    kind: result
    applied: true
    retired_at: '2026-08-01T18:13:55.334701+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-185
    target_state: Merged
    evidence_fingerprint: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
    audit_ids:
    - audit-2e98cc055e11
    kind: result
    applied: true
    retired_at: '2026-08-01T18:27:22.347020+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-185
    audit_id: audit-caa43cae56bb
    attempt_id: infrastructure-exhausted-audit-caa43cae56bb-3
    target_state: Done
    evidence_fingerprint: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
    status: Needs Human
    audit_ids:
    - audit-caa43cae56bb
    applied: true
    created_at: '2026-08-01T18:13:55.334719+00:00'
    applied_at: '2026-08-01T18:13:57.922185+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-185
    audit_id: audit-2e98cc055e11
    attempt_id: attempt-2618bf606a0d
    target_state: Merged
    evidence_fingerprint: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
    status: Merged
    audit_ids:
    - audit-2e98cc055e11
    applied: true
    created_at: '2026-08-01T18:27:22.347029+00:00'
    applied_at: '2026-08-01T18:27:26.555021+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-caa43cae56bb
    project_id: proj-c260b117
    task_id: EXOCOMP-185
    target_state: Done
    request_state: completed
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
    - version: 1
      attempt_id: attempt-f32c1f404628
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
      created_at: '2026-08-01T18:04:59.610116+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-08-01T18:04:59.610116+00:00'
      branch_key: epic-EXOCOMP-185
      candidate_rotation_count: 1
      failure_classification: infrastructure_error
      ended_at: '2026-08-01T18:05:04.552599+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-185 (tried: origin/epic-EXOCOMP-185, origin/EXOCOMP-185)'
      next_retry_at: '2026-08-01T18:05:24.552563+00:00'
    - version: 1
      attempt_id: attempt-d902cd0cf585
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
      created_at: '2026-08-01T18:12:51.526889+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-08-01T18:12:51.526889+00:00'
      branch_key: epic-EXOCOMP-185
      candidate_rotation_count: 2
      failure_classification: infrastructure_error
      ended_at: '2026-08-01T18:12:55.343219+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-185 (tried: origin/epic-EXOCOMP-185, origin/EXOCOMP-185)'
      next_retry_at: '2026-08-01T18:13:35.343181+00:00'
    - version: 1
      attempt_id: infrastructure-exhausted-audit-caa43cae56bb-3
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
      verdict: needs_human
      failure_classification: infrastructure_error
      created_at: '2026-08-01T18:13:55.334570+00:00'
      completed_at: '2026-08-01T18:13:55.334570+00:00'
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-01T18:00:19.561927+00:00'
    updated_at: '2026-08-01T18:13:55.334570+00:00'
  - version: 1
    audit_id: audit-2e98cc055e11
    project_id: proj-c260b117
    task_id: EXOCOMP-185
    target_state: Merged
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
    attempts:
    - version: 1
      attempt_id: attempt-2618bf606a0d
      target_state: Merged
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
      created_at: '2026-08-01T18:16:23.288309+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T18:16:23.288309+00:00'
      branch_key: epic-EXOCOMP-185
      verdict: pass
      completed_at: '2026-08-01T18:27:22.346886+00:00'
      ended_at: '2026-08-01T18:27:22.346886+00:00'
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-01T18:00:19.561927+00:00'
    updated_at: '2026-08-01T18:27:22.346886+00:00'
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
  - version: 1
    attempt_id: attempt-f32c1f404628
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
    created_at: '2026-08-01T18:04:59.610116+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-08-01T18:04:59.610116+00:00'
    branch_key: epic-EXOCOMP-185
    candidate_rotation_count: 1
    failure_classification: infrastructure_error
    ended_at: '2026-08-01T18:05:04.552599+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-185 (tried: origin/epic-EXOCOMP-185, origin/EXOCOMP-185)'
    next_retry_at: '2026-08-01T18:05:24.552563+00:00'
  - version: 1
    attempt_id: attempt-d902cd0cf585
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
    created_at: '2026-08-01T18:12:51.526889+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-08-01T18:12:51.526889+00:00'
    branch_key: epic-EXOCOMP-185
    candidate_rotation_count: 2
    failure_classification: infrastructure_error
    ended_at: '2026-08-01T18:12:55.343219+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-185 (tried: origin/epic-EXOCOMP-185, origin/EXOCOMP-185)'
    next_retry_at: '2026-08-01T18:13:35.343181+00:00'
  - version: 1
    attempt_id: attempt-2618bf606a0d
    target_state: Merged
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 876576de5739eeee541f22c9268c3b2a01c2806b2c735cf4ef55c6fc12d0d457
    created_at: '2026-08-01T18:16:23.288309+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T18:16:23.288309+00:00'
    branch_key: epic-EXOCOMP-185
oompah.task_costs:
  total_input_tokens: 79
  total_output_tokens: 2970
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 79
      output_tokens: 2970
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 79
    output_tokens: 2970
    cost_usd: 0.0
    recorded_at: '2026-08-01T18:27:40.497763+00:00'
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
author: oompah
created: 2026-08-01 18:05
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-08-01 18:05
---
Run #2 [attempt=2, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 2s
---
author: oompah
created: 2026-08-01 18:05
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-185 (tried: origin/epic-EXOCOMP-185, origin/EXOCOMP-185). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-01 18:12
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-08-01 18:12
---
Run #3 [attempt=3, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 2s
---
author: oompah
created: 2026-08-01 18:12
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-185 (tried: origin/epic-EXOCOMP-185, origin/EXOCOMP-185). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-01 18:13
---
Needs Human — Done audit requires operator input.

Independent auditor launches exhausted their retry budget because the audit workspace or transport failed before review began. Restore the audit infrastructure, then have a project owner rearm this terminal audit; do not reopen implementation work.
---
author: oompah
created: 2026-08-01 18:16
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 18:16
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 18:27
---
Audit PASS — Merged

[REDACTED]

Safe evidence:
- merge_commit: 2c9ad37b8a482cc5541bf72b1a0cad5d4a771752
- merge_title: Merge pull request #22 from NVShawn/epic-EXOCOMP-185
- epic_head_second_parent: a163c8323e9b83e2360af73c9f3e972b99f9dc0d
- target_branch_metadata: epic-EXOCOMP-127
- target_branch_remote_ref: origin/epic-EXOCOMP-127
- target_branch_tip_matches_merge_commit: true
- review_url: https://github.com/NVShawn/exocomp/pull/22
- review_number: 22
- child_tasks_in_done_state: EXOCOMP-187, EXOCOMP-188, EXOCOMP-189, EXOCOMP-190, EXOCOMP-191, EXOCOMP-192, EXOCOMP-193, EXOCOMP-194
- child_tasks_missing_or_open: none
- merge_files_changed: 36
- merge_insertions: 6451
- merge_deletions: 51
- key_areas_added: coordinator service_scheduler + inventory v2, Mission Control status_contract facade, exocomp_core desired_service + status_event/codec/reducer, node http_probe + service_inventory + service_observe skills, shared JSON fixtures
- plans_updated: plans/mission-control.md, plans/exocomp.md
- prior_auditor_failure_note: Earlier attempts failed with infrastructure_error because they searched for origin/epic-EXOCOMP-185 or origin/EXOCOMP-185, which do not exist post-merge; the merge is preserved on origin/epic-EXOCOMP-127 (the epic's recorded target branch).
---
author: oompah
created: 2026-08-01 18:27
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 0, Tool calls: 55
- Tokens: 79 in / 3.0K out [3.0K total]
- Cost: $0.0000
- Exit: terminated, Duration: 11m 16s
- Log: EXOCOMP-185__20260801T181631Z.jsonl
---
<!-- COMMENTS:END -->

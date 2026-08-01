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
updated_at: '2026-08-01T21:41:10.888424Z'
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
  applied_result_attempts:
    attempt-3a9cec45112b: '2026-08-01T21:31:35.545586+00:00'
    infrastructure-exhausted-audit-62a193b86f6a-3: '2026-08-01T21:40:20.503981+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-4
    target_state: Archived
    evidence_fingerprint: af00412b66a77cdddc18d01772616312cfd6270d6dcaa2526b0b1873470873b3
    audit_ids:
    - audit-5f6fb7566daa
    kind: result
    applied: true
    retired_at: '2026-08-01T21:31:35.545593+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-4
    target_state: Done
    evidence_fingerprint: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
    audit_ids:
    - audit-62a193b86f6a
    kind: result
    applied: true
    retired_at: '2026-08-01T21:40:20.503998+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-4
    audit_id: audit-5f6fb7566daa
    attempt_id: attempt-3a9cec45112b
    target_state: Archived
    evidence_fingerprint: af00412b66a77cdddc18d01772616312cfd6270d6dcaa2526b0b1873470873b3
    status: In Validation
    audit_ids:
    - audit-5f6fb7566daa
    applied: true
    created_at: '2026-08-01T21:31:35.545604+00:00'
    applied_at: '2026-08-01T21:31:38.002127+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-4
    audit_id: audit-62a193b86f6a
    attempt_id: infrastructure-exhausted-audit-62a193b86f6a-3
    target_state: Done
    evidence_fingerprint: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
    status: Needs Human
    audit_ids:
    - audit-62a193b86f6a
    applied: true
    created_at: '2026-08-01T21:40:20.504018+00:00'
    applied_at: '2026-08-01T21:40:23.489517+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-5f6fb7566daa
    project_id: proj-c260b117
    task_id: EXOCOMP-4
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: af00412b66a77cdddc18d01772616312cfd6270d6dcaa2526b0b1873470873b3
    attempts:
    - version: 1
      attempt_id: attempt-3a9cec45112b
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: af00412b66a77cdddc18d01772616312cfd6270d6dcaa2526b0b1873470873b3
      created_at: '2026-08-01T21:24:40.986740+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T21:24:40.986740+00:00'
      branch_key: epic-EXOCOMP-4
      verdict: pass
      completed_at: '2026-08-01T21:31:35.545467+00:00'
      ended_at: '2026-08-01T21:31:35.545467+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T21:19:12.334799+00:00'
    updated_at: '2026-08-01T21:31:35.545467+00:00'
  - version: 1
    audit_id: audit-62a193b86f6a
    project_id: proj-c260b117
    task_id: EXOCOMP-4
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
    attempts:
    - version: 1
      attempt_id: attempt-de53e8dbae9e
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
      created_at: '2026-08-01T21:32:14.972725+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T21:32:14.972725+00:00'
      branch_key: epic-EXOCOMP-4
      failure_classification: infrastructure_error
      ended_at: '2026-08-01T21:32:20.873116+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-4 (tried: origin/epic-EXOCOMP-4, origin/EXOCOMP-4)'
      next_retry_at: '2026-08-01T21:32:30.873085+00:00'
    - version: 1
      attempt_id: attempt-2c3a4ea43f2a
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
      created_at: '2026-08-01T21:37:20.154586+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-08-01T21:37:20.154586+00:00'
      branch_key: epic-EXOCOMP-4
      candidate_rotation_count: 1
      failure_classification: infrastructure_error
      ended_at: '2026-08-01T21:37:27.200794+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-4 (tried: origin/epic-EXOCOMP-4, origin/EXOCOMP-4)'
      next_retry_at: '2026-08-01T21:37:47.200754+00:00'
    - version: 1
      attempt_id: attempt-aa3c6eb2ee9e
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
      created_at: '2026-08-01T21:38:24.703704+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-08-01T21:38:24.703704+00:00'
      branch_key: epic-EXOCOMP-4
      candidate_rotation_count: 2
      failure_classification: infrastructure_error
      ended_at: '2026-08-01T21:38:42.210006+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-4 (tried: origin/epic-EXOCOMP-4, origin/EXOCOMP-4)'
      next_retry_at: '2026-08-01T21:39:22.209973+00:00'
    - version: 1
      attempt_id: infrastructure-exhausted-audit-62a193b86f6a-3
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
      verdict: needs_human
      failure_classification: infrastructure_error
      created_at: '2026-08-01T21:40:20.503852+00:00'
      completed_at: '2026-08-01T21:40:20.503852+00:00'
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Validation
    created_at: '2026-08-01T21:22:40.212063+00:00'
    updated_at: '2026-08-01T21:40:20.503852+00:00'
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
  - version: 1
    attempt_id: attempt-de53e8dbae9e
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
    created_at: '2026-08-01T21:32:14.972725+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T21:32:14.972725+00:00'
    branch_key: epic-EXOCOMP-4
    failure_classification: infrastructure_error
    ended_at: '2026-08-01T21:32:20.873116+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-4 (tried: origin/epic-EXOCOMP-4, origin/EXOCOMP-4)'
    next_retry_at: '2026-08-01T21:32:30.873085+00:00'
  - version: 1
    attempt_id: attempt-2c3a4ea43f2a
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
    created_at: '2026-08-01T21:37:20.154586+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-08-01T21:37:20.154586+00:00'
    branch_key: epic-EXOCOMP-4
    candidate_rotation_count: 1
    failure_classification: infrastructure_error
    ended_at: '2026-08-01T21:37:27.200794+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-4 (tried: origin/epic-EXOCOMP-4, origin/EXOCOMP-4)'
    next_retry_at: '2026-08-01T21:37:47.200754+00:00'
  - version: 1
    attempt_id: attempt-aa3c6eb2ee9e
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 695c8293f3da9f82ccfd12f9dc24b166695fe17be72a21ffa2d97f08ab972d28
    created_at: '2026-08-01T21:38:24.703704+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-08-01T21:38:24.703704+00:00'
    branch_key: epic-EXOCOMP-4
    candidate_rotation_count: 2
    failure_classification: infrastructure_error
    ended_at: '2026-08-01T21:38:42.210006+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-4 (tried: origin/epic-EXOCOMP-4, origin/EXOCOMP-4)'
    next_retry_at: '2026-08-01T21:39:22.209973+00:00'
oompah.task_costs:
  total_input_tokens: 35
  total_output_tokens: 7190
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 35
      output_tokens: 7190
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 35
    output_tokens: 7190
    cost_usd: 0.0
    recorded_at: '2026-08-01T21:31:58.294413+00:00'
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
author: oompah
created: 2026-08-01 21:31
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- merge_commit: 725120a9de7736183e1f2449ae35de03713de31a
- merge_pr: #10 epic-EXOCOMP-4
- merge_date: 2026-07-24
- plan_path: plans/milestone-4-service-recovery.md
- state_machine_module: apps/exocomp_core/lib/exocomp/recovery/state_machine.ex
- e2e_test: apps/exocomp_coordinator/test/integration/m4_a2a_recovery_test.exs
- fault_injection_test: apps/exocomp_node/test/exocomp/node/recovery/fault_injection_test.exs
- approval_required_module: apps/exocomp_node/lib/exocomp/node/recovery/approval_required.ex
- criteria_checked: M4-CRIT-1 through M4-CRIT-8 all [x] in plan
- auto_archive_trigger: Aged Merged 7-day auto-archive per comment #1
- children_states: EXOCOMP-29/30/31/32/34/106/109 Archived; EXOCOMP-33 In Validation (child-level audit)
---
author: oompah
created: 2026-08-01 21:31
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 46, Tool calls: 37
- Tokens: 35 in / 7.2K out [7.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 7m 12s
- Log: EXOCOMP-4__20260801T212449Z.jsonl
---
author: oompah
created: 2026-08-01 21:32
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 21:32
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-08-01 21:32
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-4 (tried: origin/epic-EXOCOMP-4, origin/EXOCOMP-4). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-01 21:37
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-08-01 21:37
---
Run #2 [attempt=2, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 4s
---
author: oompah
created: 2026-08-01 21:37
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-4 (tried: origin/epic-EXOCOMP-4, origin/EXOCOMP-4). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-01 21:38
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-08-01 21:38
---
Run #3 [attempt=3, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 9s
---
author: oompah
created: 2026-08-01 21:38
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-4 (tried: origin/epic-EXOCOMP-4, origin/EXOCOMP-4). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-01 21:40
---
Needs Human — Done audit requires operator input.

Independent auditor launches exhausted their retry budget because the audit workspace or transport failed before review began. Restore the audit infrastructure, then have a project owner rearm this terminal audit; do not reopen implementation work.
---
<!-- COMMENTS:END -->

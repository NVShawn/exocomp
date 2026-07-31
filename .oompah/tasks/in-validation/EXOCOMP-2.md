---
id: EXOCOMP-2
type: epic
status: In Validation
priority: 1
title: 'M2: Coordinator, discovery, and node enrollment'
parent: null
children:
- EXOCOMP-14
- EXOCOMP-15
- EXOCOMP-16
- EXOCOMP-17
- EXOCOMP-18
- EXOCOMP-19
- EXOCOMP-20
blocked_by: []
labels:
- epic:stale
assignee: null
created_at: '2026-07-23T19:08:09.243476Z'
updated_at: '2026-07-31T20:58:28.015898Z'
work_branch: epic-EXOCOMP-2
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/9
review_number: '9'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/9
oompah.review_number: '9'
oompah.work_branch: epic-EXOCOMP-2
oompah.target_branch: main
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-7ed3dd34d77a: '2026-07-31T20:58:16.116602+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-2
    target_state: Archived
    evidence_fingerprint: 72be727f0a023470da368377bbff60e3059ebfbcc9dd6dd6e9fda37d06dc9cab
    audit_ids:
    - audit-00e27e4ce78e
    kind: result
    applied: true
    retired_at: '2026-07-31T20:58:16.116614+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-2
    audit_id: audit-00e27e4ce78e
    attempt_id: attempt-7ed3dd34d77a
    target_state: Archived
    evidence_fingerprint: 72be727f0a023470da368377bbff60e3059ebfbcc9dd6dd6e9fda37d06dc9cab
    status: In Validation
    audit_ids:
    - audit-00e27e4ce78e
    applied: true
    created_at: '2026-07-31T20:58:16.116634+00:00'
    applied_at: '2026-07-31T20:58:18.355441+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-00e27e4ce78e
    project_id: proj-c260b117
    task_id: EXOCOMP-2
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 72be727f0a023470da368377bbff60e3059ebfbcc9dd6dd6e9fda37d06dc9cab
    attempts:
    - version: 1
      attempt_id: attempt-7ed3dd34d77a
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 72be727f0a023470da368377bbff60e3059ebfbcc9dd6dd6e9fda37d06dc9cab
      created_at: '2026-07-31T20:55:22.608032+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T20:55:22.608032+00:00'
      branch_key: epic-EXOCOMP-2
      verdict: pass
      completed_at: '2026-07-31T20:58:16.116435+00:00'
      ended_at: '2026-07-31T20:58:16.116435+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-31T20:46:42.404674+00:00'
    updated_at: '2026-07-31T20:58:16.116435+00:00'
  - version: 1
    audit_id: audit-c9bcd08130a2
    project_id: proj-c260b117
    task_id: EXOCOMP-2
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: f67c2632102b1b301444a2a6467de3dfc5cccb01b8e9788f109a1a31c5ef5a9f
    attempts: []
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Validation
    created_at: '2026-07-31T20:57:03.647172+00:00'
  - version: 1
    audit_id: audit-024b3eea6f9b
    project_id: proj-c260b117
    task_id: EXOCOMP-2
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: f67c2632102b1b301444a2a6467de3dfc5cccb01b8e9788f109a1a31c5ef5a9f
    attempts: []
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Validation
    created_at: '2026-07-31T20:57:03.647172+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-7ed3dd34d77a
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 72be727f0a023470da368377bbff60e3059ebfbcc9dd6dd6e9fda37d06dc9cab
    created_at: '2026-07-31T20:55:22.608032+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T20:55:22.608032+00:00'
    branch_key: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 40
  total_output_tokens: 6545
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 40
      output_tokens: 6545
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 40
    output_tokens: 6545
    cost_usd: 0.0
    recorded_at: '2026-07-31T20:58:26.813299+00:00'
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Deliver coordinator discovery, node enrollment, polling, diagnostic orchestration, and A2A service capabilities.

Scope
Coordinate child tasks for coordinator state and inventory, health polling, bootstrap PKI, node enrollment and renewal, task orchestration, the coordinator A2A surface, and milestone acceptance. Remediation execution remains disabled.

Testing
All child-task tests, PKI scenarios, and the multi-node integration suite must pass through repository Make targets.

Acceptance Criteria
- [ ] Every child task is complete and focused tests pass.
- [ ] Every M2-CRIT-* criterion in the linked plan has recorded evidence.
- [ ] Enrollment, discovery, polling, and diagnostic dispatch work across multiple nodes.
- [ ] No Milestone 2 path invokes remediation.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:47
---
YOLO: merged PR #9.
---
author: oompah
created: 2026-07-31 20:46
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-07-31 20:55
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 20:55
---
Focus: Completion Auditor
---
author: oompah
created: 2026-07-31 20:58
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- merge_commit: 6deabae (Merge PR #9 from NVShawn/epic-EXOCOMP-2)
- merge_contained_in_main: true
- plan_criteria_status: M2-CRIT-1..8 all checked in plans/milestone-2-coordinator.md
- coordinator_app_present: apps/exocomp_coordinator/ with lib/ and test/
- downstream_milestones_built_on_top: M4 EXOCOMP-117, M5 EXOCOMP-123/125/126 merged after this epic
- auto_archive_reason: Aged Merged (closed 7 days ago)
---
author: oompah
created: 2026-07-31 20:58
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 44, Tool calls: 34
- Tokens: 40 in / 6.5K out [6.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 3s
- Log: EXOCOMP-2__20260731T205525Z.jsonl
---
<!-- COMMENTS:END -->

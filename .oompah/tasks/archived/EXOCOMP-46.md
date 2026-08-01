---
id: EXOCOMP-46
type: chore
status: Archived
priority: 2
title: Document and test upgrade, rollback, backup, and removal
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-34
- EXOCOMP-43
- EXOCOMP-115
labels: []
assignee: null
created_at: '2026-07-23T19:12:05.467498Z'
updated_at: '2026-08-01T21:27:19.731786Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-d18773ea1b1f: '2026-08-01T21:26:33.813884+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-46
    target_state: Archived
    evidence_fingerprint: 8dabacef6f55414e230fceec41cbeea81fd0fb149c5ff0d60cd76bd0472f0bb8
    audit_ids:
    - audit-a2bb7b1f99fa
    kind: result
    applied: true
    retired_at: '2026-08-01T21:26:33.813896+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-46
    audit_id: audit-a2bb7b1f99fa
    attempt_id: attempt-d18773ea1b1f
    target_state: Archived
    evidence_fingerprint: 8dabacef6f55414e230fceec41cbeea81fd0fb149c5ff0d60cd76bd0472f0bb8
    status: Archived
    audit_ids:
    - audit-a2bb7b1f99fa
    applied: true
    created_at: '2026-08-01T21:26:33.813913+00:00'
    applied_at: '2026-08-01T21:26:38.147599+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-a2bb7b1f99fa
    project_id: proj-c260b117
    task_id: EXOCOMP-46
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 8dabacef6f55414e230fceec41cbeea81fd0fb149c5ff0d60cd76bd0472f0bb8
    attempts:
    - version: 1
      attempt_id: attempt-d18773ea1b1f
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 8dabacef6f55414e230fceec41cbeea81fd0fb149c5ff0d60cd76bd0472f0bb8
      created_at: '2026-08-01T21:21:34.211860+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T21:21:34.211860+00:00'
      branch_key: EXOCOMP-46
      verdict: pass
      completed_at: '2026-08-01T21:26:33.813706+00:00'
      ended_at: '2026-08-01T21:26:33.813706+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T21:19:23.623694+00:00'
    updated_at: '2026-08-01T21:26:33.813706+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-d18773ea1b1f
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 8dabacef6f55414e230fceec41cbeea81fd0fb149c5ff0d60cd76bd0472f0bb8
    created_at: '2026-08-01T21:21:34.211860+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T21:21:34.211860+00:00'
    branch_key: EXOCOMP-46
oompah.task_costs:
  total_input_tokens: 29
  total_output_tokens: 4954
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 29
      output_tokens: 4954
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 29
    output_tokens: 4954
    cost_usd: 0.0
    recorded_at: '2026-08-01T21:27:17.757052+00:00'
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Document and test upgrade, rollback, backup, and removal.

Implementation
Implement/document side-by-side upgrade, configuration validation, health-gated current-version switch, automatic rollback, compatibility limits, PKI/state backup and restore, troubleshooting, and safe removal; avoid irreversible first-release migrations.

Testing
Test successful upgrade, failed health rollback, coordinator/node version compatibility, backup/restore, interrupted upgrade, default uninstall, explicit purge categories, and preservation of PKI/audit/execution/config/user data.

Acceptance Criteria
- [ ] Failed upgrade restores a healthy prior version.
- [ ] Rollback does not reissue identities or repeat actions.
- [ ] Backup/restore procedures are verified.
- [ ] Removal deletes only recorded Exocomp-owned resources and never user data.
- [ ] Lifecycle tests pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 18:32
---
Action required: use recovery task EXOCOMP-115 to implement and verify this task's previously undelivered scope on main. Do not mark this task Merged again until EXOCOMP-115 lands and the original acceptance criteria are confirmed against main.
---
author: oompah
created: 2026-07-25 18:32
---
Moved to Needs Human from the dashboard/API. Human action required: inspect EXOCOMP-46 (Document and test upgrade, rollback, backup, and removal), add the specific decision, missing information, or manual fix needed, then move the task back to Open when it is ready for agents again.
---
author: oompah
created: 2026-07-25 20:09
---
The parent epic EXOCOMP-6 merged from epic-EXOCOMP-6, but this task was Needs Human with work branch unset. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
author: oompah
created: 2026-07-25 21:10
---
Recovered delivery verified on origin/main at merge commit 2085e44152f03ffd41f35cbfeee89a0da53b8bce (PR #14). Evidence: health-gated upgrade/rollback, backup/restore, removal lifecycle, docs, and 63 installer tests are integrated by 516faf81e5f506f9cc7d1ac24a98499e73dbfea0. The full recovery quality gates passed.
---
author: oompah
created: 2026-07-25 21:10
---
Recovered deliverable verified on origin/main via PR #14 (2085e44).
---
author: oompah
created: 2026-08-01 21:19
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-08-01 21:21
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 21:21
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 21:26
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- recovery_merge_commit: 2085e44152f03ffd41f35cbfeee89a0da53b8bce
- recovery_delivery_commit: 516faf81e5f506f9cc7d1ac24a98499e73dbfea0
- on_origin_main: yes (verified via git log origin/main --grep EXOCOMP-115)
- lifecycle_doc: docs/lifecycle.md present with upgrade/backup/rollback/removal sections
- installer_scripts: scripts/install.sh, scripts/uninstall.sh, scripts/state-backup.sh present
- installer_tests: test/installer/test_installer.py: 60+ test_ functions covering upgrade, rollback, backup/restore, interrupted install, major-version mismatch, purge categories, user-data preservation
- current_task_state: In Validation (auditor is a scheduler-selected pre-archive review of prior Merged terminal)
---
author: oompah
created: 2026-08-01 21:27
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 32, Tool calls: 25
- Tokens: 29 in / 5.0K out [5.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 5m 43s
- Log: EXOCOMP-46__20260801T212140Z.jsonl
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-45
type: chore
status: Archived
priority: 2
title: Write installation, PKI, policy, and operations guides
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-17
- EXOCOMP-28
- EXOCOMP-115
labels: []
assignee: null
created_at: '2026-07-23T19:12:04.573016Z'
updated_at: '2026-08-01T21:28:59.958177Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-ebdd3e924562: '2026-08-01T21:28:57.337537+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-45
    target_state: Archived
    evidence_fingerprint: d9d9656d8a8c6458afc468beb3f2dad49f131bdad32512711c0c133e7f78d3c3
    audit_ids:
    - audit-0a86ff1cb892
    kind: result
    applied: true
    retired_at: '2026-08-01T21:28:57.337549+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-45
    audit_id: audit-0a86ff1cb892
    attempt_id: attempt-ebdd3e924562
    target_state: Archived
    evidence_fingerprint: d9d9656d8a8c6458afc468beb3f2dad49f131bdad32512711c0c133e7f78d3c3
    status: Archived
    audit_ids:
    - audit-0a86ff1cb892
    applied: false
    created_at: '2026-08-01T21:28:57.337565+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-0a86ff1cb892
    project_id: proj-c260b117
    task_id: EXOCOMP-45
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: d9d9656d8a8c6458afc468beb3f2dad49f131bdad32512711c0c133e7f78d3c3
    attempts:
    - version: 1
      attempt_id: attempt-ebdd3e924562
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: d9d9656d8a8c6458afc468beb3f2dad49f131bdad32512711c0c133e7f78d3c3
      created_at: '2026-08-01T21:21:29.222272+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T21:21:29.222272+00:00'
      branch_key: EXOCOMP-45
      verdict: pass
      completed_at: '2026-08-01T21:28:57.337353+00:00'
      ended_at: '2026-08-01T21:28:57.337353+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T21:19:17.205724+00:00'
    updated_at: '2026-08-01T21:28:57.337353+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-ebdd3e924562
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: d9d9656d8a8c6458afc468beb3f2dad49f131bdad32512711c0c133e7f78d3c3
    created_at: '2026-08-01T21:21:29.222272+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T21:21:29.222272+00:00'
    branch_key: EXOCOMP-45
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Write installation, PKI, policy, and operations guides.

Implementation
Document supported hosts, online/offline install, coordinator initialization, offline-root handling, fingerprint distribution, enrollment, renewal/revocation/rotation, inventory, diagnostics, model sizing, service allow-lists, sudoers, approvals, data classification, bounded system cleanup, and audit retention in docs/.

Testing
Execute every command block against release fixtures; run Markdown/link checks; have scenarios cover first node, renewal, approval, cleanup boundaries, and troubleshooting unsafe permissions.

Acceptance Criteria
- [ ] Commands match shipped artifacts and pass fixture validation.
- [ ] Guides clearly state user data is never deleted and unknown data is protected.
- [ ] PKI and approval procedures include failure/recovery paths.
- [ ] All links and documentation checks pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 18:31
---
Action required: use recovery task EXOCOMP-115 to implement and verify this task's previously undelivered scope on main. Do not mark this task Merged again until EXOCOMP-115 lands and the original acceptance criteria are confirmed against main.
---
author: oompah
created: 2026-07-25 18:31
---
Moved to Needs Human from the dashboard/API. Human action required: inspect EXOCOMP-45 (Write installation, PKI, policy, and operations guides), add the specific decision, missing information, or manual fix needed, then move the task back to Open when it is ready for agents again.
---
author: oompah
created: 2026-07-25 19:59
---
The parent epic EXOCOMP-6 merged from epic-EXOCOMP-6, but this task was Needs Human with work branch unset. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
author: oompah
created: 2026-07-25 21:10
---
Recovered delivery verified on origin/main at merge commit 2085e44152f03ffd41f35cbfeee89a0da53b8bce (PR #14). Evidence: installation, PKI, policy, and operator guides are integrated by 516faf81e5f506f9cc7d1ac24a98499e73dbfea0. The full recovery quality gates passed.
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
created: 2026-08-01 21:28
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- main_head: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
- worktree_diff_vs_main: empty
- recovery_merge_commit: 2085e44152f03ffd41f35cbfeee89a0da53b8bce (PR #14 EXOCOMP-115)
- recovery_content_commit: 516faf81e5f506f9cc7d1ac24a98499e73dbfea0
- operator_docs_test_result: 7 passed in 0.06s (tests/test_operator_docs.py)
- docs_present: docs/installation.md, docs/pki-operations.md, docs/policy-operations.md, docs/lifecycle.md, docs/coordinator-restart-recovery.md, docs/clean-host-qualification.md
- user_data_guard: policy-operations.md states 'User data is never an eligible deletion target' and 'Unknown paths and caller-provided paths are protected as user data'
- pki_failure_recovery: pki-operations.md documents backup/restore, revocation, rotation, expired-cert re-enrollment, and refuses manual PKI edits when integration is absent
---
<!-- COMMENTS:END -->

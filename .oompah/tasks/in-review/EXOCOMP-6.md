---
id: EXOCOMP-6
type: epic
status: In Review
priority: 1
title: 'M6: Packaging, documentation, and open-source release'
parent: null
children:
- EXOCOMP-41
- EXOCOMP-42
- EXOCOMP-43
- EXOCOMP-44
- EXOCOMP-45
- EXOCOMP-46
- EXOCOMP-47
- EXOCOMP-82
blocked_by: []
labels:
- epic:rebasing
assignee: null
created_at: '2026-07-23T19:08:12.347323Z'
updated_at: '2026-08-02T05:14:55.019767Z'
work_branch: epic-EXOCOMP-6
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/6
review_number: '6'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/6
oompah.review_number: '6'
oompah.work_branch: epic-EXOCOMP-6
oompah.target_branch: main
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-8935d6539e98: '2026-08-02T05:11:20.013843+00:00'
    infrastructure-exhausted-audit-69383d5fc681-3: '2026-08-02T05:13:58.213736+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-6
    target_state: Archived
    evidence_fingerprint: 4da355f41d606c5c4577b8fd193ee6bbcc31c2b5844bb62da06466a05d77c740
    audit_ids:
    - audit-03a8072f482f
    kind: result
    applied: true
    retired_at: '2026-08-02T05:11:20.013854+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-6
    target_state: Done
    evidence_fingerprint: b05cc655e5fcd63c10affb9f1d80b91268486819509f0631ef3d402d449ab3d4
    audit_ids:
    - audit-69383d5fc681
    kind: result
    applied: true
    retired_at: '2026-08-02T05:13:58.213754+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-6
    audit_id: audit-03a8072f482f
    attempt_id: attempt-8935d6539e98
    target_state: Archived
    evidence_fingerprint: 4da355f41d606c5c4577b8fd193ee6bbcc31c2b5844bb62da06466a05d77c740
    status: In Validation
    audit_ids:
    - audit-03a8072f482f
    applied: true
    created_at: '2026-08-02T05:11:20.013869+00:00'
    applied_at: '2026-08-02T05:11:23.050731+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-6
    audit_id: audit-69383d5fc681
    attempt_id: infrastructure-exhausted-audit-69383d5fc681-3
    target_state: Done
    evidence_fingerprint: b05cc655e5fcd63c10affb9f1d80b91268486819509f0631ef3d402d449ab3d4
    status: Needs Human
    audit_ids:
    - audit-69383d5fc681
    applied: true
    created_at: '2026-08-02T05:13:58.213773+00:00'
    applied_at: '2026-08-02T05:14:00.531699+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-03a8072f482f
    project_id: proj-c260b117
    task_id: EXOCOMP-6
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 4da355f41d606c5c4577b8fd193ee6bbcc31c2b5844bb62da06466a05d77c740
    attempts:
    - version: 1
      attempt_id: attempt-8935d6539e98
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 4da355f41d606c5c4577b8fd193ee6bbcc31c2b5844bb62da06466a05d77c740
      created_at: '2026-08-02T05:09:53.582945+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-02T05:09:53.582945+00:00'
      branch_key: epic-EXOCOMP-6
      verdict: pass
      completed_at: '2026-08-02T05:11:20.013667+00:00'
      ended_at: '2026-08-02T05:11:20.013667+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-02T04:59:19.429993+00:00'
    updated_at: '2026-08-02T05:11:20.013667+00:00'
  - version: 1
    audit_id: audit-69383d5fc681
    project_id: proj-c260b117
    task_id: EXOCOMP-6
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b05cc655e5fcd63c10affb9f1d80b91268486819509f0631ef3d402d449ab3d4
    attempts:
    - version: 1
      attempt_id: attempt-9cc742341961
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: b05cc655e5fcd63c10affb9f1d80b91268486819509f0631ef3d402d449ab3d4
      created_at: '2026-08-02T05:11:40.825777+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-02T05:11:40.825777+00:00'
      branch_key: epic-EXOCOMP-6
      failure_classification: infrastructure_error
      ended_at: '2026-08-02T05:11:45.880536+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-6 (tried: origin/epic-EXOCOMP-6, origin/EXOCOMP-6)'
      next_retry_at: '2026-08-02T05:11:55.880506+00:00'
    - version: 1
      attempt_id: attempt-674a95db07e3
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: b05cc655e5fcd63c10affb9f1d80b91268486819509f0631ef3d402d449ab3d4
      created_at: '2026-08-02T05:12:09.333279+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-08-02T05:12:09.333279+00:00'
      branch_key: epic-EXOCOMP-6
      candidate_rotation_count: 1
      failure_classification: infrastructure_error
      ended_at: '2026-08-02T05:12:12.621829+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-6 (tried: origin/epic-EXOCOMP-6, origin/EXOCOMP-6)'
      next_retry_at: '2026-08-02T05:12:32.621796+00:00'
    - version: 1
      attempt_id: attempt-0be838c24b9a
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: b05cc655e5fcd63c10affb9f1d80b91268486819509f0631ef3d402d449ab3d4
      created_at: '2026-08-02T05:12:55.233381+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-08-02T05:12:55.233381+00:00'
      branch_key: epic-EXOCOMP-6
      candidate_rotation_count: 2
      failure_classification: infrastructure_error
      ended_at: '2026-08-02T05:12:59.248924+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-6 (tried: origin/epic-EXOCOMP-6, origin/EXOCOMP-6)'
      next_retry_at: '2026-08-02T05:13:39.248896+00:00'
    - version: 1
      attempt_id: infrastructure-exhausted-audit-69383d5fc681-3
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: b05cc655e5fcd63c10affb9f1d80b91268486819509f0631ef3d402d449ab3d4
      verdict: needs_human
      failure_classification: infrastructure_error
      created_at: '2026-08-02T05:13:58.213624+00:00'
      completed_at: '2026-08-02T05:13:58.213624+00:00'
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Validation
    created_at: '2026-08-02T04:59:37.597467+00:00'
    updated_at: '2026-08-02T05:13:58.213624+00:00'
  - version: 1
    audit_id: audit-659620b2b5f0
    project_id: proj-c260b117
    task_id: EXOCOMP-6
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b05cc655e5fcd63c10affb9f1d80b91268486819509f0631ef3d402d449ab3d4
    attempts: []
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Validation
    created_at: '2026-08-02T04:59:37.597467+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-8935d6539e98
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 4da355f41d606c5c4577b8fd193ee6bbcc31c2b5844bb62da06466a05d77c740
    created_at: '2026-08-02T05:09:53.582945+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-02T05:09:53.582945+00:00'
    branch_key: epic-EXOCOMP-6
  - version: 1
    attempt_id: attempt-9cc742341961
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b05cc655e5fcd63c10affb9f1d80b91268486819509f0631ef3d402d449ab3d4
    created_at: '2026-08-02T05:11:40.825777+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-02T05:11:40.825777+00:00'
    branch_key: epic-EXOCOMP-6
    failure_classification: infrastructure_error
    ended_at: '2026-08-02T05:11:45.880536+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-6 (tried: origin/epic-EXOCOMP-6, origin/EXOCOMP-6)'
    next_retry_at: '2026-08-02T05:11:55.880506+00:00'
  - version: 1
    attempt_id: attempt-674a95db07e3
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b05cc655e5fcd63c10affb9f1d80b91268486819509f0631ef3d402d449ab3d4
    created_at: '2026-08-02T05:12:09.333279+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-08-02T05:12:09.333279+00:00'
    branch_key: epic-EXOCOMP-6
    candidate_rotation_count: 1
    failure_classification: infrastructure_error
    ended_at: '2026-08-02T05:12:12.621829+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-6 (tried: origin/epic-EXOCOMP-6, origin/EXOCOMP-6)'
    next_retry_at: '2026-08-02T05:12:32.621796+00:00'
  - version: 1
    attempt_id: attempt-0be838c24b9a
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b05cc655e5fcd63c10affb9f1d80b91268486819509f0631ef3d402d449ab3d4
    created_at: '2026-08-02T05:12:55.233381+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-08-02T05:12:55.233381+00:00'
    branch_key: epic-EXOCOMP-6
    candidate_rotation_count: 2
    failure_classification: infrastructure_error
    ended_at: '2026-08-02T05:12:59.248924+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-6 (tried: origin/epic-EXOCOMP-6, origin/EXOCOMP-6)'
    next_retry_at: '2026-08-02T05:13:39.248896+00:00'
oompah.task_costs:
  total_input_tokens: 21
  total_output_tokens: 3215
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 21
      output_tokens: 3215
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 21
    output_tokens: 3215
    cost_usd: 0.0
    recorded_at: '2026-08-02T05:11:32.194568+00:00'
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Publish qualified Apache-2.0 Exocomp release artifacts and operator documentation for Linux amd64 and arm64.

Scope
Coordinate licensing and governance, reproducible release builds, hardened installers, complete offline bundles, operator and lifecycle documentation, and clean-host qualification. Artifacts include ERTS, llama.cpp, verified model, checksums, SBOM, and provenance.

Testing
Artifact, clean-host, offline installation, upgrade, rollback, uninstall, hardening, documentation-command, and release qualification tests must pass.

Acceptance Criteria
- [ ] Every child task is complete and focused tests pass.
- [ ] Every M6-CRIT-* criterion in the linked plan has recorded evidence.
- [ ] Clean-host qualification passes on amd64 and arm64.
- [ ] Published artifacts are self-contained, verifiable, and preserve protected state.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 23:20
---
YOLO: merged PR #6.
---
author: oompah
created: 2026-08-02 04:59
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-08-02 05:09
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-02 05:09
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-02 05:11
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- children_archived: EXOCOMP-82, EXOCOMP-41, EXOCOMP-42, EXOCOMP-43, EXOCOMP-44, EXOCOMP-45, EXOCOMP-46, EXOCOMP-47 all Archived
- crit_items_checked: M6-CRIT-1..9 all [x] in plans/milestone-6-release.md lines 194-210
- evidence_merge: PR #17 merge 01c14b89 (2026-07-25) added 11348 lines across docs/release-evidence/v0.1.0-rc.2/
- dual_arch_evidence: docs/release-evidence/v0.1.0-rc.2/raw/{amd64,arm64}/ each contain live/, artifacts/, repo-gates/, qualification results
- signed_artifacts_present: bundle.minisig, evidence-index.sha256.sig, manifest.sha256, provenance.json, sbom.spdx.json under raw/*/live/exocomp-complete-.../
- aging: Merged 2026-07-23; audit date 2026-08-02 (10 days)
---
author: oompah
created: 2026-08-02 05:11
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 20, Tool calls: 15
- Tokens: 21 in / 3.2K out [3.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 38s
- Log: EXOCOMP-6__20260802T050958Z.jsonl
---
author: oompah
created: 2026-08-02 05:11
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-02 05:11
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-08-02 05:11
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-6 (tried: origin/epic-EXOCOMP-6, origin/EXOCOMP-6). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-02 05:12
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-08-02 05:12
---
Run #2 [attempt=2, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 2s
---
author: oompah
created: 2026-08-02 05:12
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-6 (tried: origin/epic-EXOCOMP-6, origin/EXOCOMP-6). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-02 05:12
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-08-02 05:12
---
Run #3 [attempt=3, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 2s
---
author: oompah
created: 2026-08-02 05:13
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-6 (tried: origin/epic-EXOCOMP-6, origin/EXOCOMP-6). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-02 05:13
---
Needs Human — Done audit requires operator input.

Independent auditor launches exhausted their retry budget because the audit workspace or transport failed before review began. Restore the audit infrastructure, then have a project owner rearm this terminal audit; do not reopen implementation work.
---
<!-- COMMENTS:END -->

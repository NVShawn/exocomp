---
id: EXOCOMP-6
type: epic
status: In Validation
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
updated_at: '2026-08-02T05:09:57.952125Z'
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
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-03a8072f482f
    project_id: proj-c260b117
    task_id: EXOCOMP-6
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 4da355f41d606c5c4577b8fd193ee6bbcc31c2b5844bb62da06466a05d77c740
    attempts:
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
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-02T04:59:19.429993+00:00'
    updated_at: '2026-08-02T05:09:53.582945+00:00'
  - version: 1
    audit_id: audit-69383d5fc681
    project_id: proj-c260b117
    task_id: EXOCOMP-6
    target_state: Done
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
<!-- COMMENTS:END -->

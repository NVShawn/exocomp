---
id: EXOCOMP-6
type: epic
status: Merged
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
updated_at: '2026-07-23T23:31:17.388905Z'
work_branch: epic-EXOCOMP-6
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/6
review_number: '6'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/6
oompah.review_number: '6'
oompah.work_branch: epic-EXOCOMP-6
oompah.target_branch: main
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
<!-- COMMENTS:END -->

---
id: EXOCOMP-44
type: chore
status: Open
priority: 2
title: Assemble signed offline bundles, SBOMs, and provenance
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-40
- EXOCOMP-42
labels: []
assignee: null
created_at: '2026-07-23T19:12:03.621738Z'
updated_at: '2026-07-23T19:17:30.118661Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Assemble signed offline bundles, SBOMs, and provenance.

Implementation
Bundle architecture-matched OTP releases, llama-server, verified Qwen GGUF model, systemd/install assets, licenses, manifests, SHA-256 checksums, signatures, SBOM, and provenance; also define optional runtime-only bundle; pin every nested artifact.

Testing
Build and verify with network disabled; tamper with nested files to test failure; validate signatures/SBOM/provenance references; install on both target architectures.

Acceptance Criteria
- [ ] Complete bundles install fully offline.
- [ ] Every nested file is covered by manifest/checksum and relevant license.
- [ ] Tampering fails before installation.
- [ ] SBOM and provenance identify source, builder, toolchain, and dependencies.
- [ ] Both architectures pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-44
type: chore
status: In Progress
priority: 2
title: Assemble signed offline bundles, SBOMs, and provenance
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-40
- EXOCOMP-42
labels:
- needs:devops
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:12:03.621738Z'
updated_at: '2026-07-23T23:32:41.046251Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 3710aa5e-b66f-435b-9f78-bfb331f7546c
oompah.work_branch: epic-EXOCOMP-6
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 23:31
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 23:31
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 23:31
---
Understanding: This run is duplicate screening only. I will compare EXOCOMP-44's offline-bundle/SBOM/provenance scope against existing task records and Milestone 6 planning, inspect plausible candidates in full, then archive only if the same underlying deliverable is already tracked; otherwise I will hand off for implementation.
---
author: oompah
created: 2026-07-23 23:32
---
Discovery: No duplicate is evident. The closest tasks have explicit non-overlapping boundaries: EXOCOMP-41 supplies license/governance inputs; EXOCOMP-42/66 build deterministic OTP archives and reserve signing, SBOMs, and bundle assembly for EXOCOMP-44; EXOCOMP-43 supplies installer/systemd assets; EXOCOMP-68 qualifies OTP archives only; EXOCOMP-47 is downstream full-release clean-host qualification. Milestone 6 independently assigns complete/runtime-only bundle composition and supply-chain metadata to M6-CRIT-3 and M6-CRIT-8.
---
author: oompah
created: 2026-07-23 23:32
---
Focus handoff: duplicate_detector

1. Outcome: Duplicate screening found no duplicate; EXOCOMP-44 is the unique M6 task for signed complete/runtime-only offline bundles, nested integrity coverage, SBOMs, and provenance.
2. Evidence/decisions: Searched the tracker state for offline bundle, SBOM, provenance, llama-server, GGUF, and runtime-only terms; reviewed EXOCOMP-6, 41, 42, 43, 47, 66, and 68 in full. plans/milestone-6-release.md sections Artifact Architecture and Supply Chain map this scope to M6-CRIT-3 and M6-CRIT-8. EXOCOMP-66 explicitly says signing, SBOM generation, and offline-bundle assembly remain in EXOCOMP-44.
3. Remaining work/risks: Assemble amd64/arm64 complete bundles and optional runtime-only variants from the pinned OTP, llama-server, verified model, installer/systemd, notice/license, and manifest inputs; cover every nested file; verify before mutation; add signatures, SBOM, provenance, network-disabled and tamper tests. Confirm the actual merged availability/pins of all EXOCOMP-40/42/43 inputs before building.
4. Recommended next focus: devops, for reproducible supply-chain packaging/signing and offline architecture-matrix verification. No repository files were changed and implementation/test gates are not applicable to this screening-only run.
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-68
type: task
status: In Progress
priority: 2
title: Qualify multi-architecture OTP releases and reproducibility
parent: EXOCOMP-42
children: []
blocked_by:
- EXOCOMP-66
- EXOCOMP-67
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:06:25.715104Z'
updated_at: '2026-07-23T21:48:12.915284Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 71783fe5-6e1c-461e-be6b-f544d83aba7f
oompah.work_branch: epic-EXOCOMP-6
---
## Summary

Add the release-build test matrix for node and coordinator on linux-amd64 and linux-arm64. Build each architecture twice from identical source and compare archive digests where deterministic plus all declared reproducible manifest fields. Extract and start every release in a clean target container that has no Elixir, Erlang, compiler, or package manager tooling, and verify bundled ERTS is used. Add negative tests for attempting to run the wrong architecture and for a missing/corrupted required runtime dependency, asserting actionable diagnostics. Expose a non-interactive focused Make target suitable for CI and document native versus emulated execution requirements. Acceptance: the complete architecture/product matrix and both diagnostic cases pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:46
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:46
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:48
---
Duplicate screening: No duplicate found. EXOCOMP-68 is a unique child task deliberately created by the EXOCOMP-42 epic planner (see EXOCOMP-42 comment #27).

Key distinctions from the closest candidates reviewed:
- **EXOCOMP-65** (Done): Pinned multi-arch builder definitions — distinct; covers Docker image selection with architecture-select Make targets and capability checks, not the release-startup test matrix or reproducibility verification.
- **EXOCOMP-66** (Done): Deterministic archive packaging and identity manifests — distinct; builds archives and emits build-identity JSON, but does not run releases in clean containers or compare double-build digests.
- **EXOCOMP-67** (Done): ELF/NIF runtime dependency inspection and glibc baseline documentation — distinct; inspects ELF binaries inside releases and fails the build on undeclared deps, but does not test clean-container startup, wrong-arch negative cases, or double-build archive-digest comparison.
- **EXOCOMP-44** (Open): Signed offline bundles, SBOMs, and provenance — distinct; covers bundle assembly, signing, SBOM generation, and offline install, not the OTP release startup test matrix.
- **EXOCOMP-47** (Open): Full M6 clean-host qualification — distinct; is a final comprehensive release qualification covering the entire M6 release (PKI init, node enrollment, M4 recovery, M5 gates, upgrade/rollback). EXOCOMP-68 is the narrower, targeted test matrix: double-build digest comparison, clean-container ERTS startup, and specific diagnostic cases (wrong-arch, missing/corrupted runtime dep).

Evidence: EXOCOMP-42 comment #27 explicitly lists EXOCOMP-68 as the fourth and final child covering 'clean-target, wrong-architecture, missing-runtime, and double-build reproducibility qualification'. All 70+ tasks in the project have been reviewed via prior screening passes (see EXOCOMP-42 comment #6, EXOCOMP-67 comment #3).

EXOCOMP-68 is unique and should proceed to implementation.
---
<!-- COMMENTS:END -->

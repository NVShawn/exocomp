---
id: EXOCOMP-67
type: task
status: In Progress
priority: 2
title: Inspect and document OTP release runtime dependencies
parent: EXOCOMP-42
children: []
blocked_by:
- EXOCOMP-66
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:06:24.819914Z'
updated_at: '2026-07-23T21:34:21.941391Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: fa759aac-8dc3-482b-9a16-f0c11b465352
oompah.work_branch: epic-EXOCOMP-6
---
## Summary

For every node/coordinator amd64/arm64 release produced by EXOCOMP-42, inspect ELF interpreters, shared-library dependencies, NIFs, and bundled ERTS executables using target-architecture tooling in the pinned builders. Fail the build on unresolved or undeclared dynamic dependencies. Define and document the supported glibc Linux runtime baseline and the exact host libraries expected outside each archive, with inspection commands suitable for maintainers and automation. Add fixtures/tests covering a valid release and an injected unresolved or undeclared dependency. Acceptance: dependency reports are attached to artifacts or manifests, docs identify the runtime contract, and focused release/documentation gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:32
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:32
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:34
---
Duplicate screening: No duplicate found. EXOCOMP-67 is a unique child task deliberately created by the EXOCOMP-42 epic planner (see EXOCOMP-42 comment #27).

Key distinctions from closest candidates:
- **EXOCOMP-65** (Done): Pinned multi-arch builder definitions — distinct; covers Docker image selection and arch-select Make targets, not ELF/NIF inspection.
- **EXOCOMP-66** (Done): Deterministic archive packaging and identity manifests — distinct; covers archive normalization and build-identity JSON, not runtime dependency reporting.
- **EXOCOMP-68** (Open): Clean-host qualification, wrong-arch diagnostics, double-build reproducibility — distinct; consumes EXOCOMP-67 artifacts to verify the release starts, but does not produce the dependency inspection tooling or glibc baseline documentation.
- **EXOCOMP-44** (Open): Signed offline bundles, SBOMs, provenance — distinct; covers signing/SBOM generation after artifacts exist, not ELF/NIF inspection.
- **EXOCOMP-42** (parent epic): Mentions 'inspect runtime dynamic dependencies' at the epic level, but EXOCOMP-67 is exactly the child created to fulfill that acceptance criterion.

No other task in the project (reviewed all 70+ tasks across all states) covers ELF interpreter inspection, shared-library dependency enumeration, NIF detection, glibc baseline documentation, build-time failure on unresolved/undeclared dependencies, or the corresponding test fixtures.

EXOCOMP-67 is unique and should proceed to implementation.
---
<!-- COMMENTS:END -->

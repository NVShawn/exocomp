---
id: EXOCOMP-42
type: feature
status: In Progress
priority: 2
title: Build reproducible amd64 and arm64 OTP release artifacts
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T19:12:01.640063Z'
updated_at: '2026-07-23T20:43:20.941912Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: f677637d-e8cb-4fb6-ac3f-a3d3d5397798
oompah.work_branch: epic-EXOCOMP-6
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Build reproducible amd64 and arm64 OTP release artifacts.

Implementation
Create pinned target builders for node/coordinator releases with ERTS; produce versioned archives and manifests; inspect runtime dynamic dependencies; record source/toolchain/dependency identity; ensure build commands are non-interactive.

Testing
Build twice for each architecture and compare reproducible fields; start both releases in clean target containers without Elixir/Erlang; test wrong-architecture and missing-runtime diagnostics.

Acceptance Criteria
- [ ] Both architectures produce node/coordinator archives with ERTS.
- [ ] Clean targets start without development tooling.
- [ ] Runtime dependencies are documented and inspected.
- [ ] Artifacts carry exact source/build identity.
- [ ] Release-build tests pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:26
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:26
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:41
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:41
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:41
---
Understanding: Investigating EXOCOMP-42 for duplicates. The issue requests building reproducible amd64 and arm64 OTP release artifacts with ERTS-bundled archives, manifests, runtime dependency inspection, and build identity recording. Searching existing tasks for overlap.
---
author: oompah
created: 2026-07-23 20:43
---
Discovery: Reviewed all 47+ tasks in the project. No duplicate of EXOCOMP-42 found.

Closest candidates reviewed:
- **EXOCOMP-7** (Done): "Scaffold the Elixir umbrella and quality gates" — Foundational umbrella setup with ERTS-inclusive releases, but scoped to creating the Mix project structure and initial Make targets, not to building architecture-specific release archives, manifests, runtime dependency inspection, or build identity recording. The EXOCOMP-7 duplicate investigator already noted EXOCOMP-42 as distinct (comment #5 on EXOCOMP-7).
- **EXOCOMP-35** (Backlog): "Build the reproducible benchmark harness" — Shares the keyword 'reproducible' but is a M5 performance benchmark infrastructure task under parent EXOCOMP-5, unrelated to release artifact production.
- **EXOCOMP-44** (Open): "Assemble signed offline bundles, SBOMs, and provenance" — A downstream M6 sibling that is explicitly *blocked by* EXOCOMP-42; covers bundle assembly after artifacts exist, not artifact building.
- **EXOCOMP-41**, **EXOCOMP-43**, **EXOCOMP-45**, **EXOCOMP-46**, **EXOCOMP-47** — All M6 siblings with distinct scopes (licensing, installers, documentation, qualification).

EXOCOMP-42 is a unique task with its own well-defined scope: pinned amd64/arm64 builder containers, versioned OTP archives, build manifests, runtime dependency inspection, and source/toolchain identity recording.
---
<!-- COMMENTS:END -->

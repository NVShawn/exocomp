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
updated_at: '2026-07-23T20:26:21.108024Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 1a207481-0c7f-47ba-a7fe-671f5e7cc70b
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
<!-- COMMENTS:END -->

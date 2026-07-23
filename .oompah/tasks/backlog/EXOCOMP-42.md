---
id: EXOCOMP-42
type: feature
status: Backlog
priority: 2
title: Build reproducible amd64 and arm64 OTP release artifacts
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T19:12:01.640063Z'
updated_at: '2026-07-23T19:13:48.215361Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


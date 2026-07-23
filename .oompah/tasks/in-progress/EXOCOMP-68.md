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
labels: []
assignee: null
created_at: '2026-07-23T21:06:25.715104Z'
updated_at: '2026-07-23T21:46:38.278206Z'
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
<!-- COMMENTS:END -->

---
id: EXOCOMP-65
type: feature
status: In Progress
priority: 2
title: Pin multi-architecture OTP release builders
parent: EXOCOMP-42
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T21:06:03.498156Z'
updated_at: '2026-07-23T21:11:33.994758Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7e4dffa9-69cb-4476-b727-5d3b1b96d29b
oompah.work_branch: epic-EXOCOMP-6
---
## Summary

Create digest-pinned Linux amd64 and arm64 builder definitions for the supported glibc baseline and the Elixir/OTP versions established by EXOCOMP-7. Add non-interactive Make targets/scripts that select an explicit target architecture, build from a clean checkout, and fail clearly when the host lacks the required container/emulation capability. Keep builder inputs immutable and record the exact builder image digest/toolchain versions for later manifests. Add focused tests or static validation for pinning, supported-architecture mapping, and non-interactive invocation. Acceptance: both target builders can produce the node and coordinator Mix releases with ERTS enabled; no floating image/package/toolchain inputs remain; relevant Make quality gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:11
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:11
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

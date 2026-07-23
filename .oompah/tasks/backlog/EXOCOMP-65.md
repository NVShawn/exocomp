---
id: EXOCOMP-65
type: feature
status: Backlog
priority: 2
title: Pin multi-architecture OTP release builders
parent: EXOCOMP-42
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T21:06:03.498156Z'
updated_at: '2026-07-23T21:06:35.034557Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Create digest-pinned Linux amd64 and arm64 builder definitions for the supported glibc baseline and the Elixir/OTP versions established by EXOCOMP-7. Add non-interactive Make targets/scripts that select an explicit target architecture, build from a clean checkout, and fail clearly when the host lacks the required container/emulation capability. Keep builder inputs immutable and record the exact builder image digest/toolchain versions for later manifests. Add focused tests or static validation for pinning, supported-architecture mapping, and non-interactive invocation. Acceptance: both target builders can produce the node and coordinator Mix releases with ERTS enabled; no floating image/package/toolchain inputs remain; relevant Make quality gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


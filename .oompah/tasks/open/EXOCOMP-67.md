---
id: EXOCOMP-67
type: task
status: Open
priority: 2
title: Inspect and document OTP release runtime dependencies
parent: EXOCOMP-42
children: []
blocked_by:
- EXOCOMP-66
labels: []
assignee: null
created_at: '2026-07-23T21:06:24.819914Z'
updated_at: '2026-07-23T21:10:28.177576Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

For every node/coordinator amd64/arm64 release produced by EXOCOMP-42, inspect ELF interpreters, shared-library dependencies, NIFs, and bundled ERTS executables using target-architecture tooling in the pinned builders. Fail the build on unresolved or undeclared dynamic dependencies. Define and document the supported glibc Linux runtime baseline and the exact host libraries expected outside each archive, with inspection commands suitable for maintainers and automation. Add fixtures/tests covering a valid release and an injected unresolved or undeclared dependency. Acceptance: dependency reports are attached to artifacts or manifests, docs identify the runtime contract, and focused release/documentation gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


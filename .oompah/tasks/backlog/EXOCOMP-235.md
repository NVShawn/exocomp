---
id: EXOCOMP-235
type: task
status: Backlog
priority: null
title: Add cross-layer observe/manage integration coverage
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:28:13.272722Z'
updated_at: '2026-08-03T14:29:49.336416Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable:
Add deterministic integration coverage for policy authoring, distribution, resolution, and enforcement across Mission Control, the coordinator, and a node.

Acceptance criteria:
- Cover the implicit observe default and explicit settings at global, cluster, cluster/service, node, and node/service scopes.
- Cover the same-rank node versus cluster/service disagreement rule, where observe wins.
- Show that diagnostics, status reporting, chat, and remediation proposals remain available in observe mode.
- Show that approving a proposal in observe mode cannot execute a mutation.
- Show that manage mode can execute one registered typed action when every enforcement layer has valid policy and authorization.
- Use stable fixtures and assertions that identify which scope selected the effective mode.

Tests:
- Add focused integration tests for the scenarios above.
- Run the focused Makefile target plus make test, make fmt-check, and make lint.

Out of scope:
- Installer privilege-boundary tests and physical dual-architecture qualification.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


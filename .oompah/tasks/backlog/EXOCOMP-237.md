---
id: EXOCOMP-237
type: task
status: Backlog
priority: null
title: Qualify upgrade, downgrade, and mixed-version behavior
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:28:18.903629Z'
updated_at: '2026-08-03T14:29:53.532182Z'
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
Add and execute supported-version scenarios that prove upgrades enter observe safely and that unsupported mixed-version combinations cannot manage nodes.

Acceptance criteria:
- Upgrade a previously managed installation and verify no policy is synthesized that enables manage mode.
- Verify a node without a valid current policy lease remains observe after restart and reconnect.
- Cover supported mixed-version coordinator and node combinations and verify management is enabled only when every required enforcement layer is present.
- Document and test downgrade refusal or safe fallback behavior for versions that cannot preserve the enforcement boundary.
- Demonstrate a rollback procedure that leaves the cluster in observe mode.

Tests:
- Add automated upgrade and mixed-version scenarios using repository fixtures or VM harnesses.
- Run the focused Makefile targets plus make test, make fmt-check, and make lint.

Out of scope:
- General release qualification unrelated to hierarchical management policy.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


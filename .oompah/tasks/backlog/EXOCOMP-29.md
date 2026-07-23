---
id: EXOCOMP-29
type: feature
status: Backlog
priority: 1
title: Create the isolated systemd recovery fixture
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T19:10:45.456680Z'
updated_at: '2026-07-23T19:14:37.819218Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Create the isolated systemd recovery fixture.

Implementation
Add an intentionally crashable fixture systemd service with an application health endpoint, harmless workload marker, active/failed/degraded/flapping/restart-failure controls, disposable installer, and cleanup limited to fixture resources; document VM or privileged-container requirements.

Testing
Test install/start/stop/crash/degrade/flap/restart-failure/cleanup, health versus systemd state, repeated fixture setup, and proof that non-fixture services/files are untouched.

Acceptance Criteria
- [ ] Every required service state is reproducible.
- [ ] Health can disagree with systemd active state.
- [ ] Fixture setup and cleanup are idempotent and scoped.
- [ ] Focused fixture tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


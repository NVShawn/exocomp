---
id: EXOCOMP-190
type: task
status: Open
priority: 1
title: Implement enabled long-running systemd service discovery
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-187
labels: []
assignee: null
created_at: '2026-07-30T21:37:00.068929Z'
updated_at: '2026-08-01T11:50:12.734509Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, automatic service path.

Deliverable: Add the read-only exocomp.service.inventory node skill using fixed systemctl argv and bounded output.

Acceptance criteria:
- Return enabled and enabled-runtime service units with Type, RemainAfterExit, condition result, load state, active state, and substate.
- Exclude completed oneshots, static, indirect, disabled, masked, generated units, and exocomp-node.service from the expected-running set.
- Mark a failed systemd condition as not_applicable.
- Validate output size and timeout each subprocess without invoking a shell.

Tests: Use injected command fixtures for every included and excluded state, timeout, malformed output, and output truncation; run make test.

Out of scope: Scheduling discovery, health incidents, application probes, and restart behavior.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


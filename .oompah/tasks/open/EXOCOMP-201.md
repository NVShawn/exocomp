---
id: EXOCOMP-201
type: task
status: Open
priority: 1
title: Implement the restricted profile-action helper
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-195
labels: []
assignee: null
created_at: '2026-07-30T21:38:30.593722Z'
updated_at: '2026-08-01T11:50:37.047597Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, profile recovery authority.

Deliverable: Add a small compiled privileged helper with a versioned bounded stdin protocol and no command-line arguments.

Acceptance criteria:
- Accept only shipped profile IDs, typed action IDs, and strictly validated target unit names.
- Ceph v1 supports only restart_failed_daemon for recognized Ceph unit forms.
- Recheck that the target unit is loaded and already inactive or failed before executing fixed systemctl argv.
- Reject active units, unknown actions, oversized input, extra fields, malformed encoding, and shell metacharacters.
- Never invoke a shell or accept an arbitrary executable or argument list.

Tests: Add parser and validator unit tests plus negative tests for injection, malformed requests, active units, non-Ceph units, timeout, and subprocess failure; run the focused Make gate added by the task.

Out of scope: Installer integration, coordinator policy, broad Ceph repair, and Mission Control.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-197
type: task
status: Open
priority: 1
title: Collect Ceph health and topology JSON
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-196
labels: []
assignee: null
created_at: '2026-07-30T21:38:19.643459Z'
updated_at: '2026-08-01T11:50:22.895156Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, Ceph profile evidence.

Deliverable: Implement an unprivileged coordinator collector that runs the fixed Ceph CLI with fixed read-only JSON commands.

Acceptance criteria:
- Collect overall health plus monitor, manager, OSD, MDS, and available gateway topology using fixed argv.
- Enforce timeout and output-size limits and never invoke a shell.
- Normalize supported Ceph JSON versions into a versioned internal evidence structure.
- Preserve partial command failures with timestamps and sanitized reasons.
- Never expose keyring contents or command environment values.

Tests: Parse fixture output for HEALTH_OK, HEALTH_WARN, HEALTH_ERR, empty clusters, malformed JSON, partial failures, timeout, and truncation; run make test.

Out of scope: Node matching, health policy, service restart, and arbitrary Ceph commands.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


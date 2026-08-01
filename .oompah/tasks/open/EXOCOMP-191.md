---
id: EXOCOMP-191
type: task
status: Open
priority: 1
title: Implement bounded read-only service observation
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-188
labels: []
assignee: null
created_at: '2026-07-30T21:37:01.048654Z'
updated_at: '2026-08-01T11:50:14.101433Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, manual and reconciled service observation.

Deliverable: Add the exocomp.service.observe node skill for strictly validated coordinator-selected unit names.

Acceptance criteria:
- Query systemd through fixed argv for exact validated .service names.
- Optionally execute only validated loopback HTTP probes supplied by desired state.
- Return systemd and probe evidence with timestamps, partial errors, and collector versions.
- Enforce service-count, response-size, and timeout limits.
- The skill cannot execute, enable, disable, or restart a unit and does not alter the recovery allow-list.

Tests: Cover valid observations, invalid names, non-loopback URLs, mixed partial results, timeout, and bounded responses; run make test.

Out of scope: Desired-state merging, scheduling, remediation, and Ceph-specific health.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


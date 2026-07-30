---
id: EXOCOMP-198
type: task
status: Backlog
priority: 1
title: Discover local traditional and cephadm daemon units
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:38:22.833355Z'
updated_at: '2026-07-30T21:38:22.833355Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Ceph node discovery.

Deliverable: Implement the Ceph branch of exocomp.profile.inspect using fixed systemd queries.

Acceptance criteria:
- Recognize shipped patterns for traditional and cephadm monitor, manager, OSD, MDS, and gateway units.
- Return daemon kind, daemon ID, unit, FSID when available, enablement, load state, active state, and substate.
- A supported node with no Ceph installation reports not_member rather than an error.
- Strict parsing, timeouts, and output bounds prevent arbitrary unit or command injection.

Tests: Use fixtures for traditional units, cephadm units, mixed installations, no installation, malformed names, timeout, and truncated output; run make test.

Out of scope: Coordinator topology matching, cluster health policy, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


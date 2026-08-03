---
id: EXOCOMP-214
type: task
status: Backlog
priority: 1
title: Map systemd and profile targets to canonical service keys
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:24:11.664051Z'
updated_at: '2026-08-03T14:28:58.621849Z'
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

Deliverable: Add the shared canonical service-key mapper used before policy resolution.

Acceptance criteria:
- Exact systemd units map to systemd:<unit> after existing strict unit validation.
- Shipped profiles map daemon instances to stable keys such as ceph:mon, ceph:mgr, and ceph:osd.
- Unknown profiles, malformed units, ambiguous mappings, and missing keys fail to observe with structured reasons.
- Mapping is deterministic across coordinator, node, broker, and serialized fixtures.

Tests: Cover ordinary and templated systemd units, every shipped Ceph role, multiple daemon instances, invalid names, unknown profiles, and fixture round trips; run make test, make fmt-check, and make lint.

Out of scope: Policy precedence, desired-service discovery, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-200
type: task
status: Backlog
priority: 1
title: Reduce Ceph evidence into cluster and daemon health
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-199
labels: []
assignee: null
created_at: '2026-07-30T21:38:25.539449Z'
updated_at: '2026-07-30T21:40:08.102209Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, Ceph cluster health.

Deliverable: Convert fresh Ceph CLI evidence, topology mappings, and node observations into profile, coverage, and daemon health states.

Acceptance criteria:
- HEALTH_OK maps to healthy, HEALTH_WARN to degraded, and HEALTH_ERR to critical.
- Missing credentials, stale evidence, incomplete coverage, and ambiguous topology have distinct reasons.
- Required daemon units are healthy only when their expected systemd state and applicable profile evidence pass.
- Results contain bounded evidence references and deterministic severity.

Tests: Add table-driven tests for health levels, stale and partial evidence, missing daemons, unreachable nodes, unsupported profile versions, and recovery to healthy; run make test.

Out of scope: Mission Control incident records, UI, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


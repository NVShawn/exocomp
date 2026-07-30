---
id: EXOCOMP-203
type: task
status: Backlog
priority: 1
title: Connect failed Ceph daemons to the safe recovery flow
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:38:34.423102Z'
updated_at: '2026-07-30T21:38:34.423102Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Ceph safe daemon restart.

Deliverable: Allow the coordinator to propose the profile action restart_failed_daemon for one already-failed expected Ceph daemon.

Acceptance criteria:
- Require fresh node state, fresh Ceph health/topology evidence, exact node/daemon mapping, and shipped Ceph profile authority.
- Reuse existing task correlation, idempotency, durable audit-before-action, one-attempt, and per-target locking boundaries.
- Automatic-mode discovery alone cannot authorize the action.
- Active or merely degraded daemons, unsupported profiles, stale evidence, and coverage gaps do not execute.
- Invoke only the restricted profile helper action.

Tests: Cover allowed failed daemon, active daemon, stale evidence, mapping change, unsupported node, concurrent requests, replay, and helper rejection; run make test.

Out of scope: Active-daemon restart, failover, maintenance flags, OSD changes, and PG repair.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


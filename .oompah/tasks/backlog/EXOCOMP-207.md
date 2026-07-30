---
id: EXOCOMP-207
type: epic
status: Backlog
priority: 3
title: Ceph typed broad-repair roadmap
parent: null
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-186
labels: []
assignee: null
created_at: '2026-07-30T21:39:02.064482Z'
updated_at: '2026-07-30T21:40:34.522389Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Triggered by: EXOCOMP-186

Source: EXOCOMP-186.

Outcome: Extend the shipped Ceph profile beyond safe failed-daemon restart with separately accepted typed repairs such as manager failover, bounded maintenance flags, OSD lifecycle or reweight operations, and PG repair.

Entry criteria:
- EXOCOMP-186 and all safe-restart qualification work are complete.
- Each proposed action has a reviewed evidence, disruption-budget, approval, rollback, verification, cooldown, idempotency, and audit contract.
- Every action is decomposed into junior-sized schema, policy, executor, verifier, test, and documentation tasks before implementation begins.

Required invariants:
- No arbitrary Ceph command or caller-supplied argv.
- Data-changing operations require explicit operator approval and fresh evidence.
- One action family cannot broaden another action family authority.
- Failures stop and escalate without automatic unsafe fallback.

This roadmap epic is intentionally separate from M7 so broad repair does not block delivery of desired-state monitoring and safe failed-daemon restart.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


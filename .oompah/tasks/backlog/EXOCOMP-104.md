---
id: EXOCOMP-104
type: feature
status: Backlog
priority: 1
title: Recover coordinator live state after volatile restart
parent: EXOCOMP-18
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T04:29:59.527638Z'
updated_at: '2026-07-24T04:29:59.527638Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Implement startup reconstruction without a database: reload inventory/registry state, identify any recoverable downstream diagnostic tasks from bounded durable audit context where possible, and re-query node A2A task state using deterministic idempotency keys. When volatile cluster history is unavailable, return an explicit unavailable/not-found response and allow the caller to safely resubmit the same logical request without duplicate downstream work. Do not claim recovery that cannot be proven. Document volatile restart behavior, idempotent resubmission, limits, and operator-visible degraded states in docs/. Add restart-focused tests for recovered terminal/live node state, loss of coordinator ETS/process state, node-unavailable recovery, and safe resubmission.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


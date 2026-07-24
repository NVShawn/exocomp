---
id: EXOCOMP-104
type: feature
status: In Progress
priority: 1
title: Recover coordinator live state after volatile restart
parent: EXOCOMP-18
children: []
blocked_by:
- EXOCOMP-103
labels: []
assignee: null
created_at: '2026-07-24T04:29:59.527638Z'
updated_at: '2026-07-24T18:01:16.526489Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 0de413a2-94de-44dd-8eec-45e1126f65cf
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Implement startup reconstruction without a database: reload inventory/registry state, identify any recoverable downstream diagnostic tasks from bounded durable audit context where possible, and re-query node A2A task state using deterministic idempotency keys. When volatile cluster history is unavailable, return an explicit unavailable/not-found response and allow the caller to safely resubmit the same logical request without duplicate downstream work. Do not claim recovery that cannot be proven. Document volatile restart behavior, idempotent resubmission, limits, and operator-visible degraded states in docs/. Add restart-focused tests for recovered terminal/live node state, loss of coordinator ETS/process state, node-unavailable recovery, and safe resubmission.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:01
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:01
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:01
---
Understanding: screening this restart-recovery feature against existing coordinator recovery/idempotency tasks. I will search task records and project docs, inspect full candidate histories, and either archive only on a confirmed scope match or hand off with evidence; no implementation will be performed in this focus.
---
<!-- COMMENTS:END -->

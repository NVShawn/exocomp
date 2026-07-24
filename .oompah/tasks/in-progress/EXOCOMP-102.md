---
id: EXOCOMP-102
type: feature
status: In Progress
priority: 1
title: Propagate coordinator diagnostic cancellation
parent: EXOCOMP-18
children: []
blocked_by:
- EXOCOMP-101
labels: []
assignee: null
created_at: '2026-07-24T04:29:44.242098Z'
updated_at: '2026-07-24T16:55:31.996765Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: a52c0abc-e8bc-4e8c-a4b4-e5349baafd1e
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Implement cancellation for accepted and running cluster diagnostic tasks. Atomically mark the cluster task cancellation request, stop undispatched work, attempt A2A cancellation for every active downstream task that supports it, record explicit per-node cancelled/completed/cancel-failed outcomes, and make repeated cancellation idempotent. Resolve races with node completion and ensure orchestration workers terminate without leaking tasks. Add focused tests for cancellation before dispatch, during fan-out, unsupported downstream cancellation, partial cancellation failure, repeated cancel, and completion/cancel races.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 16:55
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:55
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

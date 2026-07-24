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
updated_at: '2026-07-24T16:56:56.435935Z'
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
author: oompah
created: 2026-07-24 16:55
---
Understanding: Duplicate-screening only. I will search coordinator/cluster-diagnostic cancellation tasks and planning records, inspect full descriptions/comments for plausible matches, and either archive EXOCOMP-102 as a confirmed duplicate or hand it off for implementation. The current checkout lacks .oompah/tasks and is branch epic-EXOCOMP-18, so I will use tracker/default-branch read-only evidence while remaining in this worktree.
---
author: oompah
created: 2026-07-24 16:56
---
Discovery: No confirmed duplicate. EXOCOMP-18 explicitly decomposed cancellation into this child after EXOCOMP-99/100/101. EXOCOMP-99 only supplies the outbound DiagnosticClient.cancel operation and unsupported/not-cancelable normalization; EXOCOMP-100 only atomically transitions coordinator goal state and rejects terminal cancellation; EXOCOMP-101 supplies bounded fan-out/result aggregation but no cluster cancel API or downstream cancellation propagation. EXOCOMP-79 is node-side local task/worker cancellation, EXOCOMP-19 owns the future external HTTP/A2A cancel endpoint, and EXOCOMP-105 only verifies integration. These are prerequisites/consumers or reusable precedents, not the same deliverable.
---
<!-- COMMENTS:END -->

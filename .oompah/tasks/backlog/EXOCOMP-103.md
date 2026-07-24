---
id: EXOCOMP-103
type: feature
status: Backlog
priority: 1
title: Audit every correlated diagnostic task transition
parent: EXOCOMP-18
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T04:29:52.079956Z'
updated_at: '2026-07-24T04:29:52.079956Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Integrate orchestration with the durable EXOCOMP-14 audit sink. Emit structured events for goal accepted/deduplicated, downstream dispatch and state changes, node result/failure/timeout, cancellation request/outcome, cluster completion, eviction, and recovery/resubmission decisions. Every event must carry the cluster correlation ID plus relevant downstream/node identifiers, recursively redact credentials and diagnostic secrets, and preserve diagnostic read availability with a local degraded-health signal when the audit sink is unavailable, consistent with the Milestone 2 audit policy. Add tests for event ordering/correlation, recursive redaction, sink write failures, degraded signaling, and recovery after sink availability returns.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


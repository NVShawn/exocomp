---
id: EXOCOMP-105
type: task
status: Backlog
priority: 1
title: Verify coordinator diagnostic orchestration end to end
parent: EXOCOMP-18
children: []
blocked_by:
- EXOCOMP-104
labels: []
assignee: null
created_at: '2026-07-24T04:30:05.161380Z'
updated_at: '2026-07-24T04:30:28.318630Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Add the focused multi-node integration suite for EXOCOMP-18 using at least three deterministic node fixtures and the completed coordinator foundations. Exercise duplicate submissions, healthy plus failed/slow nodes with explicit per-node results, timeouts, cancellation propagation, bounded history/task eviction and output, coordinator restart loss/reconstruction with safe resubmission, correlated durable audit redaction, and unavailable audit sink behavior. Verify the internal orchestrator contract is ready for EXOCOMP-19 cluster A2A handlers and that no remediation executor path is reachable. Run all affected Makefile gates, including make test, make lint, and make fmt-check, and fix only integration defects within EXOCOMP-18 scope.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


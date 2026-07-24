---
id: EXOCOMP-105
type: task
status: In Progress
priority: 1
title: Verify coordinator diagnostic orchestration end to end
parent: EXOCOMP-18
children: []
blocked_by:
- EXOCOMP-104
labels: []
assignee: null
created_at: '2026-07-24T04:30:05.161380Z'
updated_at: '2026-07-24T18:09:25.700915Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 99c719e5-b2f1-48db-8cf5-53fad8fa829c
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Add the focused multi-node integration suite for EXOCOMP-18 using at least three deterministic node fixtures and the completed coordinator foundations. Exercise duplicate submissions, healthy plus failed/slow nodes with explicit per-node results, timeouts, cancellation propagation, bounded history/task eviction and output, coordinator restart loss/reconstruction with safe resubmission, correlated durable audit redaction, and unavailable audit sink behavior. Verify the internal orchestrator contract is ready for EXOCOMP-19 cluster A2A handlers and that no remediation executor path is reachable. Run all affected Makefile gates, including make test, make lint, and make fmt-check, and fix only integration defects within EXOCOMP-18 scope.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:09
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:09
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:09
---
Understanding: duplicate screening will compare EXOCOMP-105's end-to-end coordinator diagnostic integration-suite scope against existing EXOCOMP-18 tasks and related plans/docs. I will inspect full candidate task descriptions/comments before deciding; no implementation will be performed in this focus.
---
<!-- COMMENTS:END -->

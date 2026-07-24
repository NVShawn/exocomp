---
id: EXOCOMP-103
type: feature
status: In Progress
priority: 1
title: Audit every correlated diagnostic task transition
parent: EXOCOMP-18
children: []
blocked_by:
- EXOCOMP-102
labels: []
assignee: null
created_at: '2026-07-24T04:29:52.079956Z'
updated_at: '2026-07-24T17:34:40.398536Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 6b8162d0-8851-419d-b993-dc5be794aa7c
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Integrate orchestration with the durable EXOCOMP-14 audit sink. Emit structured events for goal accepted/deduplicated, downstream dispatch and state changes, node result/failure/timeout, cancellation request/outcome, cluster completion, eviction, and recovery/resubmission decisions. Every event must carry the cluster correlation ID plus relevant downstream/node identifiers, recursively redact credentials and diagnostic secrets, and preserve diagnostic read availability with a local degraded-health signal when the audit sink is unavailable, consistent with the Milestone 2 audit policy. Add tests for event ordering/correlation, recursive redaction, sink write failures, degraded signaling, and recovery after sink availability returns.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 17:34
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 17:34
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 17:34
---
Understanding: Screening EXOCOMP-103 for duplication before any implementation. I will search existing tasks and project docs for correlated diagnostic audit/event-sink work, inspect plausible task descriptions and comments in full, then either archive as duplicate or hand off with evidence.
---
<!-- COMMENTS:END -->

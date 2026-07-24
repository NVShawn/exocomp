---
id: EXOCOMP-99
type: feature
status: Open
priority: 1
title: Implement coordinator diagnostic A2A client adapter
parent: EXOCOMP-18
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T04:29:25.236002Z'
updated_at: '2026-07-24T15:55:34.629126Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 82aaccaa-95c7-4c73-967a-72cad393fa2b
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Implement the coordinator-side A2A 1.0 client boundary used only for diagnostic skills. Add send, task-status/result retrieval, and cancel operations with protocol version negotiation, mTLS node identity/address handling from the EXOCOMP-14/15 registry, per-request timeout behavior, and normalized transport/protocol errors. Keep remediation/executor paths impossible. Add focused unit tests with deterministic fake transports covering successful task creation, terminal results, timeout, malformed responses, and cancellation support/unsupported responses. Relevant design: plans/milestone-2-coordinator.md Coordinator Task Flow and A2A Interface. Start from a branch containing the completed EXOCOMP-14 and EXOCOMP-15 foundations.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 15:52
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 15:53
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

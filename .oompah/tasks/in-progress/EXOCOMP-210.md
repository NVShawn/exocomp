---
id: EXOCOMP-210
type: epic
status: In Progress
priority: 1
title: 'M8B: Signed policy distribution and leases'
parent: EXOCOMP-208
children:
- EXOCOMP-219
- EXOCOMP-220
- EXOCOMP-221
- EXOCOMP-222
- EXOCOMP-223
- EXOCOMP-224
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:23:23.861906Z'
updated_at: '2026-08-03T15:45:38.592833Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/hierarchical-management-modes.md

Outcome: Deliver canonical signed cluster policy bundles, durable delivery, coordinator caching, configurable leases, expiry-to-observe behavior, and policy status reporting.

Acceptance:
- Bundles are cluster-bound, monotonic, replay-resistant, and acknowledged.
- Default lease is five minutes with validated 60-to-3600-second configuration.
- Missing or expired authority fails to observe and is durable and visible.

Out of scope: Mission Control policy editing, privileged action execution, and release qualification.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


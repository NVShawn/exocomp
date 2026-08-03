---
id: EXOCOMP-221
type: task
status: Open
priority: 1
title: Deliver policy bundles through the durable command outbox
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-219
- EXOCOMP-220
labels: []
assignee: null
created_at: '2026-08-03T14:25:14.532816Z'
updated_at: '2026-08-03T15:29:37.700911Z'
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

Deliverable: Add a policy-replace command and policy acknowledgement to the existing Mission Control coordinator transport.

Acceptance criteria:
- Every committed policy version produces at most one logical pending bundle per affected cluster while allowing safe retry.
- Newer versions supersede older undelivered policy bundles; acknowledged versions are idempotent.
- Commands survive Mission Control restart and reconnect and remain organization/cluster identity-bound.
- Expired bundles are replaced with fresh leases rather than delivered.
- Ordinary approvals and execution commands retain their existing behavior.

Tests: Cover fan-out, supersession, retry, duplicate acknowledgement, wrong cluster, expiry before delivery, reconnect, process restart, and two Mission Control replicas; run make test, make fmt-check, and make lint.

Out of scope: Coordinator validation, cache persistence, and UI.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


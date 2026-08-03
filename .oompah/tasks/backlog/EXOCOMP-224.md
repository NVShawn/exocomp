---
id: EXOCOMP-224
type: task
status: Backlog
priority: 2
title: Report policy version, lease, and enforcement status
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:25:19.911306Z'
updated_at: '2026-08-03T14:29:23.057591Z'
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

Deliverable: Extend coordinator heartbeats, status snapshots, Mission Control persistence, and metrics with policy enforcement state.

Acceptance criteria:
- Report applied policy version, lease expiry, signing-key ID, enforcement protocol version, effective-mode summary, and last rejection/fallback reason.
- Mission Control distinguishes pending delivery, applied, rejected, expired, disconnected, and unsupported states.
- Status reduction is sequence-safe, idempotent, organization-scoped, and bounded.
- Metrics count apply/reject/expire/fallback transitions without target or service cardinality explosion.

Tests: Add protocol, reducer, persistence, duplicate/out-of-order, restart, PubSub, metrics, redaction, and organization-isolation tests; run make test, make fmt-check, and make lint.

Out of scope: Policy editing UI, broker execution, and qualification.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


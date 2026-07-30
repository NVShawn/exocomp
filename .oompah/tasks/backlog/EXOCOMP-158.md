---
id: EXOCOMP-158
type: task
status: Backlog
priority: 1
title: Store bounded conversations, messages, and evidence references
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-138
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:16.513296Z'
updated_at: '2026-07-30T14:21:13.135155Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Conversations and Cluster-Local Reasoning.

Deliverables:
- Add organization-scoped conversations, memberships, ordered messages, and structured evidence-reference schemas.
- Support incident-attached and ad hoc cluster conversations.
- Enforce 16 KiB per message and a newest-50-messages-or-64-KiB context selector.
- Track queued, delivered, reasoning, completed, failed, and expired states.

Acceptance:
- Tests cover ordering, limits, context truncation, state transitions, incident membership, cluster membership, and organization isolation.
- Arbitrary file attachments and raw-log blobs are rejected.

Out of scope: transport and model calls.
Quality gate: focused context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-229
type: task
status: Backlog
priority: 1
title: Enforce policy and permits at the node safety gate
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T14:26:29.308857Z'
updated_at: '2026-08-03T14:26:29.308857Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Require a fresh signed policy bundle and matching action permit for every state-changing node workflow and invoke the broker through a bounded client.

Acceptance criteria:
- Direct node recovery requests without both artifacts fail as observe.
- Node verifies signatures, identities, action/target/service bindings, evidence hash, idempotency, and both expiry limits before broker invocation.
- Node independently resolves effective mode and requires manage.
- Duplicate permits return the durable prior result and cannot repeat execution.
- Diagnostic and proposal skills remain available without a permit.

Tests: Cover valid invocation, absent artifacts, every binding mismatch, observe, lease/permit expiry, replay, node restart, broker timeout/failure, diagnostic availability, and no invocation on denial; run make test, make fmt-check, and make lint.

Out of scope: Broker internals, sudoers installation, and specific action adapters.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


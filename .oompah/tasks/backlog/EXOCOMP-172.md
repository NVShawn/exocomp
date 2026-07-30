---
id: EXOCOMP-172
type: task
status: Backlog
priority: 1
title: Store encrypted webhook endpoint configuration
parent: EXOCOMP-134
children: []
blocked_by:
- EXOCOMP-141
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:36.185587Z'
updated_at: '2026-07-30T14:21:43.225568Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Webhooks.

Deliverables:
- Add organization-scoped webhook endpoints with URL, subscribed event types, enabled state, encrypted HMAC secret, and timestamps.
- Generate a secret, show it once, and encrypt it using a configured deployment master key.
- Add admin-only create, update subscriptions, disable, and rotate-secret context functions.

Acceptance:
- Tests cover encryption round-trip, missing/wrong master key, HTTPS URL validation, disallowed/private destinations per configured policy, secret one-time display, rotation, roles, and organization isolation.
- Plaintext secrets are absent from database/log inspection.

Out of scope: HTTP delivery.
Quality gate: focused webhook-context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


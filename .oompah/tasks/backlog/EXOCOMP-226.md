---
id: EXOCOMP-226
type: task
status: Backlog
priority: 1
title: Verify policy and resolve effective mode inside the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T14:26:21.729863Z'
updated_at: '2026-08-03T14:26:21.729863Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add independent policy-bundle verification and shared observe/manage resolution to the privileged broker.

Acceptance criteria:
- Verify Mission Control signature, key ID, organization/cluster/node identity, policy version, issue/expiry time, and canonical service key.
- Recompute the effective mode using the shared resolver and require manage.
- Missing policy, expired lease, unsupported version, invalid signature, resolver disagreement, or target mismatch denies without invoking an action.
- Broker audit output contains only bounded reason codes and safe identities.

Tests: Consume shared golden fixtures and cover every scope, peer conflict, node/service override, tamper, wrong identity, expiry, clock boundary, unknown key, malformed key, resolver disagreement, and proof that the command runner was not called; run broker tests plus make test, make fmt-check, and make lint.

Out of scope: Coordinator permits and action-specific preconditions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


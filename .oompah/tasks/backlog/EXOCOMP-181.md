---
id: EXOCOMP-181
type: task
status: Backlog
priority: 1
title: Add Mission Control security negative tests
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-144
- EXOCOMP-141
- EXOCOMP-149
- EXOCOMP-151
- EXOCOMP-162
- EXOCOMP-163
- EXOCOMP-173
- EXOCOMP-179
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:42.487515Z'
updated_at: '2026-07-30T14:23:48.961980Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Test Strategy and Acceptance Criteria.

Deliverables:
- Add negative tests for cross-organization identifiers, forged/expired OIDC identity, revoked/wrong cluster certificates, invitation replay, payload identity override, arbitrary actions/paths, stale or replayed approvals, invalid webhook signatures, and secret/redaction boundaries.
- Add a dependency and container scan appropriate to the Phoenix image.
- Document each failed-closed boundary and its expected audit event.

Acceptance:
- Every listed attack is rejected before mutation or execution.
- Security failures are bounded, correlated, and do not expose secrets.
- The suite runs from one Make target.

Out of scope: external penetration testing.
Quality gate: security target plus make compliance-check, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


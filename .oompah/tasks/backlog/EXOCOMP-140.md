---
id: EXOCOMP-140
type: task
status: Backlog
priority: 1
title: Implement OIDC login, callback, and logout
parent: EXOCOMP-129
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:14:21.377992Z'
updated_at: '2026-07-30T14:14:21.377992Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Organization and Operator Identity.

Deliverables:
- Implement generic OIDC Authorization Code flow with PKCE for Mission Control.
- Add login, callback, and logout routes with secure server-side sessions.
- Store only the stable subject, display identity, issuer, and mapped claims needed for authorization.
- Validate issuer, audience, state, nonce, and callback errors.

Acceptance:
- Tests with a fake OIDC provider cover success, bad state/nonce, invalid issuer/audience, denied login, and logout.
- Session cookies are secure, HTTP-only, same-site, rotated at login, and expire.
- Tokens and client secrets never appear in logs.

Out of scope: role mapping and administration UI.
Quality gate: focused auth tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


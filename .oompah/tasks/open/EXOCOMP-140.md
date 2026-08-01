---
id: EXOCOMP-140
type: task
status: Open
priority: 1
title: Implement OIDC login, callback, and logout
parent: EXOCOMP-129
children: []
blocked_by:
- EXOCOMP-136
- EXOCOMP-138
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:14:21.377992Z'
updated_at: '2026-08-01T11:48:59.762469Z'
work_branch: epic-EXOCOMP-129--task-EXOCOMP-140
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 50ab5199942c5bd47da5b8fac083057c86030448213f09ff3956b91204c1602d
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 383421fe-3172-4132-bc74-d7c6098f5f47
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T11:48:47.695895+00:00'
  claim_expires_at: '2026-08-01T12:18:47.695895+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 19181efc-d356-49a0-bca0-f37c5449dc80
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-140
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-140
  base_branch: epic-EXOCOMP-129
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T11:48:56.517716+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 11:48
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 11:48
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

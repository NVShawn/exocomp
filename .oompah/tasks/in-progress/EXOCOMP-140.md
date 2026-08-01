---
id: EXOCOMP-140
type: task
status: In Progress
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
updated_at: '2026-08-01T11:52:02.629964Z'
work_branch: epic-EXOCOMP-129--task-EXOCOMP-140
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 50ab5199942c5bd47da5b8fac083057c86030448213f09ff3956b91204c1602d
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T11:50:26.193824+00:00'
  matched_identifiers: []
  evidence: 'Based on my thorough investigation, I have completed the duplicate screening
    for EXOCOMP-140.


    ## Investigation Summary


    I searched the codebase for:

    1. Existing OIDC, OAuth, login, logout, session, and authentication implementations

    2. References to EXOCOMP task IDs (129, 136, 138, 140)

    3. Mission Control or related applications

    4. Similar functionality in plans and documentation


    ## Findings


    - **mission-control.md** contains the specification for OIDC implementation in
    the "Organization and Operator Identity" section, matching EXOCOMP-140''s deliverables
    exactly (OIDC Authorization Code flow with PKCE, login/callback/logout routes,
    secure server-side sessions, identity storage)

    - No existing OIDC, authentication, or login/logout implementation exists in the
    codebase

    - No Mission Control application exists yet (planned for Milestone 7)

    - No other active tasks found implementing the same OIDC authentication flow

    - The task is the canonical implementation of this feature as specified in the
    plan


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** EXOCOMP-140 is the canonical implementation task for OIDC login,
    callback, and logout functionality specified in plans/mission-control.md. No existing
    OIDC implementation, authentication routes, or similar functionality found in
    the codebase. Task is a fresh creation as part of Mission Control (Milestone 7)
    epic with documented dependencies on EXOCOMP-136 and EXOCOMP-138. The task specification
    aligns precisely with the "Organization and Operator Identity" section of the
    mission-control.md plan. No evidence of duplication with any active task in the
    repository.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: cba6d4cd-00c2-4026-9ce1-793c7d5f4067
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-140
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-140
  base_branch: epic-EXOCOMP-129
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T11:50:52.966642+00:00'
oompah.task_costs:
  total_input_tokens: 186
  total_output_tokens: 4177
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 186
      output_tokens: 4177
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 186
    output_tokens: 4177
    cost_usd: 0.0
    recorded_at: '2026-08-01T11:50:26.182796+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-140__20260801T114901Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-129--task-EXOCOMP-140
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T11:50:26.211811+00:00'
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
author: oompah
created: 2026-08-01 11:50
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 50, Tool calls: 24
- Tokens: 186 in / 4.2K out [4.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 35s
- Log: EXOCOMP-140__20260801T114901Z.jsonl
---
author: oompah
created: 2026-08-01 11:50
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 11:50
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 11:52
---
**Understanding:** This task requires implementing OIDC Authorization Code flow with PKCE for Exocomp Mission Control. The deliverables are: (1) Generic OIDC login, callback, and logout routes with server-side sessions; (2) Store only stable OIDC subject, display identity, issuer, and mapped claims; (3) Validate issuer, audience, state, nonce, and callback errors; (4) Secure session cookies (HTTP-only, same-site, rotated at login).

Acceptance criteria: Tests covering success/failure scenarios, secure cookie handling, and token/secret secrecy.

**Initial approach:** Explore existing codebase to find Mission Control app structure, identify authentication patterns, and implement OIDC flow following Elixir/Phoenix best practices.
---
<!-- COMMENTS:END -->

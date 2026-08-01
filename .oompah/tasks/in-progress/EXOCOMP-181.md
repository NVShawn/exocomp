---
id: EXOCOMP-181
type: task
status: In Progress
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
updated_at: '2026-08-01T13:20:00.654827Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-181
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 646a4ee9e3ac90b68d4a9fe5d53e640c23cd775cb1c36e4331bf7d2229c2fcef
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:19:29.882561+00:00'
  matched_identifiers: []
  evidence: 'Based on my comprehensive search of the codebase and task coordination
    information, I''ve completed the duplicate investigation for EXOCOMP-181.


    ## Investigation Summary


    **Search Coverage:**

    - Searched plans, docs, test directories for "mission control," "security tests,"
    "negative tests," and related keywords

    - Reviewed `plans/mission-control.md` which contains the design specification
    for M7 (Mission Control)

    - Examined test fixtures and existing test structure

    - Checked for any existing Phoenix apps (no `mission_control` app exists yet)

    - Reviewed coordination comments showing dependencies and peer tasks (EXOCOMP-141,
    144, 149, 151, 162, 163, 173, 179)


    **Key Findings:**


    1. **Design exists, implementation does not**: The `plans/mission-control.md`
    document contains the M7 design and explicitly states in the "Test Strategy" section:
    "Security tests prove that expired or replayed approvals, stale evidence, revoked
    clusters, cross-organization identifiers, forged OIDC identity, invalid webhook
    signatures, and arbitrary action payloads fail closed."


    2. **No existing security test suite**: There are no implementation-level security
    test files in the codebase yet. The codebase contains unit tests and qualification
    tests for releases, but no Mission Control security tests.


    3. **Task-specific dependencies resolved**: Coordination comments show that prerequisite
    tasks (EXOCOMP-149, EXOCOMP-151, EXOCOMP-162) have already been completed, providing
    the foundation this task depends on.


    4. **Unique decomposition**: EXOCOMP-181 is clearly positioned as a distinct implementation
    task within the M7 epic decomposition, with its own specific scope: adding negative
    tests for the attack vectors listed in the task description.


    5. **No terminal-state duplicates**: No completed, merged, or archived tasks cover
    Mission Control security testing.


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** The mission-co'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 5c331ee0-9535-4628-9e53-5361c05a0833
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-181
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-181
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:17:40.888753+00:00'
oompah.task_costs:
  total_input_tokens: 178
  total_output_tokens: 5249
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 178
      output_tokens: 5249
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 178
    output_tokens: 5249
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:19:29.875178+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-181__20260801T131744Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-181
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:19:29.888986+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:17
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:17
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:19
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 56, Tool calls: 27
- Tokens: 178 in / 5.2K out [5.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 53s
- Log: EXOCOMP-181__20260801T131744Z.jsonl
---
author: oompah
created: 2026-08-01 13:20
---
Agent dispatched (profile: default)
---
<!-- COMMENTS:END -->

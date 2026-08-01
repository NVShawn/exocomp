---
id: EXOCOMP-136
type: task
status: Open
priority: 2
title: Scaffold the Mission Control Phoenix application
parent: EXOCOMP-128
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:49.889616Z'
updated_at: '2026-08-01T14:36:47.998219Z'
work_branch: epic-EXOCOMP-128--task-EXOCOMP-136
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 380c474af15b6b900dc4489f4d5dbee0015706f8a120957126e6ebaa0b68866e
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: Duplicate-screening worker exited with reason normal.
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: '2026-08-01T14:37:44.544375+00:00'
oompah.agent_run_id: 89e36f9e-368c-4743-b402-9568e6acbbdb
oompah.work_branch: epic-EXOCOMP-128--task-EXOCOMP-136
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-128--task-EXOCOMP-136
  base_branch: epic-EXOCOMP-128
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:34:42.490669+00:00'
oompah.task_costs:
  total_input_tokens: 170
  total_output_tokens: 5815
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 170
      output_tokens: 5815
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 170
    output_tokens: 5815
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:36:44.543597+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-136__20260801T143445Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-128--task-EXOCOMP-136
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:36:44.551221+00:00'
---
## Summary

Plan: plans/mission-control.md, Architecture.

Deliverables:
- Add a new Phoenix LiveView application to the umbrella with a separate Mission Control OTP release.
- Add a minimal endpoint, router, supervision tree, static asset pipeline, and GET /health response.
- Keep the application independent from node and coordinator startup.

Acceptance:
- The application starts in test mode and the health route returns 200.
- A focused endpoint test and application supervision test pass.
- Existing node/coordinator tests remain unchanged.

Out of scope: PostgreSQL schemas, authentication, fleet pages, and container packaging.
Quality gate: make fmt-check, make test, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:34
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:34
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:36
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 45, Tool calls: 21
- Tokens: 170 in / 5.8K out [6.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 6s
- Log: EXOCOMP-136__20260801T143445Z.jsonl
---
<!-- COMMENTS:END -->

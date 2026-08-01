---
id: EXOCOMP-179
type: task
status: In Progress
priority: 1
title: Add shared Mission Control protocol contract tests
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-139
start_blocked_by: &id001
- EXOCOMP-194
labels: []
assignee: null
created_at: '2026-07-30T14:18:34.108558Z'
updated_at: '2026-08-01T17:59:07.480518Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-179
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 4d2521f31b73270188653d51b91f0b8a48292bb7d59b14b57561d3ba4334de1f
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:17:20.784124+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-139, EXOCOMP-149, EXOCOMP-180,\
    \ EXOCOMP-181, EXOCOMP-194, EXOCOMP-148, EXOCOMP-150, and EXOCOMP-151. They cover\
    \ protocol definitions, ingestion, integration, security, desired-state fixtures,\
    \ persistence, and command delivery respectively; none duplicates EXOCOMP-179\u2019\
    s cross-application contract-test corpus and fixture-drift validation."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: null
oompah.agent_run_id: 6dda6ce5-8b62-4705-8763-a52e7f5ab85c
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-179
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-179
  base_branch: epic-EXOCOMP-135
  base_sha: d9cc09d75701c1b15febdaff3523261ad017d1bf
  updated_at: '2026-08-01T17:58:46.870598+00:00'
oompah.task_costs:
  total_input_tokens: 781264
  total_output_tokens: 4496
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 781264
      output_tokens: 4496
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 324
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:13:30.348873+00:00'
  - profile: default
    model: haiku
    input_tokens: 781254
    output_tokens: 4172
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:17:20.779279+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-179__20260801T131120Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-179
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:13:30.365134+00:00'
  - run_id: EXOCOMP-179__20260801T131542Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-179
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:17:20.796078+00:00'
---
## Summary

Plan: plans/mission-control.md, Test Strategy.

Deliverables:
- Create one fixture corpus consumed by Mission Control and coordinator tests for every event, command, acknowledgement, error, and supported schema version.
- Add contract cases for duplicate, out-of-order, sequence gap, oversized payload, unknown kind, unsupported version, and redaction.
- Make fixture drift fail with a clear field-level error.

Acceptance:
- The same fixtures pass in both applications.
- Mutating each required field produces the expected bounded failure.
- A Make target runs the contract suite without requiring live VMs.

Out of scope: sockets and end-to-end qualification.
Quality gate: new contract target plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: consume the shared fixtures from EXOCOMP-194 and verify service/profile snapshots, deltas, duplicates, ordering, unsupported versions, bounds, redaction, retirement, and reconstruction across coordinator and Mission Control.
---
author: oompah
created: 2026-08-01 13:11
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:11
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:13
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 58, Tool calls: 26
- Tokens: 10 in / 324 out [334 total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 18s
- Log: EXOCOMP-179__20260801T131120Z.jsonl
---
author: oompah
created: 2026-08-01 13:15
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:15
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:17
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 35
- Tokens: 781.3K in / 4.2K out [785.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 46s
- Log: EXOCOMP-179__20260801T131542Z.jsonl
---
author: oompah
created: 2026-08-01 17:58
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 17:58
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 17:59
---
Understanding: I will verify the inherited EXOCOMP-194 contract, locate Mission Control/coordinator consumers and existing Make targets, then add one shared fixture corpus with field-level drift and required edge-case coverage. I will run the contract suite, make fmt-check, and make lint before committing and submitting.
---
<!-- COMMENTS:END -->

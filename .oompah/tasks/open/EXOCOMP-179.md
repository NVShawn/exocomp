---
id: EXOCOMP-179
type: task
status: Open
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
updated_at: '2026-08-01T13:15:41.811654Z'
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
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 33212a7d-63d6-4000-bbb9-ca862d970952
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:15:30.580150+00:00'
  claim_expires_at: '2026-08-01T13:45:30.580150+00:00'
  retry_count: 1
  retry_after: null
oompah.agent_run_id: ba7223ee-8d44-4b4b-90fa-38c2e08ede94
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-179
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-179
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:15:39.489245+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 324
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 324
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 324
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:13:30.348873+00:00'
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
<!-- COMMENTS:END -->

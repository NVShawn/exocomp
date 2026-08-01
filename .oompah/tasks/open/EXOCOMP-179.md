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
updated_at: '2026-08-01T13:13:34.843876Z'
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
  evidence: Duplicate-screening worker exited with reason normal.
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: '2026-08-01T13:14:30.356092+00:00'
oompah.agent_run_id: aa616a70-912d-4323-a1db-8a83e3c1aa07
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-179
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-179
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:11:17.404723+00:00'
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
<!-- COMMENTS:END -->

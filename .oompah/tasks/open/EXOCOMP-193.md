---
id: EXOCOMP-193
type: task
status: Open
priority: 1
title: Reconcile desired services and health transitions
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-189
- EXOCOMP-192
labels: []
assignee: null
created_at: '2026-07-30T21:37:03.188337Z'
updated_at: '2026-08-01T13:59:48.621733Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-193
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: f9dc2fec670abefb1df3a4e266b8cdb2f1162bf79da6db32a7df3a140611ee6c
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: fdf7b4ef-b124-4a64-8e8b-a7a7c7261efc
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:59:41.528544+00:00'
  claim_expires_at: '2026-08-01T14:29:41.528544+00:00'
  retry_count: 1
  retry_after: null
oompah.agent_run_id: 647eafde-f3e1-4b87-9085-d35c28ce3605
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-193
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-193
  base_branch: epic-EXOCOMP-185
  base_sha: e211afce695af9a158376ffc5e5eac66044c88c5
  updated_at: '2026-08-01T13:59:46.902983+00:00'
oompah.task_costs:
  total_input_tokens: 250
  total_output_tokens: 7429
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 250
      output_tokens: 7429
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 250
    output_tokens: 7429
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:57:09.281192+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-193__20260801T135444Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-185--task-EXOCOMP-193
    source_sha: 6742aa13ef4dc7e3dafa1582cebb5e4550ba9a72
    completed_at: '2026-08-01T13:57:09.347195+00:00'
---
## Summary

Plan: plans/mission-control.md, desired-state reconciliation.

Deliverable: Maintain the coordinator current view of effective service expectations and their latest health.

Acceptance criteria:
- Union manual, automatic, and profile-derived expectations using the shared resolver.
- Require every applicable configured probe to pass.
- Preserve stale or unreachable states explicitly when observation fails.
- Mark removed expectations retired and emit desired_state_removed rather than treating them as failures.
- Confirm unhealthy and recovered state only after two consecutive observations.
- Every transition is correlated and auditable.

Tests: Cover source addition/removal, enable/disable changes, conflicting observations, probe failure, stale nodes, retirement, and two-observation hysteresis; run make test.

Out of scope: Mission Control database writes, UI, incident workflow, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:54
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:54
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:57
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 69, Tool calls: 32
- Tokens: 250 in / 7.4K out [7.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 30s
- Log: EXOCOMP-193__20260801T135444Z.jsonl
---
author: oompah
created: 2026-08-01 13:59
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:59
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

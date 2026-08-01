---
id: EXOCOMP-193
type: task
status: In Progress
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
updated_at: '2026-08-01T16:34:01.744632Z'
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
  verdict: no_duplicate
  checked_at: '2026-08-01T14:02:35.510120+00:00'
  matched_identifiers: []
  evidence: "Based on my thorough investigation, I need to provide my duplicate verdict.\
    \ Let me summarize my findings:\n\n## Investigation Summary\n\nI've searched the\
    \ codebase and project documentation for evidence of duplicate work:\n\n1. **Searched\
    \ for existing implementations** of \"desired service reconciliation,\" \"expectation\
    \ union,\" \"health transitions,\" and related terms - found none in the coordinator\
    \ or core libraries.\n\n2. **Analyzed related code**: The existing `StateMachine`\
    \ (EXOCOMP-30, Milestone 4) handles service recovery for a *failed* service. EXOCOMP-193\
    \ is fundamentally different - it maintains the coordinator's view of *desired*\
    \ service expectations and reconciles them with observed health. These are separate\
    \ concerns.\n\n3. **Reviewed Mission Control plan** (plans/mission-control.md):\
    \ The acceptance criteria clearly call for new functionality to:\n   - Union manual,\
    \ automatic, and profile-derived expectations\n   - Require every applicable configured\
    \ probe to pass\n   - Preserve stale/unreachable states explicitly\n   - Mark\
    \ removed expectations as retired\n   - Implement two-observation hysteresis for\
    \ state confirmation\n   - Enable correlated, auditable transitions\n\n   This\
    \ functionality does not exist in the codebase.\n\n4. **Checked coordination notes**:\
    \ Previous duplicate investigations exited normally but did not mark this task\
    \ as a duplicate candidate (it remains Open). The coordination from EXOCOMP-188\
    \ refers to integration of that sibling epic task but provides no indication that\
    \ EXOCOMP-193's work has been completed or is redundant.\n\n5. **Examined test\
    \ coverage**: No tests exist for desired state reconciliation, health transition\
    \ hysteresis, or expectation union logic.\n\n## Conclusion\n\nThis task describes\
    \ unique, currently-unimplemented work that is distinct from existing systems.\
    \ It is a critical new component of the Mission Control infrastructure required\
    \ for Milestone 7.\n\n---\n\n**Focus handoff: duplicate_detector**\n\n**Duplicate\
    \ preflight verdict: no_duplicate**\n\n*"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: null
oompah.agent_run_id: 0598a1e5-1715-4cf6-9b1f-4f3dd6804b39
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-193
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-193
  base_branch: epic-EXOCOMP-185
  base_sha: 2304acc105f13ebc16792ffc8ea7a57e48be313d
  updated_at: '2026-08-01T16:33:36.111754+00:00'
oompah.task_costs:
  total_input_tokens: 484
  total_output_tokens: 14018
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 484
      output_tokens: 14018
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 250
    output_tokens: 7429
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:57:09.281192+00:00'
  - profile: default
    model: haiku
    input_tokens: 234
    output_tokens: 6589
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:02:35.509250+00:00'
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
  - run_id: EXOCOMP-193__20260801T135950Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-185--task-EXOCOMP-193
    source_sha: 6742aa13ef4dc7e3dafa1582cebb5e4550ba9a72
    completed_at: '2026-08-01T14:02:35.560282+00:00'
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
author: oompah
created: 2026-08-01 14:02
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 62, Tool calls: 28
- Tokens: 234 in / 6.6K out [6.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 52s
- Log: EXOCOMP-193__20260801T135950Z.jsonl
---
author: oompah
created: 2026-08-01 16:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 16:33
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 16:34
---
Understanding: reconcile the coordinator's effective desired-service expectations from manual, automatic, and profile sources; require all configured probes; preserve stale/unreachable observations; retire removed expectations with desired_state_removed; apply two-observation unhealthy/recovered hysteresis; and keep transitions correlated and auditable. I will inspect the existing resolver/observation pipeline, add focused tests, run Makefile quality gates, then submit.
---
<!-- COMMENTS:END -->

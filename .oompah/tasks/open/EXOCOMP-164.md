---
id: EXOCOMP-164
type: task
status: Open
priority: 2
title: Build the authenticated LiveView shell and navigation
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-136
- EXOCOMP-140
- EXOCOMP-141
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:55.693389Z'
updated_at: '2026-08-01T15:11:22.292884Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-164
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: cf7a5bbd6f1c40fbea90a4613c484094d34e5df050fbdd873c744755110e5d04
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 0cce148e-c393-454d-80a1-a25dc0dc8b16
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:11:11.017759+00:00'
  claim_expires_at: '2026-08-01T15:41:11.017759+00:00'
  retry_count: 1
  retry_after: null
oompah.agent_run_id: 0f6cb243-6ca3-48dc-8862-a0c670493879
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-164
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-164
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:11:19.177776+00:00'
oompah.task_costs:
  total_input_tokens: 146
  total_output_tokens: 6462
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 146
      output_tokens: 6462
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 146
    output_tokens: 6462
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:03:52.220012+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-164__20260801T150008Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-133--task-EXOCOMP-164
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:03:52.233242+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Add the authenticated root layout, navigation, flash/error handling, organization context, and role-aware route guards.
- Add reusable components for connectivity, health, severity, timestamps, empty states, and loading/error states.
- Redirect unauthenticated users through OIDC and show a bounded forbidden page for denied roles.

Acceptance:
- LiveView tests cover unauthenticated, viewer, operator, and admin navigation.
- Organization and actor identity survive reconnect without being accepted from client parameters.
- Accessibility checks cover landmarks, focus, labels, and keyboard navigation.

Out of scope: feature pages.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:00
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:00
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:03
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 51, Tool calls: 19
- Tokens: 146 in / 6.5K out [6.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 52s
- Log: EXOCOMP-164__20260801T150008Z.jsonl
---
author: oompah
created: 2026-08-01 15:11
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:11
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

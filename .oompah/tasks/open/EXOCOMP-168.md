---
id: EXOCOMP-168
type: task
status: Open
priority: 2
title: Build the conversation and evidence LiveView
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-158
- EXOCOMP-160
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:03.450139Z'
updated_at: '2026-08-01T15:37:40.671129Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-168
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: d8858ceaa03290f664473b175c6540d6776e2b9ba22a0e7e12cb51133d559c7a
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 9010f4f1-2b9d-4272-804b-d30be99085ad
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:37:31.242452+00:00'
  claim_expires_at: '2026-08-01T16:07:31.242452+00:00'
  retry_count: 2
  retry_after: null
oompah.agent_run_id: f19c2de2-969b-423d-ba87-70b30c4822d8
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-168
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-168
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:37:38.213733+00:00'
oompah.task_costs:
  total_input_tokens: 324
  total_output_tokens: 12455
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 324
      output_tokens: 12455
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 178
    output_tokens: 6013
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:27:48.793934+00:00'
  - profile: default
    model: haiku
    input_tokens: 146
    output_tokens: 6442
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:34:31.861996+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-168__20260801T152518Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-133--task-EXOCOMP-168
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:27:48.810827+00:00'
  - run_id: EXOCOMP-168__20260801T153135Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-133--task-EXOCOMP-168
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:34:31.877029+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Render ordered operator/cluster messages, structured evidence cards, and queued/delivered/reasoning/completed/failed/expired state.
- Allow operators to send a bounded message when the cluster state permits it.
- Add retry/new-message affordances that create a new command rather than rewriting history.

Acceptance:
- LiveView tests cover message limit, online/offline state, duplicate update, failed/expired reasoning, evidence rendering, viewer read-only behavior, and organization isolation.
- Raw HTML, attachments, and arbitrary raw logs are not accepted or rendered.

Out of scope: proposal decision controls.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:25
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:25
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:27
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 48, Tool calls: 21
- Tokens: 178 in / 6.0K out [6.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 37s
- Log: EXOCOMP-168__20260801T152518Z.jsonl
---
author: oompah
created: 2026-08-01 15:31
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:31
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:34
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 44, Tool calls: 22
- Tokens: 146 in / 6.4K out [6.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 7s
- Log: EXOCOMP-168__20260801T153135Z.jsonl
---
author: oompah
created: 2026-08-01 15:37
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:37
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

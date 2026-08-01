---
id: EXOCOMP-166
type: task
status: Open
priority: 2
title: Build the cluster detail LiveView
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-152
- EXOCOMP-153
- EXOCOMP-154
start_blocked_by: &id001
- EXOCOMP-152
- EXOCOMP-155
labels: []
assignee: null
created_at: '2026-07-30T14:16:59.969604Z'
updated_at: '2026-08-01T15:20:40.500286Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-166
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: a122ac1299767d55f8cb09a8ce012dfc745109d5a470c7459330591a110cc534
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T15:20:36.585117+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active tasks EXOCOMP-164, 165, 167\u2013\
    170, 152\u2013155, 171, and desired-state tasks 194, 197, 199\u2013201, and 206.\
    \ Their scopes are shell/navigation, fleet overview, incident/conversation/proposal/admin\
    \ views, persistence, history, audit storage, or backend Ceph health; none duplicates\
    \ the cluster detail LiveView. Terminal tasks were excluded."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: fd9d834f-375e-4ad8-80ae-369d50b7ca8a
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-166
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-166
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:18:47.520736+00:00'
oompah.task_costs:
  total_input_tokens: 780437
  total_output_tokens: 4547
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 780437
      output_tokens: 4547
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 780437
    output_tokens: 4547
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:20:36.580831+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-166__20260801T151850Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-133--task-EXOCOMP-166
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:20:36.594274+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Show cluster identity, labels, current nodes, capabilities, versions, health history summary, incidents, conversations, and recent audited actions.
- Add stable links to incident and conversation routes.
- Update node/connectivity/incident sections from PubSub after commit.

Acceptance:
- LiveView tests cover connected/disconnected clusters, mixed node health, missing history, pagination, updates, unknown ID, and organization isolation.
- No private certificate or secret field is rendered.

Out of scope: editing labels and starting chat.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: cluster detail must show effective services, manual/automatic/profile source badges, systemd versus application health depth, recovery authority, Ceph profile version and coverage, stale/unsupported states, and evidence timestamps.
---
author: oompah
created: 2026-08-01 15:18
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:18
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:20
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 27
- Tokens: 780.4K in / 4.5K out [785.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 53s
- Log: EXOCOMP-166__20260801T151850Z.jsonl
---
<!-- COMMENTS:END -->

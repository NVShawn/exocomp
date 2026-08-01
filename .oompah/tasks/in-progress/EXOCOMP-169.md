---
id: EXOCOMP-169
type: task
status: In Progress
priority: 1
title: Add proposal controls and the action timeline
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-168
- EXOCOMP-162
- EXOCOMP-163
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:05.145960Z'
updated_at: '2026-08-01T13:06:20.968773Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-169
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b26aa4505930df5677c25a312e9c09525d0fd8b19c06dc0003bfee54613f8808
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:03:20.820334+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active tasks EXOCOMP-161, EXOCOMP-162, EXOCOMP-163, EXOCOMP-168,
    EXOCOMP-154, and EXOCOMP-182. Their scopes are proposal storage, backend guards,
    execution, conversation UI, incident timelines, and qualification; none duplicates
    proposal controls with the correlated action timeline. Terminal tasks were excluded.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 05994a3e-7c15-4fb4-a37b-908a043f107f
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-169
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-169
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:03:35.012557+00:00'
oompah.task_costs:
  total_input_tokens: 719357
  total_output_tokens: 4635
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 719357
      output_tokens: 4635
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 719357
    output_tokens: 4635
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:03:20.799865+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-169__20260801T130130Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-133--task-EXOCOMP-169
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:03:20.828886+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Render proposal target, action, parameters, evidence age/hash, risk, disruption, rationale, policy result, and expiry.
- Add operator approve/deny controls bound to the context guards.
- Render decision, command delivery, execution, verification, and terminal artifacts as a correlated timeline.

Acceptance:
- LiveView tests cover allowed approval, denial, offline/expired/stale/terminal disabled states, concurrent decision conflict, viewer denial, execution failure, and verification failure.
- Approved is never displayed as executed until the execution event arrives.

Out of scope: changing proposal content.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:01
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:01
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:03
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 15
- Tokens: 719.4K in / 4.6K out [724.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 0s
- Log: EXOCOMP-169__20260801T130130Z.jsonl
---
author: oompah
created: 2026-08-01 13:03
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:03
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 13:04
---
**Understanding**: EXOCOMP-169 requires adding proposal controls (approve/deny buttons with context guards) and a timeline visualization to the Mission Control UI. The proposal should display: target, action, parameters, evidence age/hash, risk, disruption, rationale, policy result, and expiry. The timeline must show: decision, command delivery, execution, verification, and terminal artifacts as a correlated sequence. This is frontend work for a Phoenix LiveView application that doesn't exist yet - need to check blocking dependencies EXOCOMP-162, 163, 168 to understand what's been built.
---
author: oompah
created: 2026-08-01 13:06
---
**Discovery**: EXOCOMP-169 is blocked by EXOCOMP-162/163/168, but those haven't been completed yet. Mission Control Phoenix/LiveView app doesn't exist in the codebase. Proceeding autonomously to implement the frontend components for proposal controls and timeline as specified in the requirements. Will structure code to integrate with blocking task deliverables once ready.
---
<!-- COMMENTS:END -->

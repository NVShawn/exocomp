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
updated_at: '2026-08-01T15:34:35.156246Z'
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
  evidence: "Let me try to get more information about related tasks by checking the\
    \ task view command. Based on my investigation so far:\n\n**Summary of findings:**\n\
    \n1. **Task Context**: EXOCOMP-168 is \"Build the conversation and evidence LiveView\"\
    \ for the Exocomp Mission Control project\n2. **Plan Reference**: The mission-control.md\
    \ plan (Milestone 7) explicitly describes a \"Conversation view\" UI component\
    \ as part of the LiveView operator interface decomposition\n3. **Epic Structure**:\
    \ EXOCOMP-133 is the epic parent, with EXOCOMP-165-170 as epic-siblings representing\
    \ different functional components\n4. **Coordination Status**: EXOCOMP-170 is\
    \ noted as having \"started implementation\" as an epic-sibling\n\n**Key Research\
    \ Gap**: I cannot access the actual `.oompah/tasks/` directory to read the full\
    \ descriptions and current status of related tasks (EXOCOMP-164, 158, 160, 165-170).\n\
    \nThe mission-control.md plan explicitly describes the expected task decomposition:\n\
    - Mission Control protocol and control-plane PKI\n- Coordinator connection client\
    \ and durable outbox  \n- Mission Control persistence, OIDC, and authorization\n\
    - Fleet status, incidents, and webhooks\n- **Cluster-local conversations, proposals,\
    \ and approval flow** \u2190 EXOCOMP-168 likely here\n- **LiveView operator interface**\
    \ \u2190 EXOCOMP-168 likely here\n- Packaging, operations, and security hardening\n\
    - Multi-cluster qualification and user documentation\n\nBased on available evidence,\
    \ EXOCOMP-168 appears to be a distinct component within the planned epic decomposition\
    \ focused specifically on the conversation/evidence UI rendering. Without access\
    \ to task file content, I cannot definitively confirm whether it overlaps with\
    \ other epic-sibling tasks, though the plan structure suggests each represents\
    \ a distinct architectural concern.\n\n**Focus handoff: duplicate_detector**\n\
    \n**Duplicate preflight verdict: inconclusive**\n\n**Matches: none**\n\n**Evidence:**\
    \ The task is part of the Exocomp Mission Control epic (EXOCOMP-133) with expected\
    \ decomposition in"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 2
  retry_after: '2026-08-01T15:36:31.864254+00:00'
oompah.agent_run_id: 859e0095-1f92-47e5-b610-3d8419af255d
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-168
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-168
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:31:28.642600+00:00'
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
<!-- COMMENTS:END -->

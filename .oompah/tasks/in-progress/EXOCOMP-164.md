---
id: EXOCOMP-164
type: task
status: In Progress
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
updated_at: '2026-08-01T15:18:31.525172Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-164
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: cf7a5bbd6f1c40fbea90a4613c484094d34e5df050fbdd873c744755110e5d04
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T15:14:09.835525+00:00'
  matched_identifiers: []
  evidence: "Based on my thorough investigation, I have:\n\n1. **Searched the repository**\
    \ for existing LiveView, authenticated shell, navigation, OIDC, or operator interface\
    \ implementations \u2014 found none.\n2. **Reviewed the mission-control.md plan**\
    \ which clearly decomposes the Mission Control milestone into distinct children\
    \ including this task for \"authenticated root layout, navigation, flash/error\
    \ handling, organization context, and role-aware route guards.\"\n3. **Examined\
    \ the project structure** (apps directory) \u2014 no Phoenix/LiveView Mission\
    \ Control application yet exists.\n4. **Searched for related tasks** (EXOCOMP-136,\
    \ EXOCOMP-140, EXOCOMP-141, EXOCOMP-165-170) \u2014 no repository task files found,\
    \ confirming these are managed by oompah's server tracker.\n5. **Verified the\
    \ epic lineage** \u2014 EXOCOMP-164 is explicitly a child of epic EXOCOMP-133\
    \ (Mission Control) with specific dependencies and sibling tasks for protocol,\
    \ persistence, conversations, webhooks, and packaging.\n\nThe task is a clearly-scoped,\
    \ newly-created component within the Mission Control epic with no overlapping\
    \ existing implementation or active task.\n\n---\n\nFocus handoff: duplicate_detector\n\
    \nDuplicate preflight verdict: no_duplicate\n\nMatches: none\n\nEvidence: Searched\
    \ repository for existing LiveView, shell, navigation, authenticated layout, OIDC,\
    \ and operator interface implementations across code, plans, and docs \u2014 found\
    \ none. Mission Control LiveView app does not exist in the apps/ directory. The\
    \ task is explicitly a child of epic EXOCOMP-133 with distinct scope (authenticated\
    \ root layout, navigation, role-aware guards) separate from its documented siblings\
    \ (protocol, persistence, conversations, webhooks). No active duplicate task exists."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: null
oompah.agent_run_id: 2d0e4148-e18e-4524-99f2-018be31c9e1c
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-164
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-164
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:14:32.930832+00:00'
oompah.task_costs:
  total_input_tokens: 156
  total_output_tokens: 6801
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 156
      output_tokens: 6801
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 146
    output_tokens: 6462
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:03:52.220012+00:00'
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 339
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:14:09.834963+00:00'
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
  - run_id: EXOCOMP-164__20260801T151127Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-133--task-EXOCOMP-164
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:14:09.929660+00:00'
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
author: oompah
created: 2026-08-01 15:14
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 44, Tool calls: 19
- Tokens: 10 in / 339 out [349 total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 55s
- Log: EXOCOMP-164__20260801T151127Z.jsonl
---
author: oompah
created: 2026-08-01 15:14
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 15:14
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 15:15
---
Understanding: Building the authenticated LiveView shell and navigation UI for Mission Control. Key requirements: (1) Authenticated root layout with OIDC redirect for unauthenticated users; (2) Role-aware navigation (Viewer/Operator/Admin); (3) Reusable UI components (connectivity, health, severity, timestamps, empty states); (4) Organization and actor identity preserved across reconnect; (5) Accessibility compliance (landmarks, focus, labels, keyboard). Blocked by EXOCOMP-136/140/141 for backend infrastructure.

Planned approach:
1. Explore existing mission_control app structure and backend setup
2. Identify blocking tasks status to understand what infrastructure is ready
3. Build authenticated root layout with OIDC guard
4. Implement role-based navigation
5. Create reusable component library
6. Add LiveView tests for all roles and navigation flows
7. Verify accessibility and formatting/lint

Starting discovery now.
---
author: oompah
created: 2026-08-01 15:18
---
Discovery: Found baseline Phoenix+LiveView app from EXOCOMP-136. EXOCOMP-140 provides OIDC authentication (OIDCClient, AuthController). EXOCOMP-141 provides authorization framework (Authorization, Operator, role-based access). Merging blockers directly causes conflicts; manually integrating code from both branches instead.

Beginning integration of:
1. OIDC authentication files
2. Authorization framework
3. LiveView root layout with auth guards
4. Role-aware navigation
5. Reusable UI components
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-170
type: task
status: In Progress
priority: 2
title: Build Mission Control administration LiveViews
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-142
- EXOCOMP-144
- EXOCOMP-172
- EXOCOMP-174
- EXOCOMP-175
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:05.961611Z'
updated_at: '2026-08-01T15:43:30.768155Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-170
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 912d0e697c43d201e7de8f75c098513a3b78cf5e583f82651ccc38c1c36207ff
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T15:30:02.928042+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active task records and comments for EXOCOMP-164, EXOCOMP-166,
    EXOCOMP-142, EXOCOMP-144, EXOCOMP-172, EXOCOMP-174, and EXOCOMP-175. Their scopes
    are shell/navigation, cluster detail, backend invitations/PKI, webhook storage,
    and retention jobs. EXOCOMP-164 only provides an admin placeholder and explicitly
    excludes feature pages; none duplicates the administration LiveViews.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: b2a13da6-f3c7-44ef-8fe1-ba4aad82a43e
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-170
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-170
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:31:20.028810+00:00'
oompah.task_costs:
  total_input_tokens: 849994
  total_output_tokens: 4451
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 849994
      output_tokens: 4451
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 849994
    output_tokens: 4451
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:30:02.925571+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-170__20260801T152809Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-133--task-EXOCOMP-170
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:30:02.946564+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Add admin pages for invitation creation, cluster certificate/status display, revocation, OIDC role mappings, retention settings, and webhook endpoint navigation.
- Show invitation plaintext once and clear it after navigation.
- Require confirmation for cluster revocation and record the admin action.

Acceptance:
- LiveView tests cover admin access, viewer/operator denial, invitation one-time display, revocation confirmation, invalid role mapping, retention bounds, and organization isolation.
- Secrets and private keys are never rendered.

Out of scope: webhook delivery-attempt implementation.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:27
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:28
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:30
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 37
- Tokens: 850.0K in / 4.5K out [854.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 4s
- Log: EXOCOMP-170__20260801T152809Z.jsonl
---
author: oompah
created: 2026-08-01 15:31
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 15:31
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 15:31
---
Understanding: I will inspect the mission-control plan and existing LiveView/auth/domain patterns, implement the requested admin navigation and guarded workflows with one-time invitation display and secret-safe rendering, add focused LiveView coverage, then run the relevant Makefile quality gates and submit the branch.
---
author: oompah
created: 2026-08-01 15:33
---
Discovery: the reusable base is in the EXOCOMP-164 branch (Phoenix app, authenticated live_session, Components, RequireRole, and /admin shell); this task branch is still at the roadmap commit. The dependency history also confirms invitation and certificate concerns are secret/digest-only and webhook contexts return plaintext secrets only at creation. I will bring the shell base into this branch for a buildable implementation, then add an organization-scoped admin context and focused LiveViews around those contracts.
---
author: oompah
created: 2026-08-01 15:43
---
Implementation: added organization-scoped Administration context and safe admin records, expanded /admin into invitations, clusters/certificates, role mappings, retention, and webhook pages, added confirmation-gated cluster revocation with recorded AdminAction, transient one-time invitation token rendering/clearing, and focused context/LiveView tests. Secret material is excluded from records and templates.
---
<!-- COMMENTS:END -->

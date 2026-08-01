---
id: EXOCOMP-170
type: task
status: Open
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
updated_at: '2026-08-01T15:28:05.824894Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-170
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 912d0e697c43d201e7de8f75c098513a3b78cf5e583f82651ccc38c1c36207ff
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: fe71ac63-a1d1-4bec-aa22-1824ec3123f2
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:27:55.781320+00:00'
  claim_expires_at: '2026-08-01T15:57:55.781320+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: ab82b62e-4edc-4709-8ae7-cde0b7c780b3
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-170
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-170
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:28:03.543858+00:00'
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
<!-- COMMENTS:END -->

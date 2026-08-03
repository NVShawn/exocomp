---
id: EXOCOMP-218
type: task
status: Open
priority: 2
title: Build management-policy LiveViews
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-217
labels: []
assignee: null
created_at: '2026-08-03T14:24:22.138173Z'
updated_at: '2026-08-03T15:48:12.975276Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-218
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 64f121926bd781aaccd4719fba5f94d5e105c7e18703e801bd09b97646f77327
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: e01e336b-7f95-4035-8db3-bbf1459ca425
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:47:57.549398+00:00'
  claim_expires_at: '2026-08-03T16:17:57.549398+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: ca22748b-4a24-40be-859d-123480d860bf
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-218
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-218
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:48:10.304372+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add Mission Control views for global, cluster, cluster/service, node, and node/service policy inspection and editing.

Acceptance criteria:
- Show configured, inherited, and effective mode; winning scope; observe-wins conflict; policy version; acknowledgement; and lease expiry.
- Observe-to-manage uses a normal confirmation dialog showing scope and resulting effective value.
- Operators see only restriction controls, admins see both modes, and viewers see no mutation controls.
- Observe-mode proposals remain visible but approval and execution controls are disabled with an explanation.
- PubSub updates active views only after policy transactions commit.

Tests: Add LiveView tests for every role and scope, inheritance, conflict, confirmation/cancel, stale update, disconnected cluster, lease expiry, proposal controls, and organization isolation; run make test, make fmt-check, and make lint.

Out of scope: Policy persistence internals, bundle delivery, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:48
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:48
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

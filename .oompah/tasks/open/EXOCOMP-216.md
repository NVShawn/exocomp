---
id: EXOCOMP-216
type: task
status: Open
priority: 1
title: Enforce policy mutation authorization and auditing
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-214
- EXOCOMP-215
labels: []
assignee: null
created_at: '2026-08-03T14:24:17.168394Z'
updated_at: '2026-08-03T15:30:24.223525Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-216
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 94d8ec70989c4cae677576c6db83da1707a701a5ff634e5692ae100733bf9a57
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 93fae09a-c767-4148-a542-2c195b4e04d8
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:30:05.415537+00:00'
  claim_expires_at: '2026-08-03T16:00:05.415537+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: f315b346-763b-4d8b-81ef-0eb8ee301723
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-216
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-216
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:30:20.469042+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add Mission Control context functions that authorize and audit every management-policy mutation.

Acceptance criteria:
- Admins may set either mode and remove overrides.
- Operators may only preserve or reduce effective authority and cannot delete an override when inheritance broadens authority.
- Viewers cannot mutate policy.
- Authorization is evaluated against the post-change effective result within the same transaction.
- Successful and rejected changes record actor, scope, before/after values, version, organization, and correlation ID without secrets.

Tests: Cover every role, every scope, direct and indirect broadening, concurrent stale version, cross-organization IDs, audit failure rollback, and deletion inheritance; run make test, make fmt-check, and make lint.

Out of scope: Web controllers, LiveView, distribution, and execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:30
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:30
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-215
type: task
status: Open
priority: 1
title: Persist organization-scoped management policies
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-213
labels: []
assignee: null
created_at: '2026-08-03T14:24:14.313906Z'
updated_at: '2026-08-03T15:30:11.264489Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-215
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: fe8370d44ae7a4ef5e240a4c0adf608ab6cd533f3f2d4c22bc48dbba92fdc288
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: b69b62c4-3e7a-41d3-8260-baae0bda51da
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:29:50.377887+00:00'
  claim_expires_at: '2026-08-03T15:59:50.377887+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 0316d372-33a5-4825-a655-89fdef4865f8
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-215
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-215
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:30:08.210154+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add Mission Control migrations, schemas, and repository functions for management-policy overrides and monotonic organization policy versions.

Acceptance criteria:
- Database checks allow exactly the identity fields required by each scope.
- Unique constraints permit one override per organization and scope identity.
- Organization identity is mandatory on every query and foreign key.
- Create, update, delete, list, and effective-resolution reads are transactional.
- Concurrent version updates cannot lose a committed policy change.

Tests: Add migration and context tests for all scopes, uniqueness, invalid identity combinations, organization isolation, rollback, and concurrent updates; run the focused database Make target plus make test, make fmt-check, and make lint.

Out of scope: RBAC, HTTP endpoints, bundle creation, and UI.

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

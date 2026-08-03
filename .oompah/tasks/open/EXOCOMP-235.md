---
id: EXOCOMP-235
type: task
status: Open
priority: null
title: Add cross-layer observe/manage integration coverage
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-218
- EXOCOMP-224
- EXOCOMP-234
labels: []
assignee: null
created_at: '2026-08-03T14:28:13.272722Z'
updated_at: '2026-08-03T15:52:17.713950Z'
work_branch: epic-EXOCOMP-212--task-EXOCOMP-235
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: ec654c94276f90909869cd27657e24abab3e0e99db74f775a50d7423e2440383
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 376576b0-1c4b-44fe-93a2-30282b095bdc
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:52:03.331770+00:00'
  claim_expires_at: '2026-08-03T16:22:03.331770+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 69f43bc0-688d-4360-a459-200989f90365
oompah.work_branch: epic-EXOCOMP-212--task-EXOCOMP-235
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-212--task-EXOCOMP-235
  base_branch: epic-EXOCOMP-212
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:52:14.879368+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable:
Add deterministic integration coverage for policy authoring, distribution, resolution, and enforcement across Mission Control, the coordinator, and a node.

Acceptance criteria:
- Cover the implicit observe default and explicit settings at global, cluster, cluster/service, node, and node/service scopes.
- Cover the same-rank node versus cluster/service disagreement rule, where observe wins.
- Show that diagnostics, status reporting, chat, and remediation proposals remain available in observe mode.
- Show that approving a proposal in observe mode cannot execute a mutation.
- Show that manage mode can execute one registered typed action when every enforcement layer has valid policy and authorization.
- Use stable fixtures and assertions that identify which scope selected the effective mode.

Tests:
- Add focused integration tests for the scenarios above.
- Run the focused Makefile target plus make test, make fmt-check, and make lint.

Out of scope:
- Installer privilege-boundary tests and physical dual-architecture qualification.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:52
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:52
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

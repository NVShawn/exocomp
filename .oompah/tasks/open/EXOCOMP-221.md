---
id: EXOCOMP-221
type: task
status: Open
priority: 1
title: Deliver policy bundles through the durable command outbox
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-219
- EXOCOMP-220
labels: []
assignee: null
created_at: '2026-08-03T14:25:14.532816Z'
updated_at: '2026-08-03T15:36:59.113662Z'
work_branch: epic-EXOCOMP-210--task-EXOCOMP-221
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 465c809ea013c895a78a173c66c096ba2c38f5d0dbba0824ccbc111382404b0b
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 8d963644-1a7b-44af-ba7b-df68128fff27
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:36:37.998643+00:00'
  claim_expires_at: '2026-08-03T16:06:37.998643+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 7bb56ffe-f51e-445c-8602-6dbbe58b35be
oompah.work_branch: epic-EXOCOMP-210--task-EXOCOMP-221
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-210--task-EXOCOMP-221
  base_branch: epic-EXOCOMP-210
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:36:55.745918+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add a policy-replace command and policy acknowledgement to the existing Mission Control coordinator transport.

Acceptance criteria:
- Every committed policy version produces at most one logical pending bundle per affected cluster while allowing safe retry.
- Newer versions supersede older undelivered policy bundles; acknowledged versions are idempotent.
- Commands survive Mission Control restart and reconnect and remain organization/cluster identity-bound.
- Expired bundles are replaced with fresh leases rather than delivered.
- Ordinary approvals and execution commands retain their existing behavior.

Tests: Cover fan-out, supersession, retry, duplicate acknowledgement, wrong cluster, expiry before delivery, reconnect, process restart, and two Mission Control replicas; run make test, make fmt-check, and make lint.

Out of scope: Coordinator validation, cache persistence, and UI.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:36
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:36
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

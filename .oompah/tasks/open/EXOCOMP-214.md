---
id: EXOCOMP-214
type: task
status: Open
priority: 1
title: Map systemd and profile targets to canonical service keys
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-213
labels: []
assignee: null
created_at: '2026-08-03T14:24:11.664051Z'
updated_at: '2026-08-03T15:29:58.764870Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-214
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 6c7da08549a6c621212b6b3d5f0b06918329b6042465d72aaf01e19d194e7015
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 0e8cfcec-d3da-49ff-a315-be88b85d5f44
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:29:40.790898+00:00'
  claim_expires_at: '2026-08-03T15:59:40.790898+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 5e5400cd-0392-49af-a857-d07a3c50d28d
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-214
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-214
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:29:55.534006+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add the shared canonical service-key mapper used before policy resolution.

Acceptance criteria:
- Exact systemd units map to systemd:<unit> after existing strict unit validation.
- Shipped profiles map daemon instances to stable keys such as ceph:mon, ceph:mgr, and ceph:osd.
- Unknown profiles, malformed units, ambiguous mappings, and missing keys fail to observe with structured reasons.
- Mapping is deterministic across coordinator, node, broker, and serialized fixtures.

Tests: Cover ordinary and templated systemd units, every shipped Ceph role, multiple daemon instances, invalid names, unknown profiles, and fixture round trips; run make test, make fmt-check, and make lint.

Out of scope: Policy precedence, desired-service discovery, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:29
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:29
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-213
type: task
status: Open
priority: 1
title: Define management-policy types and resolver
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:24:08.702871Z'
updated_at: '2026-08-03T15:29:48.874366Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-213
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 32cbdb1c1b24703e141b54caf1d9a151a63f8bab4261a8d561033e5c031732b7
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: ea6ba9d5-03fb-4ea0-b32a-3d6b2ad23799
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:29:33.223043+00:00'
  claim_expires_at: '2026-08-03T15:59:33.223043+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: ca87d830-741b-4635-9174-06be73c3ddf9
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-213
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-213
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:29:45.162449+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add shared observe/manage policy types and a pure deterministic resolver for global, cluster, cluster/service, node, and node/service scopes.

Acceptance criteria:
- Missing policy resolves to observe.
- Node/service overrides all other matching scopes.
- Node and cluster/service are peers; observe wins disagreement.
- Node-only and cluster-level action resolution follows the plan.
- Results contain effective mode, winning scope or conflict, matched rules, and policy version.
- Invalid scope/identity combinations fail closed without creating atoms from input.

Tests: Add exhaustive table-driven tests for every scope, agreement, disagreement, absent rule, inheritance, deletion result, ordering, and malformed identity; run make test, make fmt-check, and make lint.

Out of scope: Database access, service-key discovery, transport, UI, and execution.

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

---
id: EXOCOMP-226
type: task
status: Open
priority: 1
title: Verify policy and resolve effective mode inside the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-220
- EXOCOMP-225
labels: []
assignee: null
created_at: '2026-08-03T14:26:21.729863Z'
updated_at: '2026-08-03T15:40:18.286062Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-226
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 02c245b3c6bf5f3451fd21e8ce67c8244a6739540f6d6ac84f90c5aea197653c
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: aeab2004-b0c4-4568-ae62-f35f85f5b9f8
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:40:01.792699+00:00'
  claim_expires_at: '2026-08-03T16:10:01.792699+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: fccecec1-4688-4a8e-9e54-38955eb30cb3
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-226
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-226
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:40:14.772326+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add independent policy-bundle verification and shared observe/manage resolution to the privileged broker.

Acceptance criteria:
- Verify Mission Control signature, key ID, organization/cluster/node identity, policy version, issue/expiry time, and canonical service key.
- Recompute the effective mode using the shared resolver and require manage.
- Missing policy, expired lease, unsupported version, invalid signature, resolver disagreement, or target mismatch denies without invoking an action.
- Broker audit output contains only bounded reason codes and safe identities.

Tests: Consume shared golden fixtures and cover every scope, peer conflict, node/service override, tamper, wrong identity, expiry, clock boundary, unknown key, malformed key, resolver disagreement, and proof that the command runner was not called; run broker tests plus make test, make fmt-check, and make lint.

Out of scope: Coordinator permits and action-specific preconditions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:40
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:40
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

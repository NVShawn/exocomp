---
id: EXOCOMP-232
type: task
status: Open
priority: 1
title: Migrate journal vacuum to the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-229
- EXOCOMP-230
labels: []
assignee: null
created_at: '2026-08-03T14:26:36.951867Z'
updated_at: '2026-08-03T15:45:10.772445Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: fea6ea4724ac53bb25cff903075cba869f4d2d05d6901eb1953bc23f788d265a
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 69f9b395-9dbc-483c-a8d0-57ddaae31dd6
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:45:03.502791+00:00'
  claim_expires_at: '2026-08-03T16:15:03.502791+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 530dc570-1d30-4a03-a2e1-c5715af5d86b
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Replace direct sudo journalctl vacuum execution with a node-scoped broker action.

Acceptance criteria:
- Resolve node, cluster, global, then implicit observe because journal vacuum has no service key.
- Preserve installed vacuum-size bounds, filesystem preconditions, approval rules, idempotency, audit, and verification.
- Caller input cannot select a path, executable, vacuum size, or argument.
- Observe denial starts no journalctl process.
- Existing direct journalctl sudo and executor paths are removed.

Tests: Port bounded-cleanup tests and add node/cluster/global precedence, observe default, permit mismatch, bounds, unsafe filesystem state, direct-path rejection, and installer privilege assertions; run make test, make test-integration, make fmt-check, and make lint.

Out of scope: Service restart and cluster-profile actions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


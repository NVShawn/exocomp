---
id: EXOCOMP-232
type: task
status: Backlog
priority: 1
title: Migrate journal vacuum to the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-229
labels: []
assignee: null
created_at: '2026-08-03T14:26:36.951867Z'
updated_at: '2026-08-03T14:31:28.664669Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
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


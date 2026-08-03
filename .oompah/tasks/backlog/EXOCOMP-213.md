---
id: EXOCOMP-213
type: task
status: Backlog
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
updated_at: '2026-08-03T14:28:57.081347Z'
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


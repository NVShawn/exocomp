---
id: EXOCOMP-161
type: task
status: Open
priority: 1
title: Store and validate typed remedy proposals
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-158
- EXOCOMP-160
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:19.626537Z'
updated_at: '2026-08-01T11:49:26.469637Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Typed Remedy Approval.

Deliverables:
- Add organization-scoped proposal records for IDs, cluster/node target, catalog action, validated parameters, evidence reference/hash, risk, expected disruption, rationale, policy result, and expiry.
- Validate proposals against the shared action catalog and immutable parameter schema before persistence.
- Link each proposal to its conversation message and correlation/task IDs.

Acceptance:
- Tests cover valid proposal, unknown action, caller-supplied command/path, invalid target/parameters, stale/missing evidence, duplicate ID, expiry, and organization mismatch.
- Persisting a proposal cannot execute it.

Out of scope: approval and coordinator execution.
Quality gate: focused schema/context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-211
type: epic
status: Backlog
priority: 1
title: 'M8C: Privileged broker and mutation enforcement'
parent: EXOCOMP-208
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T14:23:26.128876Z'
updated_at: '2026-08-03T14:23:26.128876Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
---
## Summary

Plan: plans/hierarchical-management-modes.md

Outcome: Enforce observe/manage at Mission Control, coordinator, node, and a root-owned execution broker, and migrate every mutation away from direct sudo commands.

Acceptance:
- Broker independently verifies policy, lease, effective mode, permit, target, and installed action authority.
- Service restart, journal vacuum, and profile actions use the broker.
- Fresh install and upgrade leave no direct mutation sudo path.

Out of scope: Policy authoring UI, bundle transport, and end-to-end release qualification.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


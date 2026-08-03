---
id: EXOCOMP-233
type: task
status: Backlog
priority: 1
title: Migrate shipped cluster-profile actions to the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:26:39.646035Z'
updated_at: '2026-08-03T14:29:43.380124Z'
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

Deliverable: Route Ceph and future shipped profile mutations through the common broker while preserving profile-specific policy.

Acceptance criteria:
- Profile daemon instances map to canonical service keys before policy resolution.
- Node/service overrides apply to all matching local instances; exact target and profile version remain permit-bound.
- Broker requires manage plus the installed shipped-profile action, topology/evidence, disruption, cooldown, and verification rules.
- Unknown/local profile definitions and arbitrary Ceph commands remain impossible.
- Legacy profile-helper execution and sudo entries are removed.

Tests: Cover every shipped Ceph role, multiple OSD instances, all policy scopes, peer conflict, unsupported profile/node, topology drift, observe denial, permit mismatch, legacy-path rejection, and safe-restart integration; run make test, profile integration gates, make fmt-check, and make lint.

Out of scope: Adding new Ceph repair action types.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-233
type: task
status: Open
priority: 1
title: Migrate shipped cluster-profile actions to the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-229
- EXOCOMP-230
labels: []
assignee: null
created_at: '2026-08-03T14:26:39.646035Z'
updated_at: '2026-08-03T15:46:24.472761Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: f00033530429fcefd154fe9520e524ddcfc419e6dfd218d288be242b52c246ff
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 1c9c3e02-6a6a-459a-bf4d-90acfa67c4c4
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:46:10.449399+00:00'
  claim_expires_at: '2026-08-03T16:16:10.449399+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: aca48ed7-9092-40f8-97a7-0bc6b289242a
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:46
---
Duplicate screening dispatched (profile: default, task remains Open)
---
<!-- COMMENTS:END -->

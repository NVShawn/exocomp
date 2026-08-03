---
id: EXOCOMP-234
type: task
status: Open
priority: 1
title: Remove bypass paths and gate mixed-version management
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-224
- EXOCOMP-227
- EXOCOMP-231
- EXOCOMP-232
- EXOCOMP-233
labels: []
assignee: null
created_at: '2026-08-03T14:26:42.128617Z'
updated_at: '2026-08-03T15:47:20.656498Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-234
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: cd750d70f9315356d978c96d0323321e3c39cc84a1ee74afe6144c2c7e8c5173
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: f6a0ca51-5c4f-4e56-9db4-1711813a073e
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:47:10.977120+00:00'
  claim_expires_at: '2026-08-03T16:17:10.977120+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: ce7b01dd-5318-4510-9264-1f381abfc7c5
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-234
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-234
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:47:18.207932+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Complete the mutation-path inventory, remove remaining broker bypasses, and prevent manage activation for unsupported targets.

Acceptance criteria:
- A source and packaged-artifact inventory proves every mutation reaches the broker.
- Agent Cards/status advertise management-policy and broker protocol versions.
- Mission Control rejects manage activation when the affected scope includes any unsupported node and reports those nodes.
- Direct calls to old executor/helper entry points fail without mutation.
- Static checks reject new direct sudo mutation commands or unregistered state-changing skills.

Tests: Add mixed-version scope tests, unsupported-node UI/API tests, source/package scans, old-entry-point negative tests, Agent Card contract tests, and regression fixtures for every current action; run make test, make test-installer, make test-release-packaging, make fmt-check, and make lint.

Out of scope: Operator documentation and release qualification.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:47
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:47
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

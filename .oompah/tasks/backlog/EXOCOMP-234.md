---
id: EXOCOMP-234
type: task
status: Backlog
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
updated_at: '2026-08-03T14:31:48.668422Z'
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


---
id: EXOCOMP-231
type: task
status: Backlog
priority: 1
title: Migrate systemd service restart to the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:26:35.002542Z'
updated_at: '2026-08-03T14:29:39.378004Z'
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

Deliverable: Replace direct sudo systemctl restart execution with the broker service-restart adapter.

Acceptance criteria:
- Adapter accepts only exact validated and installed allow-listed service units.
- Broker rechecks policy manage, failed/live-state policy, permit, lock, idempotency, and fixed systemctl argv immediately before execution.
- Existing automatic failed-service and approved live-service workflows retain their evidence, one-attempt, cooldown, and verification behavior.
- Observe denial produces no systemctl process.
- Existing direct executor entry is removed after migration.

Tests: Port existing recovery tests and add all five policy scopes, peer conflict, observe default, permit mismatch, action race, direct-path rejection, and shipped systemd integration coverage; run make test, make test-integration, make fmt-check, and make lint.

Out of scope: Journal vacuum and profile actions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


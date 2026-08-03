---
id: EXOCOMP-231
type: task
status: Open
priority: 1
title: Migrate systemd service restart to the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-229
- EXOCOMP-230
labels: []
assignee: null
created_at: '2026-08-03T14:26:35.002542Z'
updated_at: '2026-08-03T15:44:12.994188Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-231
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 850548fff0dcd4804922b55b28e079b9a2be9875b6ba9ecd60157b4984075829
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 29b2de7c-1b32-46da-81df-e00345774cc2
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:43:54.665653+00:00'
  claim_expires_at: '2026-08-03T16:13:54.665653+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 2c073aee-e70d-4ab0-924c-9a9e65dd8f93
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-231
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-231
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:44:10.045515+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:44
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:44
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-230
type: task
status: Open
priority: 1
title: Package the broker and replace direct mutation sudo privileges
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-226
labels: []
assignee: null
created_at: '2026-08-03T14:26:31.243597Z'
updated_at: '2026-08-03T15:43:43.736813Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 9915bf9cf7b2c6c320f041b1c0649e2ece6a37e4aa9466cd283c785c2d3443dc
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: a4ef9bce-09d9-4d41-9a47-2a53443b72a1
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:43:42.804520+00:00'
  claim_expires_at: '2026-08-03T16:13:42.804520+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Ship the broker for amd64 and arm64 and change installer policy to grant only its exact no-argument path.

Acceptance criteria:
- Broker is root-owned, non-writable, present in release manifests and SBOMs, and verified before activation.
- Sudoers contains one exact broker command and no direct systemctl, journalctl, profile-helper, shell, wildcard, or arbitrary-argument mutation entry.
- Fresh install, upgrade, rollback failure, dry run, uninstall, and visudo validation are atomic and idempotent.
- Upgrade removes stale direct entries before enabling the new node release.
- Failure restores the prior complete installation without mixed privilege state.

Tests: Extend installer, packaging, bundle, tamper, upgrade, rollback, uninstall, ownership/mode, visudo, and both-architecture manifest tests; run make test-installer, make test-release-packaging, make test-bundle, make fmt-check, and make lint.

Out of scope: Broker request parsing and action adapter behavior.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-202
type: task
status: Open
priority: 1
title: Package the profile helper with exact sudo authorization
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-201
labels: []
assignee: null
created_at: '2026-07-30T21:38:33.244906Z'
updated_at: '2026-08-01T11:50:39.639681Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, profile helper packaging.

Deliverable: Install the profile helper as a root-owned executable and grant the node account one exact no-argument sudo command for it.

Acceptance criteria:
- Release archives include both supported architectures and record the helper in manifests and SBOMs.
- Installer sets root ownership and non-writable executable permissions.
- Sudoers grants only the exact helper path with no arguments; direct systemctl wildcard privileges are not added.
- Upgrade, dry-run, rollback, and uninstall handle the helper and sudoers entry idempotently.
- visudo validation failure rolls back the policy installation.

Tests: Extend installer, packaging, tamper-detection, upgrade, uninstall, and sudoers tests; run make test-installer, make test-release-packaging, and make test-bundle.

Out of scope: Helper parsing logic, recovery policy, and Ceph health collection.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


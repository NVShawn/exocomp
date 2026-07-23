---
id: EXOCOMP-46
type: chore
status: Open
priority: 2
title: Document and test upgrade, rollback, backup, and removal
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-34
- EXOCOMP-43
labels: []
assignee: null
created_at: '2026-07-23T19:12:05.467498Z'
updated_at: '2026-07-23T19:17:31.510852Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Document and test upgrade, rollback, backup, and removal.

Implementation
Implement/document side-by-side upgrade, configuration validation, health-gated current-version switch, automatic rollback, compatibility limits, PKI/state backup and restore, troubleshooting, and safe removal; avoid irreversible first-release migrations.

Testing
Test successful upgrade, failed health rollback, coordinator/node version compatibility, backup/restore, interrupted upgrade, default uninstall, explicit purge categories, and preservation of PKI/audit/execution/config/user data.

Acceptance Criteria
- [ ] Failed upgrade restores a healthy prior version.
- [ ] Rollback does not reissue identities or repeat actions.
- [ ] Backup/restore procedures are verified.
- [ ] Removal deletes only recorded Exocomp-owned resources and never user data.
- [ ] Lifecycle tests pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-45
type: chore
status: Merged
priority: 2
title: Write installation, PKI, policy, and operations guides
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-17
- EXOCOMP-28
labels: []
assignee: null
created_at: '2026-07-23T19:12:04.573016Z'
updated_at: '2026-07-23T23:45:26.725067Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Write installation, PKI, policy, and operations guides.

Implementation
Document supported hosts, online/offline install, coordinator initialization, offline-root handling, fingerprint distribution, enrollment, renewal/revocation/rotation, inventory, diagnostics, model sizing, service allow-lists, sudoers, approvals, data classification, bounded system cleanup, and audit retention in docs/.

Testing
Execute every command block against release fixtures; run Markdown/link checks; have scenarios cover first node, renewal, approval, cleanup boundaries, and troubleshooting unsafe permissions.

Acceptance Criteria
- [ ] Commands match shipped artifacts and pass fixture validation.
- [ ] Guides clearly state user data is never deleted and unknown data is protected.
- [ ] PKI and approval procedures include failure/recovery paths.
- [ ] All links and documentation checks pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


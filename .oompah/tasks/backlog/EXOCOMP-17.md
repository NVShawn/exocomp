---
id: EXOCOMP-17
type: feature
status: Backlog
priority: 1
title: Implement node enrollment and certificate renewal
parent: EXOCOMP-2
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T19:09:30.784524Z'
updated_at: '2026-07-23T19:09:30.784524Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Implement node enrollment and certificate renewal.

Implementation
Generate node keys locally; enroll over HTTPS with pinned root fingerprint and node-bound token; submit and validate CSRs; atomically install returned chain; renew over existing mTLS identity before expiry while retaining old valid credentials on failure.

Testing
Test wrong fingerprint, token mismatch/replay/expiry, invalid CSR/key, invalid chain, interrupted install, file permissions, successful renewal, expired/revoked identity, and coordinator denial.

Acceptance Criteria
- [ ] Node private keys never leave the node.
- [ ] Enrollment succeeds only for configured identity and pinned root.
- [ ] Interrupted replacement preserves the previous valid identity.
- [ ] Renewal requires valid mTLS and installs atomically.
- [ ] Focused enrollment tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


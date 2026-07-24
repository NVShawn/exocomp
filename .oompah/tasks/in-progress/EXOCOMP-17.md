---
id: EXOCOMP-17
type: feature
status: In Progress
priority: 1
title: Implement node enrollment and certificate renewal
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-16
labels: []
assignee: null
created_at: '2026-07-23T19:09:30.784524Z'
updated_at: '2026-07-24T02:28:57.409741Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d18cdf21-49b1-4ff7-85a6-3fee6d98c002
oompah.work_branch: epic-EXOCOMP-2
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:28
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:28
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

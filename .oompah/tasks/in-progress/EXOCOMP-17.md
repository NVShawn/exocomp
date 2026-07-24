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
labels:
- focus-complete:duplicate_detector
- needs:feature
assignee: null
created_at: '2026-07-23T19:09:30.784524Z'
updated_at: '2026-07-24T02:31:11.004895Z'
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
author: oompah
created: 2026-07-24 02:29
---
Understanding: duplicate screening will compare this node enrollment/certificate-renewal feature against existing tasks and milestone plans. I will inspect full records for candidates covering local key generation, pinned-root bootstrap, one-use node tokens, CSR validation, atomic credential installation, or mTLS renewal; I will not implement code in this focus.
---
author: oompah
created: 2026-07-24 02:30
---
Discovery: duplicate screening found no duplicate. Reviewed full tracker histories for EXOCOMP-9, EXOCOMP-16, EXOCOMP-20, EXOCOMP-59, EXOCOMP-60, EXOCOMP-75, EXOCOMP-76, and EXOCOMP-77 after searching the git-backed task store and milestone plans for enrollment, renewal, CSR, pinned-root, token, and identity terms. EXOCOMP-60/59 only validate an already-installed node identity and start mTLS; EXOCOMP-75/76/77 implement coordinator PKI, token service, and integration, and EXOCOMP-77 explicitly excludes CSR issuance and node-side enrollment. EXOCOMP-20 is milestone verification. EXOCOMP-17 uniquely owns node-local key generation, pinned-root enrollment, CSR exchange/validation, atomic chain installation, and mTLS-authenticated renewal.
---
author: oompah
created: 2026-07-24 02:31
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-17 should proceed to feature implementation.

Evidence and decisions: Searched the git-backed task store on origin/oompah/state/proj-c260b117 plus docs/plans for enrollment, renewal, CSR, pinned-root, node-bound token, and certificate identity terms. Full tracker records reviewed: EXOCOMP-9 and EXOCOMP-60 cover configuration, installed-identity validation, and listener startup; archived EXOCOMP-59 was absorbed by EXOCOMP-60; EXOCOMP-16 and children EXOCOMP-75/76/77 cover coordinator CA bootstrap, durable token issuance/consume, and operator/supervision integration; EXOCOMP-77 expressly wires the boundary for EXOCOMP-17 without CSR issuance or node-side enrollment; EXOCOMP-20 only verifies the completed M2 milestone. The Milestone 2 plan assigns node-local key generation, pinned-root HTTPS bootstrap, CSR submission, atomic identity replacement, and existing-mTLS renewal to this task.

Relevant areas: plans/milestone-2-coordinator.md; apps/exocomp_node/lib/exocomp/node/identity.ex, listener.ex, config modules and node tests; coordinator PKI/enrollment-token APIs under apps/exocomp_coordinator/lib/exocomp/coordinator/ delivered by EXOCOMP-75/76/77.

Remaining work/risks: implement the actual enrollment and renewal protocol on both endpoint boundary and node client as required, while preserving local-only private keys and old valid credentials on every failure; add focused coverage for wrong root, token mismatch/replay/expiry, CSR/key/chain failures, interrupted atomic install, permissions, valid renewal, expired/revoked identity, and coordinator denial. Verify the epic branch contains the completed EXOCOMP-16 children before coding. No code or repository files were changed during screening.

Recommended next focus: feature.
---
<!-- COMMENTS:END -->

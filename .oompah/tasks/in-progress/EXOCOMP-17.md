---
id: EXOCOMP-17
type: feature
status: In Progress
priority: 1
title: Implement node enrollment and certificate renewal
parent: EXOCOMP-2
children:
- EXOCOMP-87
blocked_by:
- EXOCOMP-16
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:09:30.784524Z'
updated_at: '2026-07-24T02:52:53.292853Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 02447343-8f9b-4cfc-a23d-cc12a8f9c0fd
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 1113276
  total_output_tokens: 7854
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1113276
      output_tokens: 7854
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 1113189
    output_tokens: 4146
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:31:21.041936+00:00'
  - profile: standard
    model: unknown
    input_tokens: 87
    output_tokens: 3708
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:40:39.959916+00:00'
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
author: oompah
created: 2026-07-24 02:31
---
Agent completed successfully in 150s (1117335 tokens)
---
author: oompah
created: 2026-07-24 02:31
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 21
- Tokens: 1.1M in / 4.1K out [1.1M total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 30s
- Log: EXOCOMP-17__20260724T022858Z.jsonl
---
author: oompah
created: 2026-07-24 02:31
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 02:35
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 02:35
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-24 02:39
---
Understanding: Epic planner focus. EXOCOMP-17 is the node-side enrollment and renewal epic. EXOCOMP-16 (coordinator PKI + enrollment tokens) is Done, delivering: (a) EXOCOMP-75 — separated root/intermediate/coordinator CA and Ed25519 approval key with strict file modes; (b) EXOCOMP-76 — durable inventory-bound single-use 600s enrollment tokens with EnrollmentToken.issue/2 and EnrollmentToken.consume/3; (c) EXOCOMP-77 — coordinator supervision, validated-PKI startup, Mix init task, and integration tests. The node currently has no enrollment code. Both the coordinator (needs enrollment/renewal HTTP endpoints and CSR issuance) and the node (needs key gen, CSR, pinned-HTTPS client, atomic credential install, and renewal scheduler) require new code. I will decompose EXOCOMP-17 into 6 session-sized children covering: (1) coordinator CSR validation + leaf cert issuance library, (2) coordinator HTTPS enrollment endpoint, (3) coordinator mTLS renewal endpoint, (4) node private key management and atomic credential store, (5) node enrollment client with pinned root fingerprint, (6) node renewal scheduler and focused test suite.
---
author: oompah
created: 2026-07-24 02:40
---
Run #1 [attempt=1, profile=standard, role=standard -> Claude/default]
- Turns: 0, Tool calls: 69
- Tokens: 87 in / 3.7K out [3.8K total]
- Cost: $0.0000
- Exit: terminated, Duration: 5m 16s
- Log: EXOCOMP-17__20260724T023527Z.jsonl
---
<!-- COMMENTS:END -->

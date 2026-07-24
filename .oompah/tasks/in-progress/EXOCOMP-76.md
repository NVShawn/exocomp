---
id: EXOCOMP-76
type: feature
status: In Progress
priority: 1
title: Implement durable node-bound enrollment token service
parent: EXOCOMP-16
children: []
blocked_by:
- EXOCOMP-75
- EXOCOMP-14
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T23:01:19.306900Z'
updated_at: '2026-07-24T01:07:59.136561Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 08cd3096-9e89-4241-9d8f-54dadfb534d5
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Implement the coordinator enrollment-token service consumed by EXOCOMP-17. Use the inventory/registry contract from EXOCOMP-14 and protected online state from EXOCOMP-75. Provide explicit issue and consume APIs. Issuance must reject node IDs absent from the active inventory, use a default lifetime of 600 seconds, allow only shorter positive configured lifetimes, generate high-entropy opaque token values, return the plaintext token only once, and persist only a cryptographic digest plus node ID, expiry, and consumption metadata. Consumption must perform constant-time digest comparison and atomically validate inventory membership, bound node ID, expiry, and unused status before marking the token consumed so concurrent requests cannot both succeed. Persist replay state across coordinator restarts with restrictive permissions and fail closed on corrupt or unavailable storage; prune expired records without making replay possible inside their validity window. Inject time/randomness/storage seams for deterministic tests. Tokens, digests, keys, and private metadata must never appear in Logger output, audit payloads, errors, Inspect output, or crash reports; emit only safe node ID/result/correlation metadata through the EXOCOMP-14 audit abstraction. Add focused tests for issuance membership checks, ten-minute default and shorter overrides, expiry boundary, node mismatch, sequential and concurrent replay, restart persistence, corrupt storage, pruning, permissions, and log/audit redaction. Run coordinator-focused tests plus make fmt-check, make test, and make lint. Acceptance: tokens are inventory-node-bound, expiring, single-use under concurrency and restart, stored protected, and secret-free in observable output.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 01:06
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:06
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 01:07
---
Understanding: Duplicate screening only. EXOCOMP-76 requests the coordinator-side durable enrollment-token service: inventory-bound issuance, digest-only protected persistence, atomic single-use consumption across concurrency/restarts, expiry, redaction, audit metadata, and focused tests. I will compare the parent, dependencies, consumer, and integration sibling before deciding whether it duplicates existing work; no implementation will occur in this focus.
---
author: oompah
created: 2026-07-24 01:07
---
Discovery: No duplicate found. EXOCOMP-16 explicitly decomposed its original combined CA/token scope into EXOCOMP-75 (PKI bootstrap/state validation), EXOCOMP-76 (durable inventory-bound enrollment tokens), and EXOCOMP-77 (supervision/operator/API integration). EXOCOMP-17 is node-side enrollment that consumes this service, while EXOCOMP-14 provides inventory/registry/audit primitives. Their full descriptions and histories show complementary, non-overlapping ownership.
---
author: oompah
created: 2026-07-24 01:07
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-76 is a unique, intentionally-created child of EXOCOMP-16 and should proceed to implementation.

Evidence: Searched enrollment-token, node-bound, single-use, and replay terms in the available repository plans/docs (the local .oompah/tasks mirror is absent). Reviewed full tracker state/comments for EXOCOMP-16, EXOCOMP-14, EXOCOMP-17, EXOCOMP-75, and EXOCOMP-77. EXOCOMP-16 comments #19-23 explicitly define EXOCOMP-76 as the durable token-service slice. EXOCOMP-75 implements PKI bootstrap only; EXOCOMP-77 integrates the token service; EXOCOMP-17 consumes it node-side; EXOCOMP-14 supplies inventory and audit contracts.

Relevant files/design: plans/milestone-2-coordinator.md; apps/exocomp_coordinator/lib/exocomp/coordinator/ and its tests. The current worktree reports branch epic-EXOCOMP-16 despite the dispatch text naming epic-EXOCOMP-2, and contains an unrelated untracked apps/exocomp_coordinator/tmp/ directory; neither was modified.

Remaining work/risks: Implement the explicit issue/consume service, durable digest-only protected store, atomic concurrency/restart replay prevention, fail-closed corruption/availability behavior, pruning, injected seams, audit/redaction, and required focused/full quality gates. Preserve existing untracked files and ensure the implementation branch includes completed EXOCOMP-14 and EXOCOMP-75 work.

Recommended next focus: feature.
---
<!-- COMMENTS:END -->

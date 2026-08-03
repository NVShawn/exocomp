---
id: EXOCOMP-219
type: task
status: Backlog
priority: 1
title: Define and sign canonical policy bundles
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:25:05.936225Z'
updated_at: '2026-08-03T14:29:10.322347Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add the shared versioned cluster policy-bundle schema, canonical encoder, signature verifier, and fixture corpus.

Acceptance criteria:
- Bundle identity includes organization, cluster, policy version, issue time, expiry, signing-key ID, and only rules applicable to that cluster.
- Canonical encoding is byte-identical across Mission Control, coordinator, node, and broker implementations.
- Ed25519 signatures cover the complete canonical body.
- Unknown versions, duplicate rules, invalid scope identities, non-canonical input, and oversized bundles fail closed.

Tests: Add golden fixtures plus encode/decode, cross-runtime canonicalization, signature, tamper, size, version, duplicate, and malformed-schema tests; run make test, make fmt-check, and make lint.

Out of scope: Key storage, transport, caching, lease timers, and policy resolution semantics.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


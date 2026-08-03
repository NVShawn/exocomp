---
id: EXOCOMP-219
type: task
status: Open
priority: 1
title: Define and sign canonical policy bundles
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-213
labels: []
assignee: null
created_at: '2026-08-03T14:25:05.936225Z'
updated_at: '2026-08-03T15:31:21.471665Z'
work_branch: epic-EXOCOMP-210--task-EXOCOMP-219
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 8e4f157e381cac884559cb2fc34eb7a534f07384743fd72f70985a2263f95b6c
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 16083f1c-a374-4112-ab18-4d7801934a61
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:31:06.291842+00:00'
  claim_expires_at: '2026-08-03T16:01:06.291842+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 84afea07-d914-4ff9-8328-cb087874ed04
oompah.work_branch: epic-EXOCOMP-210--task-EXOCOMP-219
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-210--task-EXOCOMP-219
  base_branch: epic-EXOCOMP-210
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:31:18.532012+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:31
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:31
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

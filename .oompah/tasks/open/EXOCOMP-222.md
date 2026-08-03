---
id: EXOCOMP-222
type: task
status: Open
priority: 1
title: Validate and atomically cache policy in the coordinator
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-219
- EXOCOMP-221
labels: []
assignee: null
created_at: '2026-08-03T14:25:16.130462Z'
updated_at: '2026-08-03T15:37:01.356922Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 0297af041b74041ff78584c2abeb940314b7710947edbfa7348b6e5ad24424ba
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 5d17662b-ddc8-4882-8bed-81cf6b4a1805
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:36:52.855484+00:00'
  claim_expires_at: '2026-08-03T16:06:52.855484+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: c92b970d-2fb1-489d-a0b3-107206508a12
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add coordinator ingestion and protected durable caching for signed cluster policy bundles.

Acceptance criteria:
- Validate signature, signing-key ID, organization/cluster identity, schema, monotonic version, issue time, expiry, and lease bounds before replacement.
- Install the complete bundle atomically; any failure retains the previous valid bundle.
- Restart reloads and revalidates the cache before use.
- Missing, corrupt, expired, replayed, wrong-cluster, or invalid policy resolves to observe with a structured audit reason.
- A valid install emits an idempotent acknowledgement.

Tests: Cover valid replacement, stale and duplicate version, wrong identity, tamper, partial write, fsync/rename failure, corrupt cache, restart, expiry, and acknowledgement retry; run make test, make fmt-check, and make lint.

Out of scope: Lease scheduling, execution permits, and broker calls.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


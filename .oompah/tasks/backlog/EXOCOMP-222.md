---
id: EXOCOMP-222
type: task
status: Backlog
priority: 1
title: Validate and atomically cache policy in the coordinator
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T14:25:16.130462Z'
updated_at: '2026-08-03T14:25:16.130462Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
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


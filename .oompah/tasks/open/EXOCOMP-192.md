---
id: EXOCOMP-192
type: task
status: Open
priority: 2
title: Schedule service discovery and observations in the coordinator
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-188
- EXOCOMP-190
- EXOCOMP-191
labels: []
assignee: null
created_at: '2026-07-30T21:37:02.009432Z'
updated_at: '2026-08-01T15:53:29.543687Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-192
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: c3d4b1c7dfae5adf41d81e0d95bc8fe379f913c49dca8ecc83be6db1423bea0c
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 41c12550-00ba-48da-ae9a-e93c74ad3898
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:53:20.006186+00:00'
  claim_expires_at: '2026-08-01T16:23:20.006186+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 576870a7-ce29-474c-a019-7382de1b9224
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-192
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-192
  base_branch: epic-EXOCOMP-185
  base_sha: 7b3ff4a831259ec5555de09214348b3da5eb554e
  updated_at: '2026-08-01T15:53:27.587827+00:00'
---
## Summary

Plan: plans/mission-control.md, desired-state polling.

Deliverable: Add coordinator scheduling that discovers automatic services on startup and every five minutes and observes effective services on the existing 30-second health cadence.

Acceptance criteria:
- Use jitter, bounded concurrency, per-node timeouts, and the existing backoff/isolation patterns.
- Cache the newest successful discovery without replacing it with a failed scan.
- Inventory replacement triggers prompt reconciliation.
- One slow or unreachable node cannot block peers.
- Scheduling uses an injectable clock for deterministic tests.

Tests: Cover startup, periodic refresh, jitter, cache preservation, inventory reload, timeout isolation, and cancellation; run make test.

Out of scope: Merge rules, status event schemas, incidents, and recovery.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:53
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:53
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

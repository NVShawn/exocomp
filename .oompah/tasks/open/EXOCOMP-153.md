---
id: EXOCOMP-153
type: task
status: Open
priority: 2
title: Record bounded cluster and node status history
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-152
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:37.552915Z'
updated_at: '2026-08-01T14:47:31.667817Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-153
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 56ed462b0075c8b2b24ecc3c693a952e5feb167ae9d73281644cf94e129e577b
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 75c341e7-1004-4caa-a424-312481c34b34
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:47:21.949111+00:00'
  claim_expires_at: '2026-08-01T15:17:21.949111+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 175eb8b5-6f72-438c-949f-9f161298c582
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-153
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-153
  base_branch: epic-EXOCOMP-131
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:47:29.484552+00:00'
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add partition-ready status-history storage scoped to organization and source identity.
- Record cluster checkpoints every five minutes.
- Record node state changes immediately and unchanged-node checkpoints hourly.
- Preserve observation time separately from ingestion time.

Acceptance:
- Clock-controlled tests cover change detection, checkpoint cadence, duplicate snapshots, late events, and bounded batch writes.
- History writes do not block or replace the current-state transaction.

Out of scope: retention deletion and charts.
Quality gate: focused history tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:47
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:47
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-147
type: task
status: Open
priority: 1
title: Add heartbeat, disconnect detection, and reconnect backoff
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-146
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:03.538393Z'
updated_at: '2026-08-01T12:14:52.606158Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-147
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 1212be6e326192fc087f66ee0a620f8a497b62faca881250125e5e9dc98afa87
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 6314aed4-a1e7-4d0f-921d-b97a0d9bc0e7
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:14:43.698725+00:00'
  claim_expires_at: '2026-08-01T12:44:43.698725+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: a6d185c8-d9bf-412e-a17f-a64c80b7aa9e
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-147
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-147
  base_branch: epic-EXOCOMP-130
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:14:50.342958+00:00'
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Send a cluster heartbeat every 30 seconds through the active session.
- Mark a session disconnected after 90 seconds without a valid heartbeat.
- Reconnect with full-jitter exponential backoff from one second to 60 seconds.
- Reset backoff only after a stable authenticated connection.

Acceptance:
- Deterministic clock/randomness tests cover heartbeat cadence, missed heartbeats, reconnect bounds, reset, and duplicate timers.
- Connection loss does not crash the coordinator or block local work.
- Mission Control publishes connected/disconnected state only after committing it.

Out of scope: event persistence and UI.
Quality gate: focused state-machine tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:14
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:14
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

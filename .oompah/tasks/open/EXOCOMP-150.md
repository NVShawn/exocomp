---
id: EXOCOMP-150
type: task
status: Open
priority: 1
title: Persist and deliver server-to-cluster commands
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-137
- EXOCOMP-139
- EXOCOMP-146
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:07.042172Z'
updated_at: '2026-08-01T12:24:56.081659Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-150
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 0d6ca87355e1568fe7b0172c89c87020bfcf5c14e125bff600125b48626419dd
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: df95911b-a06e-49bf-9e4f-abd9cfafbbc0
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:24:45.586159+00:00'
  claim_expires_at: '2026-08-01T12:54:45.586159+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 6b3529e6-0a60-4b2a-8624-788ef97a8dd3
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-150
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-150
  base_branch: epic-EXOCOMP-130
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:24:53.602594+00:00'
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Add a durable command outbox containing command ID, kind, issued_at, expires_at, organization, cluster, and validated payload.
- Deliver pending commands to whichever Mission Control replica owns the active cluster session.
- Mark commands acknowledged exactly once; expire undelivered commands without treating them as executed.

Acceptance:
- Tests cover offline cluster, reconnect, duplicate acknowledgement, expiration, replica ownership change, invalid command kind, and database rollback.
- Commands survive Mission Control process restart.

Out of scope: chat/proposal command business logic.
Quality gate: focused command-outbox tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:24
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:24
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-151
type: task
status: Open
priority: 1
title: Report command results without duplicate execution
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-145
- EXOCOMP-148
- EXOCOMP-150
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:08.095148Z'
updated_at: '2026-08-01T12:26:23.091995Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-151
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 0be9fdedfc54d9f9f2555aaa702ef25b0f215a0510d78e1c18c172d01fdca239
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: e6745519-633c-4756-9d09-81e22185b039
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:26:12.661870+00:00'
  claim_expires_at: '2026-08-01T12:56:12.661870+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 77003c76-5dab-4b15-b445-6c0c4a625726
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-151
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-151
  base_branch: epic-EXOCOMP-130
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:26:21.030194+00:00'
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Add coordinator handling for command IDs, expiry, schema validation, and durable terminal result events.
- Reuse existing task/replay boundaries so receiving the same command twice cannot run its handler twice.
- Acknowledge receipt separately from completion and correlate terminal status to the original command.

Acceptance:
- Tests cover duplicate delivery before and after restart, expired command, unsupported kind, handler crash, completed result replay, and correlation fields.
- Receipt acknowledgement never implies successful execution.

Out of scope: specific chat and remedy handlers.
Quality gate: focused coordinator tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:26
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:26
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-162
type: task
status: Open
priority: 1
title: Implement operator approval and denial guards
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-141
- EXOCOMP-161
- EXOCOMP-147
- EXOCOMP-150
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:20.549186Z'
updated_at: '2026-08-01T12:56:42.591320Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-162
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 356b414e5aa7c4d128397587c7aef42d5081a00957de9f5d41de745e16330475
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: d205d05f-6747-4932-9e8b-b186ff749cc4
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:56:31.673141+00:00'
  claim_expires_at: '2026-08-01T13:26:31.673141+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 9375ba0f-312a-4372-b71b-06d3dc60855e
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-162
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-162
  base_branch: epic-EXOCOMP-132
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:56:40.207910+00:00'
---
## Summary

Plan: plans/mission-control.md, Typed Remedy Approval.

Deliverables:
- Add operator/admin context functions to approve or deny one pending proposal.
- Reject approval when the cluster is disconnected, proposal expired, evidence freshness elapsed, proposal terminal, or operator lacks role.
- Persist the decision and actor audit fields transactionally, then enqueue one typed approval command.
- Never queue an approval for later when the cluster is offline.

Acceptance:
- Tests cover every guard, duplicate/concurrent decisions, denial reason, queue failure rollback, viewer denial, and organization mismatch.
- An accepted decision is not represented as executed.

Out of scope: local revalidation and LiveView controls.
Quality gate: focused approval tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:56
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:56
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

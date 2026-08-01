---
id: EXOCOMP-171
type: task
status: Open
priority: 1
title: Add correlated Mission Control audit events
parent: EXOCOMP-134
children: []
blocked_by:
- EXOCOMP-138
- EXOCOMP-141
- EXOCOMP-139
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:34.779256Z'
updated_at: '2026-08-01T13:03:43.985650Z'
work_branch: epic-EXOCOMP-134--task-EXOCOMP-171
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: cf0b41ee9e841503700dd293cf9b9d0f92e9fac56ceb90af0530ca81b91aaa9a
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: f1339104-4cab-4abe-9909-1eba984fba18
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:03:31.235065+00:00'
  claim_expires_at: '2026-08-01T13:33:31.235065+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 14718e91-ee39-45d4-bef0-95889c8bbc4b
oompah.work_branch: epic-EXOCOMP-134--task-EXOCOMP-171
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-134--task-EXOCOMP-171
  base_branch: epic-EXOCOMP-134
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:03:40.705806+00:00'
---
## Summary

Plan: plans/mission-control.md, Persistence and Retention.

Deliverables:
- Add immutable organization-scoped audit-event storage for operator mutations, cluster events, commands, proposals, decisions, executions, and administrative changes.
- Store actor/cluster identity, timestamp, event type, target, outcome, and correlation IDs.
- Add one redaction module used before audit and webhook serialization.

Acceptance:
- Tests cover each actor type, correlation lookup, ordering, transaction rollback, cross-organization access, redaction, and attempts to update/delete an event through normal contexts.
- Secrets, private keys, tokens, and arbitrary raw logs are never persisted.

Out of scope: retention deletion and audit UI.
Quality gate: focused audit tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:03
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:03
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

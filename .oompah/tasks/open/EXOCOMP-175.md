---
id: EXOCOMP-175
type: task
status: Open
priority: 2
title: Delete incident, conversation, proposal, and audit history by policy
parent: EXOCOMP-134
children: []
blocked_by:
- EXOCOMP-158
- EXOCOMP-161
- EXOCOMP-171
- EXOCOMP-173
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:39.520334Z'
updated_at: '2026-08-01T15:39:47.006251Z'
work_branch: epic-EXOCOMP-134--task-EXOCOMP-175
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e2942b5b46852d438031f60f9ab9e2f44de4b4ddd0be018079a5ed1c5b3084e3
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 129b974a-ef50-4097-a62c-50a092c92c0f
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:39:39.775944+00:00'
  claim_expires_at: '2026-08-01T16:09:39.775944+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 824a03e4-d687-4168-a42e-d7d5b7603b00
oompah.work_branch: epic-EXOCOMP-134--task-EXOCOMP-175
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-134--task-EXOCOMP-175
  base_branch: epic-EXOCOMP-134
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:39:45.253349+00:00'
---
## Summary

Plan: plans/mission-control.md, Persistence and Retention.

Deliverables:
- Implement the configurable one-year default retention for resolved incidents, messages/evidence, proposals/decisions/executions, webhook event history, and audit events.
- Delete in dependency-safe bounded batches while preserving open incidents, pending proposals/commands, and records still required by a retained timeline.
- Record job counts, failures, and last successful cutoff.

Acceptance:
- Tests cover cutoff boundaries, dependency ordering, open/pending preservation, multiple organizations, interrupted resume, concurrent ingest, and audit of retention settings.
- The job never deletes cluster identity/current-state records.

Out of scope: legal hold and archival export.
Quality gate: focused retention tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:39
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:39
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

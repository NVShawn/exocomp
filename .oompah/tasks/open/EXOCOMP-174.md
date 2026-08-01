---
id: EXOCOMP-174
type: task
status: Open
priority: 2
title: Delete status history with bounded retention jobs
parent: EXOCOMP-134
children: []
blocked_by:
- EXOCOMP-153
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:38.421513Z'
updated_at: '2026-08-01T15:34:57.924695Z'
work_branch: epic-EXOCOMP-134--task-EXOCOMP-174
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: aca00fd37b09c835b1fd8c142f2e8b56df43e4a4ac38fdd09ee3a2027f1607c1
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: ad2fc03c-9c82-446e-beb1-1911df251269
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:34:49.293494+00:00'
  claim_expires_at: '2026-08-01T16:04:49.293494+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 23855897-e1b7-493b-9f36-d21f5e5d623a
oompah.work_branch: epic-EXOCOMP-134--task-EXOCOMP-174
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-134--task-EXOCOMP-174
  base_branch: epic-EXOCOMP-134
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:34:55.666687+00:00'
---
## Summary

Plan: plans/mission-control.md, Persistence and Retention.

Deliverables:
- Add configurable organization retention settings with a 90-day status-history default and validated bounds.
- Implement partition drop or bounded-batch deletion without holding long transactions or deleting current materialized state.
- Record job progress/failure metrics and audit configuration changes.

Acceptance:
- Clock-controlled tests cover cutoff boundaries, multiple organizations, batch continuation, retry after failure, concurrent ingest, and preservation of current state.
- One job cannot delete another organization data.

Out of scope: incident/conversation/audit retention.
Quality gate: focused retention tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:34
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:34
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

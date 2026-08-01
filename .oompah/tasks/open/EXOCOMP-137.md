---
id: EXOCOMP-137
type: task
status: Open
priority: 2
title: Configure PostgreSQL and the Ecto migration test harness
parent: EXOCOMP-128
children: []
blocked_by:
- EXOCOMP-136
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:51.051048Z'
updated_at: '2026-08-01T14:37:19.432922Z'
work_branch: epic-EXOCOMP-128--task-EXOCOMP-137
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b80f5e1f46d453b5f911773d73d7bc30e7ad2ce61d7d1b5e90ae108f31164170
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 4546f0ea-44dd-4fff-8889-dd748ac90f7c
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:37:06.046878+00:00'
  claim_expires_at: '2026-08-01T15:07:06.046878+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 5fa05aaa-bded-4aef-be24-bd3267f36f13
oompah.work_branch: epic-EXOCOMP-128--task-EXOCOMP-137
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-128--task-EXOCOMP-137
  base_branch: epic-EXOCOMP-128
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:37:13.178668+00:00'
---
## Summary

Plan: plans/mission-control.md, Persistence and Retention.

Deliverables:
- Add Ecto/Postgrex dependencies and a Mission Control Repo supervised by the new application.
- Add dev/test/prod database configuration with runtime validation and no embedded credentials.
- Add an initial migration and SQL-sandbox test setup.
- Add a Make target for focused Mission Control database tests if no existing target covers it.

Acceptance:
- A clean test database can migrate up and down.
- Concurrent tests use the SQL sandbox without data leakage.
- Missing production database configuration fails with a bounded actionable error.

Out of scope: domain tables and retention jobs.
Quality gate: focused database tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:37
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:37
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

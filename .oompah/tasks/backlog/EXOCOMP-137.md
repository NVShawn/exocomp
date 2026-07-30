---
id: EXOCOMP-137
type: task
status: Backlog
priority: 2
title: Configure PostgreSQL and the Ecto migration test harness
parent: EXOCOMP-128
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:51.051048Z'
updated_at: '2026-07-30T14:13:51.051048Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


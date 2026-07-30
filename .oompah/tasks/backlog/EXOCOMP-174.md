---
id: EXOCOMP-174
type: task
status: Backlog
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
updated_at: '2026-07-30T14:21:50.406068Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


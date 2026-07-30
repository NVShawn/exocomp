---
id: EXOCOMP-175
type: task
status: Backlog
priority: 2
title: Delete incident, conversation, proposal, and audit history by policy
parent: EXOCOMP-134
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:39.520334Z'
updated_at: '2026-07-30T14:17:39.520334Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


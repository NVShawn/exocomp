---
id: EXOCOMP-157
type: task
status: Open
priority: 2
title: Group related incidents deterministically
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-154
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:42.626270Z'
updated_at: '2026-08-01T11:52:44.466454Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add a pure grouping module using alert type, service, software version, and configured time window.
- Return group keys and display summaries without changing incident identity or state.
- Add query helpers for fetching related open/recent incidents within an organization.

Acceptance:
- Tests cover matching/nonmatching attributes, window boundaries, missing version/service, organization isolation, and deterministic ordering.
- No central inference call or causal claim is introduced.

Out of scope: incident UI and model-generated summaries.
Quality gate: focused grouping tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


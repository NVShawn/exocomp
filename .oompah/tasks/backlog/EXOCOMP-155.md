---
id: EXOCOMP-155
type: task
status: Backlog
priority: 1
title: Implement incident health-transition rules
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-154
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:39.771394Z'
updated_at: '2026-07-30T14:21:00.575419Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Open health incidents after two consecutive degraded observations.
- Open immediately for stale/unreachable state and identity, authentication, audit, policy, or remediation failures.
- Open explicit cluster alerts and apply deterministic severity mapping.
- Auto-resolve health incidents after two consecutive healthy observations; reopen on new matching unhealthy evidence.

Acceptance:
- Table-driven reducer tests cover every rule, threshold boundary, interleaved target, duplicate observation, manual-resolution recurrence, and explicit resolve event.
- No model is used for opening, grouping, or resolving incidents.

Out of scope: operator acknowledgement and UI.
Quality gate: focused reducer tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


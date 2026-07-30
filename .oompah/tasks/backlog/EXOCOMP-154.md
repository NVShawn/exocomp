---
id: EXOCOMP-154
type: task
status: Backlog
priority: 1
title: Add incident records and deterministic fingerprints
parent: EXOCOMP-131
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:38.872090Z'
updated_at: '2026-07-30T14:15:38.872090Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add organization-scoped incident and incident-event schemas with open, acknowledged, and resolved states.
- Implement the fingerprint from organization, cluster, alert type, source, target type, and target identity.
- Upsert repeated evidence into one incident and preserve a correlated timeline.

Acceptance:
- Tests cover identical alerts, distinct targets, distinct organizations, concurrent opens, resolved recurrence, and event ordering.
- Fingerprints are stable and contain no secret/raw-log data.

Out of scope: health thresholds and operator workflow mutations.
Quality gate: focused incident tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


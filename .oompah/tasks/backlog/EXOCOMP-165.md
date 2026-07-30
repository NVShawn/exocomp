---
id: EXOCOMP-165
type: task
status: Backlog
priority: 2
title: Build the fleet overview LiveView
parent: EXOCOMP-133
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:58.020040Z'
updated_at: '2026-07-30T14:16:58.020040Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Render cluster connectivity, health/severity counts, versions, node counts, labels, last contact, and open incident counts.
- Add organization-scoped filters and deterministic sorting.
- Subscribe to committed PubSub updates and update only affected rows.

Acceptance:
- LiveView tests cover empty/loading/error states, filters, sorting, connect/disconnect updates, health updates, and organization isolation.
- A disconnected cluster is visually distinct from a healthy connected cluster.
- Viewer access is read-only.

Out of scope: cluster detail and incident mutations.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


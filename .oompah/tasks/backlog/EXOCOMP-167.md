---
id: EXOCOMP-167
type: task
status: Backlog
priority: 2
title: Build the incident inbox and detail LiveViews
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-156
- EXOCOMP-157
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:01.826681Z'
updated_at: '2026-07-30T14:22:34.675267Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Add severity/status/cluster/label filters and pagination to the incident inbox.
- Add an incident timeline/detail view with evidence and related incidents.
- Add operator controls for acknowledge, assignment, snooze, and manual resolution with required reason.

Acceptance:
- LiveView tests cover filters, pagination, real-time open/reopen/resolve, each mutation, invalid transition, stale form, viewer denial, and organization isolation.
- Snoozed incidents remain queryable and display the wake time.

Out of scope: notifications and chat UI.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


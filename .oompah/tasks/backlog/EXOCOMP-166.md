---
id: EXOCOMP-166
type: task
status: Backlog
priority: 2
title: Build the cluster detail LiveView
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-152
- EXOCOMP-153
- EXOCOMP-154
start_blocked_by: &id001
- EXOCOMP-152
- EXOCOMP-155
labels: []
assignee: null
created_at: '2026-07-30T14:16:59.969604Z'
updated_at: '2026-07-30T21:40:41.719199Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Show cluster identity, labels, current nodes, capabilities, versions, health history summary, incidents, conversations, and recent audited actions.
- Add stable links to incident and conversation routes.
- Update node/connectivity/incident sections from PubSub after commit.

Acceptance:
- LiveView tests cover connected/disconnected clusters, mixed node health, missing history, pagination, updates, unknown ID, and organization isolation.
- No private certificate or secret field is rendered.

Out of scope: editing labels and starting chat.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


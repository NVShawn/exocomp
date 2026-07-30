---
id: EXOCOMP-169
type: task
status: Backlog
priority: 1
title: Add proposal controls and the action timeline
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-168
- EXOCOMP-162
- EXOCOMP-163
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:05.145960Z'
updated_at: '2026-07-30T14:22:44.072923Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Render proposal target, action, parameters, evidence age/hash, risk, disruption, rationale, policy result, and expiry.
- Add operator approve/deny controls bound to the context guards.
- Render decision, command delivery, execution, verification, and terminal artifacts as a correlated timeline.

Acceptance:
- LiveView tests cover allowed approval, denial, offline/expired/stale/terminal disabled states, concurrent decision conflict, viewer denial, execution failure, and verification failure.
- Approved is never displayed as executed until the execution event arrives.

Out of scope: changing proposal content.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


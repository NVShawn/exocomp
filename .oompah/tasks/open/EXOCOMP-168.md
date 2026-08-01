---
id: EXOCOMP-168
type: task
status: Open
priority: 2
title: Build the conversation and evidence LiveView
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-158
- EXOCOMP-160
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:03.450139Z'
updated_at: '2026-08-01T11:52:53.086034Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Render ordered operator/cluster messages, structured evidence cards, and queued/delivered/reasoning/completed/failed/expired state.
- Allow operators to send a bounded message when the cluster state permits it.
- Add retry/new-message affordances that create a new command rather than rewriting history.

Acceptance:
- LiveView tests cover message limit, online/offline state, duplicate update, failed/expired reasoning, evidence rendering, viewer read-only behavior, and organization isolation.
- Raw HTML, attachments, and arbitrary raw logs are not accepted or rendered.

Out of scope: proposal decision controls.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


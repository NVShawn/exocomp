---
id: EXOCOMP-151
type: task
status: Backlog
priority: 1
title: Report command results without duplicate execution
parent: EXOCOMP-130
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:08.095148Z'
updated_at: '2026-07-30T14:15:08.095148Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Add coordinator handling for command IDs, expiry, schema validation, and durable terminal result events.
- Reuse existing task/replay boundaries so receiving the same command twice cannot run its handler twice.
- Acknowledge receipt separately from completion and correlate terminal status to the original command.

Acceptance:
- Tests cover duplicate delivery before and after restart, expired command, unsupported kind, handler crash, completed result replay, and correlation fields.
- Receipt acknowledgement never implies successful execution.

Out of scope: specific chat and remedy handlers.
Quality gate: focused coordinator tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


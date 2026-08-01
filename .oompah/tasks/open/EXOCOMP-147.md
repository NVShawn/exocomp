---
id: EXOCOMP-147
type: task
status: Open
priority: 1
title: Add heartbeat, disconnect detection, and reconnect backoff
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-146
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:03.538393Z'
updated_at: '2026-08-01T11:48:58.753890Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Send a cluster heartbeat every 30 seconds through the active session.
- Mark a session disconnected after 90 seconds without a valid heartbeat.
- Reconnect with full-jitter exponential backoff from one second to 60 seconds.
- Reset backoff only after a stable authenticated connection.

Acceptance:
- Deterministic clock/randomness tests cover heartbeat cadence, missed heartbeats, reconnect bounds, reset, and duplicate timers.
- Connection loss does not crash the coordinator or block local work.
- Mission Control publishes connected/disconnected state only after committing it.

Out of scope: event persistence and UI.
Quality gate: focused state-machine tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


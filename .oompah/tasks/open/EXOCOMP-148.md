---
id: EXOCOMP-148
type: task
status: Open
priority: 1
title: Persist the coordinator event outbox
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-145
- EXOCOMP-139
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:04.648480Z'
updated_at: '2026-08-01T11:49:00.678192Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Add a durable coordinator event outbox under /var/lib/exocomp-coordinator with monotonic per-cluster sequence allocation and stable event IDs.
- Persist before send and delete only after a committed contiguous acknowledgement.
- Permit replacement of an older unsent status snapshot only; never discard alert, chat, proposal, approval, action, or audit events.
- Enforce schema, size, and redaction checks before persistence.

Acceptance:
- Tests cover process restart, host-state reopen, duplicate enqueue, snapshot coalescing, full/corrupt storage, and acknowledgement.
- Durable event kinds survive reconnect without loss.

Out of scope: server ingestion and command delivery.
Quality gate: focused persistence tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


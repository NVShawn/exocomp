---
id: EXOCOMP-149
type: task
status: Backlog
priority: 1
title: Ingest cluster events idempotently and acknowledge sequences
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-138
- EXOCOMP-139
- EXOCOMP-146
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:06.077566Z'
updated_at: '2026-07-30T14:20:27.051674Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Validate incoming event envelopes against the negotiated schema version and authenticated cluster identity.
- Commit accepted events and a per-cluster sequence cursor transactionally.
- Deduplicate by organization, cluster, and event ID; identify sequence gaps without accepting identity overrides.
- Return the highest contiguous committed sequence as the acknowledgement.

Acceptance:
- Contract tests cover duplicates, replay, out-of-order delivery, gaps, invalid payloads, oversized payloads, unsupported versions, and transaction rollback.
- An acknowledgement is never sent for an uncommitted event.

Out of scope: reducing events into fleet/incidents.
Quality gate: focused ingestion tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


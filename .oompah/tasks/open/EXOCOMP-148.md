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
updated_at: '2026-08-01T12:17:24.730191Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-148
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: f59fe47a4d808fae3f7bde52d11c9cebc550871a749779803f03f675c00a91dd
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: f5e1f5cb-54b4-48ca-9009-3530b9895ade
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:17:16.087911+00:00'
  claim_expires_at: '2026-08-01T12:47:16.087911+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: dd89db7b-0de3-4f23-b9e7-bfde014376d8
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-148
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-148
  base_branch: epic-EXOCOMP-130
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:17:22.047141+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:17
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:17
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

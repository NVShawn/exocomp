---
id: EXOCOMP-149
type: task
status: Open
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
updated_at: '2026-08-01T12:22:45.178612Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-149
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: bc4016ff4d611f0eb6ae1e60f884ca1c34eec279f8ede0c7e359de80c954461d
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 22dd16e8-f92a-4a76-ae06-4e0c734a6594
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:22:36.688484+00:00'
  claim_expires_at: '2026-08-01T12:52:36.688484+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 2bdb82fc-321f-411e-8584-bc81ce8634eb
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-149
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-149
  base_branch: epic-EXOCOMP-130
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:22:42.872517+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:22
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:22
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

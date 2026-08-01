---
id: EXOCOMP-194
type: task
status: Open
priority: 2
title: Define desired-service status events and contract fixtures
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-139
- EXOCOMP-193
labels: []
assignee: null
created_at: '2026-07-30T21:37:04.090360Z'
updated_at: '2026-08-01T16:02:57.596384Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-194
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 326449b4ff80a5a30ebd03bc178761927d5a1837f71ab3b9353cba3547843a04
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 8bed51f7-fa19-4499-a20a-373dfa405fc0
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T16:02:50.353653+00:00'
  claim_expires_at: '2026-08-01T16:32:50.353653+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 3df47a76-33d8-4d6d-a600-ace4d266f818
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-194
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-194
  base_branch: epic-EXOCOMP-185
  base_sha: 7b3ff4a831259ec5555de09214348b3da5eb554e
  updated_at: '2026-08-01T16:02:55.607305+00:00'
---
## Summary

Plan: plans/mission-control.md, connection protocol and fleet status.

Deliverable: Extend the versioned Mission Control protocol with bounded desired-state changes, service-status changes, profile coverage, and periodic service summary snapshots.

Acceptance criteria:
- Events carry node, unit, source set, health depth, recovery authority, observation time, evidence references, and correlation ID.
- Initial snapshot plus deltas reconstruct the current view idempotently.
- Payloads are size-bounded, redacted, and forward-version checked.
- Duplicate and out-of-order fixtures define deterministic behavior.
- Shared fixtures are consumable by coordinator and Mission Control tests.

Tests: Add encode/decode, schema rejection, bounds, redaction, duplicate, ordering, and reconstruction tests; run make test.

Out of scope: Database migrations, incident reduction, LiveView rendering, and Ceph collection.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 16:02
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 16:02
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

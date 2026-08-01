---
id: EXOCOMP-203
type: task
status: Open
priority: 1
title: Connect failed Ceph daemons to the safe recovery flow
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-193
- EXOCOMP-200
- EXOCOMP-202
labels: []
assignee: null
created_at: '2026-07-30T21:38:34.423102Z'
updated_at: '2026-08-01T14:19:17.771805Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-203
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 50e3cfe1229a9a004ca1117c3c77b32d22d97536c22ea524cf16d1341f588a85
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: c9caae2a-feb8-4059-a54c-ec6a47f6ddfd
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:19:10.752735+00:00'
  claim_expires_at: '2026-08-01T14:49:10.752735+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: dbf5507d-e0a6-4315-818c-2bdf0f58811e
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-203
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-203
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:19:15.918983+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph safe daemon restart.

Deliverable: Allow the coordinator to propose the profile action restart_failed_daemon for one already-failed expected Ceph daemon.

Acceptance criteria:
- Require fresh node state, fresh Ceph health/topology evidence, exact node/daemon mapping, and shipped Ceph profile authority.
- Reuse existing task correlation, idempotency, durable audit-before-action, one-attempt, and per-target locking boundaries.
- Automatic-mode discovery alone cannot authorize the action.
- Active or merely degraded daemons, unsupported profiles, stale evidence, and coverage gaps do not execute.
- Invoke only the restricted profile helper action.

Tests: Cover allowed failed daemon, active daemon, stale evidence, mapping change, unsupported node, concurrent requests, replay, and helper rejection; run make test.

Out of scope: Active-daemon restart, failover, maintenance flags, OSD changes, and PG repair.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:19
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:19
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

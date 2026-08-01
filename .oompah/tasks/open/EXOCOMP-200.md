---
id: EXOCOMP-200
type: task
status: Open
priority: 1
title: Reduce Ceph evidence into cluster and daemon health
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-199
labels: []
assignee: null
created_at: '2026-07-30T21:38:25.539449Z'
updated_at: '2026-08-01T14:12:45.990556Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-200
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 946d42eaaec9825a35a0c808c9ec0e3b5b6a93248a8f532288781895a6061bdc
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: e6ddc5cd-0e89-443c-81f1-ac6939ebc7b5
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:12:36.899738+00:00'
  claim_expires_at: '2026-08-01T14:42:36.899738+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 607b0ac7-b56a-4c99-95b7-30162cd6bb3c
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-200
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-200
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:12:43.715403+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph cluster health.

Deliverable: Convert fresh Ceph CLI evidence, topology mappings, and node observations into profile, coverage, and daemon health states.

Acceptance criteria:
- HEALTH_OK maps to healthy, HEALTH_WARN to degraded, and HEALTH_ERR to critical.
- Missing credentials, stale evidence, incomplete coverage, and ambiguous topology have distinct reasons.
- Required daemon units are healthy only when their expected systemd state and applicable profile evidence pass.
- Results contain bounded evidence references and deterministic severity.

Tests: Add table-driven tests for health levels, stale and partial evidence, missing daemons, unreachable nodes, unsupported profile versions, and recovery to healthy; run make test.

Out of scope: Mission Control incident records, UI, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:12
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:12
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

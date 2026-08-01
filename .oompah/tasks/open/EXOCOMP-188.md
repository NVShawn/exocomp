---
id: EXOCOMP-188
type: task
status: Open
priority: 1
title: Add coordinator inventory v2 service-monitoring fields
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-187
labels: []
assignee: null
created_at: '2026-07-30T21:36:57.890248Z'
updated_at: '2026-08-01T13:38:34.391464Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-188
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 5fa601cce56f09b943a2e26288b42b8f33455297aa6fe6b4929200cf4e5b26b9
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: ea6e169b-b68f-4ba6-841b-80a2e2de59a9
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:38:26.117372+00:00'
  claim_expires_at: '2026-08-01T14:08:26.117372+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: e4bb9bc2-e9d1-4d98-8592-dce3fac76cc5
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-188
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-188
  base_branch: epic-EXOCOMP-185
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:38:32.358958+00:00'
---
## Summary

Plan: plans/mission-control.md, three-path desired-state extension.

Deliverable: Extend the coordinator inventory parser with optional per-node manual service entries, optional automatic-mode enablement, and a root cluster-profile declaration.

Acceptance criteria:
- Version 2 validates exact .service names, boolean automatic enablement, and loopback HTTP health checks.
- Version 1 inventories still load with empty monitoring and profile defaults.
- Invalid replacements leave the active inventory unchanged and emit the existing rejection audit path.
- Parsed values are available through typed inventory structures.

Tests: Add focused parser tests for valid v1/v2 files and malformed names, URLs, booleans, profiles, duplicates, and atomic rejection; run make test.

Out of scope: Polling, systemd collection, Ceph logic, and Mission Control persistence.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:38
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:38
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

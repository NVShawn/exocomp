---
id: EXOCOMP-191
type: task
status: Open
priority: 1
title: Implement bounded read-only service observation
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-188
labels: []
assignee: null
created_at: '2026-07-30T21:37:01.048654Z'
updated_at: '2026-08-01T13:53:00.299804Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-191
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e3d50cc86992b2cc8acffc306a4cbabaabe5ea5be3e0a90fc80a66583e552ea1
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 0256befb-51a8-4320-84c7-69ee65b8a8e5
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:52:51.921951+00:00'
  claim_expires_at: '2026-08-01T14:22:51.921951+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: d597f579-4975-4229-8cf3-efe130b32112
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-191
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-191
  base_branch: epic-EXOCOMP-185
  base_sha: 6742aa13ef4dc7e3dafa1582cebb5e4550ba9a72
  updated_at: '2026-08-01T13:52:58.536988+00:00'
---
## Summary

Plan: plans/mission-control.md, manual and reconciled service observation.

Deliverable: Add the exocomp.service.observe node skill for strictly validated coordinator-selected unit names.

Acceptance criteria:
- Query systemd through fixed argv for exact validated .service names.
- Optionally execute only validated loopback HTTP probes supplied by desired state.
- Return systemd and probe evidence with timestamps, partial errors, and collector versions.
- Enforce service-count, response-size, and timeout limits.
- The skill cannot execute, enable, disable, or restart a unit and does not alter the recovery allow-list.

Tests: Cover valid observations, invalid names, non-loopback URLs, mixed partial results, timeout, and bounded responses; run make test.

Out of scope: Desired-state merging, scheduling, remediation, and Ceph-specific health.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:52
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:53
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

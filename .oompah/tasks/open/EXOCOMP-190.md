---
id: EXOCOMP-190
type: task
status: Open
priority: 1
title: Implement enabled long-running systemd service discovery
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-187
labels: []
assignee: null
created_at: '2026-07-30T21:37:00.068929Z'
updated_at: '2026-08-01T13:46:02.973799Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-190
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: efeecae4d6a578a0eabde567f98eca502fb2e14c34dc6df060c7ebb67e9012f4
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 80de4583-d2d2-4f81-9db2-4b5a2f67c748
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:45:54.985387+00:00'
  claim_expires_at: '2026-08-01T14:15:54.985387+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 817ae23f-78ad-42be-b8b0-c88725df78ef
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-190
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-190
  base_branch: epic-EXOCOMP-185
  base_sha: 6742aa13ef4dc7e3dafa1582cebb5e4550ba9a72
  updated_at: '2026-08-01T13:46:00.810756+00:00'
---
## Summary

Plan: plans/mission-control.md, automatic service path.

Deliverable: Add the read-only exocomp.service.inventory node skill using fixed systemctl argv and bounded output.

Acceptance criteria:
- Return enabled and enabled-runtime service units with Type, RemainAfterExit, condition result, load state, active state, and substate.
- Exclude completed oneshots, static, indirect, disabled, masked, generated units, and exocomp-node.service from the expected-running set.
- Mark a failed systemd condition as not_applicable.
- Validate output size and timeout each subprocess without invoking a shell.

Tests: Use injected command fixtures for every included and excluded state, timeout, malformed output, and output truncation; run make test.

Out of scope: Scheduling discovery, health incidents, application probes, and restart behavior.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:45
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:46
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-187
type: task
status: Open
priority: 1
title: Integrate the three-path desired-state design into project plans
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:36:56.896701Z'
updated_at: '2026-08-01T13:35:36.090262Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-187
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 7ba81767a3816b7642f4cad590e60195b0783b20b33d3683145a36be9e467816
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: fd57c306-3133-4af9-9304-a19379847225
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:35:15.596595+00:00'
  claim_expires_at: '2026-08-01T14:05:15.596595+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: af05c419-64a8-4010-82a1-384447caa16a
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-187
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-187
  base_branch: epic-EXOCOMP-185
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:35:34.100761+00:00'
---
## Summary

Plan: plans/mission-control.md.

Deliverable: Update the internal roadmap documents so manual host services, automatic enabled-service discovery, and coordinator-declared cluster profiles form one coherent design.

Acceptance criteria:
- plans/exocomp.md summarizes all three paths.
- Milestone 2 owns inventory, discovery, and reconciliation behavior.
- Milestone 4 owns profile-authorized safe recovery.
- Mission Control owns reporting, persistence, incidents, and UI but not desired-state authority.
- The documents state that broader Ceph repairs remain a separate roadmap.

Tests: Run make check-links and make test-compliance.

Out of scope: Source-code, configuration-template, or tracker changes beyond documenting the approved design.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:35
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:35
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

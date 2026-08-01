---
id: EXOCOMP-201
type: task
status: Open
priority: 1
title: Implement the restricted profile-action helper
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-195
labels: []
assignee: null
created_at: '2026-07-30T21:38:30.593722Z'
updated_at: '2026-08-01T14:14:33.692278Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-201
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b8ce017944128249b205044439d160a5a29da009a085f6b671c4e3e05e5b4fc0
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 6a6b44af-4725-425a-974a-c137739ad9d2
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:14:25.916288+00:00'
  claim_expires_at: '2026-08-01T14:44:25.916288+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 2d44a59d-e4ad-4406-8b98-41baec5f4e88
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-201
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-201
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:14:31.705137+00:00'
---
## Summary

Plan: plans/mission-control.md, profile recovery authority.

Deliverable: Add a small compiled privileged helper with a versioned bounded stdin protocol and no command-line arguments.

Acceptance criteria:
- Accept only shipped profile IDs, typed action IDs, and strictly validated target unit names.
- Ceph v1 supports only restart_failed_daemon for recognized Ceph unit forms.
- Recheck that the target unit is loaded and already inactive or failed before executing fixed systemctl argv.
- Reject active units, unknown actions, oversized input, extra fields, malformed encoding, and shell metacharacters.
- Never invoke a shell or accept an arbitrary executable or argument list.

Tests: Add parser and validator unit tests plus negative tests for injection, malformed requests, active units, non-Ceph units, timeout, and subprocess failure; run the focused Make gate added by the task.

Out of scope: Installer integration, coordinator policy, broad Ceph repair, and Mission Control.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:14
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:14
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

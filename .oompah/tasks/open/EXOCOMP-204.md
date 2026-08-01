---
id: EXOCOMP-204
type: task
status: Open
priority: 1
title: Verify Ceph daemon recovery and enforce cooldown
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-203
labels: []
assignee: null
created_at: '2026-07-30T21:38:35.429036Z'
updated_at: '2026-08-01T14:23:05.167417Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-204
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 3e99057735e10ebc0c5d1b5ea865ae72cb710621461de11f8556886ec883f18f
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: cefe410f-43ce-49e9-a032-1346091e2db0
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:22:57.313677+00:00'
  claim_expires_at: '2026-08-01T14:52:57.313677+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 67ef4cb6-030c-4966-b7ce-ee95ad215c1f
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-204
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-204
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:23:02.998547+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph recovery verification.

Deliverable: Add post-action verification and terminal audit behavior for the safe Ceph daemon restart.

Acceptance criteria:
- Recollect systemd and Ceph evidence after execution and across the configured stability window.
- Complete only when the daemon is running, mapped to the same topology identity, and cluster evidence is no worse.
- Verification failure enters cooldown and cannot trigger a second automatic restart in the same episode.
- Node or coordinator restart reconciles durable execution state without repeating the action.
- Emit correlated completed, failed, verification_failed, and cooldown evidence.

Tests: Cover successful recovery, systemd-only recovery, worsened Ceph health, identity change, flapping, process restart, cooldown expiry, and audit failure; run make test.

Out of scope: Mission Control rendering and additional Ceph repair actions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:22
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:23
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

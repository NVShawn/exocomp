---
id: EXOCOMP-198
type: task
status: Open
priority: 1
title: Discover local traditional and cephadm daemon units
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-195
labels: []
assignee: null
created_at: '2026-07-30T21:38:22.833355Z'
updated_at: '2026-08-01T14:08:27.887875Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-198
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: a1c4524f266cfc8ab1e3d92da119a2446f06f3b64a73bc80984d16d2539a6b6f
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: ce524d21-aaf1-4f8d-86fd-f9b0e9e5b649
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:08:18.897012+00:00'
  claim_expires_at: '2026-08-01T14:38:18.897012+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 28ffff43-d892-43db-aef1-7e4c0f44aad6
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-198
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-198
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:08:25.469099+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph node discovery.

Deliverable: Implement the Ceph branch of exocomp.profile.inspect using fixed systemd queries.

Acceptance criteria:
- Recognize shipped patterns for traditional and cephadm monitor, manager, OSD, MDS, and gateway units.
- Return daemon kind, daemon ID, unit, FSID when available, enablement, load state, active state, and substate.
- A supported node with no Ceph installation reports not_member rather than an error.
- Strict parsing, timeouts, and output bounds prevent arbitrary unit or command injection.

Tests: Use fixtures for traditional units, cephadm units, mixed installations, no installation, malformed names, timeout, and truncated output; run make test.

Out of scope: Coordinator topology matching, cluster health policy, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:08
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:08
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

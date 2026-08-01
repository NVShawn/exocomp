---
id: EXOCOMP-206
type: task
status: Open
priority: 2
title: Qualify three-path monitoring and Ceph safe restart in VMs
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-194
- EXOCOMP-204
- EXOCOMP-205
- EXOCOMP-155
- EXOCOMP-166
labels: []
assignee: null
created_at: '2026-07-30T21:38:38.730648Z'
updated_at: '2026-08-01T16:27:13.782799Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-206
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 7fc75c750443fd7bdaa314519d5f0f6f6909f7086dd125a5f6b394535b03b490
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: a7428f8e-3d51-42fa-969a-7d25dda0d894
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T16:27:04.823397+00:00'
  claim_expires_at: '2026-08-01T16:57:04.823397+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 99bfbc6c-9522-435b-a1a9-60e7a58f381b
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-206
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-206
  base_branch: epic-EXOCOMP-186
  base_sha: 9bd56928c896865de00d10a1f168bcbbaa9abdc9
  updated_at: '2026-08-01T16:27:11.211583+00:00'
---
## Summary

Plan: plans/mission-control.md, desired-state and Ceph qualification.

Deliverable: Add a disposable VM qualification scenario covering manual, automatic, and cluster-derived service expectations plus one safe failed Ceph daemon restart.

Acceptance criteria:
- Declare the Ceph profile once on the coordinator and do not maintain per-node Ceph service lists.
- Discover roles across a three-node Ceph cluster and report complete coverage.
- Demonstrate manual and automatic expectations composing with Ceph-derived expectations.
- Fail one expected daemon, open one deduplicated incident, restart exactly once, verify stable Ceph health, and record the full audit timeline.
- Exercise disconnect/replay without duplicate incidents or actions and qualify shipped helper artifacts on amd64 and arm64.

Tests: Add a Make target for the scenario and publish bounded qualification evidence using existing release conventions.

Out of scope: Performance soak and broad Ceph repair operations.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 16:27
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 16:27
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

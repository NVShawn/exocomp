---
id: EXOCOMP-183
type: task
status: Open
priority: 2
title: Add the Mission Control scale and soak qualification
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-165
- EXOCOMP-177
- EXOCOMP-180
- EXOCOMP-182
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:53.481557Z'
updated_at: '2026-08-01T15:51:10.760240Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-183
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 97a3e3d01c88265a4ca9802e4afe577642ac1e4aaba3d68a062229b16c1fcbfa
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 391d1fd6-dbc6-4393-8df1-7aa99eb46ab7
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:51:01.425366+00:00'
  claim_expires_at: '2026-08-01T16:21:01.425366+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 1b80a828-a2d3-460e-af8e-44c99385ba8d
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-183
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-183
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:51:08.737324+00:00'
---
## Summary

Plan: plans/mission-control.md, Test Strategy.

Deliverables:
- Build a deterministic load driver for 100 persistent clusters, 10,000 current nodes, and a burst of 100 events per second.
- Measure committed-event-to-LiveView p95 latency and event loss excluding local model inference.
- Run a four-hour soak and report connection count, BEAM processes/mailboxes, memory, file descriptors, database pool/queue, outbox depth, and webhook/retention workers.

Acceptance:
- p95 is under three seconds with zero event loss at the target load.
- Soak analysis finds no sustained unbounded growth after warm-up.
- Raw samples, summary, host profile, and exact artifact identity are retained.

Out of scope: performance optimization not required to meet the gate.
Quality gate: dedicated short and full Make targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:51
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:51
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-183
type: task
status: Backlog
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
updated_at: '2026-07-30T14:24:00.453930Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


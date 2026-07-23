---
id: EXOCOMP-38
type: chore
status: In Progress
priority: 2
title: Benchmark llama.cpp inference and restart behavior
parent: EXOCOMP-5
children: []
blocked_by:
- EXOCOMP-11
- EXOCOMP-35
labels: []
assignee: null
created_at: '2026-07-23T19:11:20.539713Z'
updated_at: '2026-07-23T22:41:11.269136Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7a8e2dad-7415-4ee3-a020-2052444bcc3d
oompah.work_branch: epic-EXOCOMP-5
---
## Summary

Plan: [Milestone 5 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-5-performance.md)

Goal
Benchmark llama.cpp inference and restart behavior.

Implementation
Measure verified model startup, readiness, RSS, sequential proposal latency, increasing concurrency through saturation, queue depth, timeout, invalid output, and crash/restart on amd64 and arm64; report model separately and as combined bundle.

Testing
Verify model and llama checksums; repeat fixed prompt/token workloads; capture token metrics, CPU/RSS, errors, queue time, restart time, and node diagnostic availability during model failure.

Acceptance Criteria
- [ ] Model results are reproducible for each host profile.
- [ ] Control-plane and model resources are not conflated.
- [ ] Saturation and timeout behavior remain bounded.
- [ ] Node diagnostics remain available through llama restart.
- [ ] Raw and summary reports are complete.

Quality Gate
Run the focused benchmark tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:41
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:41
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

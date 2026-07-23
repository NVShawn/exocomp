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
updated_at: '2026-07-23T22:43:15.849354Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d4c332a4-925b-4d31-a9c6-4c36394a7faa
oompah.work_branch: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 767083
  total_output_tokens: 3440
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 767083
      output_tokens: 3440
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 767083
    output_tokens: 3440
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:42:56.708834+00:00'
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
author: oompah
created: 2026-07-23 22:42
---
Agent completed successfully in 109s (770523 tokens)
---
author: oompah
created: 2026-07-23 22:42
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 11
- Tokens: 767.1K in / 3.4K out [770.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 49s
- Log: EXOCOMP-38__20260723T224111Z.jsonl
---
author: oompah
created: 2026-07-23 22:43
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-5`. Escalating from 'default' to 'quick'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 22:43
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-23 22:43
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-55
type: task
status: In Progress
priority: null
title: Implement BEAM telemetry sampler
parent: EXOCOMP-35
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:37:10.989869Z'
updated_at: '2026-07-23T21:52:37.293421Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: e801c5b4-a6ad-4a25-b556-cf4f8b9b4012
oompah.work_branch: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 727847
  total_output_tokens: 5083
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 727847
      output_tokens: 5083
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 361771
    output_tokens: 2262
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:50:42.002711+00:00'
  - profile: standard
    model: unknown
    input_tokens: 366076
    output_tokens: 2821
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:52:33.298617+00:00'
---
## Summary

In apps/bench, implement Bench.BeamSampler — a GenServer that polls BEAM runtime metrics at a configurable interval and appends Bench.Sample entries to an accumulator. Metrics to collect via :erlang built-ins: scheduler utilisation (:erlang.statistics(:scheduler_wall_time)), total process count (:erlang.system_info(:process_count)), run queue length (:erlang.statistics(:run_queue)), mailbox depths for a named list of registered processes (Process.info(pid, :message_queue_len)), memory categories (:erlang.memory/0), and task-registry size (if accessible via Exocomp.Registry or similar). Implement: Bench.BeamSampler.start_link/1, Bench.BeamSampler.stop/1, Bench.BeamSampler.flush/1 (returns accumulated samples). Test: starts and stops cleanly, produces samples with expected metric names, mailbox depth increases when a process receives messages without flushing, scheduler utilisation is a float in [0.0, 1.0]. Reference: plans/milestone-5-performance.md (Measurement Architecture section).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:49
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:50
---
Agent completed successfully in 70s (364033 tokens)
---
author: oompah
created: 2026-07-23 21:50
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 7
- Tokens: 361.8K in / 2.3K out [364.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 10s
- Log: EXOCOMP-55__20260723T214935Z.jsonl
---
author: oompah
created: 2026-07-23 21:50
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-35`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:51
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:51
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:52
---
Agent completed successfully in 94s (368897 tokens)
---
author: oompah
created: 2026-07-23 21:52
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 6
- Tokens: 366.1K in / 2.8K out [368.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 34s
- Log: EXOCOMP-55__20260723T215100Z.jsonl
---
author: oompah
created: 2026-07-23 21:52
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-35`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
<!-- COMMENTS:END -->

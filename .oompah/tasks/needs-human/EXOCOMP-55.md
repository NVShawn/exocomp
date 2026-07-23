---
id: EXOCOMP-55
type: task
status: Needs Human
priority: null
title: Implement BEAM telemetry sampler
parent: EXOCOMP-35
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:37:10.989869Z'
updated_at: '2026-07-23T21:55:04.043067Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d8dd5213-b29c-48ef-985a-27dcb88f746f
oompah.work_branch: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 1327571
  total_output_tokens: 9452
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1327571
      output_tokens: 9452
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
  - profile: deep
    model: unknown
    input_tokens: 599724
    output_tokens: 4369
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:55:00.498033+00:00'
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
author: oompah
created: 2026-07-23 21:53
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 21:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:55
---
Agent completed successfully in 118s (604093 tokens)
---
author: oompah
created: 2026-07-23 21:55
---
Run #3 [attempt=3, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 12
- Tokens: 599.7K in / 4.4K out [604.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 58s
- Log: EXOCOMP-55__20260723T215306Z.jsonl
---
author: oompah
created: 2026-07-23 21:55
---
Agent completed 3 times without closing this issue. Human action required: review the agent run history and task state, then either close the task if the work is done or add specific guidance and move it back to Open.
---
<!-- COMMENTS:END -->

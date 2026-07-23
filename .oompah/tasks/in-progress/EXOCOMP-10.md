---
id: EXOCOMP-10
type: feature
status: In Progress
priority: 1
title: Implement Linux and systemd diagnostic collectors
parent: EXOCOMP-1
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T19:08:55.388617Z'
updated_at: '2026-07-23T20:52:15.409592Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 8d9a5373-7113-48d5-b9d1-1a369da23dcd
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 383893
  total_output_tokens: 2791
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 383893
      output_tokens: 2791
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 383893
    output_tokens: 2791
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:43:05.836482+00:00'
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Implement Linux and systemd diagnostic collectors.

Implementation
Implement versioned CPU, memory, disk, uptime, and allow-listed systemd service collectors using /proc, /sys, filesystem APIs, and argv-only systemctl show; add explicit units, timestamps, partial errors, output limits, and timeouts; never use a shell.

Testing
Use fixture proc/sys files and stubbed process execution to test valid, partial, malformed, unavailable, timeout, large-output, and all relevant service states.

Acceptance Criteria
- [ ] Collectors return bounded versioned observations with explicit units.
- [ ] Partial failures preserve successful measurements.
- [ ] No caller or model input becomes a shell command or arbitrary service.
- [ ] Focused collector tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:41
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:41
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:43
---
Agent completed successfully in 90s (386684 tokens)
---
author: oompah
created: 2026-07-23 20:43
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 17
- Tokens: 383.9K in / 2.8K out [386.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 30s
- Log: EXOCOMP-10__20260723T204138Z.jsonl
---
author: oompah
created: 2026-07-23 20:43
---
Agent completed without closing this issue (90s (386684 tokens)). Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 20:52
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:52
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-53
type: task
status: In Progress
priority: null
title: Implement pinned amd64 and arm64 host profiles
parent: EXOCOMP-35
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:36:53.820999Z'
updated_at: '2026-07-23T21:32:56.121464Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 6f5eb836-f78a-4b2f-9c71-dde5f3d47627
oompah.work_branch: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 365426
  total_output_tokens: 2852
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 365426
      output_tokens: 2852
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 365426
    output_tokens: 2852
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:32:37.200791+00:00'
---
## Summary

In apps/bench, implement Bench.HostProfile — a module defining the static reference host profiles for amd64 and arm64, plus runtime host detection and compatibility enforcement. Each profile records: architecture, CPU model/count, RAM, kernel version, Linux distribution, libc version, power/performance governor, and container/VM boundary. Implement: Bench.HostProfile.detect/0 to detect the current host, Bench.HostProfile.load/1 to load a named profile from config, Bench.HostProfile.compatible?/2 to verify two profiles are comparable (same arch required; raise if not). Ship two reference profile YAML/TOML files: priv/bench/profiles/amd64-ci.toml and priv/bench/profiles/arm64-ci.toml. Test cases: detect returns a well-formed struct, compatible? returns false for amd64 vs arm64, incompatible profiles produce descriptive errors, missing profile file returns {:error, :not_found}. Reference: plans/milestone-5-performance.md (Benchmark Environments section).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:31
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:31
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:32
---
Agent completed successfully in 97s (368278 tokens)
---
author: oompah
created: 2026-07-23 21:32
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 10
- Tokens: 365.4K in / 2.9K out [368.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 37s
- Log: EXOCOMP-53__20260723T213102Z.jsonl
---
author: oompah
created: 2026-07-23 21:32
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-35`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:32
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:32
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

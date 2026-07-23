---
id: EXOCOMP-50
type: task
status: In Progress
priority: null
title: Scaffold the bench Mix app within the Elixir umbrella
parent: EXOCOMP-35
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T20:36:33.686028Z'
updated_at: '2026-07-23T20:53:56.564406Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 55f69cb3-aa9c-4c57-b468-9cafa7d8e31d
oompah.work_branch: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 401466
  total_output_tokens: 7519
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 401466
      output_tokens: 7519
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 24
    output_tokens: 4806
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:51:48.934766+00:00'
  - profile: standard
    model: unknown
    input_tokens: 401442
    output_tokens: 2713
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:53:38.030903+00:00'
---
## Summary

Create the apps/bench Mix application within the existing Elixir umbrella repository (established by EXOCOMP-7). Set up mix.exs with library dependencies (Jason for JSON, NimbleOptions or similar for config validation), ExUnit test configuration, and the top-level module skeleton. Establish the directory layout that all subsequent harness tasks will build into: lib/bench/, lib/bench/config.ex, lib/bench/sample.ex, lib/bench/sampler/, lib/bench/report/, lib/bench/driver.ex. Add the app to the umbrella apps/ list and verify it compiles and the empty test suite passes. Reference: plans/milestone-5-performance.md (Measurement Architecture section).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:50
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:51
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-50 is a unique task with no overlapping scope in the project.

**Evidence reviewed:**
- EXOCOMP-7 (Done): Scaffolded the Elixir umbrella with core/protocol, node, and coordinator apps — does NOT create apps/bench
- EXOCOMP-35 (parent): 'Build the reproducible benchmark harness' — EXOCOMP-50 is explicitly listed as its first child (the scaffold step)
- EXOCOMP-52–56: Other children of EXOCOMP-35 that implement specific features (config schema, host profiles, raw sample model, BEAM sampler, host sampler) — all depend on apps/bench existing first (EXOCOMP-50)
- EXOCOMP-36–40: M5 workload benchmark tasks that USE the harness but do not BUILD it
- EXOCOMP-5 (parent epic): M5 Performance — confirms EXOCOMP-35 is the harness builder and EXOCOMP-50 is its scaffold child
- Searched codebase: apps/ directory does not yet contain a bench app; plans/milestone-5-performance.md confirms bench as the harness application namespace

**Key finding:** EXOCOMP-50 is the unique scaffold task that creates apps/bench — it is the prerequisite for EXOCOMP-52, 53, 54, 55, 56 (all build within the bench app created here). No existing task covers this scope.

**Remaining work:**
- Create apps/bench as a new Mix application in the Elixir umbrella
- Set up mix.exs with Jason and NimbleOptions dependencies
- Create directory structure: lib/bench/, lib/bench/config.ex, lib/bench/sample.ex, lib/bench/sampler/, lib/bench/report/, lib/bench/driver.ex
- Add module skeleton to each file
- Verify compilation and empty test suite passes (make test)
- Register the app in the umbrella

**Risks:**
- EXOCOMP-52–56 are blocked until this scaffold is complete
- Must match umbrella conventions established in EXOCOMP-7 (Elixir 1.20/OTP 28, digest-pinned builder, containerized Make targets)

**Recommended next focus:** feature (or chore) — this is a scaffolding task that creates the Elixir bench Mix application from scratch within the existing umbrella
---
author: oompah
created: 2026-07-23 20:51
---
Agent completed successfully in 109s (4830 tokens)
---
author: oompah
created: 2026-07-23 20:51
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 45, Tool calls: 33
- Tokens: 24 in / 4.8K out [4.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 49s
- Log: EXOCOMP-50__20260723T205003Z.jsonl
---
author: oompah
created: 2026-07-23 20:51
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 20:52
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 20:52
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 20:53
---
Agent completed successfully in 79s (404155 tokens)
---
author: oompah
created: 2026-07-23 20:53
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 8
- Tokens: 401.4K in / 2.7K out [404.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 19s
- Log: EXOCOMP-50__20260723T205220Z.jsonl
---
author: oompah
created: 2026-07-23 20:53
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-35`. Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-35
type: feature
status: Backlog
priority: 2
title: Build the reproducible benchmark harness
parent: EXOCOMP-5
children:
- EXOCOMP-50
- EXOCOMP-52
- EXOCOMP-53
blocked_by:
- EXOCOMP-7
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:11:17.553654Z'
updated_at: '2026-07-23T20:36:53.853814Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: b0118804-a2fd-4232-a260-ad9ed3743941
oompah.work_branch: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 27
  total_output_tokens: 5105
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 27
      output_tokens: 5105
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 27
    output_tokens: 5105
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:26:42.677232+00:00'
---
## Summary

Plan: [Milestone 5 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-5-performance.md)

Goal
Build the reproducible benchmark harness.

Implementation
Implement versioned benchmark definitions, pinned amd64/arm64 host profiles, warm-up/run/repetition controls, process/cgroup attribution, BEAM and host sampling, raw sample schema, summary generation, baseline comparison, and short/full Make targets.

Testing
Test configuration validation, synthetic CPU/memory loads, process attribution, missing metrics, percentile calculations, threshold direction, incompatible profiles, deterministic summaries, and non-zero regression exit.

Acceptance Criteria
- [ ] Harness records build, host, model, workload, and raw metadata.
- [ ] Node/coordinator/llama processes are attributed separately.
- [ ] Invalid or incomparable runs are rejected.
- [ ] Regression failures return non-zero with exact metric details.
- [ ] Harness tests pass.

Quality Gate
Run the focused benchmark tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:24
---
Understanding (Duplicate Investigator): I am screening EXOCOMP-35 ('Build the reproducible benchmark harness') for duplicates before any implementation begins. The issue asks for: versioned benchmark definitions, pinned host profiles, warm-up/run/repetition controls, process/cgroup attribution, BEAM and host sampling, raw sample schema, summary generation, baseline comparison, and Make targets. I will now search the task tracker and project docs for any existing tasks covering the same ground.
---
author: oompah
created: 2026-07-23 20:26
---
Discovery (Duplicate Investigator): Searched the full task tracker and project docs for any existing task covering the same scope as EXOCOMP-35 ('Build the reproducible benchmark harness'). Reviewed all Milestone 5 children (EXOCOMP-36 through EXOCOMP-40) and the parent epic (EXOCOMP-5). Closest candidates: EXOCOMP-36 (node idle/diagnostic workloads), EXOCOMP-37 (coordinator polling benchmarks), EXOCOMP-38 (llama inference benchmarks), EXOCOMP-39 (soak benchmarks), EXOCOMP-40 (publish baselines) — all of these USE the harness but none BUILD the harness infrastructure itself. No duplicate exists. EXOCOMP-35 is the unique task for harness construction (versioned benchmark definitions, host profiles, sampling, schema, summary generation, baseline comparison, Make targets).
---
author: oompah
created: 2026-07-23 20:26
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-35 is a unique task with no overlapping implementation in the project.

**Evidence reviewed:**
- EXOCOMP-5 (parent epic: M5 Performance and resource analysis) — confirms EXOCOMP-35 is the designated harness-builder child
- EXOCOMP-36 through EXOCOMP-40 — all M5 siblings that use the harness; none build harness infrastructure
- Milestone 5 design (plans/milestone-5-performance.md) — describes the harness as distinct from the workload benchmark tasks
- Earlier milestones (M1-M4 tasks, EXOCOMP-7 through EXOCOMP-34) — focused on Elixir scaffold, protocol, coordinator, node, safety, recovery; no harness infrastructure
- M6 tasks (EXOCOMP-41 through EXOCOMP-47) — licensing, release, docs; no overlap

**Remaining work:**
- Implement versioned benchmark definitions (config schema + validation)
- Pinned amd64/arm64 host profiles
- Warm-up/run/repetition controls
- Process/cgroup attribution for node, coordinator, and llama.cpp processes separately
- BEAM telemetry sampling and host sampling
- Raw sample schema (build, host, model, workload, raw metadata)
- Summary generation (median, p95, p99 percentiles)
- Baseline comparison with regression gate (non-zero exit on failure with exact metric details)
- Short CI and full release Make targets (make bench-short, make bench-full or similar)
- Tests: config validation, synthetic CPU/memory loads, process attribution, missing metrics, percentile calc, threshold direction, incompatible profiles, deterministic summaries, non-zero regression exit

**Risks:**
- Blocked by EXOCOMP-7 (the Elixir umbrella scaffold — now Done), so that blocker is resolved
- Process/cgroup attribution requires platform-specific code for Linux amd64 and arm64
- The harness is a prerequisite for EXOCOMP-36 through EXOCOMP-40; delays cascade to all M5 children

**Recommended next focus:** feature — this is a substantial new implementation task building the Elixir-based benchmark harness from scratch
---
author: oompah
created: 2026-07-23 20:26
---
Agent completed successfully in 134s (5132 tokens)
---
author: oompah
created: 2026-07-23 20:26
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 44, Tool calls: 35
- Tokens: 27 in / 5.1K out [5.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 14s
- Log: EXOCOMP-35__20260723T202432Z.jsonl
---
author: oompah
created: 2026-07-23 20:26
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 20:26
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 20:26
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 20:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:33
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 20:36
---
Understanding (Epic Planner): EXOCOMP-35 is a large feature task building the benchmark harness from scratch. It is a child of EXOCOMP-5 (M5 Performance epic) and currently has no children. The blocker EXOCOMP-7 (Elixir umbrella scaffold) is Done, so development can begin. The scope spans ten distinct subsystems: app scaffold, config/schema validation, host profiles, raw sample data model, BEAM sampler, host/cgroup sampler, summary generation, regression gate, benchmark execution driver, and harness self-tests. I will decompose these into 10 child tasks with appropriate dependencies, then set EXOCOMP-35 to Backlog.
---
<!-- COMMENTS:END -->

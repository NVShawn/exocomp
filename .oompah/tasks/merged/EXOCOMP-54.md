---
id: EXOCOMP-54
type: task
status: Merged
priority: null
title: Implement raw sample data model and JSON-Lines output
parent: EXOCOMP-35
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T20:37:01.619113Z'
updated_at: '2026-07-23T23:20:27.206286Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 8afa9778-7ee2-42cf-8dde-9669dfd65615
oompah.work_branch: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 2832285
  total_output_tokens: 28923
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 2832285
      output_tokens: 28923
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 24
    output_tokens: 5909
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:35:16.785195+00:00'
  - profile: standard
    model: unknown
    input_tokens: 1568943
    output_tokens: 14145
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:49:23.283269+00:00'
  - profile: deep
    model: unknown
    input_tokens: 1263272
    output_tokens: 7438
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:53:15.605646+00:00'
  - profile: standard
    model: unknown
    input_tokens: 46
    output_tokens: 1431
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:55:36.533136+00:00'
---
## Summary

In apps/bench, implement Bench.Sample and Bench.Run — the authoritative data structures for recording benchmark results. Bench.Sample represents one timestamped observation; Bench.Run is the envelope containing build metadata, host profile, model version, workload name, benchmark config reference, and a list of samples. Each sample carries: timestamp, source (:beam | :host | :node | :coordinator | :llama), metric name, numeric value, and unit. Implement Bench.Run.new/1, Bench.Run.append_sample/2, and Bench.Run.write_jsonl/2 that serialises each sample as a JSON object on its own line (JSON Lines format). Implement Bench.Run.read_jsonl/1 to reconstruct a Run from a file. Test: round-trip serialisation is lossless, write_jsonl produces valid JSON per line, read_jsonl rejects malformed lines, build/host/workload metadata is preserved. Reference: plans/milestone-5-performance.md (Metrics and Reporting and Measurement Architecture sections).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:32
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:32
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:34
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-54 is a unique task with no overlapping scope.

**Evidence reviewed:**

- EXOCOMP-50 (Done): Scaffolded apps/bench with a stub lib/bench/sample.ex that explicitly notes 'The full field schema and JSON encoding are extended in EXOCOMP-54.' The stub has only :timestamp_ms, :source, :metrics fields and basic to_json/from_json — no Bench.Run, no write_jsonl/read_jsonl, no per-metric field breakdown.
- EXOCOMP-52 (Done): Implemented Bench.Config with parse/1 and validate/1. Its branch also contains the same Sample stub deferring to EXOCOMP-54.
- EXOCOMP-53 (In Progress): Bench.HostProfile — pinned host profiles; entirely different scope.
- EXOCOMP-55/56 (Open): BEAM telemetry sampler and host/cgroup sampler — different scope, use the data model EXOCOMP-54 will define.
- EXOCOMP-35 (parent): Benchmark harness umbrella; explicitly lists EXOCOMP-54 as a distinct child for the raw sample data model.
- No EXOCOMP-54 branch exists on origin yet.
- git show EXOCOMP-50 and EXOCOMP-52: confirmed no Bench.Run module on either branch.

**Key finding:** Bench.Sample is only a skeleton stub on the existing branches, and Bench.Run does not exist anywhere. EXOCOMP-54 is the authoritative task for implementing both, with the full sample field schema (source atoms, metric_name, value, unit) and the JSON-Lines I/O (write_jsonl/2, read_jsonl/1).

**Remaining work:**
- Extend Bench.Sample: full struct with timestamp (ISO-8601 or unix_ms), source (:beam | :host | :node | :coordinator | :llama), metric_name (string), value (number), unit (string)
- Implement Bench.Run: envelope struct with build metadata, host profile ref, model version, workload name, config ref, and samples list
- Bench.Run.new/1, append_sample/2, write_jsonl/2, read_jsonl/1
- Tests: round-trip lossless, valid JSON per line, malformed line rejection, metadata preservation
- Branch: should be built on top of EXOCOMP-52 or EXOCOMP-50 (apps/bench already scaffolded there) or re-scaffold bench if needed

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-23 21:35
---
Agent completed successfully in 145s (5933 tokens)
---
author: oompah
created: 2026-07-23 21:35
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 56, Tool calls: 34
- Tokens: 24 in / 5.9K out [5.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 25s
- Log: EXOCOMP-54__20260723T213254Z.jsonl
---
author: oompah
created: 2026-07-23 21:35
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:43
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:43
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 21:49
---
Agent completed successfully in 354s (1583088 tokens)
---
author: oompah
created: 2026-07-23 21:49
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 25
- Tokens: 1.6M in / 14.1K out [1.6M total]
- Cost: $0.0000
- Exit: normal, Duration: 5m 54s
- Log: EXOCOMP-54__20260723T214331Z.jsonl
---
author: oompah
created: 2026-07-23 21:49
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-35`. Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:49
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-23 21:49
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 21:53
---
Agent completed successfully in 213s (1270710 tokens)
---
author: oompah
created: 2026-07-23 21:53
---
Run #2 [attempt=2, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 19
- Tokens: 1.3M in / 7.4K out [1.3M total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 33s
- Log: EXOCOMP-54__20260723T214944Z.jsonl
---
author: oompah
created: 2026-07-23 21:53
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-35`. No stronger profile is configured; retrying with 'deep' in 20s (2/3).
---
author: oompah
created: 2026-07-23 21:53
---
Retrying (attempt #2, agent: standard)
---
author: oompah
created: 2026-07-23 21:53
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 21:54
---
Understanding: Reviewing previous work. The EXOCOMP-54 branch already has commit 75dda39 on origin with the full implementation (Bench.Sample extended, Bench.Run with new/1, append_sample/2, write_jsonl/2, read_jsonl/1, and tests). Now verifying tests pass before closing.
---
author: oompah
created: 2026-07-23 21:55
---
Verification: All 31 tests pass (27 bench + 2 exocomp_core + 1 exocomp_coordinator + 1 exocomp_node). Tests cover: round-trip serialisation losslessness, write_jsonl valid JSON per line, read_jsonl malformed line rejection with line numbers, build/host/workload metadata preservation, all 5 source atoms (:beam :host :node :coordinator :llama).
---
author: oompah
created: 2026-07-23 21:55
---
Completion: EXOCOMP-54 is fully implemented and already on origin/EXOCOMP-54 (commit 75dda39). Delivered: (1) Bench.Sample — full struct with timestamp, source (5 atoms), metric_name, value, unit; to_json/from_json, to_map/from_map. (2) Bench.Run — envelope struct with build_metadata, host_profile, model_version, workload_name, config_ref, samples; new/1, append_sample/2, write_jsonl/2, read_jsonl/1. (3) Tests in run_test.exs and sample_test.exs covering all required scenarios. All 31 tests pass. Previous agents had already committed and pushed the work; this run confirmed correctness and closes the task.
---
author: oompah
created: 2026-07-23 21:55
---
Implemented Bench.Sample (full field schema) and Bench.Run (new/1, append_sample/2, write_jsonl/2, read_jsonl/1) with JSON-Lines serialisation. All 31 tests pass. Code on origin/EXOCOMP-54 at commit 75dda39.
---
author: oompah
created: 2026-07-23 21:55
---
Run #3 [attempt=3, profile=standard, role=standard -> Claude/default]
- Turns: 0, Tool calls: 27
- Tokens: 46 in / 1.4K out [1.5K total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 54s
- Log: EXOCOMP-54__20260723T215343Z.jsonl
---
<!-- COMMENTS:END -->

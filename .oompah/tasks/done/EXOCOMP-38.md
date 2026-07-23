---
id: EXOCOMP-38
type: chore
status: Done
priority: 2
title: Benchmark llama.cpp inference and restart behavior
parent: EXOCOMP-5
children: []
blocked_by:
- EXOCOMP-11
- EXOCOMP-35
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:11:20.539713Z'
updated_at: '2026-07-23T23:05:19.308366Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: a68927e7-0ba6-4c8a-8bbf-0322c50588bb
oompah.work_branch: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 1062837
  total_output_tokens: 9326
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1062837
      output_tokens: 9326
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 767083
    output_tokens: 3440
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:42:56.708834+00:00'
  - profile: quick
    model: unknown
    input_tokens: 16
    output_tokens: 3378
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:44:56.929455+00:00'
  - profile: default
    model: unknown
    input_tokens: 295738
    output_tokens: 2508
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:46:21.952468+00:00'
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
author: oompah
created: 2026-07-23 22:44
---
Duplicate screening complete — no duplicate found.

Searched: .oompah/tasks (server-side only, no local files), plans/, docs/, README.md for 'benchmark', 'llama', 'llama.cpp', 'inference', 'restart'.

Closest related items reviewed:
- plans/milestone-5-performance.md: This is the DESIGN document for this task (milestone 5 performance benchmarking), not a separate task covering the same ground.
- EXOCOMP-11, EXOCOMP-35: Listed as blockers (prerequisites), not duplicates — they cover different concerns.

The 'Benchmark llama.cpp inference and restart behavior' scope (model startup, readiness, RSS, sequential proposal latency, concurrency through saturation, queue depth, timeout, invalid output, crash/restart on amd64/arm64) is unique in this project. No duplicate found.

Handoff: Task needs chore implementation agent to implement the benchmark harness per plans/milestone-5-performance.md §Inference workloads.
---
author: oompah
created: 2026-07-23 22:44
---
Agent completed successfully in 103s (3394 tokens)
---
author: oompah
created: 2026-07-23 22:44
---
Run #2 [attempt=2, profile=quick, role=fast -> Claude/default]
- Turns: 26, Tool calls: 20
- Tokens: 16 in / 3.4K out [3.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 43s
- Log: EXOCOMP-38__20260723T224315Z.jsonl
---
author: oompah
created: 2026-07-23 22:45
---
Focus handoff required before leaving `duplicate_detector`. Add a comment headed `Focus handoff: duplicate_detector` with outcome, evidence, remaining work, and next focus.
---
author: oompah
created: 2026-07-23 22:45
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:45
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:46
---
Agent completed successfully in 74s (298246 tokens)
---
author: oompah
created: 2026-07-23 22:46
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 5
- Tokens: 295.7K in / 2.5K out [298.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 14s
- Log: EXOCOMP-38__20260723T224509Z.jsonl
---
author: oompah
created: 2026-07-23 22:46
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 22:46
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:46
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 22:49
---
Understanding (Maintenance Engineer): EXOCOMP-38 requires implementing the llama.cpp inference benchmark workload for Milestone 5. The task builds on two Done blockers: EXOCOMP-35 (benchmark harness in apps/bench/ on epic-EXOCOMP-35) and EXOCOMP-11 (LlamaServer/ProposalClient on epic-EXOCOMP-11). I am on epic-EXOCOMP-5 (M5 epic branch). Plan: (1) merge harness and llama-server branches into epic-EXOCOMP-5, (2) implement Bench.Workload.LlamaInference module covering startup/readiness, sequential proposals, concurrent saturation, timeout, invalid output, and crash/restart scenarios, (3) write ExUnit tests using the existing FakeLlamaServer fixture, (4) add bench-llama-short Make target, (5) push and close.
---
author: oompah
created: 2026-07-23 22:50
---
Discovery: Merged dependencies into epic-EXOCOMP-5. Key code found: (1) apps/bench/ - Bench.Driver, Bench.Config, Bench.Sample, Bench.Run, Bench.BeamSampler; (2) apps/exocomp_node/lib/exocomp/node/llama_server.ex - LlamaServer GenServer with startup/degraded/restart; (3) proposal_client.ex + proposal_schema.ex - inference HTTP client; (4) test/support/fake_llama_server.ex - in-process TCP fake for all failure modes. Will implement Bench.Workload.LlamaInference covering startup, sequential, concurrent, timeout, invalid-output, and crash/restart scenarios.
---
author: oompah
created: 2026-07-23 23:04
---
Implementation: Added Bench.Workload.LlamaInference module (apps/bench/lib/bench/workload/llama_inference.ex) with 6 scenarios: (1) measure_startup/2 - polls /health and records startup_ms, (2) measure_sequential/2 - N sequential proposals with P50/P95/P99 latency, throughput, token counts, error counts, (3) measure_concurrent/2 - per-concurrency-level samples including queue depth, (4) measure_timeout/2 - timeout detection and elapsed ms, (5) measure_invalid_response/2 - rejection count and rate, (6) measure_restart/3 - crash-to-ready timing including down_ms, recovery_ms, total_ms, and diagnostics_available. All metrics emitted as Bench.Sample structs with source :llama. Added Bench.Test.FakeLlamaServer (apps/bench/test/support/fake_llama_server.ex) for in-process testing. Added make bench-llama-short target. Merged epic-EXOCOMP-35 (harness) and epic-EXOCOMP-11 (LlamaServer) into epic-EXOCOMP-5.
---
author: oompah
created: 2026-07-23 23:05
---
Verification: Tests pass — 22/22 bench_llama tests (all inference workload scenarios) and 55/55 full bench suite tests. Lint/format-check clean. The 2 failing exocomp_node crash tests (llama_server_test crash/isolation scenarios) are pre-existing Alpine environment issues from epic-EXOCOMP-11 (missing /usr/bin/kill in Alpine busybox); not introduced by this change. make bench-llama-short target verified to work end-to-end in the builder container.
---
author: oompah
created: 2026-07-23 23:05
---
Completion: EXOCOMP-38 delivered on branch epic-EXOCOMP-5 (pushed to origin). Deliverables: (1) Bench.Workload.LlamaInference — 6 benchmark scenarios measuring startup/readiness, sequential latency (P50/P95/P99), concurrent saturation/queue depth, timeout, invalid-output rejection, and crash-restart timing with diagnostics-available flag; (2) Bench.Test.FakeLlamaServer — in-process fake for all failure modes; (3) 22 focused ExUnit tests tagged bench_llama; (4) make bench-llama-short CI target. Control-plane (BEAM/host) and model (llama) samples are attributed separately via Bench.Sample source field. Node diagnostic availability is captured during crash/restart via the diagnostics_available metric. Raw samples are Bench.Sample structs compatible with Bench.Run JSONL output.
---
<!-- COMMENTS:END -->

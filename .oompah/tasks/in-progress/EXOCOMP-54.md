---
id: EXOCOMP-54
type: task
status: In Progress
priority: null
title: Implement raw sample data model and JSON-Lines output
parent: EXOCOMP-35
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T20:37:01.619113Z'
updated_at: '2026-07-23T21:34:59.396660Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 3077e40f-2e40-4830-9041-08aa717580aa
oompah.work_branch: epic-EXOCOMP-5
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
<!-- COMMENTS:END -->

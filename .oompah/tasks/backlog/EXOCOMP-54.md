---
id: EXOCOMP-54
type: task
status: Backlog
priority: null
title: Implement raw sample data model and JSON-Lines output
parent: EXOCOMP-35
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:37:01.619113Z'
updated_at: '2026-07-23T20:37:01.619113Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

In apps/bench, implement Bench.Sample and Bench.Run — the authoritative data structures for recording benchmark results. Bench.Sample represents one timestamped observation; Bench.Run is the envelope containing build metadata, host profile, model version, workload name, benchmark config reference, and a list of samples. Each sample carries: timestamp, source (:beam | :host | :node | :coordinator | :llama), metric name, numeric value, and unit. Implement Bench.Run.new/1, Bench.Run.append_sample/2, and Bench.Run.write_jsonl/2 that serialises each sample as a JSON object on its own line (JSON Lines format). Implement Bench.Run.read_jsonl/1 to reconstruct a Run from a file. Test: round-trip serialisation is lossless, write_jsonl produces valid JSON per line, read_jsonl rejects malformed lines, build/host/workload metadata is preserved. Reference: plans/milestone-5-performance.md (Metrics and Reporting and Measurement Architecture sections).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


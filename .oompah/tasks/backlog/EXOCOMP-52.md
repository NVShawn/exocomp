---
id: EXOCOMP-52
type: task
status: Backlog
priority: null
title: Implement versioned benchmark configuration schema and validation
parent: EXOCOMP-35
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:36:45.706594Z'
updated_at: '2026-07-23T20:36:45.706594Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

In apps/bench, implement Bench.Config — a versioned benchmark definition schema with strict validation. The config must record: schema version, benchmark name/version, warm-up duration, run duration, repetition count, concurrency, sample interval, and references to host profile and workload scenario. Use a TOML or Elixir-struct-based format with NimbleOptions or custom validators. Expose a Bench.Config.parse/1 and Bench.Config.validate/1 function that returns {:ok, config} or {:error, reason}. Test cases must cover: valid config parses correctly, missing required fields return {:error, _}, unknown fields are rejected, version mismatch returns {:error, :incompatible_version}, and numeric fields reject negative values. Reference: plans/milestone-5-performance.md (Benchmark Environments and Test Strategy sections).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


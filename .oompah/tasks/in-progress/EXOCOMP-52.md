---
id: EXOCOMP-52
type: task
status: In Progress
priority: null
title: Implement versioned benchmark configuration schema and validation
parent: EXOCOMP-35
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:36:45.706594Z'
updated_at: '2026-07-23T21:02:00.835762Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 60d65c11-4bca-4d5a-afcf-885b70e2a7d2
oompah.work_branch: epic-EXOCOMP-5
---
## Summary

In apps/bench, implement Bench.Config — a versioned benchmark definition schema with strict validation. The config must record: schema version, benchmark name/version, warm-up duration, run duration, repetition count, concurrency, sample interval, and references to host profile and workload scenario. Use a TOML or Elixir-struct-based format with NimbleOptions or custom validators. Expose a Bench.Config.parse/1 and Bench.Config.validate/1 function that returns {:ok, config} or {:error, reason}. Test cases must cover: valid config parses correctly, missing required fields return {:error, _}, unknown fields are rejected, version mismatch returns {:error, :incompatible_version}, and numeric fields reject negative values. Reference: plans/milestone-5-performance.md (Benchmark Environments and Test Strategy sections).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:53
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:02
---
Understanding (Duplicate Investigator): Investigating whether EXOCOMP-52 ('Implement versioned benchmark configuration schema and validation' in apps/bench — Bench.Config module with parse/1, validate/1, TOML/struct schema, NimbleOptions validators) is a duplicate of any existing task. Will search .oompah/tasks and plans for similar work before any implementation.
---
<!-- COMMENTS:END -->

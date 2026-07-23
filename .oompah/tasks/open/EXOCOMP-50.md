---
id: EXOCOMP-50
type: task
status: Open
priority: null
title: Scaffold the bench Mix app within the Elixir umbrella
parent: EXOCOMP-35
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:36:33.686028Z'
updated_at: '2026-07-23T20:46:44.309587Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Create the apps/bench Mix application within the existing Elixir umbrella repository (established by EXOCOMP-7). Set up mix.exs with library dependencies (Jason for JSON, NimbleOptions or similar for config validation), ExUnit test configuration, and the top-level module skeleton. Establish the directory layout that all subsequent harness tasks will build into: lib/bench/, lib/bench/config.ex, lib/bench/sample.ex, lib/bench/sampler/, lib/bench/report/, lib/bench/driver.ex. Add the app to the umbrella apps/ list and verify it compiles and the empty test suite passes. Reference: plans/milestone-5-performance.md (Measurement Architecture section).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


---
id: EXOCOMP-52
type: task
status: In Progress
priority: null
title: Implement versioned benchmark configuration schema and validation
parent: EXOCOMP-35
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- needs:feature
assignee: null
created_at: '2026-07-23T20:36:45.706594Z'
updated_at: '2026-07-23T21:04:15.797319Z'
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
author: oompah
created: 2026-07-23 21:04
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-52 is a unique task with no overlapping scope in the project.

**Evidence reviewed:**
- EXOCOMP-35 (parent): 'Build the reproducible benchmark harness' — lists EXOCOMP-52 as a distinct child alongside EXOCOMP-50, 53, 54, 55, 56. Each child covers a different harness subsystem.
- EXOCOMP-50: Scaffold the bench Mix app — creates apps/bench structure but does NOT implement config validation logic (Bench.Config).
- EXOCOMP-53: Implement pinned amd64/arm64 host profiles — Bench.HostProfile, distinct from Bench.Config.
- EXOCOMP-54: Raw sample data model — different scope.
- EXOCOMP-55: BEAM telemetry sampler — different scope.
- EXOCOMP-56: Host sampler with per-process/cgroup attribution — different scope.
- EXOCOMP-36 through EXOCOMP-40: Workload benchmark tasks that USE the harness; none build Bench.Config.
- Codebase check: no apps/ directory yet on this branch (apps/bench not yet created), so Bench.Config is definitely not implemented yet.
- plans/milestone-5-performance.md (Test Strategy section): explicitly calls for 'unit tests [to] validate benchmark configuration' — EXOCOMP-52 is the dedicated implementation of this.

**Closest candidates reviewed:** EXOCOMP-50 (scaffold only, no config validation), EXOCOMP-53 (host profiles, not benchmark config schema). Neither covers Bench.Config.

**Remaining work:**
- Implement Bench.Config module in apps/bench/lib/bench/config.ex
- Implement parse/1 and validate/1 returning {:ok, config} or {:error, reason}
- Fields: schema_version, benchmark name/version, warm_up_duration, run_duration, repetitions, concurrency, sample_interval, host_profile ref, workload_scenario ref
- Use NimbleOptions or custom validators with TOML or Elixir struct format
- Tests: valid parse, missing required fields, unknown fields rejected, version mismatch returns {:error, :incompatible_version}, negative numeric fields rejected
- Note: apps/bench does not yet exist on this branch — EXOCOMP-50 must either be merged first or the config implementation must scaffold the bench app as well

**Risks:**
- EXOCOMP-50 (scaffold) is still Open; if it hasn't landed yet, EXOCOMP-52 must include the scaffold or depend on EXOCOMP-50 being merged first
- This branch is epic-EXOCOMP-35 (not epic-EXOCOMP-5 as stated in task metadata); implementation agent should verify branch before committing

**Recommended next focus:** feature — implement Bench.Config in apps/bench with full test coverage
---
<!-- COMMENTS:END -->

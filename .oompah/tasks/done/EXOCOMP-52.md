---
id: EXOCOMP-52
type: task
status: Done
priority: null
title: Implement versioned benchmark configuration schema and validation
parent: EXOCOMP-35
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T20:36:45.706594Z'
updated_at: '2026-07-23T21:22:12.092288Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 5185ffea-c461-4aca-bce4-a82b87eed8eb
oompah.work_branch: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 34
  total_output_tokens: 4894
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 34
      output_tokens: 4894
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 34
    output_tokens: 4894
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:04:24.958553+00:00'
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
author: oompah
created: 2026-07-23 21:04
---
Agent completed successfully in 633s (4928 tokens)
---
author: oompah
created: 2026-07-23 21:04
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 39, Tool calls: 31
- Tokens: 34 in / 4.9K out [4.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 10m 33s
- Log: EXOCOMP-52__20260723T205748Z.jsonl
---
author: oompah
created: 2026-07-23 21:04
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:05
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:05
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 21:05
---
Understanding (Maintenance Engineer): Implementing Bench.Config in apps/bench — a versioned benchmark configuration schema with parse/1 and validate/1 functions. Required fields: schema_version, benchmark name/version, warm_up_duration, run_duration, repetitions, concurrency, sample_interval, host_profile ref, workload_scenario ref. Will use NimbleOptions-based validation with Elixir structs. Test coverage required: valid parse, missing required fields, unknown fields rejected, version mismatch returns {:error, :incompatible_version}, negative numerics rejected. Starting by exploring workspace structure to determine if apps/bench scaffold exists.
---
author: oompah
created: 2026-07-23 21:09
---
Discovery: The project has an Elixir umbrella scaffold from EXOCOMP-7 in apps/ with exocomp_core, exocomp_node, exocomp_coordinator. The apps/bench directory does NOT exist yet (EXOCOMP-50 not merged). I need to scaffold apps/bench as a new umbrella child app and implement Bench.Config with parse/1 and validate/1. Build uses Docker (podman available). Pattern: mix.exs refs shared _build/deps_path at root level, Application module as entry point, ExUnit tests. No NimbleOptions in existing deps — will use custom validators with Elixir structs (no external deps needed). Implementing now.
---
author: oompah
created: 2026-07-23 21:14
---
Implementation: Created apps/bench/lib/bench/config.ex with Bench.Config struct, parse/1, and validate/1. Schema has 10 required fields (schema_version, name, version, warm_up_duration, run_duration, repetitions, concurrency, sample_interval, host_profile, workload_scenario). Custom validators enforce: version compatibility (:incompatible_version), positive integers, non-empty strings, unknown field rejection, missing field detection. Also: updated Bench.Driver to use Config.parse/1 instead of Config.new/1, updated driver tests, added Jason dep for sample/report modules, added mix deps.get to Makefile build/test/lint targets. Running Docker tests now.
---
author: oompah
created: 2026-07-23 21:21
---
Verification: All tests pass. 21 bench tests + 4 in other apps = 25 total. Test coverage: (1) valid string/atom-key maps parse into Bench.Config struct, (2) missing required fields return {:error, {:missing_fields, _}}, (3) unknown fields return {:error, {:unknown_fields, _}}, (4) schema_version mismatch returns {:error, :incompatible_version}, (5) negative/zero numeric fields return {:error, {:invalid_field, _, :must_be_positive}}. Format check (mix format --check-formatted) passes. Driver tests updated to use real config maps via Config.parse/1.
---
author: oompah
created: 2026-07-23 21:22
---
Completion: Implemented Bench.Config in apps/bench/lib/bench/config.ex with:
- parse/1: accepts string or atom-keyed maps, validates schema version, required fields, unknown fields, type/range constraints
- validate/1: validates a Bench.Config struct (or delegates to parse/1 for maps)
- All 5 required test scenarios covered and passing (21 bench tests, 25 total)
- Distinct error tuples: :incompatible_version, {:missing_fields, _}, {:unknown_fields, _}, {:invalid_field, field, reason}
- Makefile updated: mix deps.get added, MIX_HOME/HEX_HOME set for container builds
- mix.lock generated with jason 1.4.5 and nimble_options 1.1.1
- Branch EXOCOMP-52 pushed to origin
---
<!-- COMMENTS:END -->

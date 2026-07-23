---
id: EXOCOMP-53
type: task
status: In Progress
priority: null
title: Implement pinned amd64 and arm64 host profiles
parent: EXOCOMP-35
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T20:36:53.820999Z'
updated_at: '2026-07-23T21:42:41.395525Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 0879f484-8514-4437-ad68-59d91fa76b3b
oompah.work_branch: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 365453
  total_output_tokens: 11916
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 365453
      output_tokens: 11916
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 365426
    output_tokens: 2852
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:32:37.200791+00:00'
  - profile: standard
    model: unknown
    input_tokens: 27
    output_tokens: 9064
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:36:03.732487+00:00'
---
## Summary

In apps/bench, implement Bench.HostProfile — a module defining the static reference host profiles for amd64 and arm64, plus runtime host detection and compatibility enforcement. Each profile records: architecture, CPU model/count, RAM, kernel version, Linux distribution, libc version, power/performance governor, and container/VM boundary. Implement: Bench.HostProfile.detect/0 to detect the current host, Bench.HostProfile.load/1 to load a named profile from config, Bench.HostProfile.compatible?/2 to verify two profiles are comparable (same arch required; raise if not). Ship two reference profile YAML/TOML files: priv/bench/profiles/amd64-ci.toml and priv/bench/profiles/arm64-ci.toml. Test cases: detect returns a well-formed struct, compatible? returns false for amd64 vs arm64, incompatible profiles produce descriptive errors, missing profile file returns {:error, :not_found}. Reference: plans/milestone-5-performance.md (Benchmark Environments section).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:31
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:31
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:32
---
Agent completed successfully in 97s (368278 tokens)
---
author: oompah
created: 2026-07-23 21:32
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 10
- Tokens: 365.4K in / 2.9K out [368.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 37s
- Log: EXOCOMP-53__20260723T213102Z.jsonl
---
author: oompah
created: 2026-07-23 21:32
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-35`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:32
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:32
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:35
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-53 is a unique task with no overlapping scope in the project.

**Evidence reviewed:**
- EXOCOMP-35 (parent): 'Build the reproducible benchmark harness' — lists EXOCOMP-53 as a distinct child for host profiles
- EXOCOMP-50 (Done): Scaffold apps/bench — creates directory structure but does NOT implement Bench.HostProfile
- EXOCOMP-52 (Done): Implements Bench.Config schema — config validation, completely different scope
- EXOCOMP-54 (In Progress): Raw sample data model — different scope
- EXOCOMP-55/56 (Open): BEAM and host samplers — different scope
- EXOCOMP-36–40: Workload tasks that USE the harness, not build it
- Searched .oompah/tasks, plans, README: no other task covers Bench.HostProfile, amd64-ci.toml, arm64-ci.toml, or detect/load/compatible? functions

**Key implementation context for the next agent:**

Branch situation: Current worktree is epic-EXOCOMP-35 at 182db99. Must create branch EXOCOMP-53 based on EXOCOMP-50 (812a83d) which has the apps/bench scaffold. EXOCOMP-52 (7ccc5e5) also has the scaffold separately. Pattern used by EXOCOMP-52: git checkout -b EXOCOMP-53 EXOCOMP-50 (or EXOCOMP-7 as base), then create branch and implement.

Files to create:
- apps/bench/lib/bench/host_profile.ex — Bench.HostProfile struct + detect/0, load/1, compatible?/2
- apps/bench/priv/bench/profiles/amd64-ci.toml — reference amd64 CI profile
- apps/bench/priv/bench/profiles/arm64-ci.toml — reference arm64 CI profile
- apps/bench/test/bench/host_profile_test.exs — test file

Required test cases (from task description):
- detect/0 returns a well-formed struct
- compatible?/2 returns false for amd64 vs arm64
- incompatible profiles produce descriptive errors
- load/1 with missing profile file returns {:error, :not_found}

Profile struct fields (from task description + milestone-5-performance.md):
architecture, cpu_model, cpu_count, ram_bytes, kernel_version, linux_distribution, libc_version, governor (power/performance), container_or_vm (boundary)

Makefile targets: make test, make lint, make fmt-check

**Risks:**
- EXOCOMP-52 and EXOCOMP-50 both scaffold apps/bench independently; EXOCOMP-53 should pick EXOCOMP-50 as base (canonical scaffold) or EXOCOMP-7 and add its own scaffold
- TOML parsing in Elixir requires a dependency (toml_ex or similar) or native Elixir config parser — check what's available or use a simple string format
- detect/0 reads /proc/cpuinfo, /proc/meminfo, uname, /etc/os-release — needs Linux-specific implementation

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-23 21:36
---
Agent completed successfully in 189s (9091 tokens)
---
author: oompah
created: 2026-07-23 21:36
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 59, Tool calls: 40
- Tokens: 27 in / 9.1K out [9.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 9s
- Log: EXOCOMP-53__20260723T213256Z.jsonl
---
author: oompah
created: 2026-07-23 21:36
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:36
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:36
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-23 21:37
---
Understanding: Implementing Bench.HostProfile in apps/bench. Need to create: (1) apps/bench/lib/bench/host_profile.ex with struct + detect/0 (reads /proc/cpuinfo, /proc/meminfo, uname, /etc/os-release), load/1 (reads named .toml profile from priv/bench/profiles/), and compatible?/2 (raises on arch mismatch); (2) priv/bench/profiles/amd64-ci.toml and arm64-ci.toml reference profiles; (3) test file with 4 required test cases. Branch created from EXOCOMP-50 which has the apps/bench scaffold. No TOML library exists in deps, so implementing a minimal flat-TOML parser inline to avoid adding a new dependency.
---
author: oompah
created: 2026-07-23 21:41
---
Implementation: Created 4 files on branch EXOCOMP-53 (based on EXOCOMP-50 scaffold). (1) apps/bench/lib/bench/host_profile.ex — Bench.HostProfile struct with detect/0 (reads /proc/cpuinfo, /proc/meminfo, /etc/os-release, uname), load/1 (reads priv/bench/profiles/<name>.toml via :code.priv_dir/1), compatible?/2 (raises ArgumentError with descriptive message when architectures differ, returns true for same arch). Includes a minimal flat-TOML parser inline — no new dependency needed. (2) apps/bench/priv/bench/profiles/amd64-ci.toml — GitHub Actions ubuntu-22.04 runner profile. (3) apps/bench/priv/bench/profiles/arm64-ci.toml — GitHub Actions ubuntu-22.04-arm runner profile. (4) apps/bench/test/bench/host_profile_test.exs — covers all 4 required test cases plus extras. Running tests now.
---
author: oompah
created: 2026-07-23 21:42
---
Verification: All quality gates pass. make test: 37 bench tests + 4 other app tests, all passed. make fmt-check: clean. make lint (compile --warnings-as-errors): no warnings. New tests cover all 4 required cases: (1) detect/0 returns well-formed struct with correct field types, (2) amd64 vs arm64 raises ArgumentError naming both architectures, (3) incompatible arch error message is descriptive (tested via error.message =~ amd64/arm64), (4) load/1 with missing profile returns {:error, :not_found}.
---
<!-- COMMENTS:END -->

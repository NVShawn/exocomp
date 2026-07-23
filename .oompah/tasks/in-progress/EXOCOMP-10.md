---
id: EXOCOMP-10
type: feature
status: In Progress
priority: 1
title: Implement Linux and systemd diagnostic collectors
parent: EXOCOMP-1
children: []
blocked_by:
- EXOCOMP-7
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:08:55.388617Z'
updated_at: '2026-07-23T21:15:57.949903Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 29a63d93-95b6-4912-9dbc-ab1f6eb37fd8
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 383925
  total_output_tokens: 3655
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 383925
      output_tokens: 3655
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 383893
    output_tokens: 2791
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:43:05.836482+00:00'
  - profile: default
    model: unknown
    input_tokens: 32
    output_tokens: 864
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:57:48.138087+00:00'
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Implement Linux and systemd diagnostic collectors.

Implementation
Implement versioned CPU, memory, disk, uptime, and allow-listed systemd service collectors using /proc, /sys, filesystem APIs, and argv-only systemctl show; add explicit units, timestamps, partial errors, output limits, and timeouts; never use a shell.

Testing
Use fixture proc/sys files and stubbed process execution to test valid, partial, malformed, unavailable, timeout, large-output, and all relevant service states.

Acceptance Criteria
- [ ] Collectors return bounded versioned observations with explicit units.
- [ ] Partial failures preserve successful measurements.
- [ ] No caller or model input becomes a shell command or arbitrary service.
- [ ] Focused collector tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:41
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:41
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:43
---
Agent completed successfully in 90s (386684 tokens)
---
author: oompah
created: 2026-07-23 20:43
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 17
- Tokens: 383.9K in / 2.8K out [386.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 30s
- Log: EXOCOMP-10__20260723T204138Z.jsonl
---
author: oompah
created: 2026-07-23 20:43
---
Agent completed without closing this issue (90s (386684 tokens)). Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 20:52
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:52
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:53
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-10 is a unique task with no overlap in the existing task graph.

**Evidence reviewed:**
- Reviewed all 7 M1 sibling tasks (EXOCOMP-7 through EXOCOMP-13) and the parent epic EXOCOMP-1
- EXOCOMP-7 (scaffold, Done): umbrella/OTP/Make gates only — no /proc or systemctl collectors
- EXOCOMP-8 (A2A protocol types): HTTP+JSON codecs only — no Linux diagnostics
- EXOCOMP-9 (node config/identity/mTLS): config loading and TLS only — not system metrics
- EXOCOMP-11 (llama.cpp supervision): loopback process supervision — not /proc or systemctl
- EXOCOMP-12 (Node A2A service): A2A HTTP routing — collectors are a dependency, not the same scope
- EXOCOMP-13 (M1 verification): integration tests — not collector implementation
- EXOCOMP-7 duplicate investigator ran a comprehensive 47-task scan (EXOCOMP-1 through EXOCOMP-47) and confirmed no Linux diagnostic collector duplicate exists in the full task graph
- EXOCOMP-9 duplicate investigator also confirmed: 'EXOCOMP-10 (Linux/systemd collectors): covers /proc, /sys, systemctl — not identity or TLS'

**Relevant files for implementation:**
- plans/milestone-1-node-agent.md — 'Diagnostic Model' section defines collector return format (versioned maps with observation timestamp, node ID, source, collector version, measurements with explicit units, per-field availability/errors, collection duration)
- apps/exocomp_node/ — home for Linux collector modules on the EXOCOMP-7 scaffold branch
- Makefile — quality gate targets: make test, make lint, make fmt-check

**Remaining work:**
1. Implement Elixir collector modules for CPU (/proc/stat, /proc/cpuinfo), memory (/proc/meminfo), disk (File.stat or :file.read_file_info), uptime (/proc/uptime)
2. Implement systemd service collector: invoke systemctl show via argv-only Process/Port (NO shell), allow-list checked against config, fixed property names, timeout enforced
3. Return versioned observations: timestamp, node ID, source, version, measurements with explicit units, per-field error structs
4. Partial failure: successful measurements preserved when any single sub-collection fails
5. Tests: fixture /proc//sys files + stubbed Process execution for valid, partial, malformed, unavailable, timeout, large-output, and all service states
6. Output limits: cap systemctl output to bounded size
7. Run make test, make lint, make fmt-check

**Risks:**
- EXOCOMP-7 branch is the scaffold source; implementation branch must be based on epic-EXOCOMP-1 (which has EXOCOMP-7 merged) or rebase on it
- systemctl must be invoked via argv list (e.g., System.cmd/Port), never via shell string interpolation or sh -c
- Service allow-list must be loaded from config (EXOCOMP-9 scope); for EXOCOMP-10 tests, the allow-list can be passed as a parameter
- /proc fixture files must be created as test resources, not dependent on the host system

**Recommended next focus:** feature — implement Elixir Linux/systemd diagnostic collectors with comprehensive fixture-based tests
---
author: oompah
created: 2026-07-23 20:57
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 20
- Tokens: 32 in / 864 out [896 total]
- Cost: $0.0000
- Exit: terminated, Duration: 5m 35s
- Log: EXOCOMP-10__20260723T205215Z.jsonl
---
author: oompah
created: 2026-07-23 21:02
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:02
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 21:03
---
**Understanding:** Implementing Linux and systemd diagnostic collectors for the Exocomp node agent.

**Scope:** Add versioned CPU (from /proc/stat, /proc/cpuinfo), memory (/proc/meminfo), disk (filesystem stats), uptime (/proc/uptime), and allow-listed systemd service collectors (systemctl show via argv-only System.cmd). All collectors return bounded versioned observations with explicit units and per-field partial errors.

**Approach:**
1. Created EXOCOMP-10 branch from EXOCOMP-7 scaffold (which has the Elixir umbrella structure)
2. Implementing modules under apps/exocomp_node/lib/exocomp/node/collectors/
3. Using fixture files in test/fixtures/proc/ for unit tests without host dependency
4. Stubbing systemctl execution via a configurable command runner (MFA-based injection)
5. Running make test, make lint, make fmt-check for quality gates

Key design decisions:
- Collector versioning via @collector_version module attribute
- Partial failures return {:error, reason} per measurement while other fields succeed
- systemctl allow-list is passed in as config; no shell interpolation or sh -c
- Output capped at 64KB max per systemctl invocation
- Timeout enforced for systemctl via Task.await with configurable ms
---
author: oompah
created: 2026-07-23 21:12
---
**Discovery:** Implemented 5 collectors + shared Types module in apps/exocomp_node/lib/exocomp/node/collectors/:

- types.ex — shared observation envelope builder (ok/err/build)
- uptime.ex — /proc/uptime parser, 256B limit
- memory.ex — /proc/meminfo parser, 128KB limit, 5 fields
- cpu.ex — /proc/stat (8 tick fields) + /proc/cpuinfo (count, model name)
- disk.ex — df -Pk via argv MFA with configurable timeout_ms
- systemd.ex — systemctl show via argv MFA, fixed property set, allow-list enforced

10 fixture files under test/fixtures/proc/ cover valid, partial, malformed, missing-field cases.

4 test modules (uptime_test, memory_test, cpu_test, disk_test, systemd_test) cover:
- Valid output → correct values and units
- Partial failures → successful fields unaffected
- Malformed content → :malformed errors
- Missing files → :unavailable errors
- Oversized output → :output_limit errors
- Timeout (stub slow runner) → :timeout errors
- Non-zero exit → :unavailable errors
- Security: allow-list enforcement, argv inspection for no shell metacharacters

About to run make test, make lint, make fmt-check for quality gate.
---
author: oompah
created: 2026-07-23 21:15
---
**Implementation:** Added 6 Elixir modules and 5 test files to apps/exocomp_node/:

Collector modules (lib/exocomp/node/collectors/):
- types.ex — shared Types module: ok/1, err/2, build/4 returning versioned observation maps
- uptime.ex — reads /proc/uptime, 256B ceiling, partial error on parse failure
- memory.ex — reads /proc/meminfo, 128KB ceiling, 5 fields (MemTotal/Free/Available, SwapTotal/Free)
- cpu.ex — reads /proc/stat (8 tick counters) + /proc/cpuinfo (count, model name), independent partial failures
- disk.ex — invokes df -Pk via argv-only MFA (configurable timeout_ms option for test injection)
- systemd.ex — invokes systemctl show --property=<FIXED_LIST> <service> via argv-only MFA; allow-list enforced before any exec; no shell involved

Test files (test/exocomp/node/collectors/):
- uptime_test.exs, memory_test.exs, cpu_test.exs, disk_test.exs, systemd_test.exs

Fixture files (test/fixtures/proc/): 10 files covering valid, partial, malformed, missing-fields, and no-aggregate-line cases.

Key decisions:
- Fixed else-clause ordering bug in uptime.ex where {:error, :malformed} was shadowed by the generic is_atom guard
- cmd_runner option uses MFA {mod, fun, extra_args} pattern; extra_args are appended last in apply/3 so public stubs receive (cmd, args, opts, extra_arg...)
- timeout_ms configurable on both disk and systemd collectors for testing

Quality gates passed — see Verification comment.
---
<!-- COMMENTS:END -->

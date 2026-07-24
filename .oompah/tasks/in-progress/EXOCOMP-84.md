---
id: EXOCOMP-84
type: task
status: In Progress
priority: null
title: Implement disk-pressure evidence collector
parent: EXOCOMP-26
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- focus-complete:epic_planner
assignee: null
created_at: '2026-07-24T01:40:57.548405Z'
updated_at: '2026-07-24T02:37:08.949830Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: bbfea449-893a-472e-8ed7-5cedd5a72e32
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 89
  total_output_tokens: 15127
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 89
      output_tokens: 15127
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 28
    output_tokens: 5234
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:30:43.299534+00:00'
  - profile: standard
    model: unknown
    input_tokens: 42
    output_tokens: 819
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:33:11.054606+00:00'
  - profile: default
    model: unknown
    input_tokens: 19
    output_tokens: 9074
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:36:56.236337+00:00'
---
## Summary

### Goal
Implement a deterministic disk-pressure evidence collector that produces typed Evidence records suitable for the M3 policy engine.

### Context
- Branch: epic-EXOCOMP-3 (working branch for all M3 tasks)
- EXOCOMP-22 (Done, origin/EXOCOMP-73 and origin/EXOCOMP-74): Provides Safety.Evidence schema, PolicyEngine, and PolicyContext. The collector must produce Evidence records that match this schema.
- EXOCOMP-25 (Done, origin/EXOCOMP-25): Provides OsCommander behaviour/SystemCommander for injectable OS calls. Reuse this for df/statvfs calls.
- Key files to read before implementing:
  - apps/exocomp_node/lib/exocomp/node/safety/evidence.ex (from origin/EXOCOMP-73)
  - apps/exocomp_node/lib/exocomp/node/os_commander.ex (from origin/EXOCOMP-25)
  - plans/milestone-3-safety-validation.md (System-Data Cleanup section)

### Implementation
Create module Exocomp.Node.Safety.DiskPressureCollector in apps/exocomp_node/lib/exocomp/node/safety/disk_pressure_collector.ex:
- Collect filesystem usage for the configured journal/log partition via deterministic OS call (df -B1 or similar) using OsCommander behaviour.
- Produce a typed Evidence record (schema_version '1', collector 'system.disk.pressure', target_id set to the measured mount point, values map containing used_bytes, free_bytes, total_bytes, used_pct as string values, integrity_hash computed per Evidence schema).
- Evaluate the evidence against installed warning and critical thresholds from application config (thresholds are installed fixed values, not caller-supplied).
- Return {:ok, evidence, :below_threshold | :warning | :critical} or {:error, reason}.
- The collector must be injectable for tests via the OsCommander behaviour pattern already in EXOCOMP-25.

### Installed config keys (not caller-supplied)
- :disk_pressure_warning_pct (integer, e.g. 75)
- :disk_pressure_critical_pct (integer, e.g. 90)
- :disk_pressure_mount_point (string, e.g. '/var/log' or '/run/log/journal')
All values are read from Application config at collection time, never from request or model fields.

### Tests
Write focused unit tests in apps/exocomp_node/test/exocomp/node/safety/disk_pressure_collector_test.exs:
- Below warning threshold: returns :below_threshold
- At exactly warning threshold: returns :warning
- Above warning, below critical: returns :warning
- At exactly critical threshold: returns :critical
- Above critical: returns :critical
- OS command failure: returns {:error, reason}
- Evidence record structure: all required fields present, integrity_hash valid, observed_at recent
- Caller cannot supply mount point or thresholds (config-only values)

### Quality Gate
Run make test and make lint before closing the task.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:28
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:28
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:30
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-84 is a unique, unimplemented task.

**Evidence reviewed:**
- Searched all git branches (50+ refs) and commit history for 'disk', 'pressure', 'disk_pressure', 'DiskPressure', 'evidence_collector', 'EvidenceCollector' — zero hits in source files.
- Checked plans/ and docs/ directories: only plans/milestone-3-safety-validation.md references disk pressure as a design requirement (System-Data Cleanup section), not an implementation.
- Examined EXOCOMP-73 and EXOCOMP-74 branches (Evidence schema and PolicyEngine): contain evidence.ex, policy_context.ex, policy_engine.ex — no disk_pressure_collector.ex.
- Examined EXOCOMP-25 branch (OsCommander/executor): contains os_commander.ex, executor.ex, sudoers_policy.ex — no disk pressure work.
- Current epic-EXOCOMP-3 HEAD lacks a safety/ directory entirely.
- EXOCOMP-83 (only nearby task with 'duplicate_detector' focus) is about Alpine LlamaServer crash tests — completely unrelated.

**Closest reviewed tasks:** EXOCOMP-73 (Evidence schema), EXOCOMP-74 (PolicyEngine), EXOCOMP-25 (OsCommander/executor). These are declared *dependencies* of EXOCOMP-84, not duplicates.

**Remaining work:** Full implementation of DiskPressureCollector module + unit tests as described in task spec.

**Recommended next focus:** `feature` (Elixir backend implementation).
---
author: oompah
created: 2026-07-24 02:30
---
Agent completed successfully in 132s (5262 tokens)
---
author: oompah
created: 2026-07-24 02:30
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 54, Tool calls: 43
- Tokens: 28 in / 5.2K out [5.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 12s
- Log: EXOCOMP-84__20260724T022834Z.jsonl
---
author: oompah
created: 2026-07-24 02:30
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 02:30
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 02:30
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-24 02:33
---
Run #1 [attempt=1, profile=standard, role=standard -> Claude/default]
- Turns: 0, Tool calls: 20
- Tokens: 42 in / 819 out [861 total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 14s
- Log: EXOCOMP-84__20260724T023102Z.jsonl
---
author: oompah
created: 2026-07-24 02:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:33
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-24 02:36
---
Understanding: EXOCOMP-84 is a concrete, leaf-level implementation task — not an epic requiring decomposition. It requires implementing a single Elixir module (DiskPressureCollector) with unit tests. As Epic Planner, my role is to confirm scope and facilitate the right specialist.

Explored the key dependency branches:
- EXOCOMP-73/EXOCOMP-74: Evidence struct (evidence.ex) — SHA-256 integrity_hash over canonical serialisation, all fields required, string→string values map.
- EXOCOMP-25: OsCommander behaviour (os_commander.ex) + SystemCommander — injectable, no shell, exact argv list, timeout enforcement.
- epic-EXOCOMP-3: M3 working branch — basic scaffolding, does not yet have safety/ directory or os_commander.ex merged in.

The task is self-contained and completable in a single feature-agent session. No child tasks are needed.
---
author: oompah
created: 2026-07-24 02:36
---
Focus handoff: epic_planner

**Outcome:** No decomposition needed. EXOCOMP-84 is a concrete leaf task — one Elixir module + unit tests. It fits comfortably in a single feature-agent session.

**Key files and locations for the feature agent:**

- Evidence struct: `git show EXOCOMP-73:apps/exocomp_node/lib/exocomp/node/safety/evidence.ex`
  - Required fields: schema_version='1', evidence_id (UUID), collector, collector_version, target_id, observed_at (DateTime), values (%{String=>String}), integrity_hash (64-char SHA-256 hex)
  - `integrity_hash` is NOT computed by Evidence module itself — the collector must compute it over the canonical serialisation before constructing the struct
  - Parse validation: `Evidence.parse(string_key_map)` validates all fields

- OsCommander behaviour: `git show EXOCOMP-25:apps/exocomp_node/lib/exocomp/node/os_commander.ex`
  - `@callback run(executable, argv, opts) :: {:ok, output, exit_code} | {:error, :timeout} | {:error, {:output_limit_exceeded, bytes}} | {:error, term()}`
  - `SystemCommander` is the production implementation; tests inject a mock via application env

- Branch situation: Current EXOCOMP-84 branch does not yet exist. Feature agent should create it based on `EXOCOMP-74` (which has all safety/ files and matches the latest M3 work) rather than `epic-EXOCOMP-3` (which only has basic scaffolding and is missing the safety/ directory).
  - `git checkout -b EXOCOMP-84 EXOCOMP-74` — or rebase EXOCOMP-74 into EXOCOMP-84

- Target file: `apps/exocomp_node/lib/exocomp/node/safety/disk_pressure_collector.ex`
- Target test: `apps/exocomp_node/test/exocomp/node/safety/disk_pressure_collector_test.exs`

**Canonical serialisation for integrity_hash:**
Evidence doesn't define a `compute_hash/1` helper; the collector must define one. A deterministic approach: sort the values map by key, build a JSON-like canonical string of all fields (schema_version|evidence_id|collector|collector_version|target_id|observed_at_iso8601|sorted_values|), then SHA-256 it. Alternatively, Jason.encode! on a sorted keyword list is idiomatic in this codebase. Check existing tests in `EXOCOMP-73` for any hash test fixture.

**Config keys (from Application.fetch_env!(:exocomp_node, key)):**
- :disk_pressure_warning_pct (integer)
- :disk_pressure_critical_pct (integer)
- :disk_pressure_mount_point (string)

**OsCommander injection pattern (from EXOCOMP-25 tests):**
Pass `commander` as optional keyword arg defaulting to `Application.get_env(:exocomp_node, :os_commander, SystemCommander)`.

**Quality gate:** `make test && make lint` (check `make help` first).

**Remaining work:** Full Elixir implementation + unit tests.

**Recommended next focus:** `feature`
---
author: oompah
created: 2026-07-24 02:36
---
Agent completed successfully in 179s (9093 tokens)
---
author: oompah
created: 2026-07-24 02:36
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 39, Tool calls: 27
- Tokens: 19 in / 9.1K out [9.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 59s
- Log: EXOCOMP-84__20260724T023359Z.jsonl
---
author: oompah
created: 2026-07-24 02:37
---
Focus handoff from `epic_planner` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 02:37
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 02:37
---
Focus: Maintenance Engineer
---
<!-- COMMENTS:END -->

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
assignee: null
created_at: '2026-07-24T01:40:57.548405Z'
updated_at: '2026-07-24T02:33:59.601690Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7eef4222-8916-43ea-b90f-be5dceec2f01
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 70
  total_output_tokens: 6053
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 70
      output_tokens: 6053
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
<!-- COMMENTS:END -->

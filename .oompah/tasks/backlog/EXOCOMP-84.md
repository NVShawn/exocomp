---
id: EXOCOMP-84
type: task
status: Backlog
priority: null
title: Implement disk-pressure evidence collector
parent: EXOCOMP-26
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T01:40:57.548405Z'
updated_at: '2026-07-24T01:40:57.548405Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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


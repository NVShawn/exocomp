---
id: EXOCOMP-85
type: task
status: Open
priority: null
title: Implement installed vacuum bounds and eligibility gate
parent: EXOCOMP-26
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T01:41:20.826005Z'
updated_at: '2026-07-24T02:28:15.395058Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

### Goal
Implement installed immutable vacuum bounds and the eligibility gate that enforces them. No caller or model output can widen these limits.

### Context
- Branch: epic-EXOCOMP-3 (shared M3 working branch)
- EXOCOMP-84 (child of EXOCOMP-26, depends-on): DiskPressureCollector producing Evidence records with :below_threshold | :warning | :critical classification. Must be done first.
- EXOCOMP-22 (Done, origin/EXOCOMP-73): Provides Safety.DataClassification. System logs are :system_data. User paths and unknown paths are :protected_user_data and must be rejected.
- EXOCOMP-25 (Done, origin/EXOCOMP-25): Provides ActionCatalog with :vacuum_logs entry. Do not replace the catalog entry; add the bounds layer on top.
- Key files to read:
  - apps/exocomp_node/lib/exocomp/node/safety/data_classification.ex (from origin/EXOCOMP-73)
  - apps/exocomp_node/lib/exocomp/node/action_catalog.ex (from origin/EXOCOMP-25)
  - plans/milestone-3-safety-validation.md (System-Data Cleanup and Safety Invariants sections)

### Implementation
Create module Exocomp.Node.VacuumBounds in apps/exocomp_node/lib/exocomp/node/vacuum_bounds.ex:

### Installed fixed limits (read from Application config at startup, never from callers)
- :vacuum_log_source — the single allowed log source path (e.g. '/var/log/journal'). Only this path is eligible. No caller-supplied path is accepted.
- :vacuum_min_retention_secs — minimum retention period (seconds). journalctl must not reclaim logs newer than this.
- :vacuum_max_reclaim_bytes — maximum bytes reclaimed per execution. This caps the journalctl --vacuum-size argument.
- :vacuum_min_free_space_bytes — minimum post-cleanup free space target.
- :vacuum_cooldown_secs — minimum interval between successful executions.
- :vacuum_max_retries — maximum consecutive failures before refusing further attempts.

### check_eligible/1 function
Takes a DiskPressureCollector result and cooldown/retry state, returns:
- {:ok, :eligible, bounds_map} — all conditions met; bounds_map contains the capped effective limits for the executor
- {:error, :below_threshold} — disk pressure is :below_threshold or :warning (critical required)
- {:error, :on_cooldown, last_executed_at} — cooldown period not yet elapsed
- {:error, :retry_exhausted, count} — max_retries exceeded
- {:error, :source_not_configured} — vacuum_log_source not set
Never accepts a caller-supplied path or limit. Any attempt to pass a path or limit value from outside the config must be rejected.

### Source and data-classification restriction
validate_source/1 validates that the configured log source path:
- Matches only known system journal/log paths (e.g. /var/log/journal, /run/log/journal)
- Is not a user home directory, /tmp, /home, or any unknown path
- Returns {:error, :user_data_path} or {:error, :unknown_path} for anything else

### Cooldown and retry state
Use a GenServer (Exocomp.Node.VacuumState) or ETS table to track last_executed_at and consecutive_failure_count per mount point. Start under the application supervisor.

### Tests
Write focused tests in apps/exocomp_node/test/exocomp/node/vacuum_bounds_test.exs:
- Below threshold (warning level pressure): check_eligible returns :below_threshold
- At critical threshold: check_eligible returns :eligible
- Cooldown active: check_eligible returns :on_cooldown
- Retry exhausted: check_eligible returns :retry_exhausted
- Caller attempts to supply a path: rejected (only config path accepted)
- Caller attempts to supply a wider limit: rejected (only config limits accepted)
- User path in config: validate_source returns :user_data_path
- Unknown path in config: validate_source returns :unknown_path
- Valid system journal path in config: validate_source returns :ok
- Bounds map returned has values capped at installed limits (max_reclaim_bytes not widened)

### Quality Gate
Run make test and make lint before closing the task.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes


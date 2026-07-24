---
id: EXOCOMP-85
type: task
status: Open
priority: null
title: Implement installed vacuum bounds and eligibility gate
parent: EXOCOMP-26
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T01:41:20.826005Z'
updated_at: '2026-07-24T02:46:16.735349Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 8dd966a3-572d-4628-ab92-b085a11a3c23
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 560071
  total_output_tokens: 2907
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 560071
      output_tokens: 2907
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 560071
    output_tokens: 2907
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:46:13.509644+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:44
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:44
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:45
---
Understanding: duplicate-screening only. I will compare the immutable vacuum-bounds/eligibility-gate scope against existing milestone-3 tasks and their full descriptions/comments. I will not modify code during this focus; if no confirmed duplicate exists, I will document the closest tasks and hand off to implementation.
---
author: oompah
created: 2026-07-24 02:45
---
Discovery: no duplicate confirmed. Reviewed EXOCOMP-3, EXOCOMP-26, EXOCOMP-84, EXOCOMP-22, and EXOCOMP-25 in full, including comments. EXOCOMP-26 is the intentional parent scope; its planner explicitly decomposed EXOCOMP-85 as the unique immutable vacuum-bounds/cooldown/retry eligibility child. EXOCOMP-84 only produces disk-pressure evidence, EXOCOMP-22 provides generic policy filtering, and EXOCOMP-25 provides ActionCatalog/executor infrastructure. Repository search found vacuum requirements only in plans/milestone-3-safety-validation.md and no separate implementation task covering EXOCOMP-85.
---
author: oompah
created: 2026-07-24 02:46
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-85 remains a unique leaf implementation task.

Evidence and decisions:
- Searched .oompah/tasks, docs, plans, README.md, and WORKFLOW.md for vacuum, journald, installed bounds, eligibility gate, and config-key terms; the only repository matches are the M3 design requirements in plans/milestone-3-safety-validation.md.
- Reviewed EXOCOMP-3 and EXOCOMP-26: EXOCOMP-85 is an intentional child decomposition of bounded system-log cleanup, not a duplicate of its parent.
- Reviewed EXOCOMP-84: it implements DiskPressureCollector and is a prerequisite, but does not implement vacuum bounds or state.
- Reviewed EXOCOMP-22 and EXOCOMP-25: they provide generic PolicyEngine/DataClassification and ActionCatalog/Executor infrastructure respectively; neither implements installed vacuum bounds, source validation, or per-mount cooldown/retry state.
- No code was changed during duplicate screening.

Remaining work and risks: implement VacuumBounds, per-mount VacuumState supervision, source classification, immutable config-only enforcement, focused tests, and make test/make lint. The current worktree is actually on epic-EXOCOMP-26 (despite the task text naming epic-EXOCOMP-3) and contains uncommitted EXOCOMP-84 prerequisite work; preserve those shared changes and wait for/coordinate with EXOCOMP-84 before building on them.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 02:46
---
Agent completed successfully in 104s (562978 tokens)
---
author: oompah
created: 2026-07-24 02:46
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 14
- Tokens: 560.1K in / 2.9K out [563.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 44s
- Log: EXOCOMP-85__20260724T024433Z.jsonl
---
author: oompah
created: 2026-07-24 02:46
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
<!-- COMMENTS:END -->

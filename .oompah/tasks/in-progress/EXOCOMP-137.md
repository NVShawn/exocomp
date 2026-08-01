---
id: EXOCOMP-137
type: task
status: In Progress
priority: 2
title: Configure PostgreSQL and the Ecto migration test harness
parent: EXOCOMP-128
children: []
blocked_by:
- EXOCOMP-136
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:51.051048Z'
updated_at: '2026-08-01T14:39:26.796922Z'
work_branch: epic-EXOCOMP-128--task-EXOCOMP-137
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b80f5e1f46d453b5f911773d73d7bc30e7ad2ce61d7d1b5e90ae108f31164170
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:39:05.004276+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-136, EXOCOMP-138, EXOCOMP-148, EXOCOMP-150,
    EXOCOMP-171, EXOCOMP-173, EXOCOMP-174, EXOCOMP-175, EXOCOMP-176, and EXOCOMP-177.
    Their scopes are application scaffolding, domain persistence, feature-specific
    schemas, retention, health, or packaging; none duplicates the PostgreSQL/Ecto
    Repo and migration harness foundation.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 3b6ba07d-2fc1-492f-9e69-23132db34290
oompah.work_branch: epic-EXOCOMP-128--task-EXOCOMP-137
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-128--task-EXOCOMP-137
  base_branch: epic-EXOCOMP-128
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:39:24.836668+00:00'
oompah.task_costs:
  total_input_tokens: 1048912
  total_output_tokens: 4341
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1048912
      output_tokens: 4341
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 1048912
    output_tokens: 4341
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:39:05.003524+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-137__20260801T143719Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-128--task-EXOCOMP-137
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:39:05.011935+00:00'
---
## Summary

Plan: plans/mission-control.md, Persistence and Retention.

Deliverables:
- Add Ecto/Postgrex dependencies and a Mission Control Repo supervised by the new application.
- Add dev/test/prod database configuration with runtime validation and no embedded credentials.
- Add an initial migration and SQL-sandbox test setup.
- Add a Make target for focused Mission Control database tests if no existing target covers it.

Acceptance:
- A clean test database can migrate up and down.
- Concurrent tests use the SQL sandbox without data leakage.
- Missing production database configuration fails with a bounded actionable error.

Out of scope: domain tables and retention jobs.
Quality gate: focused database tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:37
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:37
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:39
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 15
- Tokens: 1.0M in / 4.3K out [1.1M total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 56s
- Log: EXOCOMP-137__20260801T143719Z.jsonl
---
author: oompah
created: 2026-08-01 14:39
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:39
---
Focus: Test Engineer
---
<!-- COMMENTS:END -->

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
updated_at: '2026-08-01T15:06:19.612703Z'
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
author: oompah
created: 2026-08-01 14:39
---
Understanding: configure the Mission Control Ecto/Postgrex repository, environment-specific database settings, initial migration, and SQL-sandbox test harness. I will inspect the existing Mix/application/test structure, add behavior-focused coverage for migration/configuration/sandbox isolation, run focused tests plus make fmt-check and make lint, then commit, push, and submit.
---
author: oompah
created: 2026-08-01 14:43
---
Discovery: the umbrella has only a root config/config.exs and runtime.exs, with no environment-specific config files or Mission Control app. Existing git history confirms the app contract (, ) but not this task’s infrastructure. I’ll add a minimal database-only app, env config using DATABASE_URL/PG* variables without credential literals, production validation in a testable helper, a no-op baseline migration (domain tables remain out of scope), and a DataCase SQL-sandbox harness.
---
author: oompah
created: 2026-08-01 14:57
---
Implementation: added apps/exocomp_mission_control with Ecto SQL/Postgrex dependencies, supervised Repo, test-support DataCase sandbox ownership, and reversible 20260801000000 baseline migration. Added dev/test/prod database config using DATABASE_URL/PG* environment values, production runtime validation, root release/config wiring, focused Make target, and tests covering config edge cases, supervision, migration round-trip, and concurrent sandbox isolation. Database tests are opt-in via EXOCOMP_RUN_DB_TESTS=1 so ordinary tests remain service-independent; the focused target enables them.
---
author: oompah
created: 2026-08-01 15:00
---
Verification: focused config/application tests passed (7 tests); the full Mission Control test run passed 9 tests with the 2 PostgreSQL tests skipped unless EXOCOMP_RUN_DB_TESTS=1. New files pass local format-check, parse checks, and warnings-as-errors compilation under the available toolchain. Production runtime config loads with DATABASE_URL and fails without it using the bounded actionable message. make fmt-check, make lint, and make test-mission-control-db could not enter the pinned container because Docker is backed by Podman and the sandbox rejects chmod on /run/user/1000/libpod.
---
author: oompah
created: 2026-08-01 15:06
---
Completion: rebased onto the landed EXOCOMP-136 scaffold, preserving Phoenix supervision/endpoint behavior while adding the Repo child and Ecto/Postgrex persistence harness. Commit e9fb31b0 is pushed on epic-EXOCOMP-128--task-EXOCOMP-137 and the branch is up to date. Required container quality gates remain environment-blocked by the Podman chmod restriction; local format, parse, runtime-validation, and focused non-DB tests passed.
---
<!-- COMMENTS:END -->

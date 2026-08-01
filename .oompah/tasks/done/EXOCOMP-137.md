---
id: EXOCOMP-137
type: task
status: Done
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
updated_at: '2026-08-01T16:19:09.303851Z'
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
  state: integrated
  attempts: 1
  task_branch: epic-EXOCOMP-128--task-EXOCOMP-137
  base_branch: epic-EXOCOMP-128
  base_sha: 074712f0af1ff18d286cd2d4ff12b9399798ffdc
  head_sha: f1d8f1c0d43b498a62abccd78db2c46bcf3ffd52
  integrated_sha: f1d8f1c0d43b498a62abccd78db2c46bcf3ffd52
  submitted_at: '2026-08-01T15:06:31.639313+00:00'
  updated_at: '2026-08-01T15:44:28.218467+00:00'
  dependency_heads:
    EXOCOMP-136: 074712f0af1ff18d286cd2d4ff12b9399798ffdc
oompah.task_costs:
  total_input_tokens: 19276932
  total_output_tokens: 75779
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 19276926
      output_tokens: 75447
      cost_usd: 0.0
    unknown:
      input_tokens: 6
      output_tokens: 332
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 1048912
    output_tokens: 4341
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:39:05.003524+00:00'
  - profile: default
    model: haiku
    input_tokens: 18228014
    output_tokens: 71106
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:08:23.474961+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 6
    output_tokens: 332
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:53:04.874795+00:00'
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
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-108d45f3d64c: '2026-08-01T15:51:52.861077+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-137
    target_state: Done
    evidence_fingerprint: b1b26974021f72cbbff5734580bb4327d7526887090aa91c188850db1d4e6f05
    audit_ids:
    - audit-cfa657aa17a7
    kind: result
    applied: true
    retired_at: '2026-08-01T15:51:52.861084+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-137
    audit_id: audit-cfa657aa17a7
    attempt_id: attempt-108d45f3d64c
    target_state: Done
    evidence_fingerprint: b1b26974021f72cbbff5734580bb4327d7526887090aa91c188850db1d4e6f05
    status: Done
    audit_ids:
    - audit-cfa657aa17a7
    applied: true
    created_at: '2026-08-01T15:51:52.861095+00:00'
    applied_at: '2026-08-01T15:51:56.803600+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-cfa657aa17a7
    project_id: proj-c260b117
    task_id: EXOCOMP-137
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b1b26974021f72cbbff5734580bb4327d7526887090aa91c188850db1d4e6f05
    attempts:
    - version: 1
      attempt_id: attempt-108d45f3d64c
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: b1b26974021f72cbbff5734580bb4327d7526887090aa91c188850db1d4e6f05
      created_at: '2026-08-01T15:45:00.939996+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T15:45:00.939996+00:00'
      branch_key: epic-EXOCOMP-128--task-EXOCOMP-137
      verdict: pass
      completed_at: '2026-08-01T15:51:52.860953+00:00'
      ended_at: '2026-08-01T15:51:52.860953+00:00'
    requested_by:
      version: 1
      identity: oompah-integration
      source: service
    previous_state: Ready to Integrate
    created_at: '2026-08-01T15:44:30.666415+00:00'
    updated_at: '2026-08-01T15:51:52.860953+00:00'
  - version: 1
    audit_id: audit-4dcf15869a66
    project_id: proj-c260b117
    task_id: EXOCOMP-137
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: d8c3c8255101f75646464ad815da8021a6726b7da6fc3897ac0932e50fdac962
    attempts: []
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: Done
    created_at: '2026-08-01T16:19:08.505858+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-108d45f3d64c
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b1b26974021f72cbbff5734580bb4327d7526887090aa91c188850db1d4e6f05
    created_at: '2026-08-01T15:45:00.939996+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T15:45:00.939996+00:00'
    branch_key: epic-EXOCOMP-128--task-EXOCOMP-137
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
author: oompah
created: 2026-08-01 15:06
---
Added the Mission Control Ecto/Postgrex Repo, environment-safe database configuration and production validation, reversible baseline migration, SQL-sandbox harness/tests, and focused database Make target; rebased onto EXOCOMP-136 and pushed commit e9fb31b0.
---
author: oompah
created: 2026-08-01 15:08
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 205
- Tokens: 18.2M in / 71.1K out [18.3M total]
- Cost: $0.0000
- Exit: terminated, Duration: 29m 2s
- Log: EXOCOMP-137__20260801T143927Z.jsonl
---
author: oompah
created: 2026-08-01 15:44
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-01 15:45
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 15:45
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 15:51
---
Audit PASS — Done

[REDACTED]

Safe evidence:
- head_commit: f1d8f1c0d43b498a62abccd78db2c46bcf3ffd52
- commit_message: EXOCOMP-137: configure Mission Control PostgreSQL test harness
- pushed_branches: origin/epic-EXOCOMP-128, origin/epic-EXOCOMP-128--task-EXOCOMP-137, origin/epic-EXOCOMP-128--task-EXOCOMP-139
- files_changed: 16 files, +390 -6
- repo_supervised_in: apps/exocomp_mission_control/lib/exocomp/mission_control/application.ex
- runtime_validation: config/runtime.exs raises RuntimeError with 'DATABASE_URL' when missing in :prod
- migration_file: apps/exocomp_mission_control/priv/repo/migrations/20260801000000_create_mission_control_schema.exs (reversible)
- sandbox_module: apps/exocomp_mission_control/test/support/data_case.ex uses Ecto.Adapters.SQL.Sandbox.start_owner!
- make_target: test-mission-control-db sets EXOCOMP_RUN_DB_TESTS=1 and runs mix ecto.create/migrate + mix test
- container_gates_note: Container-based fmt-check/lint/test-mission-control-db could not be executed in the auditor sandbox (no container engine); static inspection shows consistent formatting and code structure
---
author: oompah
created: 2026-08-01 15:53
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 0, Tool calls: 45
- Tokens: 6 in / 332 out [338 total]
- Cost: $0.0000
- Exit: terminated, Duration: 8m 0s
- Log: EXOCOMP-137__20260801T154508Z.jsonl
---
<!-- COMMENTS:END -->

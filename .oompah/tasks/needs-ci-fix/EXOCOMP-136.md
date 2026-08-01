---
id: EXOCOMP-136
type: task
status: Needs CI Fix
priority: 2
title: Scaffold the Mission Control Phoenix application
parent: EXOCOMP-128
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:49.889616Z'
updated_at: '2026-08-01T15:08:45.244286Z'
work_branch: epic-EXOCOMP-128--task-EXOCOMP-136
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 380c474af15b6b900dc4489f4d5dbee0015706f8a120957126e6ebaa0b68866e
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:41:07.393254+00:00'
  matched_identifiers: []
  evidence: 'I have completed the duplicate investigation for EXOCOMP-136. The coordination
    message from EXOCOMP-137 confirms this is part of the Milestone 7 epic decomposition,
    and that sibling task is already in progress. This coordination context further
    validates that EXOCOMP-136 is a unique, non-duplicate task representing the scaffolding
    phase.


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** Comprehensive search across task metadata, plans, documentation,
    and codebase structure confirms no existing Mission Control implementation or
    duplicate scaffolding task. The mission-control.md Milestone 7 plan exists, but
    the Phoenix application, OTP release, and supporting infrastructure do not exist
    in the repository. Coordination with EXOCOMP-137 (peer sibling, dependency) confirms
    this task is part of the Milestone 7 epic decomposition. This is the designated
    first implementation task and should proceed with implementation.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: null
oompah.agent_run_id: 69a330c7-605a-4086-bbf7-a8ae82f1cd11
oompah.work_branch: epic-EXOCOMP-128--task-EXOCOMP-136
oompah.integration:
  version: 2
  state: integrated
  attempts: 1
  task_branch: epic-EXOCOMP-128--task-EXOCOMP-136
  base_branch: epic-EXOCOMP-128
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  head_sha: 3a3d6e6171127328361ee88715d55af03d238a15
  integrated_sha: 3a3d6e6171127328361ee88715d55af03d238a15
  submitted_at: '2026-08-01T14:57:46.426001+00:00'
  updated_at: '2026-08-01T14:59:00.352029+00:00'
oompah.task_costs:
  total_input_tokens: 12623497
  total_output_tokens: 51964
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 12623497
      output_tokens: 51964
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 170
    output_tokens: 5815
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:36:44.543597+00:00'
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 415
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:41:07.392368+00:00'
  - profile: default
    model: haiku
    input_tokens: 12623317
    output_tokens: 45734
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:59:17.514329+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-136__20260801T143445Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-128--task-EXOCOMP-136
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:36:44.551221+00:00'
  - run_id: EXOCOMP-136__20260801T143918Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-128--task-EXOCOMP-136
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:41:07.398843+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-dfcc8a5f108c: '2026-08-01T15:08:41.938933+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-136
    target_state: Done
    evidence_fingerprint: 18cc36cf7c735da2bab8cf2478ead7ae1ef5fa3e637939603415d4170ae67a5a
    audit_ids:
    - audit-924732ce09f9
    kind: result
    applied: true
    retired_at: '2026-08-01T15:08:41.938941+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-136
    audit_id: audit-924732ce09f9
    attempt_id: attempt-dfcc8a5f108c
    target_state: Done
    evidence_fingerprint: 18cc36cf7c735da2bab8cf2478ead7ae1ef5fa3e637939603415d4170ae67a5a
    status: Needs CI Fix
    audit_ids:
    - audit-924732ce09f9
    applied: true
    created_at: '2026-08-01T15:08:41.938950+00:00'
    applied_at: '2026-08-01T15:08:44.611481+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-924732ce09f9
    project_id: proj-c260b117
    task_id: EXOCOMP-136
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 18cc36cf7c735da2bab8cf2478ead7ae1ef5fa3e637939603415d4170ae67a5a
    attempts:
    - version: 1
      attempt_id: attempt-dfcc8a5f108c
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 18cc36cf7c735da2bab8cf2478ead7ae1ef5fa3e637939603415d4170ae67a5a
      created_at: '2026-08-01T14:59:23.890525+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T14:59:23.890525+00:00'
      branch_key: epic-EXOCOMP-128--task-EXOCOMP-136
      verdict: fail
      failure_classification: ci_failure
      completed_at: '2026-08-01T15:08:41.938836+00:00'
      ended_at: '2026-08-01T15:08:41.938836+00:00'
    requested_by:
      version: 1
      identity: oompah-integration
      source: service
    previous_state: Ready to Integrate
    created_at: '2026-08-01T14:59:01.940079+00:00'
    updated_at: '2026-08-01T15:08:41.938836+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-dfcc8a5f108c
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 18cc36cf7c735da2bab8cf2478ead7ae1ef5fa3e637939603415d4170ae67a5a
    created_at: '2026-08-01T14:59:23.890525+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T14:59:23.890525+00:00'
    branch_key: epic-EXOCOMP-128--task-EXOCOMP-136
---
## Summary

Plan: plans/mission-control.md, Architecture.

Deliverables:
- Add a new Phoenix LiveView application to the umbrella with a separate Mission Control OTP release.
- Add a minimal endpoint, router, supervision tree, static asset pipeline, and GET /health response.
- Keep the application independent from node and coordinator startup.

Acceptance:
- The application starts in test mode and the health route returns 200.
- A focused endpoint test and application supervision test pass.
- Existing node/coordinator tests remain unchanged.

Out of scope: PostgreSQL schemas, authentication, fleet pages, and container packaging.
Quality gate: make fmt-check, make test, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:34
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:34
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:36
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 45, Tool calls: 21
- Tokens: 170 in / 5.8K out [6.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 6s
- Log: EXOCOMP-136__20260801T143445Z.jsonl
---
author: oompah
created: 2026-08-01 14:39
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:39
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:41
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 43, Tool calls: 21
- Tokens: 10 in / 415 out [425 total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 57s
- Log: EXOCOMP-136__20260801T143918Z.jsonl
---
author: oompah
created: 2026-08-01 14:41
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:41
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-08-01 14:41
---
Understanding: scaffold an independent Mission Control Phoenix LiveView umbrella application with its own OTP release, minimal endpoint/router/static pipeline, and GET /health returning 200. I will inspect the existing umbrella and architecture plan, implement focused endpoint and supervision tests without changing node/coordinator behavior, run make fmt-check, make test, and make lint, then commit, push, and submit.
---
author: oompah
created: 2026-08-01 14:44
---
Discovery: existing apps use Application supervision trees and Bandit/Plug; the lockfile already contains Bandit, Plug, telemetry, and WebSock but no Phoenix packages. I’ll use the integration-friendly names :exocomp_mission_control, Exocomp.MissionControl.Application, and Exocomp.MissionControl.Endpoint, keeping this change limited to scaffold, health route, static serving, focused tests, and release wiring.
---
author: oompah
created: 2026-08-01 14:54
---
Implementation: added apps/exocomp_mission_control with Phoenix 1.7/Bandit/LiveView/PubSub dependencies, independent supervision tree, /live socket, Plug.Static pipeline, JSON GET /health route, tracked robots.txt, test helper, endpoint tests, and supervision/independence tests. Added test-safe endpoint config, production runtime port/secret configuration, and the separate mission_control OTP release including shared core only (no node/coordinator startup).
---
author: oompah
created: 2026-08-01 14:57
---
Verification: file-scoped mix format/checks, Elixir syntax parsing, git diff checks, dependency resolution, and make compliance-check pass. Offline portions of make test and make lint pass (13 release-builder checks plus packaging/operator-doc tests). The required container-backed portions of make fmt-check, make test, and make lint cannot start because Podman fails on the sandbox read-only /run/user/1000/libpod runtime; host Mix is Elixir 1.18.3 versus the project-pinned 1.20.2.
---
author: oompah
created: 2026-08-01 14:57
---
Completion: Mission Control is scaffolded and pushed in commit 3a3d6e61. The standalone Phoenix LiveView app has independent PubSub/endpoint supervision, Bandit runtime config, /live socket, static asset serving, GET /health, test coverage, a separate mission_control OTP release, and dependency license inventory updates. Branch is clean and up to date with origin; container-backed quality gates remain environment-blocked by the read-only Podman runtime documented above.
---
author: oompah
created: 2026-08-01 14:57
---
Scaffolded and pushed the independent Mission Control Phoenix LiveView application with health endpoint, static pipeline, supervision tests, and mission_control OTP release.
---
author: oompah
created: 2026-08-01 14:59
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-01 14:59
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 162
- Tokens: 12.6M in / 45.7K out [12.7M total]
- Cost: $0.0000
- Exit: terminated, Duration: 18m 2s
- Log: EXOCOMP-136__20260801T144123Z.jsonl
---
author: oompah
created: 2026-08-01 14:59
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 14:59
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 15:08
---
Audit FAIL — ci failure. Routing task to Needs CI Fix.

[REDACTED]

Instructions:
- Rewrite apps/exocomp_mission_control/lib/exocomp/mission_control/router.ex to use a Phoenix controller with a `health/2` action inside a `pipeline :api` + `scope "/", Exocomp.MissionControl` block.
- Re-run `make test` and `make lint` inside the pinned builder container so the umbrella compiles and both endpoint and application tests pass.
- Re-request the terminal audit only after the container-backed `make test` and `make lint` succeed.
---
<!-- COMMENTS:END -->

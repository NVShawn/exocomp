---
id: EXOCOMP-192
type: task
status: Done
priority: 2
title: Schedule service discovery and observations in the coordinator
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-188
- EXOCOMP-190
- EXOCOMP-191
labels: []
assignee: null
created_at: '2026-07-30T21:37:02.009432Z'
updated_at: '2026-08-01T18:01:11.179283Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-192
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: c3d4b1c7dfae5adf41d81e0d95bc8fe379f913c49dca8ecc83be6db1423bea0c
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T15:58:15.354994+00:00'
  matched_identifiers: []
  evidence: '## Investigation Complete


    I have completed my duplicate investigation for EXOCOMP-192. Here are my findings:


    ### What I Searched For


    I examined:

    1. **Existing code structure** - searched for any service discovery, discovery
    scheduler, or service observation code in the coordinator

    2. **Related infrastructure** - found `Exocomp.DesiredService` module created
    by EXOCOMP-189 with source types and resolver logic

    3. **Existing scheduling patterns** - found `HealthPoller` (30-second health cadence)
    and `Orchestrator` (bounded fan-out framework)

    4. **Test coverage** - searched for any existing tests related to service discovery
    scheduling


    ### Key Findings


    **EXOCOMP-189 (Integrated)**: Added infrastructure components:

    - `Exocomp.DesiredService` module with source types (`:manual`, `:automatic`,
    `:cluster_profile`)

    - Deterministic three-path resolver for merging contributions

    - Table-driven unit tests


    **EXOCOMP-192 (This Task)**: Distinct and separate work:

    - Requires NEW scheduler for service discovery (startup + every 5 minutes)

    - Requires service observation on health cadence (existing 30-second)

    - Requires jitter, bounded concurrency, per-node timeouts, and caching logic

    - Requires injectable clock for deterministic tests

    - No existing implementation found


    **Existing Patterns Available**:

    - `HealthPoller` - provides periodic polling framework with bounded concurrency

    - `Orchestrator` - provides fan-out with per-node isolation and timeouts

    - These are patterns to build upon, not duplicates


    ### Conclusion


    EXOCOMP-192 represents original, non-duplicated work. It''s a distinct implementation
    task that builds on the infrastructure created by EXOCOMP-189, but implements
    new scheduling logic not yet present in the coordinator.


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** After thorough exploration of the coordinator codebase, I found
    no existing service discovery scheduler, observation servi'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 967d499b-29ae-446d-8817-9643a47fcf8d
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-192
oompah.integration:
  version: 2
  state: integrated
  attempts: 1
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-192
  base_branch: epic-EXOCOMP-185
  base_sha: 7b3ff4a831259ec5555de09214348b3da5eb554e
  head_sha: 2304acc105f13ebc16792ffc8ea7a57e48be313d
  integrated_sha: 2304acc105f13ebc16792ffc8ea7a57e48be313d
  submitted_at: '2026-08-01T16:16:37.783943+00:00'
  updated_at: '2026-08-01T16:17:16.385652+00:00'
oompah.task_costs:
  total_input_tokens: 248
  total_output_tokens: 6920
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 242
      output_tokens: 6565
      cost_usd: 0.0
    unknown:
      input_tokens: 6
      output_tokens: 355
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 242
    output_tokens: 6565
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:58:15.342909+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 6
    output_tokens: 355
    cost_usd: 0.0
    recorded_at: '2026-08-01T16:34:03.403394+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-192__20260801T155333Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-185--task-EXOCOMP-192
    source_sha: 7b3ff4a831259ec5555de09214348b3da5eb554e
    completed_at: '2026-08-01T15:58:15.369409+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-7b41955c1a06: '2026-08-01T16:33:16.344729+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-192
    target_state: Done
    evidence_fingerprint: 54e2c2b55373842795235d078a99c1f683461501d2e59d940bf8e4436896ee62
    audit_ids:
    - audit-05de04dbbbb1
    kind: result
    applied: true
    retired_at: '2026-08-01T16:33:16.344741+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-192
    audit_id: audit-05de04dbbbb1
    attempt_id: attempt-7b41955c1a06
    target_state: Done
    evidence_fingerprint: 54e2c2b55373842795235d078a99c1f683461501d2e59d940bf8e4436896ee62
    status: Done
    audit_ids:
    - audit-05de04dbbbb1
    applied: true
    created_at: '2026-08-01T16:33:16.344757+00:00'
    applied_at: '2026-08-01T16:33:20.579005+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-05de04dbbbb1
    project_id: proj-c260b117
    task_id: EXOCOMP-192
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 54e2c2b55373842795235d078a99c1f683461501d2e59d940bf8e4436896ee62
    attempts:
    - version: 1
      attempt_id: attempt-7b41955c1a06
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 54e2c2b55373842795235d078a99c1f683461501d2e59d940bf8e4436896ee62
      created_at: '2026-08-01T16:17:33.000442+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T16:17:33.000442+00:00'
      branch_key: epic-EXOCOMP-185--task-EXOCOMP-192
      verdict: pass
      completed_at: '2026-08-01T16:33:16.344441+00:00'
      ended_at: '2026-08-01T16:33:16.344441+00:00'
    requested_by:
      version: 1
      identity: oompah-integration
      source: service
    previous_state: Ready to Integrate
    created_at: '2026-08-01T16:17:18.577568+00:00'
    updated_at: '2026-08-01T16:33:16.344441+00:00'
  - version: 1
    audit_id: audit-59a5874d61f3
    project_id: proj-c260b117
    task_id: EXOCOMP-192
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 4b631ebb055080e45aa30c1b0a156d043752cf9a54bbb9835671f625776e057c
    attempts: []
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: Done
    created_at: '2026-08-01T18:01:10.398405+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-7b41955c1a06
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 54e2c2b55373842795235d078a99c1f683461501d2e59d940bf8e4436896ee62
    created_at: '2026-08-01T16:17:33.000442+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T16:17:33.000442+00:00'
    branch_key: epic-EXOCOMP-185--task-EXOCOMP-192
---
## Summary

Plan: plans/mission-control.md, desired-state polling.

Deliverable: Add coordinator scheduling that discovers automatic services on startup and every five minutes and observes effective services on the existing 30-second health cadence.

Acceptance criteria:
- Use jitter, bounded concurrency, per-node timeouts, and the existing backoff/isolation patterns.
- Cache the newest successful discovery without replacing it with a failed scan.
- Inventory replacement triggers prompt reconciliation.
- One slow or unreachable node cannot block peers.
- Scheduling uses an injectable clock for deterministic tests.

Tests: Cover startup, periodic refresh, jitter, cache preservation, inventory reload, timeout isolation, and cancellation; run make test.

Out of scope: Merge rules, status event schemas, incidents, and recovery.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:53
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:58
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 68, Tool calls: 29
- Tokens: 242 in / 6.6K out [6.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 4m 52s
- Log: EXOCOMP-192__20260801T155333Z.jsonl
---
author: oompah
created: 2026-08-01 15:58
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 15:58
---
Focus: Software Engineer
---
author: oompah
created: 2026-08-01 15:58
---
Understanding: add coordinator scheduling for startup and five-minute automatic-service discovery plus 30-second effective-service observations, using injectable-clock tests and existing jitter, bounded concurrency, node timeout, backoff/isolation, cache, inventory-reload, and cancellation patterns.
---
author: oompah
created: 2026-08-01 16:02
---
Discovery: existing HealthPoller/Registry already provide 30-second jittered health cadence, bounded async workers, timeout isolation, and exponential backoff. Inventory v2 supplies automatic/manual service configuration; node skills expose exocomp.service.inventory and exocomp.service.observe. I will add a supervised ServiceScheduler around those seams, with generation guards and successful-discovery cache preservation.
---
author: oompah
created: 2026-08-01 16:12
---
Implementation: added ServiceScheduler with startup/five-minute jittered discovery, successful-cache-only updates, generation guards, bounded supervised workers, per-task timeout, failure backoff, prompt inventory-reload reconciliation, effective manual+automatic service selection, and cancellable work. Wired HealthPoller successful node cadence to queue service observations; Inventory replacement now notifies the scheduler; application starts the service task supervisor and scheduler. Added focused scheduler tests.
---
author: oompah
created: 2026-08-01 16:14
---
Verification: focused ServiceScheduler suite passed 7/7 and existing HealthPoller suite passed 5/5 via direct Elixir compilation under the available 1.18 runtime. git diff --check and targeted format checks pass. make test ran offline checks successfully, then was blocked by the pinned Elixir 1.20.2 Podman container failing to chmod /run/user/1000/libpod on the read-only filesystem.
---
author: oompah
created: 2026-08-01 16:16
---
Completion: delivered and pushed commit 2304acc1. ServiceScheduler now performs startup/jittered five-minute automatic discovery, preserves successful cache entries across failed scans, schedules effective-service observation through successful 30-second HealthPoller cadence, isolates slow peers with bounded supervised workers and per-node deadlines, reconciles inventory replacement promptly with generation guards, and supports cancellation. Focused tests cover startup, periodic jitter, cache preservation, effective services, artifact normalization, reload, timeout isolation, cancellation, and health handoff. Branch is clean and up to date with origin.
---
author: oompah
created: 2026-08-01 16:16
---
Implemented coordinator service discovery and effective-service observation scheduling with jitter, bounded isolated workers, timeouts, cache preservation, inventory-triggered reconciliation, injectable clock seams, and focused tests. Pushed commit 2304acc1; make test offline checks passed but pinned Elixir container was blocked by read-only Podman runtime.
---
author: oompah
created: 2026-08-01 16:16
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 114
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 18m 30s
- Log: EXOCOMP-192__20260801T155830Z.jsonl
---
author: oompah
created: 2026-08-01 16:17
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-01 16:17
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 16:17
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 16:33
---
Audit PASS — Done

[REDACTED]

Safe evidence:
- branch_head: 2304acc105f13ebc16792ffc8ea7a57e48be313d
- remote_head_epic-EXOCOMP-185--task-EXOCOMP-192: 2304acc105f13ebc16792ffc8ea7a57e48be313d
- files_changed: coordinator/application.ex(+9), coordinator/health_poller.ex(+19), coordinator/inventory.ex(+25), coordinator/service_scheduler.ex(new, 772 LOC), test/service_scheduler_test.exs(new, 343 LOC)
- test_make_test-deps: 9 passed, 0 failed
- test_make_test-builders: 22 passed, 0 failed (13 offline structural + 9 runtime deps)
- test_make_test-release-packaging: 16 passed (6 package + 3 normalizer + 7 operator docs)
- test_make_test: chain completed; exocomp_node and exocomp_coordinator releases rebuilt during audit at 16:27:37-38 (Makefile uses && chaining after mix test)
- test_make_test-compliance: 28/29 pass; sole failure = pre-existing trailing whitespace at inventory_test.exs:{90,99,123,133,136,149,156,158} introduced by commit e211afce (EXOCOMP-188), not by 2304acc1
- acceptance_criteria_jitter_concurrency_timeout_backoff: verified in service_scheduler.ex — discovery_jitter_ms default 30s via injectable random; concurrency default 4 enforced in dispatch_kind; per-task Process.send_after with brutal_kill; exponential backoff with backoff_cap_ms
- acceptance_criteria_cache_preservation: handle_result(:discovery) writes cache only on {:ok, services}; :error branch records failure without touching discovery_cache
- acceptance_criteria_inventory_reload: Inventory.notify_reconciliation invokes ServiceScheduler.inventory_replaced which bumps generations, cancels tasks, prunes removed nodes, and requests fresh discovery+observation
- acceptance_criteria_peer_isolation: Task.Supervisor.async_nolink + per-task timeout + generation guard verified; test 'a timed-out node does not block a peer' covers scenario
- acceptance_criteria_injectable_clock: clock and random passed as opts (defaults DateTime.utc_now/0 and :rand.uniform-based); test suite uses Agent-backed clock
---
author: oompah
created: 2026-08-01 16:34
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 0, Tool calls: 71
- Tokens: 6 in / 355 out [361 total]
- Cost: $0.0000
- Exit: terminated, Duration: 16m 26s
- Log: EXOCOMP-192__20260801T161746Z.jsonl
---
<!-- COMMENTS:END -->

---
id: EXOCOMP-147
type: task
status: In Progress
priority: 1
title: Add heartbeat, disconnect detection, and reconnect backoff
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-146
start_blocked_by: []
labels:
- focus-complete:frontend
assignee: null
created_at: '2026-07-30T14:15:03.538393Z'
updated_at: '2026-08-03T21:58:32.264591Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-147
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 1212be6e326192fc087f66ee0a620f8a497b62faca881250125e5e9dc98afa87
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:17:12.270779+00:00'
  matched_identifiers: []
  evidence: 'Thank you for the coordination message. This provides important context
    that confirms my investigation findings.


    The coordination from EXOCOMP-146 stating **"dependency, epic-sibling"** relationship
    confirms that EXOCOMP-147 and EXOCOMP-146 are **not duplicates** but rather **dependent
    sequential tasks** within the same epic (EXOCOMP-130).


    The "Blocked by" relationship in the issue description further confirms:

    - EXOCOMP-146 is preparatory/foundational work that EXOCOMP-147 depends on

    - They have a clearly defined dependency order, not overlapping scope

    - Both are parts of the larger Mission Control implementation epic


    My investigation conclusion remains unchanged:


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** No existing heartbeat, disconnect detection, or reconnect backoff
    implementation exists in the codebase. The mission-control.md plan defines these
    requirements, and EXOCOMP-147 is a fresh task with a confirmed dependency relationship
    (not duplicate relationship) to EXOCOMP-146. Coordination confirms they are dependent
    epic-sibling tasks with sequential work order, not overlapping implementations
    of the same feature.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 3cd36ed3-87b1-4763-a0d7-2f9660633292
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-147
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-147
  base_branch: epic-EXOCOMP-130
  base_sha: ea1d7208e4dec7474b76c4dc437c0d7608b4116e
  updated_at: '2026-08-03T21:51:30.106052+00:00'
oompah.task_costs:
  total_input_tokens: 1819373
  total_output_tokens: 23778
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 522
      output_tokens: 1270
      cost_usd: 0.0
    sonnet:
      input_tokens: 1818851
      output_tokens: 22508
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1180
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:17:12.270035+00:00'
  - profile: default
    model: haiku
    input_tokens: 512
    output_tokens: 90
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:20:10.652900+00:00'
  - profile: standard
    model: sonnet
    input_tokens: 384868
    output_tokens: 3758
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:36:38.626170+00:00'
  - profile: standard
    model: sonnet
    input_tokens: 156
    output_tokens: 3600
    cost_usd: 0.0
    recorded_at: '2026-08-03T21:36:46.959041+00:00'
  - profile: standard
    model: sonnet
    input_tokens: 1433827
    output_tokens: 15150
    cost_usd: 0.0
    recorded_at: '2026-08-03T21:57:54.167726+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-147__20260801T121453Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-130--task-EXOCOMP-147
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:17:12.275545+00:00'
  - run_id: EXOCOMP-147__20260801T122138Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-terra
    focus: chore
    source_branch: epic-EXOCOMP-130--task-EXOCOMP-147
    source_sha: 955a4b15b498bcbc28d770e3472a17f5f0ac633c
    completed_at: '2026-08-01T12:36:38.630449+00:00'
  - run_id: EXOCOMP-147__20260803T215137Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-terra
    focus: chore
    source_branch: epic-EXOCOMP-130--task-EXOCOMP-147
    source_sha: 6e6d6e2082af1af2ad870a22024f3054ed5d2be9
    completed_at: '2026-08-03T21:57:54.170645+00:00'
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Send a cluster heartbeat every 30 seconds through the active session.
- Mark a session disconnected after 90 seconds without a valid heartbeat.
- Reconnect with full-jitter exponential backoff from one second to 60 seconds.
- Reset backoff only after a stable authenticated connection.

Acceptance:
- Deterministic clock/randomness tests cover heartbeat cadence, missed heartbeats, reconnect bounds, reset, and duplicate timers.
- Connection loss does not crash the coordinator or block local work.
- Mission Control publishes connected/disconnected state only after committing it.

Out of scope: event persistence and UI.
Quality gate: focused state-machine tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:14
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:14
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:17
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 64, Tool calls: 27
- Tokens: 10 in / 1.2K out [1.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 27s
- Log: EXOCOMP-147__20260801T121453Z.jsonl
---
author: oompah
created: 2026-08-01 12:17
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:17
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 12:19
---
**Understanding**: Task requires implementing heartbeat protocol for coordinator-to-Mission Control connection: (1) Send heartbeat every 30s, (2) Mark disconnected after 90s without heartbeat, (3) Reconnect with full-jitter exponential backoff (1s-60s), (4) Reset backoff after stable auth connection. Acceptance requires deterministic tests covering heartbeat cadence, missed heartbeats, reconnect bounds, and no crash/blocking on connection loss.

**Assigned Focus**: Frontend Developer - mismatch detected. This is coordinator connection infrastructure work (state machines, timers, network resilience), not UI. Exploring if frontend component exists or if handoff needed to backend focus.
---
author: oompah
created: 2026-08-01 12:19
---
**HANDOFF: Backend required**

Investigation shows EXOCOMP-147 is coordinator connection infrastructure work:

**What needs implementing:**
- Heartbeat sender: send to Mission Control every 30s
- Disconnect detector: mark disconnected after 90s without heartbeat  
- Reconnect backoff: full-jitter exponential backoff from 1s to 60s cap
- Backoff reset: only after stable authenticated connection

**Why frontend handoff:**
- No existing Mission Control app or connection client to enhance
- Work is state machine logic (coordinator GenServer), not UI
- Acceptance tests require deterministic clock/randomness tests for connection state transitions
- Requires testing: heartbeat cadence, missed heartbeats, reconnect bounds, duplicate timer prevention
- This is backend resilience/network engineering, not user-facing UI

**Recommendation:** Route to backend/infrastructure focus for connection client implementation in coordinator. Frontend involvement would come later if Mission Control UI needs to display connection state indicators.

Blocked by EXOCOMP-146; check if that provides base connection scaffolding.
---
author: oompah
created: 2026-08-01 12:20
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 0, Tool calls: 33
- Tokens: 512 in / 90 out [602 total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 44s
- Log: EXOCOMP-147__20260801T121736Z.jsonl
---
author: oompah
created: 2026-08-01 12:21
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-01 12:21
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 12:36
---
Coordination review: EXOCOMP-148, EXOCOMP-149, EXOCOMP-150, and EXOCOMP-151 have started as epic siblings. EXOCOMP-147 is isolated to coordinator Mission Control connection/liveness (heartbeat, disconnect detection, and reconnect backoff), so no sibling dependency or file overlap was identified; no task graph change is required. Branch is clean and already pushed at 955a4b15 (EXOCOMP-147: add Mission Control connection liveness). Quality-gate handoff: make test and make lint passed their offline release/package/doc checks, then could not start the containerized Elixir suite because Podman cannot chmod /run/user/1000/libpod in this sandbox. make fmt-check failed at the same runner boundary. Focused local Mix tests cannot run because host Elixir 1.18.3 is below the pinned 1.20.2. Re-run make test, make fmt-check, and make lint in CI or a runner with the project container toolchain.
---
author: oompah
created: 2026-08-01 12:36
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/gpt-5.6-terra]
- Turns: 2, Tool calls: 82
- Tokens: 384.9K in / 3.8K out [388.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 15m 8s
- Log: EXOCOMP-147__20260801T122138Z.jsonl
---
author: oompah
created: 2026-08-01 12:36
---
Task handoff failed after the worker ran: the server-owned, task-scoped tracker capability could not update this task. The task is held in Needs Human and will not be redispatched automatically; verify the handoff service and reconcile the worker's branch before resuming it.
---
author: oompah
created: 2026-08-01 13:42
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:42
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 13:43
---
Understanding: I will verify the existing Mission Control liveness implementation against the heartbeat, disconnect, jittered reconnect, stable-auth reset, duplicate-timer, commit-before-publish, and local-work resilience requirements; then add only missing focused tests/code, run the required Makefile gates, and push/submit the branch.
---
author: oompah
created: 2026-08-01 13:45
---
Discovery: the current branch has transport-independent Connection and SessionLiveness state machines. Connection schedules one generation-tagged heartbeat per active session, runs connect attempts in monitored workers, and applies 0..cap full-jitter bounds; SessionLiveness records each valid heartbeat and retries failed durable commits before publishing. Focused tests are format-clean, but host Elixir 1.18.3 cannot run the pinned 1.20.2 Mix suite. I’m hardening stale liveness timer handling and adding coverage for connect-worker races and duplicate reconnect signals.
---
author: oompah
created: 2026-08-01 13:48
---
Implementation: hardened the existing liveness state machines. Connection now ignores stale stability signals unless the session is still authenticated/connected and stops an obsolete in-flight connect worker when a session is installed. SessionLiveness now tags timeout vs commit-retry timers, retries the requested connected/disconnected transition, clears pending transitions after commit, and ignores duplicate fired/canceled timer signals. Added deterministic tests for stale stability, worker replacement, duplicate disconnect signals, and connected-state commit retry.
---
author: oompah
created: 2026-08-01 13:49
---
Verification: focused deterministic liveness tests pass (11 tests, 0 failures) using direct Elixir execution; focused mix format check and git diff --check pass. make test, make fmt-check, and make lint each pass their offline structural/release/package/document checks, then stop at the environment boundary because Podman cannot chmod /run/user/1000/libpod (read-only filesystem), so the pinned Elixir 1.20.2 container gates remain for CI/privileged runner.
---
author: oompah
created: 2026-08-01 13:50
---
Completion: pushed commit 9c720a4d on the issue branch. Delivered heartbeat cadence and generation-safe timers, 90-second valid-heartbeat disconnect detection, bounded full-jitter reconnect backoff with stable-auth reset, commit-before-publish state transitions, duplicate timer protection, stale worker shutdown, and deterministic focused coverage. Focused tests pass (11/11), formatting/diff checks pass, and all required Make gates reach their offline checks before the sandbox Podman permission boundary. Branch is clean and up to date with origin.
---
author: oompah
created: 2026-08-01 13:50
---
Harden Mission Control heartbeat, disconnect, reconnect backoff, and duplicate-timer state machines with deterministic coverage.
---
author: oompah
created: 2026-08-01 13:50
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 59
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 7m 48s
- Log: EXOCOMP-147__20260801T134241Z.jsonl
---
author: oompah
created: 2026-08-03 21:08
---
Integration found a rebase conflict on `epic-EXOCOMP-130--task-EXOCOMP-147`. Resolve it against `epic-EXOCOMP-130`, run the required tests, push the same private branch, and `oompah task submit` it again.
---
author: oompah
created: 2026-08-03 21:19
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-03 21:20
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-03 21:35
---
Discovery: Previous agents had already implemented both deliverables: connection.ex (heartbeat every 30s, full-jitter exponential backoff 1s-60s, stable connection reset after 90s) and session_liveness.ex (disconnect detection after 90s without heartbeat, commit-before-publish). Tests existed in connection_test.exs (5 tests) and session_liveness_test.exs (5 tests), covering all acceptance criteria. However make lint failed with a type warning indicating a latent bug: the :DOWN handler for connect_monitor_ref used a pipe chain that reversed the schedule_reconnect/2 arguments (state passed as reason, reason as state). The bug was silent at runtime because connect workers normally exit cleanly via safely/catch, but would crash the coordinator if a worker was killed externally mid-connect.
---
author: oompah
created: 2026-08-03 21:35
---
Implementation: (1) Fixed bug in connection.ex line 171: pipe chain  reversed the args to schedule_reconnect/2 (which takes reason first, state second). Replaced with . (2) Added test  in connection_test.exs: kills the worker with Process.exit(:kill) (bypasses safely wrapper) so the :DOWN path is hit directly, verifying backoff is scheduled with last_error: {:connect_worker_down, :killed}. Files changed: apps/exocomp_coordinator/lib/exocomp/coordinator/mission_control/connection.ex, apps/exocomp_coordinator/test/exocomp/coordinator/mission_control/connection_test.exs.
---
author: oompah
created: 2026-08-03 21:36
---
Verification: All 12 focused state-machine tests pass (11 pre-existing + 1 new worker DOWN test). make fmt-check passes. make lint passes with no warnings (previously failing with type warning on swapped args). Branch 2289df54 pushed to origin.
---
author: oompah
created: 2026-08-03 21:36
---
Delivered heartbeat, disconnect detection, and reconnect backoff for Mission Control coordinator sessions. connection.ex provides 30s heartbeat cadence, full-jitter exponential backoff 1s-60s, and 90s stability window for backoff reset. session_liveness.ex tracks server-side disconnect detection at 90s with commit-before-publish guarantee. Fixed a latent bug: schedule_reconnect args were reversed in the connect-worker :DOWN handler, which would have crashed the coordinator if a worker was killed externally mid-connect. Added test covering the :DOWN path with uncatchable :kill signal. All 12 focused tests pass, make fmt-check and make lint both clean at 2289df54.
---
author: oompah
created: 2026-08-03 21:36
---
Run #1 [attempt=1, profile=standard, role=standard -> Claude/sonnet]
- Turns: 0, Tool calls: 65
- Tokens: 156 in / 3.6K out [3.8K total]
- Cost: $0.0000
- Exit: terminated, Duration: 16m 51s
- Log: EXOCOMP-147__20260803T212022Z.jsonl
---
author: oompah
created: 2026-08-03 21:50
---
Integration found a rebase conflict on `epic-EXOCOMP-130--task-EXOCOMP-147`. Resolve it against `epic-EXOCOMP-130`, run the required tests, push the same private branch, and `oompah task submit` it again.
---
author: oompah
created: 2026-08-03 21:51
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-03 21:51
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-03 21:57
---
Agent completed successfully in 391s (1448977 tokens)
---
author: oompah
created: 2026-08-03 21:57
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/gpt-5.6-terra]
- Turns: 1, Tool calls: 42
- Tokens: 1.4M in / 15.2K out [1.4M total]
- Cost: $0.0000
- Exit: normal, Duration: 6m 31s
- Log: EXOCOMP-147__20260803T215137Z.jsonl
---
author: oompah
created: 2026-08-03 21:58
---
Agent completed without closing this issue (391s (1448977 tokens)). Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
<!-- COMMENTS:END -->

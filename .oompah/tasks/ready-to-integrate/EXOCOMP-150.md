---
id: EXOCOMP-150
type: task
status: Ready to Integrate
priority: 1
title: Persist and deliver server-to-cluster commands
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-137
- EXOCOMP-139
- EXOCOMP-146
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:07.042172Z'
updated_at: '2026-08-03T21:30:20.938024Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-150
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 0d6ca87355e1568fe7b0172c89c87020bfcf5c14e125bff600125b48626419dd
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:26:02.847195+00:00'
  matched_identifiers: []
  evidence: "Based on my comprehensive investigation of the codebase and task tracking\
    \ system, I have completed my duplicate screening for EXOCOMP-150.\n\n## Investigation\
    \ Summary\n\nI searched for:\n1. Direct command outbox and durable delivery patterns\
    \ \u2014 no matches\n2. Server-to-cluster command handling \u2014 no matches\n\
    3. References to all related EXOCOMP task IDs (EXOCOMP-137, 139, 145-149, 151)\
    \ \u2014 no matches anywhere in the repository\n4. Similar queue/acknowledgment/expiration\
    \ patterns \u2014 no matches\n5. Existing command handling implementation \u2014\
    \ no matches\n\n**Key Finding:** EXOCOMP-150 requests implementation of the \"\
    Connection and Delivery Protocol\" section from `plans/mission-control.md`, which\
    \ is a Milestone 7 design document. The plan explicitly describes the command\
    \ outbox requirement but no implementation code exists yet. No other active task\
    \ is implementing this same functionality.\n\n**Evidence:** The mission-control.md\
    \ plan (section \"Connection and Delivery Protocol\") documents the exact specification:\
    \ \"Server-to-cluster commands carry `command_id`, `kind`, `issued_at`, `expires_at`,\
    \ and `payload`. Commands remain in a durable server outbox until the active cluster\
    \ session acknowledges them or they expire.\" This matches EXOCOMP-150's deliverables\
    \ precisely. The repository contains no existing implementation of this pattern,\
    \ and no other tasks reference this functionality.\n\n---\n\n**Focus handoff:\
    \ duplicate_detector**\n\n**Duplicate preflight verdict: no_duplicate**\n\n**Matches:\
    \ none**\n\n**Evidence:** After exhaustive search across `.oompah`, `apps/`, `docs/`,\
    \ and `plans/` directories for command outbox, server-to-cluster delivery, durable\
    \ queue, acknowledgement, or expiration patterns, I found no matching active tasks\
    \ or implementations. EXOCOMP-150 is the sole task implementing the \"Connection\
    \ and Delivery Protocol\" from the mission-control.md Milestone 7 plan. All referenced\
    \ peer tasks (EXOCOMP-137, 139, 145-149, 151) exist in the coordination metadata\
    \ but not in the repository, conf"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 5d7a9185-fe44-4b50-b928-a2d14a528ee0
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-150
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-150
  head_sha: 8272b07d81bfeb75d7831a252a7f9fff54db83f2
  submitted_at: '2026-08-03T21:29:51.498555+00:00'
  updated_at: '2026-08-03T21:29:51.498555+00:00'
oompah.task_costs:
  total_input_tokens: 768
  total_output_tokens: 4005
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 768
      output_tokens: 4005
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 114
    output_tokens: 3850
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:26:02.846544+00:00'
  - profile: default
    model: haiku
    input_tokens: 654
    output_tokens: 155
    cost_usd: 0.0
    recorded_at: '2026-08-03T21:30:19.192793+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-150__20260801T122456Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-130--task-EXOCOMP-150
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:26:02.852468+00:00'
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Add a durable command outbox containing command ID, kind, issued_at, expires_at, organization, cluster, and validated payload.
- Deliver pending commands to whichever Mission Control replica owns the active cluster session.
- Mark commands acknowledged exactly once; expire undelivered commands without treating them as executed.

Acceptance:
- Tests cover offline cluster, reconnect, duplicate acknowledgement, expiration, replica ownership change, invalid command kind, and database rollback.
- Commands survive Mission Control process restart.

Out of scope: chat/proposal command business logic.
Quality gate: focused command-outbox tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:24
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:26
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 37, Tool calls: 20
- Tokens: 114 in / 3.9K out [4.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 16s
- Log: EXOCOMP-150__20260801T122456Z.jsonl
---
author: oompah
created: 2026-08-01 12:26
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:26
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 12:26
---
Understanding: I will trace the Mission Control command/session and database patterns, add a durable validated command outbox with ownership-aware delivery and exactly-once acknowledgement/expiry semantics, cover the listed failure cases, then run focused tests and the required Makefile quality gates.
---
author: oompah
created: 2026-08-01 12:31
---
Discovery: the task graph confirms EXOCOMP-137 will provide the Mission Control Ecto/Postgrex Repo, EXOCOMP-139 the protocol allow-list/validation, and EXOCOMP-146 the authenticated session owner. This checkout contains none of those merged yet. I will keep the outbox boundary isolated in Exocomp.MissionControl.CommandOutbox, use an organization/cluster-scoped durable schema, and make delivery session-targeted so a reconnecting/new replica can drain the same pending rows without coupling to transport internals.
---
author: oompah
created: 2026-08-01 12:38
---
Implementation: added Exocomp.MissionControl.CommandOutbox with validated command creation, organization/cluster-scoped pending queries, atomic pending-to-acknowledged transition, idempotent duplicate acknowledgement, expiry to a terminal non-executed state, and session-targeted at-least-once delivery. Added durable command_outbox migration/schema, local active-session ownership replacement, and focused outbox/registry tests. Ecto/Postgrex dependencies are locked for the new Mission Control app.
---
author: oompah
created: 2026-08-01 12:42
---
Verification: focused command-outbox tests pass (9 tests, 0 failures); Ecto-backed modules compile without warnings when compiled against the fetched Ecto/Postgrex dependencies; session-registry smoke test passes. make test and make lint passed their offline builder checks but could not enter the container phase because podman reports the sandbox filesystem is read-only for /run/user/1000/libpod. make fmt-check is similarly blocked at container startup. Scoped source formatting and git diff checks pass.
---
author: oompah
created: 2026-08-01 12:43
---
Completion: delivered commit 5977f064 and pushed epic-EXOCOMP-130--task-EXOCOMP-150. The Mission Control outbox persists validated commands, retries them through the active session owner after reconnect/replica replacement, acknowledges exactly once, and expires undelivered rows without execution semantics. Focused tests pass 9/9; Make offline checks pass, while container-backed make test/fmt-check/lint remain environment-blocked by the read-only podman runtime directory.
---
author: oompah
created: 2026-08-01 12:43
---
Added durable server-to-cluster command outbox with validated payloads, active-session delivery, exactly-once acknowledgement, expiration, and focused tests.
---
author: oompah
created: 2026-08-01 12:44
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 93
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 17m 53s
- Log: EXOCOMP-150__20260801T122619Z.jsonl
---
author: oompah
created: 2026-08-03 20:46
---
Integration found a rebase conflict on `epic-EXOCOMP-130--task-EXOCOMP-150`. Resolve it against `epic-EXOCOMP-130`, run the required tests, push the same private branch, and `oompah task submit` it again.
---
author: oompah
created: 2026-08-03 20:47
---
[watchdog:stalled_task] Stalled-task watchdog audit (run #5)

**State audited:** `Needs Rebase`
**Classification:** `actionable`
**Action:** `reopen`
**Evidence:** Recent comment indicates the conflict or rebase has been resolved; safe to reopen.

*This comment is posted automatically by the oompah stalled-task watchdog. No human action required unless the classification above is incorrect.*
---
author: oompah
created: 2026-08-03 20:51
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-03 20:52
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-03 20:57
---
Understanding: Implement a durable command outbox in Mission Control to persist server-to-cluster commands and deliver them reliably. Need to: (1) create a database schema for command outbox (ID, kind, issued_at, expires_at, org, cluster, payload), (2) implement delivery logic to route commands to the owning replica, (3) track acknowledgments exactly-once, (4) expire undelivered commands without marking as executed, (5) ensure commands survive process restart. Will focus on command-outbox tests, Makefile quality gates. Plan: explore existing code patterns in coordinator and mission_control, check plans/mission-control.md for protocol details, then implement outbox table/queries and delivery logic.
---
author: oompah
created: 2026-08-03 21:22
---
Discovery: Command outbox implementation is complete with Command schema, CommandOutbox module, SessionRegistry, database migration, and comprehensive tests. Found unreachable clause in acknowledgement_result causing type warning. Removing that clause to clean up type checking. Tests: 511 passed. Format check: passed.
---
author: oompah
created: 2026-08-03 21:28
---
Implementation verified: (1) Durable command outbox schema with command_id, kind, issued_at, expires_at, organization_id, cluster_id, payload, status. (2) SessionRegistry tracks active cluster sessions for replica-aware delivery. (3) CommandOutbox.deliver_registered() routes to owning replica. (4) Acknowledge() provides exactly-once semantics via database state transition. (5) Expire() marks undelivered commands terminal. (6) Tests: reconnect, duplicate ack, expiration, ownership change, invalid kind, rollback. All 511 tests passing. Format: passed. Code quality: improved by removing unreachable clause. Ready to integrate.
---
author: oompah
created: 2026-08-03 21:29
---
Completed durable server-to-cluster command outbox with idempotent delivery, replica-aware routing, and terminal expiry. All acceptance tests pass.
---
author: oompah
created: 2026-08-03 21:30
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 0, Tool calls: 35
- Tokens: 654 in / 155 out [809 total]
- Cost: $0.0000
- Exit: terminated, Duration: 38m 33s
- Log: EXOCOMP-150__20260803T205216Z.jsonl
---
<!-- COMMENTS:END -->

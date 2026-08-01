---
id: EXOCOMP-150
type: task
status: In Progress
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
updated_at: '2026-08-01T12:42:24.574425Z'
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
oompah.agent_run_id: ee45f393-6af2-4d9a-98e4-979b9fe3fa9b
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-150
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-150
  base_branch: epic-EXOCOMP-130
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:26:16.391071+00:00'
oompah.task_costs:
  total_input_tokens: 114
  total_output_tokens: 3850
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 114
      output_tokens: 3850
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 114
    output_tokens: 3850
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:26:02.846544+00:00'
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
<!-- COMMENTS:END -->

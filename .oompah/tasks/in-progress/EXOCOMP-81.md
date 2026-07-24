---
id: EXOCOMP-81
type: task
status: In Progress
priority: null
title: Wire A2A message endpoints to TaskRegistry and skill dispatch
parent: EXOCOMP-12
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- focus-complete:epic_planner
assignee: null
created_at: '2026-07-23T23:05:17.322742Z'
updated_at: '2026-07-24T02:01:45.723459Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 3d9037d6-8716-4dcd-abd8-514ecabc75d6
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 336673
  total_output_tokens: 3788
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 336673
      output_tokens: 3788
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 336636
    output_tokens: 2429
    cost_usd: 0.0
    recorded_at: '2026-07-24T01:54:54.872970+00:00'
  - profile: standard
    model: unknown
    input_tokens: 37
    output_tokens: 1359
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:01:28.266398+00:00'
---
## Summary

### Goal
Complete the A2A HTTP endpoint wiring: connect POST /message:send, GET /tasks/:id, GET /tasks, and POST /tasks/:id:cancel to the TaskRegistry and skill Dispatcher. Replace the stub handlers from EXOCOMP-78 with real A2A request/response logic.

### Prerequisites
- EXOCOMP-78: A2ARouter scaffold exists with stub handlers
- EXOCOMP-79: TaskRegistry GenServer is implemented
- EXOCOMP-80: Skill Dispatcher + all three skill handlers are implemented

### Relevant files
- apps/exocomp_node/lib/exocomp/node/a2a_router.ex — add real handlers
- apps/exocomp_node/lib/exocomp/node/task_registry.ex — submit/get/list/cancel API
- apps/exocomp_node/lib/exocomp/node/skills/dispatcher.ex — route to skill handlers
- apps/exocomp_core/lib/exocomp/a2a/ — types for encoding/decoding

### Implementation

### POST /message:send
1. Decode JSON body as A2A Message struct (role, parts, messageId optional)
2. Extract skill_id from message parts (look for TextPart or DataPart with skill key; validate it is one of the three supported skills)
3. Extract skill params from message parts (DataPart data map)
4. Call TaskRegistry.submit(message, skill_id) → {:ok, task_id} | {:error, :at_capacity}
5. If at_capacity → return 429 with InternalError
6. If ok → spawn async worker: Task.start(fn → run_skill_async(task_id, skill_id, params) end)
7. Return 202 with A2A Task JSON (status: submitted)

#### Async skill execution (run_skill_async/3)
1. TaskRegistry.transition(task_id, :working) — registers worker pid
2. Call Skills.Dispatcher.dispatch(skill_id, params)
3. On success: TaskRegistry.transition(task_id, :completed, artifact)
4. On error: TaskRegistry.transition(task_id, :failed, error)
5. Enforce per-skill timeout via Task.await with timeout

### GET /tasks/:id
1. Call TaskRegistry.get(task_id)
2. Not found → 404 with TaskNotFoundError JSON
3. Found → 200 with A2A Task JSON

### GET /tasks
1. Call TaskRegistry.list()
2. Return 200 with JSON array of A2A Task objects

### POST /tasks/:id:cancel
Note: Plug Router pattern for this route is "/tasks/:id:cancel" or use path params carefully.
1. Call TaskRegistry.cancel(task_id)
2. Not found → 404 with TaskNotFoundError JSON
3. Not cancelable → 400 with TaskNotCancelableError JSON
4. Canceled → 200 with updated A2A Task JSON

### JSON encoding/decoding helpers
Create Exocomp.Node.A2A.Codec (or add to A2ARouter) with:
- decode_message/1 — parse JSON map to Message struct; return {:error, InvalidParamsError} on bad input
- encode_task/1 — Task struct → JSON map (handle TaskStatus, Artifact, DataPart)
- encode_error/1 — A2A error struct → JSON-RPC-style %{error: %{code:, message:, data:}}

### A2A error response format
All error responses use Content-Type: application/a2a+json with body:
```json
{"error": {"code": -32001, "message": "Task not found"}}
```

### Tests
- POST /message:send: valid message → 202 with task in submitted state
- POST /message:send: invalid JSON body → 400 InvalidRequestError
- POST /message:send: unknown skill → 400 InvalidParamsError
- POST /message:send: at_capacity → 429
- GET /tasks/:id: known task → 200 with task JSON
- GET /tasks/:id: unknown id → 404 TaskNotFoundError
- GET /tasks: returns list including at least the submitted task
- POST /tasks/:id:cancel: submitted task → 200 with canceled task
- POST /tasks/:id:cancel: completed task → 400 TaskNotCancelableError
- POST /tasks/:id:cancel: unknown id → 404
- Async skill execution: success → task transitions to :completed with artifact
- Async skill execution: skill error → task transitions to :failed

### Quality gate
mix test apps/exocomp_node (focused)

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 01:53
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 01:53
---
Understanding: Screening EXOCOMP-81 for duplication before any implementation. I will search existing tasks and project docs for A2A message endpoint, TaskRegistry, and skill-dispatch wiring, then read plausible candidate tasks in full and either archive this issue as duplicate or hand it off for implementation.
---
author: oompah
created: 2026-07-24 01:54
---
Discovery: Duplicate screening found no confirmed duplicate. Reviewed EXOCOMP-78 (router scaffold with these handlers explicitly left as stubs for child D), EXOCOMP-79 (TaskRegistry only), EXOCOMP-80 (skill handlers/Dispatcher only), EXOCOMP-12 (parent epic whose child graph assigns endpoint wiring uniquely to EXOCOMP-81), EXOCOMP-13 (integration verification only), and EXOCOMP-48 (A2A structs only). The repository task directory is not materialized in this worktree; the required rg search of docs/plans found only the milestone endpoint specification. These tasks are prerequisites, parent, or verification/type-layer work—not duplicates.
---
author: oompah
created: 2026-07-24 01:54
---
Focus handoff: duplicate_detector

Outcome: No duplicate is confirmed. EXOCOMP-81 is the unique endpoint-integration child of EXOCOMP-12; no code was changed.

Evidence and decisions: EXOCOMP-78 explicitly leaves POST /message:send and task get/list/cancel as stubs to be wired by child D. EXOCOMP-79 implements only the bounded TaskRegistry. EXOCOMP-80 implements only Behaviour, three skill handlers, and Dispatcher. EXOCOMP-12 lists all four as complementary children. EXOCOMP-13 covers later end-to-end milestone verification, and EXOCOMP-48 supplies structs without endpoint logic. The current checkout is epic-EXOCOMP-12 (not the prompt's epic-EXOCOMP-1), and it already contains the merged prerequisites from EXOCOMP-80's completion.

Relevant files: apps/exocomp_node/lib/exocomp/node/a2a_router.ex; apps/exocomp_node/lib/exocomp/node/task_registry.ex; apps/exocomp_node/lib/exocomp/node/skills/dispatcher.ex; apps/exocomp_core/lib/exocomp/a2a/; plans/milestone-1-node-agent.md.

Remaining work and risks: Implement message decoding/skill extraction, task submission and async dispatch with timeout/error transitions, task get/list/cancel responses, A2A encoding/error helpers, and all focused endpoint/lifecycle tests. Confirm actual struct field and Dispatcher arity conventions before wiring. Preserve authentication/version/body-limit behavior already established by EXOCOMP-78. Run the focused node test gate and repository quality checks.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 01:54
---
Agent completed successfully in 101s (339065 tokens)
---
author: oompah
created: 2026-07-24 01:54
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 14
- Tokens: 336.6K in / 2.4K out [339.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 41s
- Log: EXOCOMP-81__20260724T015317Z.jsonl
---
author: oompah
created: 2026-07-24 01:54
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 01:55
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 01:55
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-24 01:55
---
Understanding: In the epic-planner phase I will inspect EXOCOMP-81 and any existing child graph, evaluate whether its endpoint/codec/async/test scope should be decomposed into single-session children, avoid implementation, and leave the tracker ready for the feature phase.
---
author: oompah
created: 2026-07-24 01:56
---
Discovery: EXOCOMP-81 is not an epic; EXOCOMP-12 is the parent epic and already has a complete four-child decomposition (EXOCOMP-78 router/auth, EXOCOMP-79 registry, EXOCOMP-80 skills, EXOCOMP-81 endpoint integration). The parent view lists no missing implementation child, and EXOCOMP-81's router/codec/async/tests form one cohesive, single-session integration change. Creating grandchildren would duplicate coordination and introduce artificial dependencies. Relevant specification is plans/milestone-1-node-agent.md:128-161; current stubs are in apps/exocomp_node/lib/exocomp/node/a2a_router.ex.
---
author: oompah
created: 2026-07-24 01:56
---
Implementation (planning phase): No code or tracker children were created. The existing EXOCOMP-12 decomposition already assigns this cohesive endpoint-wiring slice uniquely to EXOCOMP-81, so the actionable plan remains: add A2A codec/validation, replace four router stubs with TaskRegistry-backed handlers, implement timeout-bounded async Dispatcher execution and transitions, and cover request/error/lifecycle behavior in focused node tests.
---
author: oompah
created: 2026-07-24 01:56
---
Verification (planning phase): Confirmed via Task EXOCOMP-12 - Expose diagnostic-only node A2A service
==================================================
Status: Open
Priority: 1
Project: exocomp
Labels: focus-complete:duplicate_detector

Description:
Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Expose diagnostic-only node A2A service.

Implementation
Publish the node Agent Card and diagnostic skills exocomp.system.diagnose, exocomp.service.diagnose, and exocomp.remediation.propose over mTLS; implement send, task get/list/cancel, bounded in-memory task history, body/time limits, and standards-defined unsupported responses; advertise no state-changing capability.

Testing
Add A2A contract tests, mTLS authentication tests, concurrent task tests, cancellation, eviction, request limit, collector failure, inference failure, and unsupported-operation cases.

Acceptance Criteria
- [ ] Authenticated clients receive schema-valid diagnostic artifacts.
- [ ] Unauthenticated clients are rejected before request handling.
- [ ] Task history and concurrency are bounded.
- [ ] The Agent Card exposes no execution skill.
- [ ] All service and protocol tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

Children:
  - EXOCOMP-78: A2A router scaffold, Agent Card endpoint, and mTLS enforcement [Done]
  - EXOCOMP-79: Bounded in-memory task registry GenServer [Done]
  - EXOCOMP-80: Skill handler implementations: system.diagnose, service.diagnose, remediation.propose [Done]
  - EXOCOMP-81: Wire A2A message endpoints to TaskRegistry and skill dispatch [In Progress]

Comments:
  #1 - oompah - 2026-07-23 22:49
    Agent dispatched (profile: default)
  #2 - oompah - 2026-07-23 22:49
    Focus: Duplicate Investigator
  #3 - oompah - 2026-07-23 22:51
    Focus handoff: duplicate_detector
    
    **Outcome:** No duplicate confirmed. EXOCOMP-12 is a unique task with no overlap in the existing task graph.
    
    **Evidence reviewed:**
    - Reviewed all 7 M1 sibling tasks (EXOCOMP-7 through EXOCOMP-13) and their child tasks (EXOCOMP-48, EXOCOMP-49, EXOCOMP-51, EXOCOMP-57 through EXOCOMP-64)
    - EXOCOMP-7 (Done): Elixir umbrella scaffold only — no A2A HTTP routing or service endpoints
    - EXOCOMP-8 (Done): A2A 1.0 shared protocol TYPE definitions only (codecs, structs, fixtures) — not the HTTP service layer
    - EXOCOMP-9 (Done): Node config, identity, mTLS listener STARTUP — provides the TLS listener foundation but not the A2A request handlers, task registry, or skill routing
    - EXOCOMP-10 (Done): Linux/systemd diagnostic COLLECTORS — data collection modules invoked BY skills, not the A2A service itself
    - EXOCOMP-11 (Done): llama.cpp supervision and proposal VALIDATION — inference layer invoked BY exocomp.remediation.propose, not the A2A service
    - EXOCOMP-13 (Open): M1 integration/verification — testing, not implementation
    - EXOCOMP-19 (Open): Coordinator cluster A2A service (Milestone 2) — covers the COORDINATOR agent, not the node agent
    - The EXOCOMP-7 duplicate investigator conducted a comprehensive 47-task scan (EXOCOMP-1 through EXOCOMP-47) and found no overlap with the node A2A service implementation scope
    - Prior duplicate investigators for EXOCOMP-8, 9, 10, 11 each explicitly identified EXOCOMP-12 as a distinct task covering the HTTP service layer
    
    **EXOCOMP-12 scope is uniquely:** Plug/Bandit HTTP router for Agent Card endpoint + A2A send/task-get/list/cancel handlers; in-memory bounded task registry; skill dispatch to collector and inference layers; request body and time limits; UnsupportedOperation responses; mTLS client authentication enforcement; Agent Card JSON with skills (exocomp.system.diagnose, exocomp.service.diagnose, exocomp.remediation.propose) and no execution capabilities.
    
    **Relevant files for implementation agent:**
    - apps/exocomp_node/ — where the A2A service router and task registry belong
    - apps/exocomp_core/lib/exocomp/a2a/ — A2A type structs from EXOCOMP-8 (AgentCard, Task, Message, etc.)
    - apps/exocomp_node/lib/exocomp/node/listeners/ — mTLS Bandit listener from EXOCOMP-9
    - apps/exocomp_node/lib/exocomp/node/collectors/ — collectors from EXOCOMP-10
    - apps/exocomp_node/lib/exocomp/node/proposal_client.ex — ProposalClient from EXOCOMP-11
    - plans/milestone-1-node-agent.md — A2A Interface section (endpoints, skills, limits), Test Strategy, Acceptance Criteria
    
    **Remaining work:**
    1. Implement Agent Card JSON handler (GET /.well-known/agent-card.json) with skills and no streaming/push
    2. Implement Plug router for all A2A endpoints
    3. Implement in-memory task registry GenServer with bounded history (age+count eviction), state machine transitions, cancellation
    4. Implement skill handlers dispatching to collectors and ProposalClient
    5. Enforce mTLS auth before request decoding, body size limits, timeouts
    6. Return UnsupportedOperationError for streaming/push requests
    7. Add A2A contract tests, mTLS auth tests, concurrent task tests, cancellation, eviction, request limit, collector failure, inference failure, unsupported-operation cases
    8. Run make test, make lint, make fmt-check
    
    **Recommended next focus:** feature — this is a substantial Elixir/Plug implementation task covering the HTTP service layer, task registry, and comprehensive test suite
  #4 - oompah - 2026-07-23 22:51
    Agent completed successfully in 137s (5595 tokens)
  #5 - oompah - 2026-07-23 22:51
    Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
    - Turns: 42, Tool calls: 30
    - Tokens: 23 in / 5.6K out [5.6K total]
    - Cost: $0.0000
    - Exit: normal, Duration: 2m 17s
    - Log: EXOCOMP-12__20260723T224921Z.jsonl
  #6 - oompah - 2026-07-23 22:51
    Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
  #7 - oompah - 2026-07-23 22:51
    Agent dispatched (profile: standard)
  #8 - oompah - 2026-07-23 22:51
    Focus: Epic Planner
  #9 - oompah - 2026-07-23 22:58
    Agent completed successfully in 378s (839755 tokens)
  #10 - oompah - 2026-07-23 22:58
    Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
    - Turns: 1, Tool calls: 15
    - Tokens: 832.8K in / 6.9K out [839.8K total]
    - Cost: $0.0000
    - Exit: normal, Duration: 6m 18s
    - Log: EXOCOMP-12__20260723T225149Z.jsonl
  #11 - oompah - 2026-07-23 22:58
    Agent completed without closing this issue (378s (839755 tokens)). Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
  #12 - oompah - 2026-07-23 22:58
    Agent dispatched (profile: deep)
  #13 - oompah - 2026-07-23 22:58
    Focus: Epic Planner
  #14 - oompah - 2026-07-23 23:03
    **Understanding (Epic Planner):** EXOCOMP-12 is the node A2A service epic. Based on codebase exploration:
    
    **Prerequisite code in branches (not yet in main):**
    - `origin/epic-EXOCOMP-8`: A2A type structs (AgentCard, Task, Message, errors, etc.) in apps/exocomp_core/lib/exocomp/a2a/
    - `EXOCOMP-10` / `EXOCOMP-60`: Diagnostic collectors (CPU, Disk, Memory, Systemd, Uptime) in apps/exocomp_node/lib/exocomp/node/collectors/
    - `EXOCOMP-60`: mTLS Listener GenServer + Config + Identity + Plug.Stub in apps/exocomp_node/lib/exocomp/node/
    - `epic-EXOCOMP-11` / `EXOCOMP-63`: LlamaServer + ProposalClient + ProposalSchema in apps/exocomp_node/lib/exocomp/node/
    
    **Core implementation gap (EXOCOMP-12 scope):**
    The mTLS Listener currently uses Exocomp.Node.Plug.Stub. EXOCOMP-12 must replace it with a real A2A Plug router covering Agent Card, message send, task get/list/cancel, with bounded task registry and skill dispatch.
    
    **Decomposition plan:** 5 child tasks covering (A) router scaffold + Agent Card + mTLS enforcement, (B) bounded task registry, (C) skill handlers, (D) endpoint wiring, (E) test suite + quality gate.
  #15 - oompah - 2026-07-23 23:05
    Run #2 [attempt=2, profile=deep, role=deep -> Claude/default]
    - Turns: 0, Tool calls: 77
    - Tokens: 113 in / 3.9K out [4.0K total]
    - Cost: $0.0000
    - Exit: terminated, Duration: 7m 26s
    - Log: EXOCOMP-12__20260723T225822Z.jsonl that EXOCOMP-81 is the final implementation child alongside three completed prerequisites, and inspected the milestone A2A contract plus current router stubs. ## epic-EXOCOMP-12...origin/epic-EXOCOMP-12 is clean and up to date on epic-EXOCOMP-12; no code quality gate was applicable because this phase made no repository changes.
---
author: oompah
created: 2026-07-24 01:56
---
Focus handoff: epic_planner

Outcome: EXOCOMP-81 requires no further decomposition. It is already the cohesive endpoint-integration child of EXOCOMP-12 and is appropriately sized for one feature-agent session; no child tasks or code changes were created.

Evidence and decisions: Task EXOCOMP-12 - Expose diagnostic-only node A2A service
==================================================
Status: Open
Priority: 1
Project: exocomp
Labels: focus-complete:duplicate_detector

Description:
Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Expose diagnostic-only node A2A service.

Implementation
Publish the node Agent Card and diagnostic skills exocomp.system.diagnose, exocomp.service.diagnose, and exocomp.remediation.propose over mTLS; implement send, task get/list/cancel, bounded in-memory task history, body/time limits, and standards-defined unsupported responses; advertise no state-changing capability.

Testing
Add A2A contract tests, mTLS authentication tests, concurrent task tests, cancellation, eviction, request limit, collector failure, inference failure, and unsupported-operation cases.

Acceptance Criteria
- [ ] Authenticated clients receive schema-valid diagnostic artifacts.
- [ ] Unauthenticated clients are rejected before request handling.
- [ ] Task history and concurrency are bounded.
- [ ] The Agent Card exposes no execution skill.
- [ ] All service and protocol tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

Children:
  - EXOCOMP-78: A2A router scaffold, Agent Card endpoint, and mTLS enforcement [Done]
  - EXOCOMP-79: Bounded in-memory task registry GenServer [Done]
  - EXOCOMP-80: Skill handler implementations: system.diagnose, service.diagnose, remediation.propose [Done]
  - EXOCOMP-81: Wire A2A message endpoints to TaskRegistry and skill dispatch [In Progress]

Comments:
  #1 - oompah - 2026-07-23 22:49
    Agent dispatched (profile: default)
  #2 - oompah - 2026-07-23 22:49
    Focus: Duplicate Investigator
  #3 - oompah - 2026-07-23 22:51
    Focus handoff: duplicate_detector
    
    **Outcome:** No duplicate confirmed. EXOCOMP-12 is a unique task with no overlap in the existing task graph.
    
    **Evidence reviewed:**
    - Reviewed all 7 M1 sibling tasks (EXOCOMP-7 through EXOCOMP-13) and their child tasks (EXOCOMP-48, EXOCOMP-49, EXOCOMP-51, EXOCOMP-57 through EXOCOMP-64)
    - EXOCOMP-7 (Done): Elixir umbrella scaffold only — no A2A HTTP routing or service endpoints
    - EXOCOMP-8 (Done): A2A 1.0 shared protocol TYPE definitions only (codecs, structs, fixtures) — not the HTTP service layer
    - EXOCOMP-9 (Done): Node config, identity, mTLS listener STARTUP — provides the TLS listener foundation but not the A2A request handlers, task registry, or skill routing
    - EXOCOMP-10 (Done): Linux/systemd diagnostic COLLECTORS — data collection modules invoked BY skills, not the A2A service itself
    - EXOCOMP-11 (Done): llama.cpp supervision and proposal VALIDATION — inference layer invoked BY exocomp.remediation.propose, not the A2A service
    - EXOCOMP-13 (Open): M1 integration/verification — testing, not implementation
    - EXOCOMP-19 (Open): Coordinator cluster A2A service (Milestone 2) — covers the COORDINATOR agent, not the node agent
    - The EXOCOMP-7 duplicate investigator conducted a comprehensive 47-task scan (EXOCOMP-1 through EXOCOMP-47) and found no overlap with the node A2A service implementation scope
    - Prior duplicate investigators for EXOCOMP-8, 9, 10, 11 each explicitly identified EXOCOMP-12 as a distinct task covering the HTTP service layer
    
    **EXOCOMP-12 scope is uniquely:** Plug/Bandit HTTP router for Agent Card endpoint + A2A send/task-get/list/cancel handlers; in-memory bounded task registry; skill dispatch to collector and inference layers; request body and time limits; UnsupportedOperation responses; mTLS client authentication enforcement; Agent Card JSON with skills (exocomp.system.diagnose, exocomp.service.diagnose, exocomp.remediation.propose) and no execution capabilities.
    
    **Relevant files for implementation agent:**
    - apps/exocomp_node/ — where the A2A service router and task registry belong
    - apps/exocomp_core/lib/exocomp/a2a/ — A2A type structs from EXOCOMP-8 (AgentCard, Task, Message, etc.)
    - apps/exocomp_node/lib/exocomp/node/listeners/ — mTLS Bandit listener from EXOCOMP-9
    - apps/exocomp_node/lib/exocomp/node/collectors/ — collectors from EXOCOMP-10
    - apps/exocomp_node/lib/exocomp/node/proposal_client.ex — ProposalClient from EXOCOMP-11
    - plans/milestone-1-node-agent.md — A2A Interface section (endpoints, skills, limits), Test Strategy, Acceptance Criteria
    
    **Remaining work:**
    1. Implement Agent Card JSON handler (GET /.well-known/agent-card.json) with skills and no streaming/push
    2. Implement Plug router for all A2A endpoints
    3. Implement in-memory task registry GenServer with bounded history (age+count eviction), state machine transitions, cancellation
    4. Implement skill handlers dispatching to collectors and ProposalClient
    5. Enforce mTLS auth before request decoding, body size limits, timeouts
    6. Return UnsupportedOperationError for streaming/push requests
    7. Add A2A contract tests, mTLS auth tests, concurrent task tests, cancellation, eviction, request limit, collector failure, inference failure, unsupported-operation cases
    8. Run make test, make lint, make fmt-check
    
    **Recommended next focus:** feature — this is a substantial Elixir/Plug implementation task covering the HTTP service layer, task registry, and comprehensive test suite
  #4 - oompah - 2026-07-23 22:51
    Agent completed successfully in 137s (5595 tokens)
  #5 - oompah - 2026-07-23 22:51
    Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
    - Turns: 42, Tool calls: 30
    - Tokens: 23 in / 5.6K out [5.6K total]
    - Cost: $0.0000
    - Exit: normal, Duration: 2m 17s
    - Log: EXOCOMP-12__20260723T224921Z.jsonl
  #6 - oompah - 2026-07-23 22:51
    Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
  #7 - oompah - 2026-07-23 22:51
    Agent dispatched (profile: standard)
  #8 - oompah - 2026-07-23 22:51
    Focus: Epic Planner
  #9 - oompah - 2026-07-23 22:58
    Agent completed successfully in 378s (839755 tokens)
  #10 - oompah - 2026-07-23 22:58
    Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
    - Turns: 1, Tool calls: 15
    - Tokens: 832.8K in / 6.9K out [839.8K total]
    - Cost: $0.0000
    - Exit: normal, Duration: 6m 18s
    - Log: EXOCOMP-12__20260723T225149Z.jsonl
  #11 - oompah - 2026-07-23 22:58
    Agent completed without closing this issue (378s (839755 tokens)). Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
  #12 - oompah - 2026-07-23 22:58
    Agent dispatched (profile: deep)
  #13 - oompah - 2026-07-23 22:58
    Focus: Epic Planner
  #14 - oompah - 2026-07-23 23:03
    **Understanding (Epic Planner):** EXOCOMP-12 is the node A2A service epic. Based on codebase exploration:
    
    **Prerequisite code in branches (not yet in main):**
    - `origin/epic-EXOCOMP-8`: A2A type structs (AgentCard, Task, Message, errors, etc.) in apps/exocomp_core/lib/exocomp/a2a/
    - `EXOCOMP-10` / `EXOCOMP-60`: Diagnostic collectors (CPU, Disk, Memory, Systemd, Uptime) in apps/exocomp_node/lib/exocomp/node/collectors/
    - `EXOCOMP-60`: mTLS Listener GenServer + Config + Identity + Plug.Stub in apps/exocomp_node/lib/exocomp/node/
    - `epic-EXOCOMP-11` / `EXOCOMP-63`: LlamaServer + ProposalClient + ProposalSchema in apps/exocomp_node/lib/exocomp/node/
    
    **Core implementation gap (EXOCOMP-12 scope):**
    The mTLS Listener currently uses Exocomp.Node.Plug.Stub. EXOCOMP-12 must replace it with a real A2A Plug router covering Agent Card, message send, task get/list/cancel, with bounded task registry and skill dispatch.
    
    **Decomposition plan:** 5 child tasks covering (A) router scaffold + Agent Card + mTLS enforcement, (B) bounded task registry, (C) skill handlers, (D) endpoint wiring, (E) test suite + quality gate.
  #15 - oompah - 2026-07-23 23:05
    Run #2 [attempt=2, profile=deep, role=deep -> Claude/default]
    - Turns: 0, Tool calls: 77
    - Tokens: 113 in / 3.9K out [4.0K total]
    - Cost: $0.0000
    - Exit: terminated, Duration: 7m 26s
    - Log: EXOCOMP-12__20260723T225822Z.jsonl shows the complete child graph: EXOCOMP-78 router/auth, EXOCOMP-79 TaskRegistry, EXOCOMP-80 skill Dispatcher/handlers, and EXOCOMP-81 wiring. The first three are Done. plans/milestone-1-node-agent.md:128-161 defines exactly the four operational endpoints and bounded lifecycle behavior. apps/exocomp_node/lib/exocomp/node/a2a_router.ex contains the corresponding stubs. Creating grandchildren would duplicate the established decomposition. Because EXOCOMP-81 is a task rather than the epic, it was not moved to Backlog; it should return to Open for feature dispatch.

Remaining work and risks: Implement strict Message decoding and skill/params extraction against actual A2A structs; encode Task/artifact/error shapes with application/a2a+json; wire submit/get/list/cancel; run Dispatcher asynchronously with per-skill timeout and safe terminal transitions; preserve mTLS, version, and body-limit middleware; add all specified endpoint and lifecycle tests. Key risks are races between immediate 202 responses and fast workers, cancellation/worker registration semantics, Plug parsing of , and matching existing Dispatcher/TaskRegistry return shapes.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 01:56
---
Focus handoff: epic_planner (corrected; prior handoff text was altered by shell interpolation)

Outcome: EXOCOMP-81 requires no further decomposition. It is already the cohesive endpoint-integration child of EXOCOMP-12 and is sized for one feature-agent session; no child tasks or code changes were created.

Evidence and decisions: The EXOCOMP-12 task view shows the complete child graph: EXOCOMP-78 router/auth, EXOCOMP-79 TaskRegistry, EXOCOMP-80 skill Dispatcher/handlers, and EXOCOMP-81 wiring. The first three are Done. The A2A section of plans/milestone-1-node-agent.md defines the four operational endpoints and bounded lifecycle behavior. apps/exocomp_node/lib/exocomp/node/a2a_router.ex contains the corresponding stubs. Creating grandchildren would duplicate the established decomposition. Because EXOCOMP-81 is a task rather than the epic, it was not moved to Backlog; it should return to Open for feature dispatch.

Remaining work and risks: Implement strict Message decoding and skill/params extraction against actual A2A structs; encode Task, artifact, and error shapes with application/a2a+json; wire submit/get/list/cancel; run Dispatcher asynchronously with per-skill timeout and safe terminal transitions; preserve mTLS, version, and body-limit middleware; add all specified endpoint and lifecycle tests. Key risks are races between immediate 202 responses and fast workers, cancellation/worker registration semantics, Plug parsing of the task-cancel path, and matching existing Dispatcher/TaskRegistry return shapes.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 01:57
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 0, Tool calls: 16
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 13s
- Log: EXOCOMP-81__20260724T015509Z.jsonl
---
author: oompah
created: 2026-07-24 01:58
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 01:58
---
Focus: Refactoring Specialist
---
author: oompah
created: 2026-07-24 01:58
---
Understanding: Assigned as Refactoring Specialist to EXOCOMP-81. This task requires implementing new A2A endpoint wiring (POST /message:send, GET /tasks/:id, GET /tasks, POST /tasks/:id:cancel) connected to TaskRegistry and skill Dispatcher. I will explore the current codebase state to determine whether there is existing code to refactor or if this is purely new feature work, then hand off appropriately.
---
author: oompah
created: 2026-07-24 02:01
---
Run #1 [attempt=1, profile=standard, role=standard -> Claude/default]
- Turns: 0, Tool calls: 28
- Tokens: 37 in / 1.4K out [1.4K total]
- Cost: $0.0000
- Exit: terminated, Duration: 3m 1s
- Log: EXOCOMP-81__20260724T015830Z.jsonl
---
author: oompah
created: 2026-07-24 02:01
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 02:01
---
Focus: Refactoring Specialist
---
<!-- COMMENTS:END -->

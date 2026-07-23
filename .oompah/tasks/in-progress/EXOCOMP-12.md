---
id: EXOCOMP-12
type: feature
status: In Progress
priority: 1
title: Expose diagnostic-only node A2A service
parent: EXOCOMP-1
children: []
blocked_by:
- EXOCOMP-8
- EXOCOMP-9
- EXOCOMP-10
- EXOCOMP-11
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:08:57.046675Z'
updated_at: '2026-07-23T22:58:06.813654Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 993dcb73-b7be-4287-91c4-108f6568e6e5
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 832860
  total_output_tokens: 12490
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 832860
      output_tokens: 12490
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 23
    output_tokens: 5572
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:51:32.875256+00:00'
  - profile: standard
    model: unknown
    input_tokens: 832837
    output_tokens: 6918
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:58:04.405188+00:00'
---
## Summary

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

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:49
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:51
---
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
---
author: oompah
created: 2026-07-23 22:51
---
Agent completed successfully in 137s (5595 tokens)
---
author: oompah
created: 2026-07-23 22:51
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 42, Tool calls: 30
- Tokens: 23 in / 5.6K out [5.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 17s
- Log: EXOCOMP-12__20260723T224921Z.jsonl
---
author: oompah
created: 2026-07-23 22:51
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 22:51
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:51
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 22:58
---
Agent completed successfully in 378s (839755 tokens)
---
author: oompah
created: 2026-07-23 22:58
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 15
- Tokens: 832.8K in / 6.9K out [839.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 6m 18s
- Log: EXOCOMP-12__20260723T225149Z.jsonl
---
author: oompah
created: 2026-07-23 22:58
---
Agent completed without closing this issue (378s (839755 tokens)). Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
<!-- COMMENTS:END -->

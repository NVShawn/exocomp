---
id: EXOCOMP-78
type: task
status: In Progress
priority: null
title: A2A router scaffold, Agent Card endpoint, and mTLS enforcement
parent: EXOCOMP-12
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T23:04:01.391705Z'
updated_at: '2026-07-24T00:54:53.953660Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 8a442ff5-19cb-4441-a716-09751615bde5
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 21
  total_output_tokens: 6333
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 21
      output_tokens: 6333
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 21
    output_tokens: 6333
    cost_usd: 0.0
    recorded_at: '2026-07-24T00:54:38.891171+00:00'
---
## Summary

### Goal
Implement the Plug/Bandit HTTP router that replaces Exocomp.Node.Plug.Stub with a real A2A 1.0 service. This task establishes the request-handling foundation all other EXOCOMP-12 child tasks build on.

### Prerequisites
The following branches contain prerequisite code that must be merged into this task's working branch before implementation:
- \`origin/epic-EXOCOMP-8\`: A2A type structs in apps/exocomp_core/lib/exocomp/a2a/ (AgentCard, AgentSkill, AgentCapabilities, Task, Message, Artifact, DataPart, errors, etc.)
- \`EXOCOMP-10\` or \`EXOCOMP-60\`: Diagnostic collectors + mTLS Listener + Config + Identity + Plug.Stub in apps/exocomp_node/
- \`epic-EXOCOMP-11\` or \`EXOCOMP-63\`: LlamaServer + ProposalClient + ProposalSchema in apps/exocomp_node/

### Relevant files (after merge)
- apps/exocomp_node/lib/exocomp/node/listener.ex — GenServer that starts Bandit; currently uses Plug.Stub
- apps/exocomp_node/lib/exocomp/node/plug/stub.ex — to be replaced by the real router
- apps/exocomp_node/lib/exocomp/node/application.ex — supervision tree
- apps/exocomp_core/lib/exocomp/a2a/ — A2A types

### Implementation

### mix.exs changes
Add Bandit, Plug, and Jason (or Poison) as deps in apps/exocomp_node/mix.exs and apps/exocomp_core/mix.exs. Add a mix.lock. Update Makefile to use real Mix commands for build, test, lint, fmt, fmt-check.

### Exocomp.Node.A2ARouter (Plug pipeline)
Create apps/exocomp_node/lib/exocomp/node/a2a_router.ex as a Plug.Router (or Plug.Builder) with:

1. **mTLS auth plug** — first plug in the pipeline. Calls Plug.Conn.get_peer_data/1 to check ssl_cert from peer_data. Reject (return 401 JSON error) if no client certificate was presented, before reading the request body. Log the auth outcome.

2. **A2A version check** — check request header 'A2A-Version: 1.0'. Return 400 with InvalidRequestError if missing or wrong.

3. **Body size limit** — use Plug.Parsers with :json parser, max_body_length: 1_048_576 (1 MB), pass_assigns: true. Return 413 if body exceeds limit.

4. **Routes**:
   - GET /.well-known/agent-card.json → AgentCardHandler.call/2 — returns Agent Card JSON (see below)
   - POST /message:send → stub 202 (wired fully in child task D)
   - GET /tasks/:id → stub 200 (wired fully in child task D)
   - GET /tasks → stub 200 (wired fully in child task D)
   - POST /tasks/:id:cancel → stub 200 (wired fully in child task D)
   - POST /message/stream → UnsupportedOperationError (-32004) response
   - POST /tasks/:id/resubscribe → UnsupportedOperationError (-32004) response
   - Catch-all → 404 MethodNotFoundError

### Agent Card
Serve at GET /.well-known/agent-card.json:
```json
{
  "name": "Exocomp Node Agent",
  "description": "Diagnostic-only Exocomp node agent. Cannot modify host state.",
  "url": "https://<node_id>/",
  "version": "0.1.0",
  "capabilities": {
    "streaming": false,
    "pushNotifications": false,
    "stateTransitionHistory": false
  },
  "skills": [
    {"id": "exocomp.system.diagnose", "name": "System Diagnose", "description": "Collect CPU, memory, disk, and uptime observations."},
    {"id": "exocomp.service.diagnose", "name": "Service Diagnose", "description": "Inspect systemd service state for named services."},
    {"id": "exocomp.remediation.propose", "name": "Remediation Propose", "description": "Propose a known remediation intent given current diagnostic context."}
  ]
}
```
No execution capability is advertised.

### Wire into supervision tree
Update Exocomp.Node.Listener to use Exocomp.Node.A2ARouter as the Bandit plug instead of Plug.Stub.

### Tests
- Unit test: GET /.well-known/agent-card.json returns valid JSON with exactly the three skills and capabilities.streaming = false
- Unit test: request without client cert → 401 before body is read
- Unit test: A2A-Version header missing → 400
- Unit test: body over 1 MB → 413
- Unit test: POST /message/stream → UnsupportedOperationError JSON
- Unit test: unknown route → 404

### Quality gate
make test (exocomp_node focused), make lint, make fmt-check

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 00:50
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 00:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 00:52
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 00:52
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 00:52
---
Understanding: Investigating EXOCOMP-78 (A2A router scaffold, Agent Card endpoint, mTLS enforcement) for duplicates. Will search task tracker for existing tasks covering Plug/Bandit HTTP router, A2A routing, mTLS enforcement, and Agent Card endpoint. Task is a child of EXOCOMP-12.
---
author: oompah
created: 2026-07-24 00:54
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-78 is a unique child task with no overlap with any existing task.

**Evidence reviewed:**
- EXOCOMP-12 (parent epic, Open): 'Expose diagnostic-only node A2A service' — EXOCOMP-78 was explicitly created as child task A by the EXOCOMP-12 Epic Planner covering (A) router scaffold + Agent Card + mTLS enforcement. The parent's prior duplicate investigator already scanned EXOCOMP-1 through EXOCOMP-47 and found no competing implementation.
- EXOCOMP-60 (Done): Implements `Exocomp.Node.Listener` (GenServer owning Bandit mTLS server) + `Exocomp.Node.Plug.Stub` — this is the prerequisite foundation. EXOCOMP-78 REPLACES the Plug.Stub with a real router; complementary, not duplicate.
- EXOCOMP-79 (Open): Bounded task registry GenServer — different scope; used by EXOCOMP-81 which depends on EXOCOMP-78.
- EXOCOMP-80 (Open): Skill handler implementations — different scope; invoked by EXOCOMP-81.
- EXOCOMP-81 (Open): Wire A2A message endpoints to TaskRegistry and skill dispatch — explicitly lists EXOCOMP-78 as its prerequisite; different and dependent scope.
- EXOCOMP-63 (Done): ProposalClient inference HTTP client — completely different scope.
- EXOCOMP-70, 71, 72 (Done/Merged): systemd fixture tasks — entirely unrelated.
- EXOCOMP-75 (In Progress): Coordinator PKI bootstrap — entirely unrelated.
- No A2ARouter, agent_card, AgentCardHandler, or /.well-known/agent.json files exist anywhere in the codebase (confirmed via find + grep search).
- No git commits on any branch reference A2ARouter or Agent Card.

**Relevant files for feature agent:**
- apps/exocomp_node/lib/exocomp/node/listener.ex — currently uses Plug.Stub; must be updated to use A2ARouter
- apps/exocomp_node/lib/exocomp/node/plug/stub.ex — from EXOCOMP-60 branch; will be superseded by real router
- apps/exocomp_node/lib/exocomp/node/application.ex — supervision tree
- apps/exocomp_core/lib/exocomp/a2a/ — A2A types (AgentCard, Task, Message, etc.) from epic-EXOCOMP-8
- Prerequisite branches: origin/epic-EXOCOMP-8, EXOCOMP-60 (or origin/epic-EXOCOMP-9), epic-EXOCOMP-11 or EXOCOMP-63

**Remaining work:**
1. Merge prerequisite branches (epic-EXOCOMP-8, EXOCOMP-60, EXOCOMP-63) into EXOCOMP-78 working branch
2. Add Bandit, Plug, Jason deps to mix.exs (some already added in EXOCOMP-60)
3. Create Exocomp.Node.A2ARouter (Plug.Router with mTLS auth plug, A2A version check, body size limit, all routes)
4. Create Exocomp.Node.Handlers.AgentCardHandler (returns Agent Card JSON with 3 skills, no streaming)
5. Update Exocomp.Node.Listener to use A2ARouter instead of Plug.Stub
6. Write all 6 required unit tests (agent card, no cert → 401, missing header → 400, body > 1MB → 413, /message/stream → UnsupportedOperationError, unknown route → 404)
7. Run make test, make lint, make fmt-check

**Recommended next focus:** feature (Elixir/Plug/Bandit implementation)
---
author: oompah
created: 2026-07-24 00:54
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 45, Tool calls: 29
- Tokens: 21 in / 6.3K out [6.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 24s
- Log: EXOCOMP-78__20260724T005217Z.jsonl
---
author: oompah
created: 2026-07-24 00:54
---
Agent completed successfully in 144s (6354 tokens)
---
author: oompah
created: 2026-07-24 00:54
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 00:54
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 00:54
---
Focus: Maintenance Engineer
---
<!-- COMMENTS:END -->

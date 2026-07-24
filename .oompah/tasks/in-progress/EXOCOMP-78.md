---
id: EXOCOMP-78
type: task
status: In Progress
priority: null
title: A2A router scaffold, Agent Card endpoint, and mTLS enforcement
parent: EXOCOMP-12
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T23:04:01.391705Z'
updated_at: '2026-07-24T00:52:16.807141Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: ea0c7eba-61c3-4f91-a4b6-1add55645821
oompah.work_branch: epic-EXOCOMP-1
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
<!-- COMMENTS:END -->

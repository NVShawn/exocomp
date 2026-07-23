---
id: EXOCOMP-11
type: feature
status: Open
priority: 1
title: Supervise llama.cpp and validate structured proposals
parent: EXOCOMP-1
children:
- EXOCOMP-61
- EXOCOMP-62
- EXOCOMP-63
- EXOCOMP-64
blocked_by:
- EXOCOMP-7
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:08:56.242530Z'
updated_at: '2026-07-23T21:53:44.483118Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7bcb788c-a65c-4d23-9455-8e38f27cd7de
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 71
  total_output_tokens: 7251
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 71
      output_tokens: 7251
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 23
    output_tokens: 5856
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:46:18.476349+00:00'
  - profile: default
    model: unknown
    input_tokens: 48
    output_tokens: 1395
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:05:29.897633+00:00'
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Supervise llama.cpp and validate structured proposals.

Implementation
Supervise a pinned loopback-only llama-server process with readiness checks, bounded restart backoff, and independent failure isolation; implement the Qwen2.5 proposal client with fixed prompt, bounded context, timeouts, checksum validation, and strict versioned output schema.

Testing
Use a fake llama-server to test startup, readiness, valid proposal, invalid JSON/schema, timeout, crash/restart, backoff, unavailable model, and output redaction.

Acceptance Criteria
- [ ] A llama.cpp crash cannot terminate node diagnostics or the BEAM.
- [ ] Only schema-valid known proposal IDs are returned.
- [ ] Invalid, timed-out, or unavailable inference never yields an executable action.
- [ ] Focused supervisor/client tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:43
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:43
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:45
---
Understanding: Acting as Duplicate Investigator for EXOCOMP-11 (Supervise llama.cpp and validate structured proposals). Searching all sibling M1 tasks (EXOCOMP-7 through EXOCOMP-13), the milestone plan, and the extended task range for any task covering the same scope: supervising a loopback-only llama-server process, implementing the Qwen2.5 proposal client with fixed prompt/bounded context/timeouts/checksum validation, and validating structured output against a versioned schema.
---
author: oompah
created: 2026-07-23 20:46
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-11 is a unique task with no overlap in the existing task graph.

**Evidence reviewed:**
- Reviewed all 7 M1 sibling tasks (EXOCOMP-7 through EXOCOMP-13)
- EXOCOMP-7 (scaffold, Done): umbrella/OTP/Make gates only — no llama.cpp supervision
- EXOCOMP-8 (A2A protocol types): HTTP+JSON codecs only — no inference process management
- EXOCOMP-9 (node config/identity/mTLS): config loading and TLS only — not llama-server supervision
- EXOCOMP-10 (Linux/systemd collectors): /proc and systemctl only — no inference layer
- EXOCOMP-12 (Node A2A service): exposes the remediation.propose endpoint but does NOT implement the llama-server supervisor or proposal client
- EXOCOMP-13 (M1 verification): uses a fake llama.cpp in integration tests but does not implement supervision
- The EXOCOMP-7 duplicate investigator ran a comprehensive 47-task scan (EXOCOMP-1 through EXOCOMP-47) and found no llama.cpp supervision duplicate
- plans/milestone-1-node-agent.md 'Inference Integration' section explicitly scopes EXOCOMP-11: loopback-only llama-server, readiness polling, restart backoff, Qwen2.5 proposal client, versioned schema validation

**Relevant files:**
- plans/milestone-1-node-agent.md — 'Inference Integration' section (~lines 95–115) defines the full implementation scope
- origin/EXOCOMP-7:apps/exocomp_node — home for the supervisor and client modules (umbrella scaffold is on branch EXOCOMP-7, not yet merged to epic-EXOCOMP-1)
- git branch EXOCOMP-7 at origin has the umbrella: apps/exocomp_node, apps/exocomp_core, apps/exocomp_coordinator, Makefile with containerized build targets

**Remaining work:**
1. Merge/rebase origin/EXOCOMP-7 into epic-EXOCOMP-1 to get the umbrella scaffold
2. Implement Exocomp.Node.LlamaServer (OS process supervisor): spawn llama-server pinned to loopback, poll /health for readiness, bounded restart with exponential backoff, crash isolation
3. Implement Exocomp.Node.ProposalClient (HTTP client): fixed system prompt, bounded diagnostic context, Qwen2.5 completion request with timeout, checksum validation on model binary, parse and validate output against versioned schema, reject invalid/timed-out/unknown output
4. Define the versioned proposal schema (closed list of proposal IDs, required fields, no executable shell commands)
5. Write focused ExUnit tests with a fake llama-server covering: startup, readiness success/timeout, valid proposal, invalid JSON, schema violation, request timeout, crash-and-restart, backoff, unavailable model, output redaction
6. Verify make test, make lint, make fmt-check pass

**Risks:**
- EXOCOMP-7 umbrella is on a separate branch; the feature agent must merge it before implementing EXOCOMP-11
- The fake llama-server for tests can be a simple Plug/Cowboy HTTP server in the test process
- Checksum validation requires the llama-server binary path and expected SHA-256 from config (EXOCOMP-9 scope); for EXOCOMP-11 tests, the model binary check can be stubbed
- Output redaction in audit logs must strip raw model output (sensitive content policy)
- EXOCOMP-9 (mTLS startup) and EXOCOMP-8 (A2A protocol types) both depend on EXOCOMP-7 but not on EXOCOMP-11; EXOCOMP-11 can proceed in parallel

**Recommended next focus:** feature — implement Elixir OTP process supervisor and HTTP client for llama-server supervision and proposal validation
---
author: oompah
created: 2026-07-23 20:46
---
Agent completed successfully in 181s (5879 tokens)
---
author: oompah
created: 2026-07-23 20:46
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 45, Tool calls: 31
- Tokens: 23 in / 5.9K out [5.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 1s
- Log: EXOCOMP-11__20260723T204321Z.jsonl
---
author: oompah
created: 2026-07-23 20:46
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 20:46
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:46
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 21:02
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:02
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 21:03
---
Understanding: Acting as Epic Planner for EXOCOMP-11. This epic requires decomposing the llama.cpp supervision and proposal validation work into 4 focused child tasks: (1) define the versioned proposal schema module, (2) implement the LlamaServer OTP process supervisor, (3) implement the ProposalClient HTTP inference client, and (4) write focused ExUnit tests with a fake llama-server. Prerequisite: EXOCOMP-7 (umbrella scaffold) is Done. Plan doc reference: plans/milestone-1-node-agent.md, Inference Integration section.
---
author: oompah
created: 2026-07-23 21:05
---
Focus handoff: epic_planner

**Outcome:** Epic decomposed into 4 focused child tasks covering the full EXOCOMP-11 scope. Epic status set to Backlog.

**Child tasks created:**
- EXOCOMP-61: Define versioned proposal schema module (foundational, no blocking deps beyond EXOCOMP-7)
- EXOCOMP-62: Implement LlamaServer OTP process supervisor (depends on EXOCOMP-7)
- EXOCOMP-63: Implement ProposalClient inference HTTP client (depends on EXOCOMP-61 + EXOCOMP-62)
- EXOCOMP-64: Write focused ExUnit tests for LlamaServer and ProposalClient (depends on EXOCOMP-62 + EXOCOMP-63)

**Dependency graph:**
EXOCOMP-7 (Done) → EXOCOMP-61, EXOCOMP-62 → EXOCOMP-63 → EXOCOMP-64

**Key design decisions:**
- Fake llama-server uses in-process Plug/Cowboy to avoid real binary dependency in CI
- Checksum validation in ProposalClient uses a configurable stub (real impl in EXOCOMP-9)
- LlamaServer uses :one_for_one isolation under a dedicated supervisor branch
- ProposalClient redacts raw model output in audit logs (replaces with [REDACTED])
- Schema is closed (fixed proposal ID allowlist), versioned, no shell commands

**Relevant files:**
- plans/milestone-1-node-agent.md (Inference Integration + Failure and Security Behavior sections)
- apps/exocomp_node/ (umbrella app from EXOCOMP-7 branch)

**Remaining work:** None for epic_planner. Feature implementation follows task order: EXOCOMP-61 and EXOCOMP-62 can run in parallel (both unblocked), then EXOCOMP-63, then EXOCOMP-64.

**Recommended next focus:** feature — implement EXOCOMP-61 (schema) and EXOCOMP-62 (LlamaServer supervisor) in parallel
---
author: oompah
created: 2026-07-23 21:05
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 30
- Tokens: 48 in / 1.4K out [1.4K total]
- Cost: $0.0000
- Exit: terminated, Duration: 3m 29s
- Log: EXOCOMP-11__20260723T210206Z.jsonl
---
<!-- COMMENTS:END -->

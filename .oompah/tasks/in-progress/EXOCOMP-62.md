---
id: EXOCOMP-62
type: task
status: In Progress
priority: null
title: Implement LlamaServer OTP process supervisor
parent: EXOCOMP-11
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T21:03:55.522595Z'
updated_at: '2026-07-23T21:21:40.967840Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: feeef624-359d-4da9-9abc-cd5fd470adf6
oompah.work_branch: epic-EXOCOMP-1
---
## Summary

### Goal

Implement `Exocomp.Node.LlamaServer`, an OTP GenServer that supervises the llama-server OS process in strict isolation from node diagnostics.

### Context

The node supervision tree must isolate llama.cpp crashes from the rest of the BEAM. This task implements the OS-process lifecycle manager for llama-server. The ProposalClient (sibling task) will call into this module to obtain the running server's base URL.

Reference: plans/milestone-1-node-agent.md, 'Inference Integration' section.

### Implementation

In `apps/exocomp_node/lib/exocomp_node/llama_server.ex`:

- OTP GenServer (or Supervisor+GenServer pair) that manages a single llama-server OS process
- Spawn llama-server with `--host 127.0.0.1` (loopback only) and a configurable port from application config
- After spawn, poll `GET http://127.0.0.1:<port>/health` every 500ms until ready (max configurable timeout, default 30s); enter `:degraded` state on timeout
- Expose `status/0` → `:ready | :starting | :degraded | :stopped`
- Expose `base_url/0` → `{:ok, url} | {:error, :not_ready}`
- On process exit: apply exponential backoff before restart (base 1s, max 60s, jitter); track restart count
- Crash isolation: this GenServer must be under a `:one_for_one` supervisor branch so its crash does NOT propagate to diagnostic collectors or the A2A listener
- Config keys (from application env): `:llama_server_path`, `:llama_model_path`, `:llama_port`, `:llama_host` (default `127.0.0.1`), `:llama_ready_timeout_ms`, `:llama_max_restart_backoff_ms`

### Testing (unit, with stub)

Unit tests go in a sibling task (EXOCOMP-11 tests). This task should include a basic ExUnit smoke test:
- `LlamaServer` starts without error under a test supervisor
- `status/0` returns `:starting` before readiness
- When llama_server_path points to a nonexistent binary, state transitions to `:degraded` without crashing the test process

### Acceptance Criteria
- [ ] A llama.cpp crash cannot terminate node diagnostics or the BEAM
- [ ] Exponential backoff is applied between restarts
- [ ] Status is observable via `status/0`
- [ ] Loopback binding is enforced (no external interface)

### Dependencies
- EXOCOMP-7 (umbrella scaffold, Done)

### Quality Gate
`make test` and `make lint` from the umbrella root must pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:21
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:21
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->

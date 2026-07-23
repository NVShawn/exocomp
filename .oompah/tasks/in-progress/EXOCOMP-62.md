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
labels:
- focus-complete:duplicate_detector
- needs:feature
assignee: null
created_at: '2026-07-23T21:03:55.522595Z'
updated_at: '2026-07-23T21:23:28.591287Z'
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
author: oompah
created: 2026-07-23 21:23
---
Duplicate screening found no duplicate. EXOCOMP-62 is a purpose-built child task of EXOCOMP-11, created by the EXOCOMP-11 Epic Planner to isolate the LlamaServer OS-process supervisor from the ProposalClient (EXOCOMP-63) and tests (EXOCOMP-64).

Tasks reviewed:
- EXOCOMP-11: parent epic covering llama.cpp supervision + proposal validation — too broad, intentionally decomposed into children
- EXOCOMP-61: versioned proposal schema (Done) — foundational, no process management scope
- EXOCOMP-63: ProposalClient HTTP client — depends on EXOCOMP-62's base_url/0 API, does not implement the supervisor
- EXOCOMP-64: test suite — no implementation
- EXOCOMP-7 through EXOCOMP-13: umbrella scaffold, A2A types, identity/TLS, diagnostics, A2A service, verification — none cover OTP process supervision of llama-server
- Sibling milestone tasks EXOCOMP-21, EXOCOMP-27, EXOCOMP-31, EXOCOMP-52: different milestones/domains

Evidence: EXOCOMP-11 comment #13 (Epic Planner handoff) explicitly created EXOCOMP-62 for 'Implement LlamaServer OTP process supervisor'. No other task in the system defines Exocomp.Node.LlamaServer, the status/0 API, base_url/0 API, or llama-server OS process lifecycle management.
---
author: oompah
created: 2026-07-23 21:23
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-62 is unique — it implements the OS-process lifecycle manager for llama-server that no other task covers.

**Evidence:**
- EXOCOMP-11 Epic Planner explicitly created EXOCOMP-62 as a distinct child for the LlamaServer OTP supervisor (comment #13)
- EXOCOMP-61 (Done): proposal schema module — no process management
- EXOCOMP-63 (Open): ProposalClient — consumes LlamaServer.base_url/0 but does NOT implement the supervisor
- EXOCOMP-64 (Open): tests only — depends on this task
- All other M1 tasks (EXOCOMP-7 through EXOCOMP-13) cover different scope: umbrella scaffold, A2A types, identity/TLS, diagnostics, A2A service, verification
- No existing file Exocomp.Node.LlamaServer exists in the codebase

**Relevant files:**
- plans/milestone-1-node-agent.md (Inference Integration section) — defines the design
- apps/exocomp_node/lib/exocomp/node/ — target directory for implementation (EXOCOMP-61 established the module convention Exocomp.Node.*)
- Target file: apps/exocomp_node/lib/exocomp/node/llama_server.ex

**Key implementation notes from EXOCOMP-11 history:**
- Module convention is Exocomp.Node.* (not ExocompNode.*)
- Makefile uses Docker for make test/lint (rootless Docker --user flag issue was fixed in EXOCOMP-61)
- EXOCOMP-61 already merged its branch with the umbrella scaffold; build should work
- Test files go in apps/exocomp_node/test/exocomp/node/

**Remaining work:**
1. Implement Exocomp.Node.LlamaServer GenServer (or Supervisor+GenServer pair) in apps/exocomp_node/lib/exocomp/node/llama_server.ex:
   - Spawn llama-server with --host 127.0.0.1 and configurable port
   - Poll GET /health every 500ms until ready (max configurable timeout, default 30s) or enter :degraded
   - Expose status/0 → :ready | :starting | :degraded | :stopped
   - Expose base_url/0 → {:ok, url} | {:error, :not_ready}
   - Exponential backoff on process exit (base 1s, max 60s, jitter); track restart count
   - Must be under :one_for_one supervisor for crash isolation
   - Config keys: :llama_server_path, :llama_model_path, :llama_port, :llama_host, :llama_ready_timeout_ms, :llama_max_restart_backoff_ms
2. Write smoke tests in apps/exocomp_node/test/exocomp/node/llama_server_test.exs:
   - Starts without error under test supervisor
   - status/0 returns :starting before readiness
   - Nonexistent binary path → :degraded without crashing test process
3. Run make test and make lint

**Risks:**
- Port management in tests: use a random high port to avoid conflicts
- Rebase on the EXOCOMP-61 branch (already merged to epic-EXOCOMP-1 per task history) to get the latest scaffold
- The :sys.get_state approach may not work across supervisor restarts; design state observation carefully

**Recommended next focus:** feature
---
<!-- COMMENTS:END -->

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
assignee: null
created_at: '2026-07-23T21:03:55.522595Z'
updated_at: '2026-07-23T21:37:02.778073Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7434eea5-7b3b-47c0-9d17-d5c4f3fe07f8
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 1977822
  total_output_tokens: 24611
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1977822
      output_tokens: 24611
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 24
    output_tokens: 5098
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:23:38.042504+00:00'
  - profile: standard
    model: unknown
    input_tokens: 1977798
    output_tokens: 19513
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:32:09.777918+00:00'
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
author: oompah
created: 2026-07-23 21:23
---
Agent completed successfully in 120s (5122 tokens)
---
author: oompah
created: 2026-07-23 21:23
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 43, Tool calls: 29
- Tokens: 24 in / 5.1K out [5.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 0s
- Log: EXOCOMP-62__20260723T212141Z.jsonl
---
author: oompah
created: 2026-07-23 21:23
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:23
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:23
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 21:32
---
Agent completed successfully in 504s (1997311 tokens)
---
author: oompah
created: 2026-07-23 21:32
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 36
- Tokens: 2.0M in / 19.5K out [2.0M total]
- Cost: $0.0000
- Exit: normal, Duration: 8m 24s
- Log: EXOCOMP-62__20260723T212347Z.jsonl
---
author: oompah
created: 2026-07-23 21:32
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-11`. Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:32
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-23 21:32
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 21:33
---
Understanding: The previous agent (Codex) already implemented the code and pushed to origin/EXOCOMP-62. Files committed: llama_server.ex (GenServer lifecycle manager), llama_server_test.exs (smoke tests), fixtures/llama-server-stub, and application.ex update. The task was marked 'Agent completed without landing' by the orchestrator, possibly a branch confusion - the Codex agent worked on epic-EXOCOMP-11 branch locally but the commits are actually on EXOCOMP-62. Running quality gates (make test + make lint) now to verify all acceptance criteria are met.
---
author: oompah
created: 2026-07-23 21:37
---
Implementation: Previous agent (Codex) already wrote the core implementation in commit ee74746. The implementation includes:

- apps/exocomp_node/lib/exocomp/node/llama_server.ex: GenServer that spawns llama-server with --host 127.0.0.1, polls /health every 500ms, exposes status/0 and base_url/0, applies exponential backoff (base 1s, max 60s, jittered) on process exit
- apps/exocomp_node/test/exocomp/node/llama_server_test.exs: Smoke tests for startup, :starting status, and :degraded on nonexistent binary
- apps/exocomp_node/test/fixtures/llama-server-stub: stub binary (exec sleep 5)
- apps/exocomp_node/lib/exocomp/node/application.ex: wires LlamaServer into the one_for_one supervisor tree when llama_server_path is configured

Additional fix in this run (d600763): Makefile rootless Docker detection — omit --user flag when running rootless Docker to fix volume write permission errors.
---
<!-- COMMENTS:END -->

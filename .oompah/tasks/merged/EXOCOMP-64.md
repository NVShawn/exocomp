---
id: EXOCOMP-64
type: task
status: Merged
priority: null
title: Write focused ExUnit tests for LlamaServer and ProposalClient
parent: EXOCOMP-11
children: []
blocked_by:
- EXOCOMP-62
- EXOCOMP-63
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:04:41.808383Z'
updated_at: '2026-07-24T03:51:22.356208Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 352f2193-b691-4145-9e76-f48d44c93c2a
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 750108
  total_output_tokens: 18110
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 750108
      output_tokens: 18110
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 18
    output_tokens: 4331
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:51:21.913286+00:00'
  - profile: default
    model: unknown
    input_tokens: 340733
    output_tokens: 3331
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:53:19.042851+00:00'
  - profile: standard
    model: unknown
    input_tokens: 409136
    output_tokens: 4421
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:55:23.388190+00:00'
  - profile: deep
    model: unknown
    input_tokens: 221
    output_tokens: 6027
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:26:27.876340+00:00'
---
## Summary

### Goal

Write the focused ExUnit test suite that validates all acceptance criteria for EXOCOMP-11, using a fake llama-server (in-process Plug/Cowboy HTTP server).

### Context

The acceptance criteria require covering all failure modes: startup, readiness, valid proposals, invalid JSON, schema violations, timeout, crash+restart, backoff, unavailable model, and output redaction. A real llama-server binary is NOT available in CI — all tests use a fake server.

Reference: plans/milestone-1-node-agent.md, 'Test Strategy' and 'Failure and Security Behavior' sections.

### Implementation

### Fake llama-server

Create a test helper `ExocmpNode.Test.FakeLlamaServer` using Cowboy/Bandit+Plug:
- Starts as a supervised process in `setup` blocks, binds to a random loopback port
- Configurable: `/health` response (200 OK, timeout/no-response, 503), `/v1/chat/completions` response (valid JSON, invalid JSON, HTTP 500, timeout)
- Controllable via message-passing from test process

### Test file: `apps/exocomp_node/test/exocomp_node/llama_server_test.exs`

1. **Startup and readiness success**: Fake server returns 200 on `/health`; `LlamaServer.status/0` transitions to `:ready`
2. **Readiness timeout**: Fake server never responds to `/health`; after configured timeout, status becomes `:degraded`; diagnostic supervisor remains running
3. **Crash and restart**: Kill the llama-server OS process (or simulate exit); verify LlamaServer restarts and re-polls readiness
4. **Restart backoff**: Simulate repeated crashes; verify that restart delay increases exponentially (measure timestamps between restart attempts)
5. **Crash isolation**: After simulated crash, verify diagnostic collector GenServers are still alive and responsive

### Test file: `apps/exocomp_node/test/exocomp_node/proposal_client_test.exs`

6. **Valid proposal round-trip**: Fake server returns well-formed JSON matching schema; `propose/1` returns `{:ok, proposal}` with all required fields
7. **Invalid JSON from model**: Fake server returns malformed JSON; `propose/1` returns `{:error, :invalid_json}`; no crash
8. **Schema violation**: Fake server returns valid JSON with unknown proposal_id; `propose/1` returns `{:error, {:schema_error, :unknown_proposal_id}}`
9. **Request timeout**: Fake server hangs on completion request; `propose/1` returns `{:error, :inference_timeout}` within configured timeout + tolerance
10. **Unavailable model**: `LlamaServer` is in `:degraded` state; `propose/1` returns `{:error, :inference_unavailable}` immediately
11. **Output redaction**: After a proposal call, check log output (using `ExUnit.CaptureLog`); raw model content string must NOT appear in logs; only `[REDACTED]` placeholder or validated fields

### Acceptance Criteria
- [ ] All 11 test scenarios pass
- [ ] Tests use only in-process fake server, no real llama-server binary
- [ ] Tests are deterministic (no flakiness from timing — use explicit synchronization)
- [ ] `make test` passes with all tests included

### Dependencies
- EXOCOMP-62 (LlamaServer supervisor)
- EXOCOMP-63 (ProposalClient)

### Quality Gate
`make test`, `make lint`, and `make fmt-check` from umbrella root must all pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:49
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:50
---
Duplicate screening found no duplicate. EXOCOMP-64 is a unique child task of EXOCOMP-11, explicitly created by the Epic Planner (see EXOCOMP-11 comment #13) with a distinct scope: focused ExUnit tests for LlamaServer and ProposalClient using an in-process fake llama-server.

Tasks reviewed:
- EXOCOMP-11: Parent epic (Open) — too broad, intentionally decomposed into 4 children; EXOCOMP-64 is child #4
- EXOCOMP-61: ProposalSchema module (Done) — foundational schema, no test infrastructure
- EXOCOMP-62: LlamaServer OTP supervisor (Done) — implementation only; includes smoke tests but NOT the 11 focused scenarios described in EXOCOMP-64
- EXOCOMP-63: ProposalClient HTTP client (Done) — implementation with unit smoke test, explicitly defers full scenario tests to 'the sibling test task' (this task)
- EXOCOMP-13: M1 milestone verification (Open) — integration/acceptance tests for the full M1 milestone, different scope from focused LlamaServer+ProposalClient unit tests

Evidence: EXOCOMP-63 comment #3 explicitly states 'Full scenario tests are in the sibling test task' (EXOCOMP-64). No existing task defines FakeLlamaServer or the 11 test scenarios required by EXOCOMP-64. Both blocking dependencies (EXOCOMP-62, EXOCOMP-63) are now Done, so EXOCOMP-64 is unblocked.
---
author: oompah
created: 2026-07-23 21:51
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-64 is a unique, original task that is now fully unblocked (EXOCOMP-62 and EXOCOMP-63 are both Done).

**Evidence:**
- EXOCOMP-11 Epic Planner (comment #13) explicitly created EXOCOMP-64 as the 4th child for 'Write focused ExUnit tests for LlamaServer and ProposalClient'
- EXOCOMP-62 (Done): LlamaServer OTP supervisor — includes 3 smoke tests only; not the full 11-scenario suite
- EXOCOMP-63 (Done): ProposalClient — includes unavailability smoke test only; defers full scenarios to this task explicitly
- EXOCOMP-13 (Open): M1 milestone verification — broader integration scope, not a duplicate
- No existing task defines FakeLlamaServer or covers all 11 required test scenarios

**Key implementation context:**
- Module convention: Exocomp.Node.* (not ExocmpNode.*) — see existing modules in apps/exocomp_node/lib/exocomp/node/
- FakeLlamaServer should use Bandit+Plug (already in deps) or :cowboy if available; bind to random loopback port via {:tcp, :loopback, 0}
- Test helper: apps/exocomp_node/test/support/fake_llama_server.ex
- Test files: apps/exocomp_node/test/exocomp/node/llama_server_test.exs AND apps/exocomp_node/test/exocomp/node/proposal_client_test.exs
- LlamaServer exposes status/0 -> :ready | :starting | :degraded | :stopped and base_url/0 -> {:ok, url} | {:error, :not_ready}
- ProposalClient exposes propose/1 -> {:ok, proposal} | {:error, reason}
- EXOCOMP-62 branch is merged into epic-EXOCOMP-1; EXOCOMP-63 must be checked to see if its commits are on epic-EXOCOMP-1 too
- ProposalClient uses :httpc (built-in inets), raw model output is always [REDACTED] in logs
- Makefile uses Docker for quality gates (make test, make lint, make fmt-check)
- Check the existing tests in apps/exocomp_node/test/ for patterns before writing new tests

**Remaining work:**
1. Examine current state of apps/exocomp_node/lib/exocomp/node/ and test/ directories
2. Implement FakeLlamaServer test helper (controllable via message-passing; configurable /health and /v1/chat/completions responses)
3. Write llama_server_test.exs: 5 scenarios (startup success, readiness timeout, crash+restart, restart backoff, crash isolation)
4. Write proposal_client_test.exs: 6 scenarios (valid round-trip, invalid JSON, schema violation, request timeout, unavailable model, output redaction)
5. Run make test, make lint, make fmt-check
6. Commit and push

**Risks:**
- Timing tests (backoff measurement) require careful synchronization; use explicit receive/assert_receive patterns with Process.monitor rather than :timer.sleep
- LlamaServer crash simulation: need to access the OS pid via GenServer state or use a test-only stop/start mechanism
- If EXOCOMP-63 commits aren't on epic-EXOCOMP-1, the agent must merge/rebase first
- Port conflicts: always use port 0 (OS-assigned) for fake server

**Recommended next focus:** test
---
author: oompah
created: 2026-07-23 21:51
---
Agent completed successfully in 107s (4349 tokens)
---
author: oompah
created: 2026-07-23 21:51
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 31, Tool calls: 21
- Tokens: 18 in / 4.3K out [4.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 47s
- Log: EXOCOMP-64__20260723T214940Z.jsonl
---
author: oompah
created: 2026-07-23 21:51
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:51
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:51
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-23 21:53
---
Agent completed successfully in 105s (344064 tokens)
---
author: oompah
created: 2026-07-23 21:53
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 6
- Tokens: 340.7K in / 3.3K out [344.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 45s
- Log: EXOCOMP-64__20260723T215135Z.jsonl
---
author: oompah
created: 2026-07-23 21:53
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-11`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:53
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:53
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-23 21:55
---
Agent completed successfully in 106s (413557 tokens)
---
author: oompah
created: 2026-07-23 21:55
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 22
- Tokens: 409.1K in / 4.4K out [413.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 46s
- Log: EXOCOMP-64__20260723T215338Z.jsonl
---
author: oompah
created: 2026-07-23 21:55
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-11`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 21:55
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 21:55
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-23 21:57
---
Understanding: This task requires writing focused ExUnit tests for LlamaServer and ProposalClient. The current branch (epic-EXOCOMP-11) is at commit 182db99 and needs to incorporate EXOCOMP-62 (LlamaServer) and EXOCOMP-63 (ProposalClient) implementations. Previous agent runs had no commits because no actual code was written. My plan: (1) rebase epic-EXOCOMP-11 on origin/EXOCOMP-63 to get all dependencies, (2) create FakeLlamaServer test helper, (3) expand llama_server_test.exs with all 5 scenarios, (4) expand proposal_client_test.exs with all 6 scenarios, (5) run quality gates, (6) commit and push.
---
author: oompah
created: 2026-07-23 22:07
---
Discovery: Found the codebase with all dependencies in place after rebasing onto origin/EXOCOMP-63. Key findings: (1) LlamaServer uses raw TCP for health checks on its configured port_number, not the port the OS process listens on - this means FakeLlamaServer just needs to listen on the same port as llama_port config. (2) ProposalClient uses :httpc for completions requests. (3) No external HTTP framework deps (no Plug/Bandit/Cowboy) - need raw TCP server. (4) llama-server-stub is 'exec sleep 5', so LlamaServer tests need to account for 5-second stub lifetime. (5) Current 37 tests all pass. Implementation plan: create FakeLlamaServer TCP HTTP server helper, expand llama_server_test.exs (5 scenarios), expand proposal_client_test.exs (6 scenarios).
---
author: oompah
created: 2026-07-23 22:25
---
Implementation: Created all required test infrastructure and wrote all 11 EXOCOMP-64 test scenarios.

New files:
- apps/exocomp_node/test/support/fake_llama_server.ex: In-process TCP HTTP server using :gen_tcp, no external deps. Handles /health (health_mode: :ok/:error_503/:timeout) and /v1/chat/completions (completions_mode: :valid_json/:schema_violation/:invalid_json/:error_500/:timeout). Controllable via message-passing.
- apps/exocomp_node/test/fixtures/llama-server-forever: Long-running stub (sleep 300) for crash/restart tests.

Modified files:
- llama_server_test.exs: 5 new scenarios + 3 retained smoke tests = 8 tests
- proposal_client_test.exs: 7 new scenarios + 7 retained tests = 14 tests  
- test_helper.exs: require support file; ensure :public_key in code path for :httpc in OTP 27+

Key implementation decisions:
- LlamaServer crash simulation uses System.cmd kill -TERM on OS PID (from Port.info/2) rather than Port.close/1 to avoid port ownership issues
- Backoff test uses a non-existent executable (never recovers to :ready) so backoff_attempt accumulates and can be measured
- Output redaction test uses a custom OTP :logger handler that captures raw log events+metadata, allowing verification that raw_model_output: '[REDACTED]' is present in the emitted event metadata
- FakeLlamaServer accept loop uses 50ms gen_tcp.accept timeout to stay responsive without blocking the GenServer
---
author: oompah
created: 2026-07-23 22:26
---
Verification: All tests pass.

Local run (via extracted OTP toolchain):
- mix test: 52 tests pass (2 exocomp_core + 1 exocomp_coordinator + 49 exocomp_node)
- make lint: passed (mix format --check-formatted + compile --warnings-as-errors)
- make fmt-check: passed

Test count breakdown:
- llama_server_test.exs: 8 tests (3 smoke + 5 new scenarios)
- proposal_client_test.exs: 14 tests (7 smoke + 7 new scenarios)
- proposal_schema_test.exs: 23 tests (existing, all still pass)
- application_test.exs: 1 test (existing)

All 11 EXOCOMP-64 acceptance criteria scenarios have passing tests. Tests use only the in-process FakeLlamaServer — no real llama-server binary.
---
author: oompah
created: 2026-07-23 22:26
---
Completion: EXOCOMP-64 delivered. Branch epic-EXOCOMP-11 pushed to origin.

Delivered:
- FakeLlamaServer in-process TCP HTTP server test helper
- 5 focused LlamaServer scenarios (startup, readiness timeout, crash+restart, exponential backoff, crash isolation)
- 6 focused ProposalClient scenarios (valid round-trip, invalid JSON, schema violation, timeout, unavailable model, output redaction)
- All 11 acceptance criteria scenarios pass
- make lint and make fmt-check both clean
- 52 total tests pass (12 net new)

Security: Verified raw model content never appears in log output and raw_model_output: '[REDACTED]' metadata is present in audit log events on both success and error paths.
---
author: oompah
created: 2026-07-23 22:26
---
Implemented all 11 focused ExUnit test scenarios for LlamaServer and ProposalClient. Created FakeLlamaServer in-process TCP HTTP test helper (no external deps), llama-server-forever fixture, and expanded both test files with full scenario coverage. All 52 tests pass, lint and fmt-check clean. Branch epic-EXOCOMP-11 pushed to origin.
---
author: oompah
created: 2026-07-23 22:26
---
Run #3 [attempt=3, profile=deep, role=deep -> Claude/default]
- Turns: 0, Tool calls: 136
- Tokens: 221 in / 6.0K out [6.2K total]
- Cost: $0.0000
- Exit: terminated, Duration: 30m 36s
- Log: EXOCOMP-64__20260723T215553Z.jsonl
---
<!-- COMMENTS:END -->

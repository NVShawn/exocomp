---
id: EXOCOMP-64
type: task
status: In Progress
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
updated_at: '2026-07-23T21:51:14.745483Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 6019e82a-0d5e-44d9-880e-03056ad6f125
oompah.work_branch: epic-EXOCOMP-1
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
<!-- COMMENTS:END -->

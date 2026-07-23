---
id: EXOCOMP-64
type: task
status: Backlog
priority: null
title: Write focused ExUnit tests for LlamaServer and ProposalClient
parent: EXOCOMP-11
children: []
blocked_by:
- EXOCOMP-62
- EXOCOMP-63
labels: []
assignee: null
created_at: '2026-07-23T21:04:41.808383Z'
updated_at: '2026-07-23T21:05:01.040520Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

